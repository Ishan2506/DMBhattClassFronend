import 'package:flutter/foundation.dart'
    show debugPrint, kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:dm_bhatt_tutions/utils/guest_utils.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:dm_bhatt_tutions/utils/custom_toast.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_loader.dart';
import 'package:dm_bhatt_tutions/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:dm_bhatt_tutions/network/api_service.dart';
import 'package:dm_bhatt_tutions/utils/revenue_cat_service.dart';
import 'package:dm_bhatt_tutions/utils/razorpay_helper.dart';
import 'package:intl/intl.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/upgrade_receipt_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UpgradePlanScreen extends StatefulWidget {
  const UpgradePlanScreen({super.key});

  @override
  State<UpgradePlanScreen> createState() => _UpgradePlanScreenState();
}

class _UpgradePlanScreenState extends State<UpgradePlanScreen> {
  static const Set<int> _allowedRewardPointOptions = {200, 400};

  final TextEditingController _promoCodeController = TextEditingController();
  final TextEditingController _rewardPointsController = TextEditingController();

  String? _selectedStandard;
  String? _selectedMedium;
  String? _selectedStream;

  final List<String> _standards = ["6", "7", "8", "9", "10", "11", "12"];
  final List<String> _mediums = ["English", "Gujarati"];
  final List<String> _streams = ["Science", "Commerce"];

  double _originalAmount = 0;
  double _finalAmount = 0;
  double _promoDiscount = 0;
  bool _isPromoApplied = false;
  bool _isRewardPointsApplied = false;
  bool? _isRedeemValid;
  String _redeemMessage = '';
  bool? _areRewardPointsValid;
  String _rewardPointsMessage = '';

  // Simulated available points
  int _availablePoints = 0;

  String? _currentStandard;
  bool _isLoading = true;
  bool _isGuest = false;
  bool _isPaid = true;

  // Dynamic plans storage
  Map<String, double> _planPrices = {};

  RazorpayHelper? _razorpayHelper;

  bool get _isIOS => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
    _fetchSubscriptionPlans();

    if (_isIOS) {
      // RevenueCat is initialized in main.dart
    } else {
      _razorpayHelper = RazorpayHelper(
        context: context,
        onSuccess: _handlePaymentSuccess,
        onFailure: _handlePaymentFailure,
      );
    }
  }

  @override
  void dispose() {
    _razorpayHelper?.dispose();
    _promoCodeController.dispose();
    _rewardPointsController.dispose();
    super.dispose();
  }

  void _handlePaymentFailure(dynamic response) {
    CustomToast.showError(context, "Payment Failed: ${response.message}");
  }

  void _handlePaymentSuccess(dynamic response) {
    _verifyUpgrade(
      paymentId: response.paymentId!,
      orderId: response.orderId!,
      signature: response.signature!,
    );
  }

  Future<void> _verifyUpgrade({
    required String paymentId,
    required String orderId,
    required String signature,
  }) async {
    try {
      CustomLoader.show(context);
      final response = await ApiService.verifyUpgradePayment(
        razorpayPaymentId: paymentId,
        razorpayOrderId: orderId,
        razorpaySignature: signature,
        amount: _finalAmount,
        newStandard: _selectedStandard!,
        medium: _selectedMedium!,
        stream: _selectedStream,
      );

      if (!mounted) return;
      CustomLoader.hide(context);

      if (response.statusCode == 200) {
        CustomToast.showSuccess(
          context,
          AppLocalizations.of(context)!.planUpgradeSuccess,
        );
        Navigator.pop(context);
      } else {
        final errorMsg = ApiService.getErrorMessage(response.body);
        CustomToast.showError(context, "Verification Failed: $errorMsg");
      }
    } catch (e) {
      if (mounted) {
        CustomLoader.hide(context);
        CustomToast.showError(context, "Error: $e");
      }
    }
  }

  Future<void> _fetchUserProfile() async {
    try {
      // Token managed internally
      final response = await ApiService.getProfile();

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final profile = data['profile'];
        final user = data['user'];

        if (profile != null) {
          final rewardPoints = profile['totalRewardPoints'];
          setState(() {
            _currentStandard = profile['std']?.toString();
            _availablePoints = rewardPoints is num
                ? rewardPoints.toInt()
                : int.tryParse(rewardPoints?.toString() ?? '') ?? 0;
            _isPaid = user['isPaid'] ?? false;
          });

          if (_currentStandard == "12") {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
              CustomToast.showInfo(
                context,
                "You are already in the highest standard (12th). No higher plans available to upgrade.",
              );
              Navigator.pop(context);
            }
            return;
          }
        }
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        CustomToast.showError(context, "${l10n.registrationFailed} $e");
      }
    } finally {
      if (mounted && _currentStandard != "12") {
        _isGuest = await GuestUtils.isGuest();
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchSubscriptionPlans() async {
    try {
      final response = await ApiService.getActivePlans();

      if (response.statusCode == 200) {
        final plans = jsonDecode(response.body) as List;
        final Map<String, double> prices = {};

        for (var plan in plans) {
          prices[plan['standard']] = (plan['amount'] as num).toDouble();
        }

        setState(() {
          _planPrices = prices;
        });
      } else {
        debugPrint('Failed to fetch plans: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching subscription plans: $e');
    }
  }

  List<String> get _filteredStandards {
    if (_currentStandard == null) return _standards;
    int current = int.tryParse(_currentStandard!) ?? 0;

    // If NOT paid, include the current standard (e.g. 6th) to allow payment
    if (!_isPaid) {
      return _standards
          .where((s) => (int.tryParse(s) ?? 0) >= current)
          .toList();
    }

    // Filter standards strictly greater than current standard
    return _standards.where((s) => (int.tryParse(s) ?? 0) > current).toList();
  }

  // ... existing methods (_calculateAmount, etc.) ...

  void _calculateAmount() {
    if (_selectedStandard == null) {
      _originalAmount = 0;
      _recalculateFinal();
      return;
    }

    _originalAmount = _planPrices[_selectedStandard] ?? 0;
    _recalculateFinal();
  }

  void _recalculateFinal() {
    setState(() {
      _finalAmount = _originalAmount > 0 ? _originalAmount - 1 : 0;
      final discountAmount = _activeDiscountAmount;
      if (discountAmount > 0) {
        _promoDiscount = discountAmount;
        _finalAmount -= _promoDiscount;
      } else {
        _promoDiscount = 0;
      }

      if (_finalAmount < 0) _finalAmount = 0;
    });
  }

  bool get _hasValidCodeDiscount => _isPromoApplied || _isRewardPointsApplied;

  double get _activeDiscountAmount {
    if (_isRewardPointsApplied && _appliedRewardPoints == 400) return 200;
    if (_hasValidCodeDiscount) return 100;
    return 0;
  }

  int? get _appliedRewardPoints {
    if (!_isRewardPointsApplied) return null;
    return int.tryParse(_rewardPointsController.text.trim());
  }

  void _validateRedeemCode() {
    if (_selectedStandard == null) {
      final l10n = AppLocalizations.of(context)!;
      CustomToast.showError(context, l10n.selectStandardFirst);
      return;
    }
    final code = _promoCodeController.text.trim().toUpperCase();
    if (code.isEmpty) {
      _resetRedeemValidation();
      CustomToast.showError(context, "Redeem code is required");
      return;
    }

    final expectedCode = "DMBHATT$_selectedStandard";

    if (code == expectedCode) {
      setState(() {
        _isPromoApplied = true;
        _isRedeemValid = true;
        _redeemMessage = "Redeem code applied successfully.";
      });
      _recalculateFinal();
      final l10n = AppLocalizations.of(context)!;
      CustomToast.showSuccess(context, l10n.promoAppliedSuccess);
    } else {
      setState(() {
        _isPromoApplied = false;
        _isRedeemValid = false;
        _redeemMessage = AppLocalizations.of(context)!.invalidPromoCode;
      });
      _recalculateFinal();
      final l10n = AppLocalizations.of(context)!;
      CustomToast.showError(context, l10n.invalidPromoCode);
    }
  }

  bool _hasValidRedeemCodeForSelectedStandard() {
    if (_selectedStandard == null) return false;
    final code = _promoCodeController.text.trim().toUpperCase();
    return _isRedeemValid == true && code == "DMBHATT$_selectedStandard";
  }

  void _resetRedeemValidation({bool recalculate = true}) {
    setState(() {
      _isPromoApplied = false;
      _isRedeemValid = null;
      _redeemMessage = '';
    });
    if (recalculate) _recalculateFinal();
  }

  bool _validateRedeemCodeForPurchase() {
    final code = _promoCodeController.text.trim().toUpperCase();
    if (code.isEmpty) return true;
    if (_hasValidRedeemCodeForSelectedStandard()) return true;

    CustomToast.showError(context, "Please validate redeem code first");
    return false;
  }

  void _resetRewardPoints({bool recalculate = true}) {
    setState(() {
      _isRewardPointsApplied = false;
      _areRewardPointsValid = null;
      _rewardPointsMessage = '';
    });
    if (recalculate) _recalculateFinal();
  }

  void _applyRewardPoints() {
    final input = _rewardPointsController.text.trim();

    if (input.isEmpty) {
      setState(() {
        _isRewardPointsApplied = false;
        _areRewardPointsValid = null;
        _rewardPointsMessage = '';
      });
      _recalculateFinal();
      return;
    }

    final points = int.tryParse(input);

    if (points == null || !_allowedRewardPointOptions.contains(points)) {
      const message = "Enter either 200 or 400 points";
      CustomToast.showError(context, message);
      setState(() {
        _isRewardPointsApplied = false;
        _areRewardPointsValid = false;
        _rewardPointsMessage = message;
      });
      _recalculateFinal();
      return;
    }

    if (points > _availablePoints) {
      final l10n = AppLocalizations.of(context)!;
      final message = l10n.insufficientPoints(_availablePoints);
      CustomToast.showError(context, message);
      setState(() {
        _isRewardPointsApplied = false;
        _areRewardPointsValid = false;
        _rewardPointsMessage = message;
      });
      _recalculateFinal();
      return;
    }

    final message = "$points reward points applied successfully.";
    setState(() {
      _isRewardPointsApplied = true;
      _areRewardPointsValid = true;
      _rewardPointsMessage = message;
    });
    _recalculateFinal();
    CustomToast.showSuccess(context, message);
  }

  bool _validateRewardPointsForPurchase() {
    if (_rewardPointsController.text.trim().isEmpty || _isRewardPointsApplied) {
      return true;
    }

    final points = int.tryParse(_rewardPointsController.text.trim());
    if (points == null || !_allowedRewardPointOptions.contains(points)) {
      const message = "Enter either 200 or 400 points";
      CustomToast.showError(context, message);
      setState(() {
        _isRewardPointsApplied = false;
        _areRewardPointsValid = false;
        _rewardPointsMessage = message;
      });
      _recalculateFinal();
      return false;
    }

    CustomToast.showError(context, "Please apply reward points first");
    return false;
  }

  Future<void> _processUpgrade() async {
    if (_isGuest) {
      GuestUtils.showGuestRestrictionDialog(
        context,
        message:
            "Guests cannot upgrade plans. Please register as a full student to access premium features.",
      );
      return;
    }
    if (_selectedStandard == null || _selectedMedium == null) {
      final l10n = AppLocalizations.of(context)!;
      CustomToast.showError(context, l10n.selectStandardMediumError);
      return;
    }
    if (!_validateRewardPointsForPurchase()) return;
    if ((_selectedStandard == "11" || _selectedStandard == "12") &&
        _selectedStream == null) {
      final l10n = AppLocalizations.of(context)!;
      CustomToast.showError(context, l10n.selectStreamError);
      return;
    }

    if (_isIOS) {
      if (!_validateRedeemCodeForPurchase()) return;

      final useRedeemProduct =
          _hasValidRedeemCodeForSelectedStandard() || _isRewardPointsApplied;
      final rewardPoints = _appliedRewardPoints;
      // iOS: Show the RevenueCat package matching the selected standard.
      final result = await RevenueCatService.instance
          .presentStandardPaywallWithResult(
            context: context,
            standard: _selectedStandard,
            useRedeemProduct: useRedeemProduct,
            rewardPoints: rewardPoints,
          );
      if (!mounted) return;
      if (result.isSuccess) {
        await _completeAppleUpgradeFromRevenueCat(result);
      } else {
        await _showApplePurchaseDialog(result.title, result.message);
      }
    } else {
      // Android: Use Razorpay
      try {
        CustomLoader.show(context);
        final response = await ApiService.createUpgradeOrder(
          amount: _finalAmount,
          newStandard: _selectedStandard!,
          medium: _selectedMedium!,
          stream: _selectedStream,
        );

        if (!mounted) return;
        CustomLoader.hide(context);

        if (response.statusCode == 200) {
          final orderData = jsonDecode(response.body);
          final String orderId = orderData['id'];

          _razorpayHelper!.openCheckout(
            amount: _finalAmount,
            name: "Padhaku Desk",
            description: "Upgrade to Standard $_selectedStandard",
            contact: '',
            email: '',
            orderId: orderId,
          );
        } else {
          final errorMsg = ApiService.getErrorMessage(response.body);
          CustomToast.showError(context, "Failed: $errorMsg");
        }
      } catch (e) {
        if (mounted) {
          CustomLoader.hide(context);
          CustomToast.showError(context, "Error: $e");
        }
      }
    }
  }

  Future<void> _completeAppleUpgradeFromRevenueCat(
    RevenueCatPurchaseResult result,
  ) async {
    final productId = result.productId;
    final expectedProductId =
        result.requestedProductId ??
        RevenueCatService.primaryProductIdForStandard(
          _selectedStandard,
          useRedeemProduct:
              _hasValidRedeemCodeForSelectedStandard() ||
              _isRewardPointsApplied,
          rewardPoints: _appliedRewardPoints,
        );
    final transactionId = result.transactionId;
    debugPrint("[Apple Upgrade Screen] Completing via RevenueCat");
    debugPrint("[Apple Upgrade Screen] productId: $productId");
    debugPrint("[Apple Upgrade Screen] expectedProductId: $expectedProductId");
    debugPrint("[Apple Upgrade Screen] transactionId: $transactionId");
    debugPrint("[Apple Upgrade Screen] selectedStandard: $_selectedStandard");
    debugPrint("[Apple Upgrade Screen] selectedMedium: $_selectedMedium");
    debugPrint("[Apple Upgrade Screen] selectedStream: $_selectedStream");
    debugPrint(
      "[Apple Upgrade Screen] amount: ${result.amountPaid ?? _finalAmount}",
    );
    final active = await RevenueCatService.instance.refreshIsProActive();
    if (!active ||
        productId == null ||
        productId.isEmpty ||
        transactionId == null ||
        transactionId.isEmpty ||
        _selectedStandard == null ||
        _selectedMedium == null) {
      debugPrint(
        "[Apple Upgrade Screen] Missing verification details: "
        "entitlementActive=$active, "
        "productIdMissing=${productId == null || productId.isEmpty}, "
        "transactionIdMissing=${transactionId == null || transactionId.isEmpty}, "
        "standardMissing=${_selectedStandard == null}, "
        "mediumMissing=${_selectedMedium == null}",
      );
      await _showApplePurchaseDialog(
        "Purchase Failed",
        "Apple purchase finished, but active subscription access was not found. Please restore purchases or try again.",
      );
      return;
    }

    if (expectedProductId != null && productId != expectedProductId) {
      debugPrint(
        "[Apple Upgrade Screen] Product mismatch: "
        "expected=$expectedProductId actual=$productId",
      );
      await _showApplePurchaseDialog(
        "Purchase Failed",
        "Apple returned a different product ($productId) than the selected plan ($expectedProductId). Please try again or restore the correct subscription.",
      );
      return;
    }

    final refreshedReceipt = await RevenueCatService.instance
        .getAppleReceiptAfterPurchase(
          maxAttempts: 8,
          delay: const Duration(milliseconds: 1500),
          forceRefresh: true,
        );
    final receipt =
        (refreshedReceipt != null &&
            refreshedReceipt.length > (result.receipt?.length ?? 0))
        ? refreshedReceipt
        : result.receipt;

    if (receipt == null || receipt.isEmpty) {
      debugPrint("[Apple Upgrade Screen] Missing Apple receipt");
      await _showApplePurchaseDialog(
        "Verification Failed",
        "Apple purchase completed, but the receipt was not available. Please try restore purchases.",
      );
      return;
    }

    final response = await _verifyAppleUpgradeWithReceiptRetry(
      receipt: receipt,
      productId: productId,
      expectedProductId: expectedProductId,
      transactionId: transactionId,
      amount: result.amountPaid ?? _finalAmount,
    );

    if (!mounted) return;
    if (response.statusCode != 200 && response.statusCode != 201) {
      await _showApplePurchaseDialog(
        "Verification Failed",
        ApiService.getErrorMessage(response.body),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("std", _selectedStandard!);
    await prefs.setString("medium", _selectedMedium!);
    if (_selectedStream != null) {
      await prefs.setString("stream", _selectedStream!);
    }
    if (!mounted) return;
    await _showApplePurchaseDialog(
      "Purchase Successful",
      "Your subscription is active.",
    );
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  Future<dynamic> _verifyAppleUpgradeWithReceiptRetry({
    required String receipt,
    required String productId,
    required String? expectedProductId,
    required String transactionId,
    required double amount,
  }) async {
    var response = await ApiService.verifyAppleUpgrade(
      receipt: receipt,
      productId: productId,
      expectedProductId: expectedProductId,
      transactionId: transactionId,
      newStandard: _selectedStandard!,
      medium: _selectedMedium!,
      stream: _selectedStream,
      amount: amount,
    );

    if (!_isReceiptMissingProductError(response.body)) {
      return response;
    }

    debugPrint(
      "[Apple Upgrade Screen] Receipt missing purchased product. Refreshing receipt and retrying verification.",
    );
    await Future.delayed(const Duration(seconds: 4));
    final refreshedReceipt = await RevenueCatService.instance
        .getAppleReceiptAfterPurchase(
          maxAttempts: 8,
          delay: const Duration(milliseconds: 1500),
          forceRefresh: true,
        );

    if (refreshedReceipt == null || refreshedReceipt.isEmpty) {
      return response;
    }

    return ApiService.verifyAppleUpgrade(
      receipt: refreshedReceipt,
      productId: productId,
      expectedProductId: expectedProductId,
      transactionId: transactionId,
      newStandard: _selectedStandard!,
      medium: _selectedMedium!,
      stream: _selectedStream,
      amount: amount,
    );
  }

  bool _isReceiptMissingProductError(String body) {
    final lower = body.toLowerCase();
    return lower.contains("purchased product was missing") ||
        lower.contains("missing in the receipt") ||
        lower.contains("receipt is not valid");
  }

  Future<void> _showApplePurchaseDialog(String title, String message) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _showUpgradeHistory() async {
    try {
      CustomLoader.show(context);
      final response = await ApiService.getUpgradeHistory();

      if (!mounted) return;
      CustomLoader.hide(context);

      if (response.statusCode == 200) {
        final List<dynamic> history = jsonDecode(response.body);
        if (history.isEmpty) {
          CustomToast.showInfo(context, "No upgrade history found.");
          return;
        }

        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => _buildHistoryModal(history),
        );
      } else {
        CustomToast.showError(context, "Failed to fetch history");
      }
    } catch (e) {
      if (mounted) {
        CustomLoader.hide(context);
        CustomToast.showError(context, "Error: $e");
      }
    }
  }

  Widget _buildHistoryModal(List<dynamic> history) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Upgrade History",
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: history.length,
              itemBuilder: (context, index) {
                final item = history[index];
                final date = DateTime.parse(item['createdAt']);
                final formattedDate = DateFormat(
                  'dd MMM yyyy, hh:mm a',
                ).format(date);

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UpgradeReceiptScreen(
                            historyItem: item as Map<String, dynamic>,
                          ),
                        ),
                      );
                    },
                    title: Text(
                      "Standard ${item['oldStandard']} ➔ ${item['newStandard']}",
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Medium: ${item['medium']}${item['stream'] != null ? ' (${item['stream']})' : ''}",
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Date: $formattedDate",
                          style: const TextStyle(fontSize: 12),
                        ),
                        Text(
                          "Transaction ID: ${item['razorpayPaymentId']}",
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    trailing: Text(
                      "₹${item['amount']}",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                        fontSize: 16,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: CustomAppBar(title: l10n.upgradePlan, centerTitle: true),
        body: const Center(child: CustomLoader()),
      );
    }
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: CustomAppBar(
        title: l10n.upgradePlan,
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _showUpgradeHistory,
            icon: const Icon(Icons.history, color: Colors.white),
            tooltip: "Upgrade History",
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Selection Section
            Text(
              "Select Your New Plan",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: colorScheme.outlineVariant.withOpacity(0.5),
                ),
              ),
              child: Column(
                children: [
                  _buildDropdown(
                    label: l10n.standard,
                    value: _selectedStandard,
                    items: _filteredStandards,
                    onChanged: (val) {
                      setState(() {
                        _selectedStandard = val;
                        if (val != "11" && val != "12") {
                          _selectedStream = null;
                        }
                      });
                      _calculateAmount();
                      _resetRedeemValidation();
                      _resetRewardPoints();
                    },
                    colorScheme: colorScheme,
                  ),
                  if (_selectedStandard == "11" ||
                      _selectedStandard == "12") ...[
                    const SizedBox(height: 16),
                    _buildDropdown(
                      label: l10n.stream,
                      value: _selectedStream,
                      items: _streams,
                      onChanged: (val) {
                        setState(() {
                          _selectedStream = val;
                        });
                      },
                      colorScheme: colorScheme,
                    ),
                  ],
                  const SizedBox(height: 16),
                  _buildDropdown(
                    label: l10n.medium,
                    value: _selectedMedium,
                    items: _mediums,
                    onChanged: (val) {
                      setState(() {
                        _selectedMedium = val;
                      });
                    },
                    colorScheme: colorScheme,
                  ),
                ],
              ),
            ),

            if (_selectedStandard != null) ...[
              const SizedBox(height: 32),
              // Plan Details Card (Matching PaymentScreen)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withOpacity(0.2),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Standard $_selectedStandard",
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onPrimary.withOpacity(0.8),
                              ),
                            ),
                            Text(
                              "${_selectedMedium ?? ''} Medium",
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onPrimary,
                              ),
                            ),
                            if (_selectedStream != null)
                              Text(
                                _selectedStream!,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: colorScheme.onPrimary.withOpacity(0.8),
                                ),
                              ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            "ANNUAL",
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Divider(color: Colors.white24, thickness: 1),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.totalPayable,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: colorScheme.onPrimary.withOpacity(0.9),
                          ),
                        ),
                        Text(
                          "₹${_finalAmount.toStringAsFixed(0)}",
                          style: GoogleFonts.poppins(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
              // Membership Benefits (Chips style)
              Text(
                "Membership Benefits",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _buildBenefitChip(
                    context,
                    Icons.auto_stories,
                    "Full Access",
                    Colors.blue,
                  ),
                  _buildBenefitChip(
                    context,
                    Icons.description,
                    "School Papers",
                    Colors.green,
                  ),
                  _buildBenefitChip(
                    context,
                    Icons.stars_rounded,
                    "Board Papers",
                    Colors.orange,
                  ),
                  _buildBenefitChip(
                    context,
                    Icons.hub_outlined,
                    "Mind Maps",
                    Colors.purple,
                  ),
                  _buildBenefitChip(
                    context,
                    Icons.timer,
                    "5 Min Test",
                    Colors.red,
                  ),
                  _buildBenefitChip(
                    context,
                    Icons.analytics,
                    "Performance",
                    Colors.teal,
                  ),
                  _buildBenefitChip(
                    context,
                    Icons.library_books,
                    "Premium Material",
                    Colors.indigo,
                  ),
                ],
              ),

              const SizedBox(height: 32),
              Text(
                "Apply Code",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              _buildCodeField(
                label: "Redeem Code",
                hintText: "Enter Redeem Code",
                controller: _promoCodeController,
                colorScheme: colorScheme,
                showValidIcon: _hasValidRedeemCodeForSelectedStandard(),
                showErrorIcon: _isRedeemValid == false,
                onChanged: (_) => _resetRedeemValidation(),
                actionLabel: "Validate",
                onActionPressed: _validateRedeemCode,
              ),
              if (_redeemMessage.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  _redeemMessage,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _isRedeemValid == true ? Colors.green : Colors.red,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              // Reward Points Section
              Text(
                "Use Reward Points (Available: $_availablePoints)",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colorScheme.outlineVariant.withOpacity(0.5),
                        ),
                      ),
                      child: TextField(
                        controller: _rewardPointsController,
                        keyboardType: TextInputType.number,
                        onChanged: (_) => _resetRewardPoints(),
                        decoration: InputDecoration(
                          hintText: l10n.pointsHint,
                          hintStyle: GoogleFonts.poppins(
                            color: colorScheme.onSurfaceVariant.withOpacity(
                              0.5,
                            ),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                          ),
                        ),
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _applyRewardPoints,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.inverseSurface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 20,
                      ),
                    ),
                    child: Text(
                      l10n.use,
                      style: GoogleFonts.poppins(
                        color: colorScheme.onInverseSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              if (_rewardPointsMessage.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  _rewardPointsMessage,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _areRewardPointsValid == true
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
              ],

              const SizedBox(height: 32),
              // Terms/Info Section
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Colors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "This membership will be expired after 1 year.",
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.orange.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
              // Pay Button
              Container(
                width: double.infinity,
                height: 60,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _processUpgrade,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        l10n.payAndUpgrade(_finalAmount.toStringAsFixed(0)),
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
    required ColorScheme colorScheme,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              hint: Text(
                "${l10n.selectSubject} $label",
                style: GoogleFonts.poppins(color: colorScheme.onSurfaceVariant),
              ), // Assuming selectSubject is "Select" or using l10n.selectStandard etc? Actually I added selectStandard key. Let's use a generic one if I have or specific.
              dropdownColor: colorScheme.surface, // Or any distinct surface
              items: items.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    item,
                    style: GoogleFonts.poppins(color: colorScheme.onSurface),
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCodeField({
    required String label,
    required String hintText,
    required TextEditingController controller,
    required ColorScheme colorScheme,
    bool showValidIcon = false,
    bool showErrorIcon = false,
    bool showLoadingIcon = false,
    ValueChanged<String>? onChanged,
    String? actionLabel,
    VoidCallback? onActionPressed,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withOpacity(0.5),
                  ),
                ),
                child: TextField(
                  controller: controller,
                  textCapitalization: TextCapitalization.characters,
                  onChanged: onChanged,
                  decoration: InputDecoration(
                    hintText: hintText,
                    hintStyle: GoogleFonts.poppins(
                      color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    suffixIcon: showLoadingIcon
                        ? Padding(
                            padding: const EdgeInsets.all(12),
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  colorScheme.primary,
                                ),
                              ),
                            ),
                          )
                        : showValidIcon
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : showErrorIcon
                        ? const Icon(Icons.error, color: Colors.red)
                        : null,
                  ),
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ),
            if (actionLabel != null) ...[
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: onActionPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.inverseSurface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 20,
                  ),
                ),
                child: Text(
                  actionLabel,
                  style: GoogleFonts.poppins(
                    color: colorScheme.onInverseSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value,
    ColorScheme colorScheme, {
    bool isDiscount = false,
    bool isTotal = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: isTotal ? 18 : 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isDiscount ? Colors.green : colorScheme.onSurface,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: isTotal ? 20 : 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.bold,
              color: isDiscount
                  ? Colors.green
                  : (isTotal ? colorScheme.primary : colorScheme.onSurface),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitChip(
    BuildContext context,
    IconData icon,
    String text,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }
}
