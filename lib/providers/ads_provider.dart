import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:vpnprowithjava/utils/preferences.dart';

class AdsProvider with ChangeNotifier {
  // --------------------------------------------------------------------------
  // VARIABLES
  // --------------------------------------------------------------------------
  BannerAd? _bannerAd, _bannerAd2;
  InterstitialAd? _interstitialAd;

  bool _isBannerLoading = false;
  bool _isBannerLoading2 = false;

  // bool _isBannerDisposed = false;

  bool _isSubscribed = Prefs.getBool('isSubscribed') ?? false;

  int _bannerRetry = 0;
  int _bannerRetry2 = 0;
  int _interstitialRetry = 0;

  // --------------------------------------------------------------------------
  // GETTERS
  // --------------------------------------------------------------------------
  bool get isSubscribed => _isSubscribed;

  BannerAd? get getBannerAd =>
      (!_isSubscribed && _bannerAd != null) ? _bannerAd : null;

  BannerAd? get getBannerAd2 =>
      (!_isSubscribed && _bannerAd2 != null) ? _bannerAd2 : null;

  //
  bool get isBannerLoading => _isBannerLoading;

  bool get isBannerLoading2 => _isBannerLoading2;

  // --------------------------------------------------------------------------
  // BANNER ADS
  // --------------------------------------------------------------------------

  Future<void> loadBanner() async {
    if (_isSubscribed) return;
    if (_isBannerLoading || _bannerAd != null) return;

    debugPrint('BANNER: load called');

    _isBannerLoading = true;
    // _isBannerDisposed = false;

    final adUnitId = kDebugMode
        ? 'ca-app-pub-3940256099942544/6300978111'
        : 'ca-app-pub-5697489208417002/3946036672';

    final banner = BannerAd(
      adUnitId: adUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('BANNER: Loaded');
          _isBannerLoading = false;
          _bannerRetry = 0;
          notifyListeners();
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('BANNER: Failed → $error');
          ad.dispose();
          _bannerAd = null;
          _isBannerLoading = false;

          if (_bannerRetry < 2) {
            _bannerRetry++;
            Future.delayed(
              Duration(seconds: 2 * _bannerRetry),
              loadBanner,
            );
          }

          notifyListeners();
        },
        onAdClosed: (ad) {
          debugPrint('BANNER: Closed');
          // _isBannerDisposed = true;
          notifyListeners();
        },
      ),
    );

    _bannerAd = banner; // ✅ ASSIGN IMMEDIATELY
    await banner.load();
  }

  Future<void> loadBanner2() async {
    if (_isSubscribed) return;
    if (_isBannerLoading2 || _bannerAd2 != null) return;

    debugPrint('BANNER: load called');

    _isBannerLoading2 = true;

    final adUnitId = kDebugMode
        ? "ca-app-pub-3940256099942544/9214589741" //test Id
        : "ca-app-pub-5697489208417002/5217883603";

    final banner = BannerAd(
      adUnitId: adUnitId,
      size: AdSize.largeBanner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('BANNER: Loaded');
          _isBannerLoading2 = false;
          _bannerRetry2 = 0;
          notifyListeners();
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('BANNER: Failed → $error');
          ad.dispose();
          _bannerAd2 = null;
          _isBannerLoading2 = false;

          if (_bannerRetry2 < 2) {
            _bannerRetry2++;
            Future.delayed(
              Duration(seconds: 2 * _bannerRetry2),
              loadBanner2,
            );
          }

          notifyListeners();
        },
        onAdClosed: (ad) {
          debugPrint('BANNER: Closed');
          notifyListeners();
        },
      ),
    );

    _bannerAd2 = banner; // ✅ ASSIGN IMMEDIATELY
    await banner.load();
  }

  Future<void> disposeBanner() async {
    if (_bannerAd == null) return;

    debugPrint('BANNER: Disposing');
    try {
      await _bannerAd!.dispose();
    } catch (_) {}

    _bannerAd = null;
    // _isBannerDisposed = true;
    _isBannerLoading = false;
    notifyListeners();
  }

  Future<void> disposeBanner2() async {
    if (_bannerAd2 == null) return;

    debugPrint('BANNER: Disposing');
    try {
      await _bannerAd2!.dispose();
    } catch (_) {}

    _bannerAd2 = null;
    // _isBannerDisposed = true;
    _isBannerLoading2 = false;
    notifyListeners();
  }

  // Future<void> reloadBanner() async {
  //   if (_isSubscribed) return;
  //   await disposeBanner();
  //   await loadBanner();
  // }

  // --------------------------------------------------------------------------
  // INTERSTITIAL ADS
  // --------------------------------------------------------------------------
  void preloadInterstitial() {
    if (_isSubscribed) return;
    if (_interstitialAd != null) return;

    final adUnitId = kDebugMode
        ? 'ca-app-pub-3940256099942544/1033173712'
        : 'ca-app-pub-5697489208417002/1319873339';
    // : 'ca-app-pub-5697489208417002/4944397076';

    InterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _interstitialRetry = 0;
          debugPrint('INTERSTITIAL: Loaded');
        },
        onAdFailedToLoad: (error) {
          debugPrint('INTERSTITIAL: Failed → $error');
          _interstitialAd = null;

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
    if (_isSubscribed) return;

    if (_interstitialAd == null) {
      debugPrint("INTERSTITIAL: Not ready, loading...");
      preloadInterstitial();
      return;
    }

    try {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          debugPrint('INTERSTITIAL: Closed, reloading...');
          ad.dispose();
          _interstitialAd = null;
          preloadInterstitial();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          debugPrint('INTERSTITIAL: Show failed → $error');
          ad.dispose();
          _interstitialAd = null;
          preloadInterstitial();
        },
        onAdShowedFullScreenContent: (ad) {
          debugPrint('Interstitial ad showed');
        },
      );

      await _interstitialAd!.show();
      _interstitialAd = null;
    } catch (e) {
      debugPrint("INTERSTITIAL: Failed to show → $e");
      _interstitialAd?.dispose();
      _interstitialAd = null;
      preloadInterstitial(); // preload next ad
    }
  }

  // --------------------------------------------------------------------------
  // SUBSCRIPTION HANDLING
  // --------------------------------------------------------------------------
  void setSubscriptionStatus() {
    bool newStatus = Prefs.getBool('isSubscribed') ?? false;

    if (newStatus == _isSubscribed) return;

    _isSubscribed = newStatus;
    debugPrint('SUBSCRIPTION CHANGED: $_isSubscribed');

    if (_isSubscribed) {
      // disposeBanner();
      _interstitialAd?.dispose();
      _interstitialAd = null;
      disposeBanner();
      disposeBanner2();
    } else {
      // loadBanner();
      preloadInterstitial();
    }

    notifyListeners();
  }

  // --------------------------------------------------------------------------
  // DISPOSE ALL ADS
  // --------------------------------------------------------------------------
  void disposeAll() {
    debugPrint('Disposing ALL ads...');
    disposeBanner();
    disposeBanner2();
    _interstitialAd?.dispose();
    _interstitialAd = null;
  }
}
