import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import 'package:purchases_ui_flutter/views/customer_center_view_method_handler.dart';

enum RevenueCatPurchaseStatus {
  purchased,
  restored,
  cancelled,
  error,
  noActiveEntitlement,
}

class RevenueCatPurchaseResult {
  const RevenueCatPurchaseResult({
    required this.status,
    required this.isEntitlementActive,
    this.didShowStatusAlert = false,
  });

  final RevenueCatPurchaseStatus status;
  final bool isEntitlementActive;
  final bool didShowStatusAlert;

  bool get isSuccess => isEntitlementActive;

  String get title {
    switch (status) {
      case RevenueCatPurchaseStatus.purchased:
        return "Purchase Successful";
      case RevenueCatPurchaseStatus.restored:
        return "Purchase Restored";
      case RevenueCatPurchaseStatus.noActiveEntitlement:
        return "No Active Purchase Found";
      case RevenueCatPurchaseStatus.error:
        return "Restore Failed";
      case RevenueCatPurchaseStatus.cancelled:
        return "Purchase Cancelled";
    }
  }

  String get message {
    switch (status) {
      case RevenueCatPurchaseStatus.purchased:
        return "Your Padhaku Pro access is now active.";
      case RevenueCatPurchaseStatus.restored:
        return "Your previous purchase was restored successfully.";
      case RevenueCatPurchaseStatus.noActiveEntitlement:
        return "We checked your Apple account, but no active Padhaku Pro purchase was found.";
      case RevenueCatPurchaseStatus.error:
        return "We could not complete the purchase or restore request. Please try again.";
      case RevenueCatPurchaseStatus.cancelled:
        return "No purchase was made.";
    }
  }

  bool get shouldShowAlert =>
      !didShowStatusAlert &&
      (status == RevenueCatPurchaseStatus.restored ||
          status == RevenueCatPurchaseStatus.noActiveEntitlement ||
          status == RevenueCatPurchaseStatus.error);
}

class RevenueCatService {
  static final RevenueCatService instance = RevenueCatService._internal();
  RevenueCatService._internal();

  static const String _apiKey = "appl_MjnwkNgBHNTDModyowxlLnKWtWp";
  static const String defaultOfferingId = "default";
  static const String entitlementId = "Padhaku Pro";

  bool _isInitialized = false;
  CustomerInfo? _customerInfo;

  /// Initialize the RevenueCat SDK
  Future<void> init() async {
    if (_isInitialized) return;

    if (kDebugMode) {
      await Purchases.setLogLevel(LogLevel.debug);
    }

    // RevenueCat only works on mobile platforms
    if (!kIsWeb && (Platform.isIOS || Platform.isAndroid)) {
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

  Future<bool> refreshIsProActive() async {
    try {
      _customerInfo = await Purchases.getCustomerInfo();
      return isProActive;
    } catch (e) {
      debugPrint("Error refreshing RevenueCat customer info: $e");
      return isProActive;
    }
  }

  Future<CustomerInfo?> getCustomerInfo() async {
    try {
      _customerInfo = await Purchases.getCustomerInfo();
      return _customerInfo;
    } catch (e) {
      debugPrint("Error fetching RevenueCat customer info: $e");
      return _customerInfo;
    }
  }

  /// Present the RevenueCat Paywall
  /// [offeringId] can be passed to show a specific RevenueCat offering.
  /// Returns the paywall result and current entitlement status.
  Future<RevenueCatPurchaseResult> presentPaywallWithResult({
    String? offeringId,
    BuildContext? context,
  }) async {
    if (context != null) {
      return _presentPaywallViewWithResult(context, offeringId: offeringId);
    }

    try {
      Offering? offering;
      if (offeringId != null) {
        Offerings offerings = await Purchases.getOfferings();
        offering = offerings.all[offeringId];
        if (offering == null) {
          debugPrint(
            "Warning: Offering $offeringId not found. Falling back to default.",
          );
        }
      }

      final paywallResult = await RevenueCatUI.presentPaywall(
        offering: offering,
        displayCloseButton: true,
        presentationConfiguration: PaywallPresentationConfiguration.fullScreen,
      );
      debugPrint("Paywall Result: $paywallResult");

      _customerInfo = await Purchases.getCustomerInfo();
      final active = isProActive;

      switch (paywallResult) {
        case PaywallResult.purchased:
          return RevenueCatPurchaseResult(
            status: active
                ? RevenueCatPurchaseStatus.purchased
                : RevenueCatPurchaseStatus.noActiveEntitlement,
            isEntitlementActive: active,
          );
        case PaywallResult.restored:
          return RevenueCatPurchaseResult(
            status: active
                ? RevenueCatPurchaseStatus.restored
                : RevenueCatPurchaseStatus.noActiveEntitlement,
            isEntitlementActive: active,
          );
        case PaywallResult.cancelled:
        case PaywallResult.notPresented:
          return RevenueCatPurchaseResult(
            status: RevenueCatPurchaseStatus.cancelled,
            isEntitlementActive: active,
          );
        case PaywallResult.error:
          return RevenueCatPurchaseResult(
            status: RevenueCatPurchaseStatus.error,
            isEntitlementActive: active,
          );
      }
    } catch (e) {
      debugPrint("Error presenting paywall: $e");
      return const RevenueCatPurchaseResult(
        status: RevenueCatPurchaseStatus.error,
        isEntitlementActive: false,
      );
    }
  }

  /// Returns true if a purchase or restore activated the entitlement.
  Future<bool> presentPaywall({
    String? offeringId,
    BuildContext? context,
  }) async {
    final result = await presentPaywallWithResult(
      offeringId: offeringId,
      context: context,
    );
    return result.isSuccess;
  }

  Future<RevenueCatPurchaseResult> _presentPaywallViewWithResult(
    BuildContext context, {
    String? offeringId,
  }) async {
    try {
      Offering? offering;
      if (offeringId != null) {
        final offerings = await Purchases.getOfferings();
        offering = offerings.all[offeringId];
        if (offering == null) {
          debugPrint(
            "Warning: Offering $offeringId not found. Falling back to default.",
          );
        }
      }

      if (!context.mounted) {
        return const RevenueCatPurchaseResult(
          status: RevenueCatPurchaseStatus.cancelled,
          isEntitlementActive: false,
        );
      }

      final result = await Navigator.of(context, rootNavigator: true)
          .push<RevenueCatPurchaseResult>(
            MaterialPageRoute(
              fullscreenDialog: true,
              builder: (routeContext) => _RevenueCatPaywallRoute(
                offering: offering,
                onCustomerInfoChanged: (customerInfo) {
                  _customerInfo = customerInfo;
                },
              ),
            ),
          );

      _customerInfo = await Purchases.getCustomerInfo();
      return result ??
          RevenueCatPurchaseResult(
            status: RevenueCatPurchaseStatus.cancelled,
            isEntitlementActive: isProActive,
          );
    } catch (e) {
      debugPrint("Error presenting paywall view: $e");
      return const RevenueCatPurchaseResult(
        status: RevenueCatPurchaseStatus.error,
        isEntitlementActive: false,
      );
    }
  }

  /// Present the Paywall only if the user is not already Pro
  Future<void> presentPaywallIfNeeded() async {
    try {
      await RevenueCatUI.presentPaywallIfNeeded(
        entitlementId,
        displayCloseButton: true,
        presentationConfiguration: PaywallPresentationConfiguration.fullScreen,
      );
      _customerInfo = await Purchases.getCustomerInfo();
    } catch (e) {
      debugPrint("Error presenting paywall if needed: $e");
    }
  }

  /// Present the Customer Center for managing subscriptions
  Future<void> presentCustomerCenter({
    CustomerCenterRestoreStarted? onRestoreStarted,
    CustomerCenterRestoreCompleted? onRestoreCompleted,
    CustomerCenterRestoreFailed? onRestoreFailed,
    CustomerCenterManagementOptionSelected? onManagementOptionSelected,
    CustomerCenterCustomActionSelected? onCustomActionSelected,
  }) async {
    try {
      await RevenueCatUI.presentCustomerCenter(
        onRestoreStarted: onRestoreStarted,
        onRestoreCompleted: onRestoreCompleted,
        onRestoreFailed: onRestoreFailed,
        onManagementOptionSelected: onManagementOptionSelected,
        onCustomActionSelected: onCustomActionSelected,
      );
    } catch (e) {
      debugPrint("Error presenting customer center: $e");
    }
  }

  /// Restore purchases
  Future<RevenueCatPurchaseResult> restorePurchases() async {
    try {
      _customerInfo = await Purchases.restorePurchases();
      final active = isProActive;
      return RevenueCatPurchaseResult(
        status: active
            ? RevenueCatPurchaseStatus.restored
            : RevenueCatPurchaseStatus.noActiveEntitlement,
        isEntitlementActive: active,
      );
    } catch (e) {
      debugPrint("Error restoring purchases: $e");
      return const RevenueCatPurchaseResult(
        status: RevenueCatPurchaseStatus.error,
        isEntitlementActive: false,
      );
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

class _RevenueCatPaywallRoute extends StatelessWidget {
  const _RevenueCatPaywallRoute({
    required this.offering,
    required this.onCustomerInfoChanged,
  });

  final Offering? offering;
  final ValueChanged<CustomerInfo> onCustomerInfoChanged;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        top: false,
        child: PaywallView(
          offering: offering,
          displayCloseButton: true,
          onPurchaseCompleted: (customerInfo, _) {
            onCustomerInfoChanged(customerInfo);
            final active = _isPadhakuProActive(customerInfo);
            Navigator.of(context, rootNavigator: true).pop(
              RevenueCatPurchaseResult(
                status: active
                    ? RevenueCatPurchaseStatus.purchased
                    : RevenueCatPurchaseStatus.noActiveEntitlement,
                isEntitlementActive: active,
              ),
            );
          },
          onPurchaseCancelled: () {
            Navigator.of(context, rootNavigator: true).pop(
              const RevenueCatPurchaseResult(
                status: RevenueCatPurchaseStatus.cancelled,
                isEntitlementActive: false,
              ),
            );
          },
          onPurchaseError: (error) {
            _showPaywallAlert(
              context,
              title: "Purchase Failed",
              message: error.message,
            );
          },
          onRestoreCompleted: (customerInfo) async {
            onCustomerInfoChanged(customerInfo);
            final active = _isPadhakuProActive(customerInfo);
            await _showPaywallAlert(
              context,
              title: active ? "Subscription Restored" : "No Subscription Found",
              message: active
                  ? "You successfully restored your subscription."
                  : "You don't have any active subscription to restore.",
            );
            if (!context.mounted) return;
            if (active) {
              Navigator.of(context, rootNavigator: true).pop(
                const RevenueCatPurchaseResult(
                  status: RevenueCatPurchaseStatus.restored,
                  isEntitlementActive: true,
                  didShowStatusAlert: true,
                ),
              );
            }
          },
          onRestoreError: (error) {
            _showPaywallAlert(
              context,
              title: "Restore Failed",
              message: error.message,
            );
          },
          onDismiss: () {
            Navigator.of(context, rootNavigator: true).pop(
              const RevenueCatPurchaseResult(
                status: RevenueCatPurchaseStatus.cancelled,
                isEntitlementActive: false,
              ),
            );
          },
        ),
      ),
    );
  }

  static bool _isPadhakuProActive(CustomerInfo customerInfo) {
    return customerInfo
            .entitlements
            .all[RevenueCatService.entitlementId]
            ?.isActive ??
        false;
  }

  static Future<void> _showPaywallAlert(
    BuildContext context, {
    required String title,
    required String message,
  }) async {
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }
}
