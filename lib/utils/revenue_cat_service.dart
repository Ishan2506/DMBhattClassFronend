import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

class RevenueCatService {
  static final RevenueCatService instance = RevenueCatService._internal();
  RevenueCatService._internal();

  static const String _apiKey = "test_bLKXFNFxQPKKLdFvQoeJDessRPx";
  static const String entitlementId = "Padhaku Pro";

  bool _isInitialized = false;
  CustomerInfo? _customerInfo;

  /// Initialize the RevenueCat SDK
  Future<void> init() async {
    if (_isInitialized) return;

    if (kDebugMode) {
      await Purchases.setLogLevel(LogLevel.debug);
    }

    if (Platform.isIOS || Platform.isAndroid) {
      PurchasesConfiguration configuration = PurchasesConfiguration(_apiKey);
      await Purchases.configure(configuration);
      _isInitialized = true;
      
      // Initial fetch of customer info
      try {
        _customerInfo = await Purchases.getCustomerInfo();
      } catch (e) {
        debugPrint("Error fetching RevenueCat customer info: $e");
      }

      // Listen for customer info updates
      Purchases.addCustomerInfoUpdateListener((customerInfo) {
        _customerInfo = customerInfo;
        debugPrint("RevenueCat Customer Info Updated");
      });
    }
  }

  /// Check if the user has an active "Padhaku Pro" entitlement
  bool get isProActive {
    if (_customerInfo == null) return false;
    return _customerInfo!.entitlements.all[entitlementId]?.isActive ?? false;
  }

  /// Present the RevenueCat Paywall
  /// [offeringId] can be passed to show a specific standard's offering (e.g., 'std_7')
  /// Returns true if a purchase was successful
  Future<bool> presentPaywall({String? offeringId}) async {
    try {
      Offering? offering;
      if (offeringId != null) {
        Offerings offerings = await Purchases.getOfferings();
        offering = offerings.all[offeringId];
        if (offering == null) {
          debugPrint("Warning: Offering $offeringId not found. Falling back to default.");
        }
      }

      final paywallResult = await RevenueCatUI.presentPaywall(offering: offering);
      debugPrint("Paywall Result: $paywallResult");
      
      // Refresh customer info after paywall
      _customerInfo = await Purchases.getCustomerInfo();
      return isProActive;
    } catch (e) {
      debugPrint("Error presenting paywall: $e");
      return false;
    }
  }

  /// Present the Paywall only if the user is not already Pro
  Future<void> presentPaywallIfNeeded() async {
    try {
      await RevenueCatUI.presentPaywallIfNeeded(entitlementId);
      _customerInfo = await Purchases.getCustomerInfo();
    } catch (e) {
      debugPrint("Error presenting paywall if needed: $e");
    }
  }

  /// Present the Customer Center for managing subscriptions
  Future<void> presentCustomerCenter() async {
    try {
      await RevenueCatUI.presentCustomerCenter();
    } catch (e) {
      debugPrint("Error presenting customer center: $e");
    }
  }

  /// Restore purchases
  Future<void> restorePurchases() async {
    try {
      _customerInfo = await Purchases.restorePurchases();
    } catch (e) {
      debugPrint("Error restoring purchases: $e");
    }
  }

  /// Log in a user with their unique ID (e.g., from your backend)
  Future<void> login(String userId) async {
    try {
      LogInResult result = await Purchases.logIn(userId);
      _customerInfo = result.customerInfo;
    } catch (e) {
      debugPrint("Error logging in to RevenueCat: $e");
    }
  }

  /// Log out
  Future<void> logout() async {
    try {
      _customerInfo = await Purchases.logOut();
    } catch (e) {
      debugPrint("Error logging out of RevenueCat: $e");
    }
  }
}
