import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class InitializationHelper {
  Future<FormError?> initialize() async {
    final completer = Completer<FormError?>();

    final params = ConsentRequestParameters(
      consentDebugSettings: kDebugMode
          ? ConsentDebugSettings(
              debugGeography: DebugGeography.debugGeographyEea,
              testIdentifiers: ["60256A48643384917B642A1C38968797"],
            )
          : null,
    );
    ConsentInformation.instance.requestConsentInfoUpdate(params, () async {
      if (await ConsentInformation.instance.isConsentFormAvailable()) {
        await _loadConsentForm();
      } else {
        await _initializeAds();
      }

      completer.complete();
    }, (error) {
      completer.complete(error);
    });
    return completer.future;
  }
}

Future<FormError?> _loadConsentForm() async {
  final completer = Completer<FormError?>();

  ConsentForm.loadConsentForm((consentForm) async {
    final status = await ConsentInformation.instance.getConsentStatus();
    if (status == ConsentStatus.required) {
      consentForm.show((formError) async {
        if (formError != null) {
          debugPrint('Form error: $formError');
          completer.complete(formError);
          return;
        }
        await _initializeAds();
        completer.complete();
      });
    } else {
      await _initializeAds();
      completer.complete();
    }
  }, (FormError? error) {
    debugPrint('Consent form load error: $error');
    completer.complete(error);
  });

  return completer.future;
}

Future<void> _initializeAds() async {
  await MobileAds.instance.initialize();

  if (kDebugMode) {
    final requestConfiguration = RequestConfiguration(
        testDeviceIds: ["60256A48643384917B642A1C38968797"]);
    MobileAds.instance.updateRequestConfiguration(requestConfiguration);
  }
  debugPrint('Mobile Ads initialized successfully.');
}
