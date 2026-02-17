import 'dart:convert';
import 'package:dm_bhatt_tutions/network/api_service.dart';
import 'package:dm_bhatt_tutions/screen/authentication/login_screen.dart';
import 'package:dm_bhatt_tutions/utils/custom_toast.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_loader.dart';
import 'package:dm_bhatt_tutions/model/registration_payload.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';

class PaymentScreen extends StatefulWidget {
  final RegistrationPayload payload;
  final String password; // needed for api call

  const PaymentScreen({super.key, required this.payload, required this.password});

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
  
  // Referral code validation states
  bool _isValidatingReferral = false;
  bool? _isReferralValid;
  String _referralMessage = '';
  
  String get _std => widget.payload.fields['std'].toString();
  String get _medium => widget.payload.fields['medium'].toString();

  @override
  void initState() {
    super.initState();
    _calculateInitialAmount();
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
      });
      return;
    }

    setState(() {
      _isValidatingReferral = true;
      _isReferralValid = null;
      _referralMessage = '';
    });

    try {
      final response = await ApiService.validateReferralCode(code);
      final data = jsonDecode(response.body);

      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() {
          _isReferralValid = true;
          _referralMessage = data['message'] ?? 'Valid referral code';
          _referralDiscount = (data['discountAmount'] ?? 0).toDouble();
          _calculateFinalAmount();
        });
        CustomToast.showSuccess(context, _referralMessage);
      } else {
        setState(() {
          _isReferralValid = false;
          _referralMessage = data['message'] ?? 'Invalid referral code';
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

  Future<void> _processPaymentAndRegister() async {
    // Get referral code if provided and valid
    final referralCode = _referralCodeController.text.trim();
    final shouldIncludeReferral = referralCode.isNotEmpty && _isReferralValid == true;
    
    // Proceed to Registration
    try {
      CustomLoader.show(context);
      final response = await ApiService.registerUser(
        payload: widget.payload,
        dpin: widget.password,
        referralCode: shouldIncludeReferral ? referralCode : null,
      );
      
      if (!mounted) return;
      CustomLoader.hide(context);

      if (response.statusCode == 201 || response.statusCode == 200) {
         CustomToast.showSuccess(context, "Registration Successful");
         Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      } else {
         CustomToast.showError(context, "Registration Failed: ${response.body}");
      }
    } catch (e) {
       if (mounted) {
         CustomLoader.hide(context);
         CustomToast.showError(context, "Error: $e");
       }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_originalAmount == 0) {
       return Scaffold(
        appBar: AppBar(title: const Text("Error")),
        body: const Center(child: Text("Invalid Class/Standard selected")),
       );
    }

    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: CustomAppBar(
        title: "Payment",
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Plan Details Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Standard $_std ($_medium Medium)",
                    style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: colorScheme.primary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Membership Plan",
                    style: GoogleFonts.poppins(fontSize: 14, color: colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 16),
                  Divider(color: colorScheme.outlineVariant),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Amount", style: GoogleFonts.poppins(fontSize: 16, color: colorScheme.onSurface)),
                      Text("₹${_originalAmount.toStringAsFixed(0)}", 
                        style: GoogleFonts.poppins(
                          fontSize: 16, 
                          color: _isDiscountApplied ? colorScheme.onSurfaceVariant : colorScheme.onSurface,
                          decoration: _isDiscountApplied ? TextDecoration.lineThrough : null,
                        )
                      ),
                    ],
                  ),
                  if (_isDiscountApplied) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Discount (50%)", style: GoogleFonts.poppins(fontSize: 16, color: Colors.green)),
                        Text("-₹${_discount.toStringAsFixed(0)}", style: GoogleFonts.poppins(fontSize: 16, color: Colors.green, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                  if (_referralDiscount > 0) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Referral Discount", style: GoogleFonts.poppins(fontSize: 16, color: Colors.green)),
                        Text("-₹${_referralDiscount.toStringAsFixed(0)}", style: GoogleFonts.poppins(fontSize: 16, color: Colors.green, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  Divider(color: colorScheme.outlineVariant),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Total Payable", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
                      Text("₹${_finalAmount.toStringAsFixed(0)}", style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: colorScheme.primary)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Promo Code
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
                        if (_isReferralValid != null) {
                          setState(() {
                            _isReferralValid = null;
                            _referralMessage = '';
                          });
                        }
                      },
                      decoration: InputDecoration(
                        hintText: "Enter Referral Code (Optional)",
                        hintStyle: GoogleFonts.poppins(color: colorScheme.onSurfaceVariant),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                        suffixIcon: _isValidatingReferral
                          ? const Padding(
                              padding: EdgeInsets.all(12.0),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
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
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _processPaymentAndRegister,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  elevation: 4,
                  shadowColor: colorScheme.primary.withOpacity(0.4),
                ),
                child: Text(
                  "Pay ₹${_finalAmount.toStringAsFixed(0)} & Register",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
