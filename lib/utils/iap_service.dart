import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:dm_bhatt_tutions/network/api_service.dart';
import 'package:flutter/material.dart';

class IAPService {
  static final IAPService _instance = IAPService._internal();
  factory IAPService() => _instance;
  IAPService._internal();

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

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

  // Generic consumable product for material purchases
  static const String materialProductId = "com.dmbhatt.material.purchase";

  List<ProductDetails> _products = [];
  bool _isAvailable = false;
  bool _initialized = false;

  // Callbacks
  Function(PurchaseDetails)? onPurchaseSuccess;
  Function(String)? onPurchaseError;

  /// Context tag to identify what purchase is for (e.g., "registration", "upgrade", "material")
  String _purchaseContext = '';
  /// Extra data associated with the current purchase
  Map<String, dynamic> _purchaseMetadata = {};

  void initialize() {
    if (_initialized) return;
    _initialized = true;

    final Stream<List<PurchaseDetails>> purchaseUpdated = _iap.purchaseStream;
    _subscription = purchaseUpdated.listen(
      _listenToPurchaseUpdated,
      onDone: () => _subscription?.cancel(),
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
    final Set<String> ids = {
      ...membershipProductIds.values,
      materialProductId,
    };
    final ProductDetailsResponse response = await _iap.queryProductDetails(ids);

    if (response.error == null) {
      _products = response.productDetails;
      debugPrint("Loaded ${_products.length} products from App Store");
    } else {
      debugPrint("Error loading products: ${response.error}");
    }
  }

  /// Set context before initiating a purchase so the listener knows what to do
  void setPurchaseContext(String context, {Map<String, dynamic>? metadata}) {
    _purchaseContext = context;
    _purchaseMetadata = metadata ?? {};
  }

  String get purchaseContext => _purchaseContext;
  Map<String, dynamic> get purchaseMetadata => _purchaseMetadata;

  /// Purchase membership for a given standard (used for registration & upgrade)
  Future<void> purchaseMembership(String standard) async {
    final productId = membershipProductIds[standard];
    if (productId == null) {
      onPurchaseError?.call("Invalid standard selected for IAP.");
      return;
    }
    await purchaseProduct(productId);
  }

  /// Purchase a material/product (generic consumable)
  Future<void> purchaseMaterial() async {
    await purchaseProduct(materialProductId);
  }

  /// Generic purchase method
  Future<void> purchaseProduct(String productId) async {
    if (!_isAvailable) {
      onPurchaseError?.call("In-App Purchases are not available on this device.");
      return;
    }

    // Ensure products are loaded
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

    // Memberships are non-consumable, materials are consumable
    if (productId == materialProductId) {
      await _iap.buyConsumable(purchaseParam: purchaseParam);
    } else {
      await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    }
  }

  void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        // Show loading or wait — handled by the calling screen
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        onPurchaseError?.call(purchaseDetails.error?.message ?? "Purchase failed");
        if (purchaseDetails.pendingCompletePurchase) {
          _iap.completePurchase(purchaseDetails);
        }
      } else if (purchaseDetails.status == PurchaseStatus.purchased ||
                 purchaseDetails.status == PurchaseStatus.restored) {
        // Notify caller — they handle backend verification
        onPurchaseSuccess?.call(purchaseDetails);

        if (purchaseDetails.pendingCompletePurchase) {
          _iap.completePurchase(purchaseDetails);
        }
      }
    }
  }

  void dispose() {
    _subscription?.cancel();
    _initialized = false;
  }
}
