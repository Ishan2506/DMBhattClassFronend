import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:dm_bhatt_tutions/utils/custom_toast.dart';

class InAppReviewService {
  static final InAppReview _inAppReview = InAppReview.instance;

  /// Numeric Apple ID of the app (App Store Connect > App Information >
  /// Apple ID), e.g. '6501234567'. iOS needs this to open the App Store
  /// listing; Android finds its listing from the package name instead.
  /// While it is empty, "Rate Us" on iOS falls back to the native
  /// in-app review prompt.
  static const String iosAppStoreId = '';

  /// Returns true if in-app review is supported (Android and iOS, not Web).
  static bool get isSupported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  /// For a silent, non-button trigger (e.g. on a good result, or on app
  /// exit) where it's fine if nothing visibly happens. Both Google's and
  /// Apple's native review prompts are quota-limited and never report back
  /// whether they were actually shown, so this is the only place that's an
  /// acceptable trade-off.
  static Future<void> requestContextualReview() async {
    if (!isSupported) return;
    try {
      if (await _inAppReview.isAvailable()) {
        await _inAppReview.requestReview();
      }
    } catch (e) {
      debugPrint('Error requesting in-app review: $e');
    }
  }

  /// For an explicit "Rate Us" tap. Google's and Apple's guidance both say
  /// the quota-gated review prompt should not sit behind a visible button,
  /// since a student can silently hit the (undisclosed) quota and the
  /// button then does nothing. So a deliberate tap opens the store listing
  /// directly instead, which is guaranteed to show something, and reports
  /// an error if even that fails.
  static Future<void> openStoreListingForRating(
    BuildContext context, {
    String appStoreId = 'com.bondbyte.students',
  }) async {
    if (!isSupported) return;
    if (Platform.isIOS && iosAppStoreId.isEmpty) {
      await requestContextualReview();
      return;
    }
    try {
      await _inAppReview.openStoreListing(
        appStoreId: Platform.isIOS ? iosAppStoreId : appStoreId,
      );
    } catch (e) {
      debugPrint('Error opening store listing: $e');
      if (context.mounted) {
        CustomToast.showError(
          context,
          Platform.isIOS
              ? 'Could not open the App Store. Please try again.'
              : 'Could not open the Play Store. Please try again.',
        );
      }
    }
  }

  /// Opens the Play Store / App Store listing directly.
  static Future<void> openStoreListing({String appStoreId = 'com.bondbyte.students'}) async {
    if (!isSupported || (Platform.isIOS && iosAppStoreId.isEmpty)) {
      return;
    }
    try {
      await _inAppReview.openStoreListing(
        appStoreId: Platform.isIOS ? iosAppStoreId : appStoreId,
      );
    } catch (e) {
      debugPrint('Error opening store listing: $e');
    }
  }
}
