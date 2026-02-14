import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:vpnsheild/utils/preferences.dart';

class AdsController extends GetxController {
  // --------------------------------------------------------------------------
  // ADS
  // --------------------------------------------------------------------------
  BannerAd? bannerAd;
  BannerAd? bannerAd2;
  InterstitialAd? interstitialAd;

  RxBool isBannerAdLoaded = false.obs;
  RxBool isBannerAd2Loaded = false.obs;

  // --------------------------------------------------------------------------
  // STATE (Rx)
  // --------------------------------------------------------------------------
  final isBannerLoading = false.obs;
  final isBannerLoading2 = false.obs;

  final isSubscribed = (Prefs.getBool('isSubscribed') ?? false).obs;

  int _bannerRetry = 0;
  int _bannerRetry2 = 0;
  int _interstitialRetry = 0;

  bool _showWhenReady = false;

  // --------------------------------------------------------------------------
  // GETTERS (UI SAFE)
  // --------------------------------------------------------------------------
  BannerAd? get banner =>
      (!isSubscribed.value && bannerAd != null) ? bannerAd : null;

  BannerAd? get banner2 =>
      (!isSubscribed.value && bannerAd2 != null) ? bannerAd2 : null;

  // --------------------------------------------------------------------------
  // BANNER 1
  // --------------------------------------------------------------------------
  Future<void> loadBanner() async {
    if (isSubscribed.value) return;
    if (isBannerLoading.value || bannerAd != null) return;

    debugPrint('BANNER: load called');

    isBannerLoading.value = true;

    final adUnitId = kDebugMode
        ? 'ca-app-pub-3940256099942544/9214589741'
        : 'ca-app-pub-5697489208417002/5399948448'; // ← YOUR NEW BANNER ID

    final banner = BannerAd(
      adUnitId: adUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('BANNER: Loaded');
          isBannerAdLoaded.value = true;
          isBannerLoading.value = false;
          _bannerRetry = 0;
        },
        onAdFailedToLoad: (ad, error) {
          isBannerAdLoaded.value = false;
          debugPrint('BANNER: Failed → $error');
          ad.dispose();
          bannerAd = null;
          isBannerLoading.value = false;

          if (_bannerRetry < 2) {
            _bannerRetry++;
            Future.delayed(
              Duration(seconds: 2 * _bannerRetry),
              loadBanner,
            );
          }
        },
      ),
    );

    bannerAd = banner;
    banner.load();
    loadBanner2();
  }

  // --------------------------------------------------------------------------
  // BANNER 2 (MEDIUM RECTANGLE)
  // --------------------------------------------------------------------------
  Future<void> loadBanner2() async {
    if (isSubscribed.value) return;
    if (isBannerLoading2.value || bannerAd2 != null) return;

    debugPrint('BANNER2: load called');

    isBannerLoading2.value = true;

    final adUnitId = kDebugMode
        ? 'ca-app-pub-3940256099942544/6300978111'
        : 'ca-app-pub-5697489208417002/5399948448';

    final banner = BannerAd(
      adUnitId: adUnitId,
      size: AdSize.mediumRectangle,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('BANNER2: Loaded');
          isBannerAd2Loaded.value = true;
          isBannerLoading2.value = false;
          _bannerRetry2 = 0;
        },
        onAdFailedToLoad: (ad, error) {
          isBannerAd2Loaded.value = false;
          debugPrint('BANNER2: Failed → $error');
          ad.dispose();
          bannerAd2 = null;
          isBannerLoading2.value = false;

          if (_bannerRetry2 < 2) {
            _bannerRetry2++;
            Future.delayed(
              Duration(seconds: 2 * _bannerRetry2),
              loadBanner2,
            );
          }
        },
      ),
    );

    bannerAd2 = banner;
    banner.load();
  }

  // --------------------------------------------------------------------------
  // DISPOSE BANNERS
  // --------------------------------------------------------------------------
  Future<void> disposeBanner() async {
    isBannerAdLoaded.value = false;
    if (bannerAd == null) return;
    await bannerAd!.dispose();
    bannerAd = null;
    isBannerLoading.value = false;
  }

  Future<void> disposeBanner2() async {
    isBannerAd2Loaded.value = false;
    if (bannerAd2 == null) return;
    await bannerAd2!.dispose();
    bannerAd2 = null;
    isBannerLoading2.value = false;
  }

  // --------------------------------------------------------------------------
  // INTERSTITIAL
  // --------------------------------------------------------------------------
  Future<void> preloadInterstitial() async {
    if (isSubscribed.value || interstitialAd != null) return;

    final adUnitId = kDebugMode
        ? 'ca-app-pub-3940256099942544/1033173712'
        : 'ca-app-pub-5697489208417002/1955527454'; // ← YOUR NEW INTERSTITIAL ID

    InterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          interstitialAd = ad;
          _interstitialRetry = 0;
          debugPrint('INTERSTITIAL: Loaded');

          if (_showWhenReady) {
            _showWhenReady = false;
            showInterstitial();
          }
        },
        onAdFailedToLoad: (error) {
          debugPrint('INTERSTITIAL: Failed → $error');
          interstitialAd = null;

          if (_interstitialRetry < 3) {
            _interstitialRetry++;
            Future.delayed(
              Duration(seconds: 2 * _interstitialRetry),
              preloadInterstitial,
            );
          }
        },
      ),
    );
  }

  Future<void> showInterstitial() async {
    if (isSubscribed.value) return;

    if (interstitialAd == null) {
      _showWhenReady = true;
      preloadInterstitial();
      return;
    }

    interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        interstitialAd = null;
        preloadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        interstitialAd = null;
        preloadInterstitial();
      },
    );

    interstitialAd!.show();
    // interstitialAd = null;
  }

  // --------------------------------------------------------------------------
  // SUBSCRIPTION
  // --------------------------------------------------------------------------
  void setSubscriptionStatus() {
    final bool newStatus = Prefs.getBool('isSubscribed') ?? false;

    if (newStatus == isSubscribed.value) return;

    isSubscribed.value = newStatus;
    debugPrint('SUBSCRIPTION CHANGED: ${isSubscribed.value}');

    if (isSubscribed.value) {
      interstitialAd?.dispose();
      interstitialAd = null;
      disposeBanner();
      disposeBanner2();
    } else {
      preloadInterstitial();
    }
  }

  // --------------------------------------------------------------------------
  // CLEANUP
  // --------------------------------------------------------------------------
  @override
  void onClose() {
    bannerAd?.dispose();
    bannerAd2?.dispose();
    interstitialAd?.dispose();
    super.onClose();
  }
}

