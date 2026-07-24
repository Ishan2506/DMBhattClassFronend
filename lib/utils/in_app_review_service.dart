import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';

class InAppReviewService {
  static final InAppReview _inAppReview = InAppReview.instance;

  /// Returns true if in-app review is supported (Android only, not iOS or Web).
  static bool get isAndroidSupported => !kIsWeb && Platform.isAndroid;

  /// Prompts the user with Google In-App Review dialog if available on Android.
  /// Falls back to opening the Play Store listing if unavailable.
  /// Does nothing on iOS.
  static Future<void> requestReviewOrOpenStore({String appStoreId = 'com.bondbyte.students'}) async {
    // Explicitly ignore/don't execute on iOS or Web
    if (kIsWeb || Platform.isIOS) {
      return;
    }

    try {
      if (await _inAppReview.isAvailable()) {
        await _inAppReview.requestReview();
      } else {
        await _inAppReview.openStoreListing(
          appStoreId: appStoreId,
        );
      }
    } catch (e) {
      debugPrint('Error requesting in-app review: $e');
      try {
        await _inAppReview.openStoreListing(appStoreId: appStoreId);
      } catch (err) {
        debugPrint('Error opening store listing fallback: $err');
      }
    }
  }

  /// Opens the Play Store listing directly.
  static Future<void> openStoreListing({String appStoreId = 'com.bondbyte.students'}) async {
    if (kIsWeb || Platform.isIOS) {
      return;
    }
    try {
      await _inAppReview.openStoreListing(
        appStoreId: appStoreId,
      );
    } catch (e) {
      debugPrint('Error opening store listing: $e');
    }
  }
}
