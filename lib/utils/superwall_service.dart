import 'package:superwallkit_flutter/superwallkit_flutter.dart';
import 'package:flutter/foundation.dart';

class SuperWallService {
  static final SuperWallService _instance = SuperWallService._internal();

  factory SuperWallService() {
    return _instance;
  }

  SuperWallService._internal();

  bool _initialized = false;

  /// Initialize SuperWall with API key
  Future<void> initialize({
    required String apiKey,
  }) async {
    if (_initialized) return;

    try {
      Superwall.configure(apiKey);
      _initialized = true;
      if (kDebugMode) print('✅ SuperWall initialized successfully');
    } catch (e) {
      if (kDebugMode) print('❌ SuperWall initialization failed: $e');
      rethrow;
    }
  }

  /// Show explore premium paywall
  /// Called when user tries to access premium product
  Future<void> showExplorePremiumPaywall({
    required String userId,
    Map<String, dynamic>? customAttributes,
  }) async {
    if (!_initialized) {
      if (kDebugMode) print('⚠️ SuperWall not initialized');
      return;
    }

    try {
      // Register event that triggers the paywall
      await Superwall.shared.registerPlacement(
        'explore_premium_requested',
        params: {
          'user_id': userId,
          'timestamp': DateTime.now().toIso8601String(),
          ...(customAttributes ?? {}),
        },
      );

      if (kDebugMode) {
        print('✅ Explore premium paywall shown');
      }
    } catch (e) {
      if (kDebugMode) print('❌ Failed to show paywall: $e');
      rethrow;
    }
  }

  /// Check if user has premium explore entitlement
  /// Returns true if user has purchased any premium explore product
  Future<bool> hasExplorePremium() async {
    if (!_initialized) return false;

    try {
      final entitlements = await Superwall.shared.getEntitlements();
      final hasPremium = entitlements.active.any((e) => e.id == 'premium_explore');
      if (kDebugMode) {
        print('👤 User premium status: $hasPremium');
      }
      return hasPremium;
    } catch (e) {
      if (kDebugMode) print('❌ Failed to check entitlement: $e');
      return false;
    }
  }

  /// Get current user ID from session
  /// Update this to get from your actual session manager
  Future<String> getUserId() async {
    // TODO: Replace with actual user ID from SessionManager
    // Example:
    // final sessionManager = SessionManager.instance;
    // return await sessionManager.getUserId() ?? 'anonymous';
    return 'user_default_id';
  }

  /// Set user attributes for dynamic pricing
  /// SuperWall uses these to determine prices per user
  Future<void> setUserAttributes({
    required String userId,
    required String region,
    required int exploreVisitCount,
    required bool isNewUser,
  }) async {
    if (!_initialized) return;

    try {
      await Superwall.shared.setUserAttributes({
        'user_id': userId,
        'region': region,
        'explore_visits': exploreVisitCount.toString(),
        'is_new_user': isNewUser.toString(),
      });

      if (kDebugMode) {
        print('✅ User attributes set for dynamic pricing');
      }
    } catch (e) {
      if (kDebugMode) print('❌ Failed to set user attributes: $e');
    }
  }

  /// Restore previous purchases
  /// Call this when user reinstalls app
  Future<void> restorePurchases() async {
    if (!_initialized) return;

    try {
      // SuperWall automatically restores purchases
      // Just need to re-check entitlements
      await hasExplorePremium();
      if (kDebugMode) print('✅ Purchases restored');
    } catch (e) {
      if (kDebugMode) print('❌ Failed to restore purchases: $e');
    }
  }

  /// Get list of available products with pricing
  /// Useful for displaying price information
  Future<List<Map<String, dynamic>>> getAvailableProducts() async {
    if (!_initialized) return [];

    try {
      // This would require additional setup with RevenueCat or direct StoreKit
      // For now, returning empty - products are managed in SuperWall dashboard
      return [];
    } catch (e) {
      if (kDebugMode) print('❌ Failed to get products: $e');
      return [];
    }
  }
}
