import 'package:superwallkit_flutter/superwallkit_flutter.dart';
import 'package:flutter/foundation.dart';

class SuperWallService {
  static final SuperWallService _instance = SuperWallService._internal();

  factory SuperWallService() {
    return _instance;
  }

  SuperWallService._internal();

  bool _initialized = false;

  // ─────────────────────────────────────────────
  // INITIALIZE
  // ─────────────────────────────────────────────

  /// Initialize SuperWall with your Public API Key
  /// Call this once in main.dart before runApp()
  Future<void> initialize({required String apiKey}) async {
    if (_initialized) {
      if (kDebugMode) print('⚠️ SuperWall already initialized, skipping');
      return;
    }

    try {
      // Do NOT pass a PurchaseController here — let Superwall manage
      // purchases entirely on its own (no RevenueCat controller)
      Superwall.configure(apiKey);

      // Set the delegate to handle custom actions
      Superwall.shared.delegate = _SuperWallDelegate();

      _initialized = true;
      if (kDebugMode) print('✅ SuperWall initialized successfully');
    } catch (e) {
      if (kDebugMode) print('❌ SuperWall initialization failed: $e');
      rethrow;
    }
  }

  // ─────────────────────────────────────────────
  // SHOW PAYWALL
  // ─────────────────────────────────────────────

  /// Show the explore premium paywall.
  ///
  /// [onPurchased]  — called after a successful purchase
  /// [onCancelled]  — called when user dismisses without purchasing
  /// [onFailed]     — called when the paywall errors or no campaign matches
  Future<void> showExplorePremiumPaywall({
    required String userId,
    Map<String, dynamic>? customAttributes,
    VoidCallback? onPurchased,
    VoidCallback? onCancelled,
    void Function(String reason)? onFailed,
  }) async {
    if (!_initialized) {
      if (kDebugMode) print('⚠️ SuperWall not initialized');
      onFailed?.call('SuperWall not initialized');
      return;
    }

    try {
      final handler = PaywallPresentationHandler();

      // Paywall appeared on screen
      handler.onPresent((paywallInfo) {
        if (kDebugMode) print('✅ Paywall presented: ${paywallInfo.name}');
      });

      // Paywall was dismissed — check the dismissState to know WHY
      handler.onDismiss((paywallInfo, dismissState) async {
        if (kDebugMode) print('👋 Paywall dismissed — state: $dismissState');

        // Check the actual entitlement AFTER the paywall closes
        final hasPremium = await hasExplorePremium();

        if (hasPremium) {
          if (kDebugMode) print('🎉 Purchase confirmed via entitlement');
          onPurchased?.call();
        } else {
          if (kDebugMode) print('🚫 No active entitlement after dismissal');
          onCancelled?.call();
        }
      });

      // Paywall failed to load (network error, products not found, etc.)
      handler.onError((error) {
        if (kDebugMode) print('❌ Paywall error: $error');
        onFailed?.call('Paywall error: $error');
      });

      // Placement skipped — means no campaign matched this placement name.
      // This is the most common cause of "paywall didn't load".
      // Check: campaign is Published, placement name matches EXACTLY
      handler.onSkip((reason) {
        if (kDebugMode) {
          print('⏭️ Paywall skipped — reason: $reason');
        }
        // Send the skip reason back to UI as a failure so it can be shown in a toast
        onFailed?.call('Paywall skipped: $reason');
      });

      await Superwall.shared.registerPlacement(
        'explore_premium_requested',
        params: {
          'user_id': userId,
          'timestamp': DateTime.now().toIso8601String(),
          ...(customAttributes ?? {}),
        },
        handler: handler,
      );

      if (kDebugMode) print('📤 registerPlacement called — waiting for handler callbacks');
    } catch (e) {
      if (kDebugMode) print('❌ Failed to register placement: $e');
      onFailed?.call(e.toString());
    }
  }

  // ─────────────────────────────────────────────
  // ENTITLEMENT CHECK
  // ─────────────────────────────────────────────

  /// Returns true if the user has an active 'premium_explore' entitlement.
  /// Always call this AFTER onDismiss fires, not immediately after registerPlacement.
  Future<bool> hasExplorePremium() async {
    if (!_initialized) return false;

    try {
      final entitlements = await Superwall.shared.getEntitlements();
      final hasPremium = entitlements.active.any((e) => e.id == 'premium_explore');
      if (kDebugMode) print('👤 User has premium_explore: $hasPremium');
      return hasPremium;
    } catch (e) {
      if (kDebugMode) print('❌ Failed to check entitlement: $e');
      return false;
    }
  }

  // ─────────────────────────────────────────────
  // RESTORE PURCHASES
  // ─────────────────────────────────────────────

  /// Restores previous purchases. Call when user taps "Restore Purchases".
  /// Returns true if restore was successful and user has an active entitlement.
  Future<bool> restorePurchases() async {
    if (!_initialized) return false;

    try {
      final result = await Superwall.shared.restorePurchases();
      if (kDebugMode) print('🔄 Restore result: $result');

      // After restore, check entitlement
      final hasPremium = await hasExplorePremium();
      if (kDebugMode) print('👤 After restore — has premium: $hasPremium');
      return hasPremium;
    } catch (e) {
      if (kDebugMode) print('❌ Restore failed: $e');
      return false;
    }
  }

  // ─────────────────────────────────────────────
  // USER ATTRIBUTES
  // ─────────────────────────────────────────────

  /// Set user attributes for campaign targeting and dynamic pricing.
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
      if (kDebugMode) print('✅ User attributes set');
    } catch (e) {
      if (kDebugMode) print('❌ Failed to set user attributes: $e');
    }
  }

  // ─────────────────────────────────────────────
  // USER ID
  // ─────────────────────────────────────────────

  /// Get current user ID. Replace with your actual SessionManager call.
  Future<String> getUserId() async {
    // TODO: Replace with your actual session manager
    // Example: return SessionManager.instance.getUserId() ?? 'anonymous';
    return 'user_default_id';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SUPERWALL DELEGATE — Handles custom button actions
// ─────────────────────────────────────────────────────────────────────────────

class _SuperWallDelegate extends SuperwallDelegate {
  @override
  void handleCustomPaywallAction(String name) {
    if (kDebugMode) print('🎯 Custom action triggered: $name');

    switch (name) {
      case 'continue':
        // Continue button was tapped — this is where you handle the continue action
        if (kDebugMode) print('✅ Continue button tapped');
        // The paywall will automatically dismiss after this action
        break;

      case 'help':
        if (kDebugMode) print('❓ Help action tapped');
        // Implement help center logic here if needed
        break;

      default:
        if (kDebugMode) print('⚠️ Unknown action: $name');
    }
  }

  @override
  void willPresentPaywall(PaywallInfo paywallInfo) {
    if (kDebugMode) print('👀 Paywall will present: ${paywallInfo.identifier}');
  }

  @override
  void didPresentPaywall(PaywallInfo paywallInfo) {
    if (kDebugMode) print('✅ Paywall did present: ${paywallInfo.identifier}');
  }

  @override
  void willDismissPaywall(PaywallInfo paywallInfo) {
    if (kDebugMode) print('👋 Paywall will dismiss: ${paywallInfo.identifier}');
  }

  @override
  void didDismissPaywall(PaywallInfo paywallInfo) {
    if (kDebugMode) print('🚪 Paywall did dismiss: ${paywallInfo.identifier}');
  }

  @override
  void subscriptionStatusDidChange(
    SubscriptionStatus previousStatus,
    SubscriptionStatus currentStatus,
  ) {
    if (kDebugMode) {
      print('💳 Subscription changed from $previousStatus to $currentStatus');
    }
  }

  @override
  void handleSuperwallEvent(SuperwallEventInfo eventInfo) {
    if (kDebugMode) print('📊 Superwall event: ${eventInfo.event}');
  }
}