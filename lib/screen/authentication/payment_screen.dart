import 'dart:convert';
import 'dart:io';
import 'package:dm_bhatt_tutions/network/api_service.dart';
import 'package:dm_bhatt_tutions/screen/authentication/login_screen.dart';
import 'package:dm_bhatt_tutions/utils/custom_toast.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_loader.dart';
import 'package:dm_bhatt_tutions/model/registration_payload.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'package:dm_bhatt_tutions/utils/razorpay_helper.dart';
import 'package:dm_bhatt_tutions/utils/iap_service.dart';
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
  double _referralDiscount = 0;
  bool _isDiscountApplied = false;
  
  // Platform-specific payment helpers
  RazorpayHelper? _razorpayHelper;
  final IAPService _iapService = IAPService();
  
  // Referral code validation states
  bool _isValidatingReferral = false;
  bool? _isReferralValid;
  String _referralMessage = '';
  
  String? _std;
  String? _medium;
  String? _phoneNum;
  String? _email;
  String? _cachedPassword;
  bool _isLoading = true;

  bool get _isIOS => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  @override
  void initState() {
    super.initState();
    _initData();

    if (_isIOS) {
      // iOS: Use Apple In-App Purchase
      _iapService.initialize();
      _iapService.onPurchaseSuccess = _handleApplePurchaseSuccess;
      _iapService.onPurchaseError = (error) {
        if (mounted) {
          CustomToast.showError(context, "Purchase Failed: $error");
        }
      };
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
      _phoneNum = prefs.getString('user_phone');
      _email = prefs.getString('user_email');
      _cachedPassword = prefs.getString('user_password');
    }

    // Always ensure _cachedPassword is loaded if not already provided
    if (_cachedPassword == null) {
      final prefs = await SharedPreferences.getInstance();
      _cachedPassword = prefs.getString('user_password');
    }
    
    if (_std != null) {
      _calculateInitialAmount();
    }
    
    setState(() {
      _isLoading = false;
    });
  }
  
  @override
  void dispose() {
    _razorpayHelper?.dispose();
    super.dispose();
  }

  void _handlePaymentFailure(PaymentFailureResponse response) {
    CustomToast.showError(context, "Payment Cancelled");
  }

  void _calculateInitialAmount() {
    // Base amounts from the excel requirement
    switch (_std) {
      case "6":
        _originalAmount = 300;
        break;
      case "7":
        _originalAmount = 400;
        break;
      case "8":
        _originalAmount = 500;
        break;
      case "9":
        _originalAmount = 600;
        break;
      case "10":
        _originalAmount = 700;
        break;
      case "11":
        _originalAmount = 800;
        break;
      case "12":
        _originalAmount = 900;
        break;
      default:
        _originalAmount = 0;
    }
    _calculateFinalAmount();
  }

  void _calculateFinalAmount() {
    _finalAmount = _originalAmount - _discount - _referralDiscount;
    if (_finalAmount < 0) _finalAmount = 0;
  }

  void _applyPromoCode() {
    final code = _promoCodeController.text.trim().toUpperCase();
    final expectedCode = "DMBHATT$_std";

    if (code == expectedCode) {
      setState(() {
        _isDiscountApplied = true;
        _discount = _originalAmount * 0.50; // 50% discount
        _calculateFinalAmount();
      });
      CustomToast.showSuccess(context, "Promo code applied successfully!");
    } else {
      setState(() {
        _isDiscountApplied = false;
        _discount = 0;
        _calculateFinalAmount();
      });
      if (code.isNotEmpty) {
        CustomToast.showError(context, "Invalid promo code");
      }
    }
  }

  Future<void> _validateReferralCode() async {
    final code = _referralCodeController.text.trim();
    
    if (code.isEmpty) {
      setState(() {
        _isReferralValid = null;
        _referralMessage = '';
        _referralDiscount = 0; // Reset discount if empty
        _calculateFinalAmount();
      });
      return;
    }

    setState(() {
      _isValidatingReferral = true;
      _isReferralValid = null;
      _referralMessage = '';
    });

    try {
      // 1. Try student referral check first
      final refResponse = await ApiService.validateReferralCode(code);
      
      if (!mounted) return;

      if (refResponse.statusCode == 200) {
        final refData = jsonDecode(refResponse.body);
        setState(() {
          _isReferralValid = true;
          final double discountAmount = (refData['discountAmount'] as num).toDouble();
          _referralMessage = refData['message'] ?? "Referral applied!";
          _referralDiscount = discountAmount;
          _calculateFinalAmount();
        });
        CustomToast.showSuccess(context, _referralMessage);
        return;
      }

      // 2. Fallback to admin-generated redeem code check
      final response = await ApiService.validateRedeemCode(
        code,
        targetStd: _std,
        targetMedium: _medium,
      );
      final data = jsonDecode(response.body);

      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() {
          _isReferralValid = true;
          final double discountPercent = (data['discount'] as num).toDouble();
          _referralMessage = "Applied! ${data['message'] ?? '$discountPercent% discount'}";
          _referralDiscount = _originalAmount * (discountPercent / 100);
          _calculateFinalAmount();
        });
        CustomToast.showSuccess(context, _referralMessage);
      } else {
        setState(() {
          _isReferralValid = false;
          _referralMessage = ApiService.getErrorMessage(response.body);
          _referralDiscount = 0;
          _calculateFinalAmount();
        });
        CustomToast.showError(context, _referralMessage);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isReferralValid = false;
          _referralMessage = 'Error validating referral code';
          _referralDiscount = 0;
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

  Future<void> _initiatePayment() async {
    if (_finalAmount <= 0) {
      // If amount is 0 (e.g. 100% discount), skip payment
      _processRegistration(paymentId: "FREE_PLAN");
      return;
    }

    if (_isIOS) {
      // iOS: Use Apple In-App Purchase
      _iapService.setPurchaseContext('registration', metadata: {
        'std': _std,
        'medium': _medium,
      });
      await _iapService.purchaseMembership(_std ?? "6");
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
            name: "Our Learning Platform",
            description: "Standard $_std Membership",
            contact: _phoneNum ?? '',
            email: _email ?? '',
            orderId: orderId,
          );
        } else {
           CustomToast.showError(context, "Failed to create order: ${ApiService.getErrorMessage(orderResponse.body)}");
        }
      } catch (e) {
         if (mounted) {
           CustomLoader.hide(context);
           CustomToast.showError(context, "Error initiating payment: $e");
         }
      }
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    CustomToast.showSuccess(context, "Payment Successful: ${response.paymentId}");
    _processRegistration(
      paymentId: response.paymentId,
      orderId: response.orderId,
      signature: response.signature,
    );
  }

  void _handleApplePurchaseSuccess(PurchaseDetails purchaseDetails) {
    if (!mounted) return;
    CustomToast.showSuccess(context, "Apple Purchase Successful!");
    _processRegistrationWithApple(purchaseDetails);
  }

  /// Process registration with Apple IAP receipt
  Future<void> _processRegistrationWithApple(PurchaseDetails purchaseDetails) async {
    final referralCode = _referralCodeController.text.trim();
    final shouldIncludeReferral = referralCode.isNotEmpty && _isReferralValid == true;

    try {
      CustomLoader.show(context);

      final currentPayload = widget.payload ?? RegistrationPayload(
        role: 'student',
        fields: {
          "firstName": (await SharedPreferences.getInstance()).getString('firstName') ?? "",
          "email": _email ?? "",
          "phoneNum": _phoneNum ?? "",
          "parentPhone": (await SharedPreferences.getInstance()).getString('parentPhone') ?? "",
          "std": _std ?? "",
          "medium": _medium ?? "",
          "stream": (await SharedPreferences.getInstance()).getString('stream') ?? "",
          "board": (await SharedPreferences.getInstance()).getString('board') ?? "",
          "loginAs": (await SharedPreferences.getInstance()).getString('user_role') ?? "student",
        },
        files: [],
      );

      final response = await ApiService.registerUserWithApple(
        payload: currentPayload,
        dpin: _cachedPassword ?? "",
        referralCode: shouldIncludeReferral ? referralCode : null,
        appleReceipt: purchaseDetails.verificationData.serverVerificationData,
        appleProductId: purchaseDetails.productID,
        appleTransactionId: purchaseDetails.purchaseID ?? "",
        amount: _finalAmount,
      );

      if (!mounted) return;
      CustomLoader.hide(context);

      if (response.statusCode == 201 || response.statusCode == 200) {
        CustomToast.showSuccess(context, "Membership Activated Successfully!");
        if (widget.payload != null) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
        } else {
          Navigator.pop(context, true);
        }
      } else {
        CustomToast.showError(context, "Registration Failed: ${ApiService.getErrorMessage(response.body)}");
      }
    } catch (e) {
      if (mounted) {
        CustomLoader.hide(context);
        CustomToast.showError(context, "Error: $e");
      }
    }
  }

  Future<void> _processRegistration({
    String? paymentId,
    String? orderId,
    String? signature,
  }) async {
    // Get referral code if provided and valid
    final referralCode = _referralCodeController.text.trim();
    final shouldIncludeReferral = referralCode.isNotEmpty && _isReferralValid == true;
    
    // Proceed to Registration
    try {
      CustomLoader.show(context);
      
      final currentPayload = widget.payload ?? RegistrationPayload(
        role: 'student',
        fields: {
          "firstName": (await SharedPreferences.getInstance()).getString('firstName') ?? "",
          "email": _email ?? "",
          "phoneNum": _phoneNum ?? "",
          "parentPhone": (await SharedPreferences.getInstance()).getString('parentPhone') ?? "",
          "std": _std ?? "",
          "medium": _medium ?? "",
          "stream": (await SharedPreferences.getInstance()).getString('stream') ?? "",
          "board": (await SharedPreferences.getInstance()).getString('board') ?? "",
          "loginAs": (await SharedPreferences.getInstance()).getString('user_role') ?? "student",
        },
        files: [],
      );

      final response = await ApiService.registerUser(
        payload: currentPayload,
        dpin: _cachedPassword ?? "",
        referralCode: shouldIncludeReferral ? referralCode : null,
        razorpayPaymentId: paymentId,
        razorpayOrderId: orderId,
        razorpaySignature: signature,
        amount: _finalAmount,
      );
      
      if (!mounted) return;
      CustomLoader.hide(context);

      if (response.statusCode == 201 || response.statusCode == 200) {
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
         CustomToast.showError(context, "Registration Failed: ${ApiService.getErrorMessage(response.body)}");
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
                                      color: colorScheme.onPrimary.withOpacity(0.8),
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
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                        _buildBenefitChip(context, Icons.videogame_asset_rounded, "Mind Games", Colors.orange),
                        _buildBenefitChip(context, Icons.assignment_rounded, "Unlimted Exams", Colors.blue),
                        _buildBenefitChip(context, Icons.timer_rounded, "5 Min Test", Colors.red),
                        _buildBenefitChip(context, Icons.notes_rounded, "One Liners", Colors.purple),
                        _buildBenefitChip(context, Icons.description_rounded, "School Paper", Colors.green),
                        _buildBenefitChip(context, Icons.image_rounded, "Image Material", Colors.teal),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Promo Code (hide on iOS since Apple doesn't allow external discounts on IAP)
                    if (!_isIOS) ...[
                      Text("Have a Redeem Code?", style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainer,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
                              ),
                              child: TextField(
                                controller: _promoCodeController,
                                onChanged: (value) {
                                  if (_isDiscountApplied) {
                                    setState(() {
                                      _isDiscountApplied = false;
                                      _discount = 0;
                                      _calculateFinalAmount();
                                    });
                                  }
                                },
                                decoration: InputDecoration(
                                  hintText: "Enter Code (e.g. DMBHATT7)",
                                  hintStyle: GoogleFonts.poppins(color: colorScheme.onSurfaceVariant),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                                ),
                                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, letterSpacing: 1.0, color: colorScheme.onSurface),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: _applyPromoCode,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.inverseSurface,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                            ),
                            child: Text("Apply", style: GoogleFonts.poppins(color: colorScheme.onInverseSurface, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 24),

                      // Referral Code
                      Text("Have a Referral Code?", style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainer,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _isReferralValid == true 
                                    ? Colors.green 
                                    : _isReferralValid == false 
                                      ? Colors.red 
                                      : colorScheme.outlineVariant.withOpacity(0.5)
                                ),
                              ),
                              child: TextField(
                                controller: _referralCodeController,
                                onChanged: (value) {
                                  // Reset validation state when user types
                                  if (_isReferralValid != null || _referralDiscount > 0) {
                                    setState(() {
                                      _isReferralValid = null;
                                      _referralMessage = '';
                                      _referralDiscount = 0;
                                      _calculateFinalAmount();
                                    });
                                  }
                                },
                                decoration: InputDecoration(
                                  hintText: "Enter Referral Code (Optional)",
                                  hintStyle: GoogleFonts.poppins(color: colorScheme.onSurfaceVariant),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                                  suffixIcon: _isValidatingReferral
                                    ? Padding(
                                        padding: EdgeInsets.all(12.0),
                                        child: SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                                          ),
                                        ),
                                      )
                                    : _isReferralValid == true
                                      ? const Icon(Icons.check_circle, color: Colors.green)
                                      : _isReferralValid == false
                                        ? const Icon(Icons.error, color: Colors.red)
                                        : null,
                                ),
                                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, letterSpacing: 1.0, color: colorScheme.onSurface),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: _isValidatingReferral ? null : _validateReferralCode,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.inverseSurface,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                            ),
                            child: Text("Validate", style: GoogleFonts.poppins(color: colorScheme.onInverseSurface, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      if (_referralMessage.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          _referralMessage,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: _isReferralValid == true ? Colors.green : Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
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
                          const Icon(Icons.info_outline, color: Colors.orange, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "This membership will be expired after 1 year.",
                              style: GoogleFonts.poppins(fontSize: 12, color: Colors.orange.shade800),
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
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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

  Widget _buildBenefitChip(BuildContext context, IconData icon, String text, Color color) {
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
