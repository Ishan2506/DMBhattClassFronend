import 'dart:convert';
import 'package:dm_bhatt_tutions/network/api_service.dart';
import 'package:dm_bhatt_tutions/screen/authentication/login_screen.dart';
import 'package:dm_bhatt_tutions/utils/custom_toast.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_loader.dart';
import 'package:dm_bhatt_tutions/model/registration_payload.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dm_bhatt_tutions/utils/revenue_cat_service.dart';
import 'package:dm_bhatt_tutions/utils/razorpay_helper.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class PaymentScreen extends StatefulWidget {
  final RegistrationPayload? payload;
  final String? password; // needed for api call
  final String? std;
  final String? medium;
  final String? phone;
  final String? email;

  const PaymentScreen({
    super.key,
    this.payload,
    this.password,
    this.std,
    this.medium,
    this.phone,
    this.email,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final TextEditingController _promoCodeController = TextEditingController();
  final TextEditingController _referralCodeController = TextEditingController();

  double _originalAmount = 0;
  double _finalAmount = 0;
  double _discount = 0;
  bool _isDiscountApplied = false;
  bool? _isRedeemValid;
  String _redeemMessage = '';

  // Platform-specific payment helpers
  RazorpayHelper? _razorpayHelper;

  // Referral code validation states
  bool _isValidatingReferral = false;
  bool? _isReferralValid;
  String _referralMessage = '';
  double _referralDiscount = 0;

  String? _board;
  String _redeemDiscountType = 'percentage'; // 'percentage' | 'flat'
  double _redeemDiscountValue = 0;
  String? _validatedRedeemCode;

  String? _std;
  String? _medium;
  String? _stream;
  String? _phoneNum;
  String? _email;
  String? _cachedPassword;
  bool _isLoading = true;

  // Dynamic plans storage
  Map<String, double> _planPrices = {};

  bool get _isIOS => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  @override
  void initState() {
    super.initState();
    _initData();
    _fetchSubscriptionPlans();

    if (_isIOS) {
      // RevenueCat is initialized in main.dart
    } else {
      // Android: Use Razorpay
      _razorpayHelper = RazorpayHelper(
        context: context,
        onSuccess: _handlePaymentSuccess,
        onFailure: _handlePaymentFailure,
      );
    }
  }

  Future<void> _initData() async {
    if (widget.payload != null) {
      _std = widget.payload!.fields['std']?.toString();
      _medium = widget.payload!.fields['medium']?.toString();
      _stream = widget.payload!.fields['stream']?.toString();
      _phoneNum = widget.payload!.fields['phoneNum'];
      _email = widget.payload!.fields['email'];
      _cachedPassword = widget.password;
    } else if (widget.std != null) {
      _std = widget.std;
      _medium = widget.medium;
      _phoneNum = widget.phone;
      _email = widget.email;
      _cachedPassword = widget.password; // If passed
    } else {
      final prefs = await SharedPreferences.getInstance();
      _std = prefs.getString('std');
      _medium = prefs.getString('medium');
      _stream = prefs.getString('stream');
      _phoneNum = prefs.getString('user_phone');
      _email = prefs.getString('user_email');
      _cachedPassword = prefs.getString('user_password');
    }

    // Always ensure values not passed by the caller are loaded from the profile.
    final prefs = await SharedPreferences.getInstance();
    _board = widget.payload?.fields['board']?.toString() ?? prefs.getString('board');
    if (_cachedPassword == null) {
      _cachedPassword = prefs.getString('user_password');
    }
    _stream ??= prefs.getString('stream');

    if (_std != null) {
      _calculateInitialAmount();
    }

    setState(() {
      _isLoading = false;
    });
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

        if (!mounted) return;
        setState(() {
          _planPrices = prices;
          if (_std != null) {
            _calculateInitialAmount();
          }
        });
      } else {
        debugPrint('Failed to fetch plans: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching subscription plans: $e');
    }
  }

  @override
  void dispose() {
    _razorpayHelper?.dispose();
    _promoCodeController.dispose();
    _referralCodeController.dispose();
    super.dispose();
  }

  void _handlePaymentFailure(PaymentFailureResponse response) {
    CustomToast.showError(context, "Payment Cancelled");
  }

  void _calculateInitialAmount() {
    _originalAmount = _planPrices[_std] ?? 0;
    _calculateFinalAmount();
  }

  void _calculateFinalAmount() {
    _finalAmount = _originalAmount > 0 ? _originalAmount - 1 : 0;
    if (_isIOS) {
      // Keep iOS logic completely untouched
      if (_hasValidCodeDiscount) {
        _discount = 100;
        _finalAmount -= _discount;
      } else {
        _discount = 0;
      }
    } else {
      // Android / non-iOS logic: Apply redeem code and/or referral code dynamically
      double totalDiscount = 0;
      if (_isDiscountApplied) {
        if (_redeemDiscountType == 'flat') {
          totalDiscount += _redeemDiscountValue;
        } else {
          totalDiscount += (_originalAmount * _redeemDiscountValue / 100.0);
        }
      }
      if (_hasValidatedReferralCode) {
        totalDiscount += _referralDiscount; // Referral discount
      }
      _discount = totalDiscount;
      _finalAmount -= _discount;
      debugPrint("[_calculateFinalAmount] _originalAmount: $_originalAmount, _discount: $_discount, _finalAmount: $_finalAmount, _referralDiscount: $_referralDiscount, _hasValidatedReferralCode: $_hasValidatedReferralCode");
    }
    if (_finalAmount < 0) _finalAmount = 0;
  }

  bool get _hasValidCodeDiscount =>
      _isDiscountApplied || _hasValidatedReferralCode;

  bool get _hasValidatedReferralCode =>
      _referralCodeController.text.trim().isNotEmpty &&
      _isReferralValid == true;

  Future<void> _validateRedeemCode() async {
    if (_hasValidatedReferralCode) {
      CustomToast.showError(
        context,
        "Cannot apply redeem code when a referral code is already applied.",
      );
      return;
    }
    final code = _promoCodeController.text.trim().toUpperCase();

    if (code.isEmpty) {
      _resetRedeemValidation();
      CustomToast.showError(context, "Redeem code is required");
      return;
    }

    try {
      CustomLoader.show(context);
      final response = await ApiService.validateRedeemCode(
        code,
        targetStd: _std,
        targetBoard: _board,
        targetMedium: _medium,
        targetStream: _stream,
      );
      if (!mounted) return;
      CustomLoader.hide(context);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _isDiscountApplied = true;
          _isRedeemValid = true;
          _redeemDiscountType = data['discountType'] == 'flat'
              ? 'flat'
              : 'percentage';
          _redeemDiscountValue = (data['discount'] ?? 0).toDouble();
          _validatedRedeemCode = code;
          _redeemMessage = data['message'] ?? "Redeem code applied successfully.";
          _calculateFinalAmount();
        });
        CustomToast.showSuccess(context, _redeemMessage);
      } else {
        final errorMsg = ApiService.getErrorMessage(response.body);
        setState(() {
          _isDiscountApplied = false;
          _isRedeemValid = false;
          _redeemDiscountValue = 0;
          _validatedRedeemCode = null;
          _redeemMessage = errorMsg;
          _calculateFinalAmount();
        });
        CustomToast.showError(context, errorMsg);
      }
    } catch (e) {
      if (mounted) {
        CustomLoader.hide(context);
        setState(() {
          _isDiscountApplied = false;
          _isRedeemValid = false;
          _redeemDiscountValue = 0;
          _validatedRedeemCode = null;
          _redeemMessage = "Error validating code: $e";
          _calculateFinalAmount();
        });
        CustomToast.showError(context, _redeemMessage);
      }
    }
  }

  void _resetRedeemValidation() {
    setState(() {
      _isDiscountApplied = false;
      _isRedeemValid = null;
      _redeemDiscountValue = 0;
      _validatedRedeemCode = null;
      _redeemMessage = '';
      _calculateFinalAmount();
    });
  }

  bool _hasValidRedeemCodeForSelectedStandard() {
    final code = _promoCodeController.text.trim().toUpperCase();
    return _isRedeemValid == true &&
        _validatedRedeemCode != null &&
        code == _validatedRedeemCode;
  }

  bool _validateRedeemCodeForPurchase() {
    final code = _promoCodeController.text.trim().toUpperCase();
    if (code.isEmpty) return true;
    if (_hasValidRedeemCodeForSelectedStandard()) return true;

    CustomToast.showError(context, "Please validate redeem code first");
    return false;
  }

  void _resetReferralValidation() {
    setState(() {
      _isReferralValid = null;
      _referralMessage = '';
      _referralDiscount = 0;
      _calculateFinalAmount();
    });
  }

  Future<void> _validateReferralCode() async {
    debugPrint("[XCODE][Referral Validate Screen] Validate button tapped");
    if (_isDiscountApplied) {
      debugPrint(
        "[XCODE][Referral Validate Screen] Blocked: redeem code already applied",
      );
      CustomToast.showError(
        context,
        "Cannot apply referral code when a redeem code is already applied.",
      );
      return;
    }
    final code = _referralCodeController.text.trim();
    debugPrint("[XCODE][Referral Validate Screen] Entered code: $code");

    if (code.isEmpty) {
      debugPrint("[XCODE][Referral Validate Screen] Blocked: empty code");
      _resetReferralValidation();
      CustomToast.showError(context, "Referral code is required");
      return;
    }

    setState(() {
      _isValidatingReferral = true;
      _isReferralValid = null;
      _referralMessage = '';
    });

    try {
      debugPrint("[XCODE][Referral Validate Screen] Calling API");
      final refResponse = await ApiService.validateReferralCode(code);
      debugPrint(
        "[XCODE][Referral Validate Screen] API status: ${refResponse.statusCode}",
      );
      debugPrint(
        "[XCODE][Referral Validate Screen] API body: ${refResponse.body}",
      );

      if (!mounted) return;

      if (refResponse.statusCode == 200) {
        final refData = jsonDecode(refResponse.body);
        debugPrint(
          "[XCODE][Referral Validate Screen] Parsed valid=${refData['valid']} discount=${refData['discountAmount']} message=${refData['message']}",
        );
        setState(() {
          _isReferralValid = refData['valid'] == true;
          _referralMessage = refData['message'] ?? "Referral applied!";
          _referralDiscount = (refData['discountAmount'] ?? 0).toDouble();
          _calculateFinalAmount();
        });
        CustomToast.showSuccess(context, _referralMessage);
        return;
      }

      setState(() {
        _isReferralValid = false;
        _referralMessage = ApiService.getErrorMessage(refResponse.body);
        _calculateFinalAmount();
      });
      debugPrint(
        "[XCODE][Referral Validate Screen] Validation failed: $_referralMessage",
      );
      CustomToast.showError(context, _referralMessage);
    } catch (e) {
      debugPrint("[XCODE][Referral Validate Screen] Exception: $e");
      if (mounted) {
        setState(() {
          _isReferralValid = false;
          _referralMessage = 'Error validating referral code';
          _calculateFinalAmount();
        });
        CustomToast.showError(context, _referralMessage);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isValidatingReferral = false;
        });
      }
    }
  }

  bool _validateReferralForPurchase() {
    final code = _referralCodeController.text.trim();
    if (code.isEmpty) return true;
    if (_isReferralValid == true) return true;

    CustomToast.showError(context, "Please validate referral code first");
    return false;
  }

  Future<void> _applyReferralAfterPurchase() async {
    final code = _referralCodeController.text.trim();
    if (!_hasValidatedReferralCode) return;

    try {
      final response = await ApiService.applyReferralCode(code);
      if (!mounted) return;
      if (response.statusCode != 200) {
        CustomToast.showError(
          context,
          "Referral apply failed: ${ApiService.getErrorMessage(response.body)}",
        );
      }
    } catch (e) {
      if (!mounted) return;
      CustomToast.showError(context, "Referral apply failed: $e");
    }
  }

  Future<void> _initiatePayment() async {
    if (!_validateReferralForPurchase()) return;
    if (!_validateRedeemCodeForPurchase()) return;

    if (_finalAmount <= 0) {
      // If amount is 0 (e.g. 100% discount), skip payment
      _processRegistration(paymentId: "FREE_PLAN");
      return;
    }

    if (_isIOS) {
      final useRedeemProduct = _hasValidRedeemCodeForSelectedStandard();
      final useReferralProduct = !useRedeemProduct && _hasValidatedReferralCode;
      // iOS: Show the RevenueCat package matching the selected standard.
      final result = await RevenueCatService.instance
          .presentStandardPaywallWithResult(
            context: context,
            standard: _std,
            useRedeemProduct: useRedeemProduct,
            useReferralProduct: useReferralProduct,
          );
      if (!mounted) return;
      if (result.isSuccess) {
        await _completeAppleMembershipFromRevenueCat(result);
      } else {
        await _showApplePurchaseDialog(result.title, result.message);
      }
    } else {
      // Android: Use Razorpay
      try {
        CustomLoader.show(context);
        final orderResponse = await ApiService.createPaymentOrder(_finalAmount);

        if (!mounted) return;
        CustomLoader.hide(context);

        if (orderResponse.statusCode == 200) {
          final orderData = jsonDecode(orderResponse.body);
          final String orderId = orderData['id'];

          _razorpayHelper!.openCheckout(
            amount: _finalAmount,
            name: "Padhaku Desk",
            description: "Standard $_std Membership",
            contact: _phoneNum ?? '',
            email: _email ?? '',
            orderId: orderId,
          );
        } else {
          CustomToast.showError(
            context,
            "Failed to create order: ${ApiService.getErrorMessage(orderResponse.body)}",
          );
        }
      } catch (e) {
        if (mounted) {
          CustomLoader.hide(context);
          CustomToast.showError(context, "Error initiating payment: $e");
        }
      }
    }
  }

  Future<void> _completeAppleMembershipFromRevenueCat(
    RevenueCatPurchaseResult result,
  ) async {
    try {
      CustomLoader.show(context);
      final active = await RevenueCatService.instance.refreshIsProActive();
      if (!mounted) return;

      final productId = result.productId;
      final expectedProductId =
          result.requestedProductId ??
          RevenueCatService.productIdForStandard(
            _std,
            useRedeemProduct: _hasValidRedeemCodeForSelectedStandard(),
            useReferralProduct:
                !_hasValidRedeemCodeForSelectedStandard() &&
                _hasValidatedReferralCode,
          );
      final transactionId = result.transactionId;
      debugPrint("[Apple Membership Screen] Completing via RevenueCat");
      debugPrint("[Apple Membership Screen] productId: $productId");
      debugPrint(
        "[Apple Membership Screen] expectedProductId: $expectedProductId",
      );
      debugPrint("[Apple Membership Screen] transactionId: $transactionId");
      debugPrint("[Apple Membership Screen] standard: $_std");
      debugPrint("[Apple Membership Screen] medium: $_medium");
      debugPrint("[Apple Membership Screen] stream: $_stream");
      debugPrint(
        "[Apple Membership Screen] amount: ${result.amountPaid ?? _finalAmount}",
      );
      if (!active ||
          productId == null ||
          productId.isEmpty ||
          transactionId == null ||
          transactionId.isEmpty ||
          _std == null ||
          _medium == null) {
        CustomLoader.hide(context);
        debugPrint(
          "[Apple Membership Screen] Missing verification details: "
          "entitlementActive=$active, "
          "productIdMissing=${productId == null || productId.isEmpty}, "
          "transactionIdMissing=${transactionId == null || transactionId.isEmpty}, "
          "standardMissing=${_std == null}, "
          "mediumMissing=${_medium == null}",
        );
        await _showApplePurchaseDialog(
          "Purchase Failed",
          "Apple purchase finished, but active subscription access was not found. Please restore purchases or try again.",
        );
        return;
      }

      if (expectedProductId != null && productId != expectedProductId) {
        CustomLoader.hide(context);
        debugPrint(
          "[Apple Membership Screen] Product mismatch: "
          "expected=$expectedProductId actual=$productId",
        );
        await _showApplePurchaseDialog(
          "Purchase Failed",
          "Apple returned a different product ($productId) than the selected plan ($expectedProductId). Please try again or restore the correct subscription.",
        );
        return;
      }

      final refreshedReceipt = await RevenueCatService.instance
          .getAppleReceiptAfterPurchase();
      if (!mounted) return;

      final receipt =
          (refreshedReceipt != null &&
              refreshedReceipt.length > (result.receipt?.length ?? 0))
          ? refreshedReceipt
          : result.receipt;

      if (receipt == null || receipt.isEmpty) {
        CustomLoader.hide(context);
        debugPrint("[Apple Membership Screen] Missing Apple receipt");
        await _showApplePurchaseDialog(
          "Verification Failed",
          "Apple purchase completed, but the receipt was not available. Please try restore purchases.",
        );
        return;
      }

      final response = await ApiService.verifyAppleMembership(
        receipt: receipt,
        productId: productId,
        expectedProductId: expectedProductId,
        transactionId: transactionId,
        standard: _std!,
        medium: _medium!,
        stream: _stream,
        amount: result.amountPaid ?? _finalAmount,
      );
      if (!mounted) return;

      if (response.statusCode != 200 && response.statusCode != 201) {
        CustomLoader.hide(context);
        await _showApplePurchaseDialog(
          "Verification Failed",
          ApiService.getErrorMessage(response.body),
        );
        return;
      }

      if (widget.payload == null && _hasValidatedReferralCode) {
        await _applyReferralAfterPurchase();
        if (!mounted) return;
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool("apple_membership_verified", true);
      await prefs.setString("apple_membership_standard", _std!);
      await prefs.remove("skipped_payment_prompt");
      if (!mounted) return;
      CustomLoader.hide(context);
      await _showApplePurchaseDialog(
        "Purchase Successful",
        "Your subscription is active.",
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      CustomLoader.hide(context);
      await _showApplePurchaseDialog(
        "Purchase Failed",
        "We could not activate your subscription. Please try again.",
      );
    }
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

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    CustomToast.showSuccess(
      context,
      "Payment Successful: ${response.paymentId}",
    );
    _processRegistration(
      paymentId: response.paymentId,
      orderId: response.orderId,
      signature: response.signature,
    );
  }

  Future<void> _processRegistration({
    String? paymentId,
    String? orderId,
    String? signature,
  }) async {
    // Get referral code if provided and valid
    final referralCode = _referralCodeController.text.trim();
    final shouldIncludeReferral = _hasValidatedReferralCode;
    // Redeem codes and referral codes are mutually exclusive in this flow;
    // the backend's registerUser accepts either through the same field.
    final hasValidRedeemCode = _hasValidRedeemCodeForSelectedStandard();

    // Proceed to Registration
    try {
      CustomLoader.show(context);

      final currentPayload =
          widget.payload ??
          RegistrationPayload(
            role: 'student',
            fields: {
              "firstName":
                  (await SharedPreferences.getInstance()).getString(
                    'firstName',
                  ) ??
                  "",
              "email": _email ?? "",
              "phoneNum": _phoneNum ?? "",
              "parentPhone":
                  (await SharedPreferences.getInstance()).getString(
                    'parentPhone',
                  ) ??
                  "",
              "std": _std ?? "",
              "medium": _medium ?? "",
              "stream":
                  (await SharedPreferences.getInstance()).getString('stream') ??
                  "",
              "board":
                  (await SharedPreferences.getInstance()).getString('board') ??
                  "",
              "loginAs":
                  (await SharedPreferences.getInstance()).getString(
                    'user_role',
                  ) ??
                  "student",
            },
            files: [],
          );

      final response = await ApiService.registerUser(
        payload: currentPayload,
        dpin: _cachedPassword ?? "",
        referralCode: shouldIncludeReferral
            ? referralCode
            : (hasValidRedeemCode ? _validatedRedeemCode : null),
        razorpayPaymentId: paymentId,
        razorpayOrderId: orderId,
        razorpaySignature: signature,
        amount: _finalAmount,
      );

      if (!mounted) return;
      CustomLoader.hide(context);

      if (response.statusCode == 201 || response.statusCode == 200) {
        if (widget.payload == null && _hasValidatedReferralCode) {
          await _applyReferralAfterPurchase();
          if (!mounted) return;
        }
        CustomToast.showSuccess(context, "Membership Activated Successfully!");
        // If from landing, pop. If from registration, push login.
        if (widget.payload != null) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
        } else {
          Navigator.pop(context, true); // Return success to Landing
        }
      } else {
        CustomToast.showError(
          context,
          "Registration Failed: ${ApiService.getErrorMessage(response.body)}",
        );
      }
    } catch (e) {
      if (mounted) {
        CustomLoader.hide(context);
        CustomToast.showError(context, "Error: $e");
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return Scaffold(body: CustomLoader());

    if (_originalAmount == 0) {
      return Scaffold(
        appBar: AppBar(title: const Text("Error")),
        body: const Center(child: Text("Invalid Class/Standard selected")),
      );
    }

    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Upgrade Membership",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('skipped_payment_prompt', true);
              if (context.mounted) Navigator.pop(context);
            },
            child: Text(
              "Skip",
              style: GoogleFonts.poppins(
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Plan Details Card
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
                                  "Standard $_std",
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.onPrimary.withOpacity(
                                      0.8,
                                    ),
                                  ),
                                ),
                                Text(
                                  "$_medium Medium",
                                  style: GoogleFonts.poppins(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onPrimary,
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
                        Divider(color: Colors.white24, thickness: 1),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Total Payable",
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
                  const SizedBox(height: 24),

                  // Membership Benefits
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      "Membership Benefits",
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _buildBenefitChip(
                        context,
                        Icons.videogame_asset_rounded,
                        "Mind Games",
                        Colors.orange,
                      ),
                      _buildBenefitChip(
                        context,
                        Icons.assignment_rounded,
                        "Unlimted Exams",
                        Colors.blue,
                      ),
                      _buildBenefitChip(
                        context,
                        Icons.timer_rounded,
                        "5 Min Test",
                        Colors.red,
                      ),
                      _buildBenefitChip(
                        context,
                        Icons.notes_rounded,
                        "One Liners",
                        Colors.purple,
                      ),
                      _buildBenefitChip(
                        context,
                        Icons.description_rounded,
                        "School Paper",
                        Colors.green,
                      ),
                      _buildBenefitChip(
                        context,
                        Icons.image_rounded,
                        "Image Material",
                        Colors.teal,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  Text(
                    "Have a Redeem Code?",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildCodeField(
                    colorScheme: colorScheme,
                    controller: _promoCodeController,
                    hintText: "Enter Redeem Code (Optional)",
                    showValidIcon: _isRedeemValid == true,
                    showErrorIcon: _isRedeemValid == false,
                    onChanged: (_) => _resetRedeemValidation(),
                    actionLabel: "Validate",
                    onActionPressed: _validateRedeemCode,
                  ),
                  if (_redeemMessage.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildCodeMessage(_redeemMessage, _isRedeemValid == true),
                  ],

                  const SizedBox(height: 24),

                  Text(
                    "Have a Referral Code?",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildCodeField(
                    colorScheme: colorScheme,
                    controller: _referralCodeController,
                    hintText: "Enter Referral Code (Optional)",
                    showValidIcon: _isReferralValid == true,
                    showErrorIcon: _isReferralValid == false,
                    showLoadingIcon: _isValidatingReferral,
                    onChanged: (_) => _resetReferralValidation(),
                    actionLabel: "Validate",
                    onActionPressed: _isValidatingReferral
                        ? null
                        : _validateReferralCode,
                  ),
                  if (_referralMessage.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildCodeMessage(
                      _referralMessage,
                      _isReferralValid == true,
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Terms
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
                      onPressed: _initiatePayment,
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
                            _isIOS
                                ? "Subscribe ₹${_finalAmount.toStringAsFixed(0)}"
                                : "Pay ₹${_finalAmount.toStringAsFixed(0)}",
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            _isIOS ? Icons.apple : Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeField({
    required ColorScheme colorScheme,
    required TextEditingController controller,
    required String hintText,
    required bool showValidIcon,
    required bool showErrorIcon,
    required ValueChanged<String> onChanged,
    required String actionLabel,
    required VoidCallback? onActionPressed,
    bool showLoadingIcon = false,
  }) {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: showValidIcon
                    ? Colors.green
                    : showErrorIcon
                    ? Colors.red
                    : colorScheme.outlineVariant.withOpacity(0.5),
              ),
            ),
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: GoogleFonts.poppins(
                  color: colorScheme.onSurfaceVariant,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                suffixIcon: showLoadingIcon
                    ? Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: SizedBox(
                          width: 20,
                          height: 20,
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
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: onActionPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.inverseSurface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
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
    );
  }

  Widget _buildCodeMessage(String message, bool isValid) {
    return Text(
      message,
      style: GoogleFonts.poppins(
        fontSize: 12,
        color: isValid ? Colors.green : Colors.red,
        fontWeight: FontWeight.w500,
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 10),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }
}
