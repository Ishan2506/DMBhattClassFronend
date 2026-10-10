import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:dm_bhatt_tutions/utils/custom_toast.dart';

class InAppReviewService {
  static final InAppReview _inAppReview = InAppReview.instance;

  /// Returns true if in-app review is supported (Android only, not iOS or Web).
  static bool get isAndroidSupported => !kIsWeb && Platform.isAndroid;

  /// For a silent, non-button trigger (e.g. on a good result, or on app
  /// exit) where it's fine if nothing visibly happens. Google's native
  /// review dialog is quota-limited and never reports back whether it was
  /// actually shown, so this is the only place that's an acceptable trade-off.
  static Future<void> requestContextualReview() async {
    if (kIsWeb || Platform.isIOS) return;
    try {
      if (await _inAppReview.isAvailable()) {
        await _inAppReview.requestReview();
      }
    } catch (e) {
      debugPrint('Error requesting in-app review: $e');
    }
  }

  /// For an explicit "Rate Us" tap. Google's own guidance says the
  /// quota-gated review dialog should not sit behind a visible button,
  /// since a student can silently hit the (undisclosed) quota and the
  /// button then does nothing. So a deliberate tap always opens the Play
  /// Store listing directly instead, which is guaranteed to show something,
  /// and reports an error if even that fails.
  static Future<void> openStoreListingForRating(
    BuildContext context, {
    String appStoreId = 'com.bondbyte.students',
  }) async {
    if (kIsWeb || Platform.isIOS) return;
    try {
      await _inAppReview.openStoreListing(appStoreId: appStoreId);
    } catch (e) {
      debugPrint('Error opening store listing: $e');
      if (context.mounted) {
        CustomToast.showError(
          context,
          'Could not open the Play Store. Please try again.',
        );
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
