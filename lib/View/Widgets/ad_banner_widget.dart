import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:vpnprowithjava/utils/preferences.dart';

class AdBannerWidget extends StatefulWidget {
  final String adUnitId;
  final AdSize adSize;

  const AdBannerWidget({
    super.key,
    required this.adUnitId,
    this.adSize = AdSize.banner,
  });

  @override
  State<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends State<AdBannerWidget> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  int retryCountSettings = 0, maxRetrySettings = 3;
  final bool _isSubscribed = Prefs.getBool('isSubscribed') ?? false;

  @override
  void initState() {
    super.initState();
    // Initialize and load the ad
    if (!_isSubscribed) {
      initAd();
    } else {
      _bannerAd?.dispose();
    }
  }

  Future<void> initAd() async {
    await Future.delayed(Duration(seconds: 2));
    debugPrint("----- Banner ad init called -----");
    _bannerAd = BannerAd(
      size: widget.adSize,
      adUnitId: widget.adUnitId,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() => _isAdLoaded = true);
          debugPrint('----Ad loaded successfully----');
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('----Failed to load ad----');
          setState(() => _isAdLoaded = false);
          ad.dispose();
          retryCountSettings++;
          if (retryCountSettings <= maxRetrySettings) {
            Future.delayed(const Duration(seconds: 3), () => initAd());
          } else {
            debugPrint(
                'Failed to load banner ad after $maxRetrySettings attempts.');
          }
        },
      ),
      request: const AdRequest(),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    debugPrint('----Ad disposed----');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Display the ad if loaded, otherwise an empty container
    if (_isAdLoaded && _bannerAd != null) {
      return Container(
        alignment: Alignment.center,
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      );
    } else {
      return SizedBox.shrink();
    }
  }
}
