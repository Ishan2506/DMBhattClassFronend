import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import 'package:purchases_ui_flutter/views/customer_center_view_method_handler.dart';
import 'package:url_launcher/url_launcher.dart';

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
    this.receipt,
    this.productId,
    this.transactionId,
    this.amountPaid,
  });

  final RevenueCatPurchaseStatus status;
  final bool isEntitlementActive;
  final bool didShowStatusAlert;
  final String? receipt;
  final String? productId;
  final String? transactionId;
  final double? amountPaid;

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
  static const MethodChannel _appleReceiptChannel = MethodChannel(
    "dm_bhatt_tutions/apple_receipt",
  );
  static const Map<String, String> standardProductIds = {
    "6": "com.standard.six",
    "7": "com.standard.seven",
    "8": "com.standard.eigth",
    "9": "com.standard.ninth",
    "10": "com.standard.ten",
    "11": "com.standard.eleven",
    "12": "com.standard.twelve",
  };
  static const Map<String, String> standardRedeemProductIds = {
    "6": "com.standard.six.redeem",
    "7": "com.standard.seven.redeem",
    "8": "com.standard.eigth.redeem",
    "9": "com.standard.ninth.redeem",
    "10": "com.standard.ten.redeem",
    "11": "com.standard.eleven.redeem",
    "12": "com.standard.twelve.redeem",
  };

  bool _isInitialized = false;
  CustomerInfo? _customerInfo;

  /// Initialize the RevenueCat SDK
  Future<void> init() async {
    if (_isInitialized) return;

    if (kDebugMode) {
      await Purchases.setLogLevel(LogLevel.debug);
    }

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

  Future<String?> getAppleReceipt() async {
    if (kIsWeb || !Platform.isIOS) return null;
    try {
      return await _appleReceiptChannel.invokeMethod<String>("getReceipt");
    } on PlatformException catch (e) {
      debugPrint("Error fetching Apple receipt: ${e.message}");
      return null;
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

  /// Shows the custom paywall for the product matching [standard].
  ///
  /// RevenueCat hosted paywalls do not support a runtime-selected package, so
  /// this route fetches the default offering and purchases the matching package.
  Future<RevenueCatPurchaseResult> presentStandardPaywallWithResult({
    required BuildContext context,
    required String? standard,
    bool useRedeemProduct = false,
    bool useReferralProduct = false,
  }) async {
    final normalizedStandard = _normalizeStandard(standard);
    final shouldUseRedeemProduct = useRedeemProduct || useReferralProduct;
    final productIds = shouldUseRedeemProduct
        ? standardRedeemProductIds
        : standardProductIds;
    final productId = productIds[normalizedStandard];
    if (productId == null) {
      final productType = shouldUseRedeemProduct ? "redeem " : "";
      debugPrint(
        "No RevenueCat ${productType}product configured for standard: $standard",
      );
      return const RevenueCatPurchaseResult(
        status: RevenueCatPurchaseStatus.error,
        isEntitlementActive: false,
      );
    }

    try {
      Package? selectedPackage;
      StoreProduct? selectedProduct;

      final offerings = await Purchases.getOfferings();
      final offering = offerings.all[defaultOfferingId];
      if (offering != null) {
        for (final package in offering.availablePackages) {
          if (package.storeProduct.identifier == productId) {
            selectedPackage = package;
            selectedProduct = package.storeProduct;
            break;
          }
        }
      }

      if (selectedProduct == null) {
        debugPrint(
          "RevenueCat product $productId was not found in $defaultOfferingId. Fetching directly.",
        );
        final products = await Purchases.getProducts([productId]);
        if (products.isNotEmpty) {
          selectedProduct = products.first;
        }
      }

      if (selectedProduct == null) {
        debugPrint(
          "RevenueCat product $productId could not be fetched from offerings or products.",
        );
        return const RevenueCatPurchaseResult(
          status: RevenueCatPurchaseStatus.error,
          isEntitlementActive: false,
        );
      }

      if (!context.mounted) {
        return const RevenueCatPurchaseResult(
          status: RevenueCatPurchaseStatus.cancelled,
          isEntitlementActive: false,
        );
      }

      final result = await Navigator.of(context, rootNavigator: true)
          .push<RevenueCatPurchaseResult>(
            CupertinoPageRoute(
              fullscreenDialog: true,
              builder: (routeContext) => _StandardRevenueCatPaywallRoute(
                standard: normalizedStandard!,
                package: selectedPackage,
                product: selectedProduct!,
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
      debugPrint("Error presenting standard paywall: $e");
      return const RevenueCatPurchaseResult(
        status: RevenueCatPurchaseStatus.error,
        isEntitlementActive: false,
      );
    }
  }

  Future<bool> presentStandardPaywall({
    required BuildContext context,
    required String? standard,
  }) async {
    final result = await presentStandardPaywallWithResult(
      context: context,
      standard: standard,
    );
    return result.isSuccess;
  }

  static String? _normalizeStandard(String? standard) {
    if (standard == null) return null;
    return RegExp(r"(\d+)").firstMatch(standard)?.group(1);
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

class _StandardRevenueCatPaywallRoute extends StatefulWidget {
  const _StandardRevenueCatPaywallRoute({
    required this.standard,
    required this.product,
    required this.onCustomerInfoChanged,
    this.package,
  });

  final String standard;
  final Package? package;
  final StoreProduct product;
  final ValueChanged<CustomerInfo> onCustomerInfoChanged;

  @override
  State<_StandardRevenueCatPaywallRoute> createState() =>
      _StandardRevenueCatPaywallRouteState();
}

class _StandardRevenueCatPaywallRouteState
    extends State<_StandardRevenueCatPaywallRoute> {
  bool _isPurchasing = false;
  bool _isRestoring = false;

  StoreProduct get _product => widget.product;

  Future<void> _purchase() async {
    if (_isPurchasing || _isRestoring) return;
    setState(() => _isPurchasing = true);
    try {
      final result = await Purchases.purchase(
        widget.package != null
            ? PurchaseParams.package(widget.package!)
            : PurchaseParams.storeProduct(widget.product),
      );
      widget.onCustomerInfoChanged(result.customerInfo);
      final active = _isPadhakuProActive(result.customerInfo);
      final receipt = await RevenueCatService.instance.getAppleReceipt();
      if (!mounted) return;
      Navigator.pop(
        context,
        RevenueCatPurchaseResult(
          status: active
              ? RevenueCatPurchaseStatus.purchased
              : RevenueCatPurchaseStatus.noActiveEntitlement,
          isEntitlementActive: active,
          receipt: receipt,
          productId: result.storeTransaction.productIdentifier,
          transactionId: result.storeTransaction.transactionIdentifier,
          amountPaid: _product.price,
        ),
      );
    } on PlatformException catch (e) {
      if (PurchasesErrorHelper.getErrorCode(e) ==
          PurchasesErrorCode.purchaseCancelledError) {
        if (mounted) setState(() => _isPurchasing = false);
        return;
      }
      await _showAlert(
        title: "Purchase Failed",
        message: e.message ?? "We could not complete your purchase.",
      );
      if (mounted) setState(() => _isPurchasing = false);
    } catch (e) {
      await _showAlert(
        title: "Purchase Failed",
        message: "We could not complete your purchase. Please try again.",
      );
      if (mounted) setState(() => _isPurchasing = false);
    }
  }

  Future<void> _restore() async {
    if (_isPurchasing || _isRestoring) return;
    setState(() => _isRestoring = true);
    try {
      final customerInfo = await Purchases.restorePurchases();
      widget.onCustomerInfoChanged(customerInfo);
      final active = _isPadhakuProActive(customerInfo);
      await _showAlert(
        title: active ? "Purchase Restored" : "No Purchase Found",
        message: active
            ? "Your previous purchase was restored successfully."
            : "We could not find an active Padhaku Pro purchase for this Apple ID.",
      );
      if (!mounted) return;
      if (active) {
        Navigator.pop(
          context,
          const RevenueCatPurchaseResult(
            status: RevenueCatPurchaseStatus.restored,
            isEntitlementActive: true,
            didShowStatusAlert: true,
          ),
        );
      }
    } catch (e) {
      await _showAlert(
        title: "Restore Failed",
        message: "We could not restore your purchase. Please try again.",
      );
    } finally {
      if (mounted) setState(() => _isRestoring = false);
    }
  }

  Future<void> _showAlert({
    required String title,
    required String message,
  }) async {
    if (!mounted) return;
    await showCupertinoDialog<void>(
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

  static bool _isPadhakuProActive(CustomerInfo customerInfo) {
    return customerInfo
            .entitlements
            .all[RevenueCatService.entitlementId]
            ?.isActive ??
        false;
  }

  Future<void> _openExternalUrl(String url) async {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  Widget _buildFeature({required String title, required String description}) {
    const purple = Color(0xFFC13FF0);
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(CupertinoIcons.check_mark, color: purple, size: 19),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: CupertinoColors.black,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(
                    color: Color(0xFF8A8791),
                    fontSize: 13,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final busy = _isPurchasing || _isRestoring;
    const purple = Color(0xFFC13FF0);
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.white,
      child: SafeArea(
        child: DefaultTextStyle.merge(
          style: const TextStyle(decoration: TextDecoration.none),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(22, 10, 22, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            onPressed: busy ? null : _restore,
                            child: _isRestoring
                                ? const CupertinoActivityIndicator()
                                : const Text(
                                    "Restore",
                                    style: TextStyle(
                                      color: purple,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      decoration: TextDecoration.none,
                                    ),
                                  ),
                          ),
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            onPressed: busy
                                ? null
                                : () => Navigator.pop(context),
                            child: Container(
                              width: 29,
                              height: 29,
                              decoration: const BoxDecoration(
                                color: Color(0xFFE8E8EC),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                CupertinoIcons.xmark,
                                color: Color(0xFF9999A1),
                                size: 17,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Center(
                        child: Image.asset(
                          "assets/images/robot_logo.png",
                          height: 100,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "Padhaku Pro",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: CupertinoColors.black,
                          fontSize: 31,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "Upgrade Your Learning, Anytime Anywhere.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF8A8791),
                          fontSize: 17,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.fromLTRB(20, 18, 16, 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF6F5F7),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            _buildFeature(
                              title: "Mind Games",
                              description:
                                  "Boost thinking skills with fun brain challenges",
                            ),
                            _buildFeature(
                              title: "Unlimited Exams",
                              description:
                                  "Practice unlimited exams anytime without restrictions",
                            ),
                            _buildFeature(
                              title: "5 Min Test",
                              description:
                                  "Quick 5 min tests for instant learning checks",
                            ),
                            _buildFeature(
                              title: "One Liners",
                              description:
                                  "Learn important concepts through short notes",
                            ),
                            _buildFeature(
                              title: "School Paper",
                              description:
                                  "Previous school papers for better exam preparation",
                            ),
                            _buildFeature(
                              title: "Image Material",
                              description:
                                  "Visual study materials for faster understanding skills",
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(22, 0, 22, 8),
                color: CupertinoColors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(height: 1, color: const Color(0xFFE2E0E4)),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.fromLTRB(13, 11, 10, 11),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F3F8),
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(color: purple, width: 2),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "${widget.standard}th Standard Plan",
                                  style: const TextStyle(
                                    color: CupertinoColors.black,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _product.priceString,
                                  style: const TextStyle(
                                    color: CupertinoColors.black,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                                const SizedBox(height: 7),
                                const Text(
                                  "One-time purchase",
                                  style: TextStyle(
                                    color: Color(0xFF8A8791),
                                    fontSize: 13,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 31,
                            height: 31,
                            decoration: BoxDecoration(
                              color: purple,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: CupertinoColors.white,
                                width: 3,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x33000000),
                                  blurRadius: 5,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                            child: const Icon(
                              CupertinoIcons.check_mark,
                              color: CupertinoColors.white,
                              size: 17,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    CupertinoButton(
                      color: purple,
                      borderRadius: BorderRadius.circular(7),
                      onPressed: busy ? null : _purchase,
                      child: _isPurchasing
                          ? const CupertinoActivityIndicator(
                              color: CupertinoColors.white,
                            )
                          : const Text(
                              "Continue",
                              style: TextStyle(
                                color: CupertinoColors.white,
                                fontWeight: FontWeight.w700,
                                decoration: TextDecoration.none,
                              ),
                            ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CupertinoButton(
                          minimumSize: Size.zero,
                          padding: EdgeInsets.zero,
                          onPressed: () => _openExternalUrl(
                            "https://dmbhatt.bondbyte.in/terms-and-conditions.html",
                          ),
                          child: const Text(
                            "Terms of Use",
                            style: TextStyle(
                              color: purple,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ),
                        const SizedBox(width: 32),
                        CupertinoButton(
                          minimumSize: Size.zero,
                          padding: EdgeInsets.zero,
                          onPressed: () => _openExternalUrl(
                            "https://dmbhatt.bondbyte.in/privacy.html",
                          ),
                          child: const Text(
                            "Privacy Policy",
                            style: TextStyle(
                              color: purple,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
