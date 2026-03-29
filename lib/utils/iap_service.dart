import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:dm_bhatt_tutions/network/api_service.dart';
import 'package:dm_bhatt_tutions/utils/custom_toast.dart';
import 'package:flutter/material.dart';

class IAPService {
  static final IAPService _instance = IAPService._internal();
  factory IAPService() => _instance;
  IAPService._internal();

  final InAppPurchase _iap = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;

  // Product IDs for memberships (Standards 6-12)
  static const Map<String, String> membershipProductIds = {
    "6": "com.dmbhatt.membership.std6",
    "7": "com.dmbhatt.membership.std7",
    "8": "com.dmbhatt.membership.std8",
    "9": "com.dmbhatt.membership.std9",
    "10": "com.dmbhatt.membership.std10",
    "11": "com.dmbhatt.membership.std11",
    "12": "com.dmbhatt.membership.std12",
  };

  List<ProductDetails> _products = [];
  bool _isAvailable = false;

  Function(PurchaseDetails)? onPurchaseSuccess;
  Function(String)? onPurchaseError;

  void initialize() {
    final Stream<List<PurchaseDetails>> purchaseUpdated = _iap.purchaseStream;
    _subscription = purchaseUpdated.listen(
      _listenToPurchaseUpdated,
      onDone: () => _subscription.cancel(),
      onError: (error) {
        debugPrint("IAP Subscription Error: $error");
      },
    );
    _checkAvailability();
  }

  Future<void> _checkAvailability() async {
    _isAvailable = await _iap.isAvailable();
    if (_isAvailable) {
      await _loadProducts();
    }
  }

  Future<void> _loadProducts() async {
    final Set<String> ids = membershipProductIds.values.toSet();
    final ProductDetailsResponse response = await _iap.queryProductDetails(ids);

    if (response.error == null) {
      _products = response.productDetails;
      debugPrint("Loaded ${_products.length} products from App Store");
    } else {
      debugPrint("Error loading products: ${response.error}");
    }
  }

  Future<void> purchaseMembership(String standard) async {
    final productId = membershipProductIds[standard];
    if (productId == null) {
      onPurchaseError?.call("Invalid standard selected for IAP.");
      return;
    }
    await purchaseProduct(productId);
  }

  Future<void> purchaseProduct(String productId) async {
    if (!_isAvailable) {
      onPurchaseError?.call("In-App Purchases are not available on this device.");
      return;
    }

    // Ensure products are loaded (or try to query them specifically if not in initial list)
    if (!_products.any((p) => p.id == productId)) {
      final ProductDetailsResponse response = await _iap.queryProductDetails({productId});
      if (response.error == null && response.productDetails.isNotEmpty) {
        _products.addAll(response.productDetails);
      } else {
        onPurchaseError?.call("Product $productId not found in App Store.");
        return;
      }
    }

    final product = _products.firstWhere((p) => p.id == productId);
    final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);
    await _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
    purchaseDetailsList.forEach((PurchaseDetails purchaseDetails) async {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        // Show loading or wait
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        onPurchaseError?.call(purchaseDetails.error?.message ?? "Purchase failed");
        if (purchaseDetails.pendingCompletePurchase) {
          await _iap.completePurchase(purchaseDetails);
        }
      } else if (purchaseDetails.status == PurchaseStatus.purchased ||
                 purchaseDetails.status == PurchaseStatus.restored) {
        
        // Verify with backend
        final bool verified = await _verifyPurchase(purchaseDetails);
        if (verified) {
          onPurchaseSuccess?.call(purchaseDetails);
        } else {
          onPurchaseError?.call("Transaction verification failed on server.");
        }

        if (purchaseDetails.pendingCompletePurchase) {
          await _iap.completePurchase(purchaseDetails);
        }
      }
    });
  }

  Future<bool> _verifyPurchase(PurchaseDetails purchaseDetails) async {
    try {
      // For Apple, the receipt is in purchaseDetails.verificationData.serverVerificationData
      final receipt = purchaseDetails.verificationData.serverVerificationData;
      final productId = purchaseDetails.productID;

      // Call backend API to verify
      final response = await ApiService.verifyApplePurchase(
        receipt: receipt,
        productId: productId,
        transactionId: purchaseDetails.purchaseID ?? "",
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint("Backend Verification Error: $e");
      return false;
    }
  }

  void dispose() {
    _subscription.cancel();
  }
}
