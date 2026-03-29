import 'dart:io';
import 'package:dm_bhatt_tutions/utils/guest_utils.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:dm_bhatt_tutions/utils/custom_toast.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_loader.dart';
import 'package:dm_bhatt_tutions/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'dart:convert';
import 'package:dm_bhatt_tutions/network/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dm_bhatt_tutions/utils/razorpay_helper.dart';
import 'package:dm_bhatt_tutions/utils/iap_service.dart';
import 'package:intl/intl.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/upgrade_receipt_screen.dart';

class UpgradePlanScreen extends StatefulWidget {
  const UpgradePlanScreen({super.key});

  @override
  State<UpgradePlanScreen> createState() => _UpgradePlanScreenState();
}

class _UpgradePlanScreenState extends State<UpgradePlanScreen> {
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
  double _pointsDiscount = 0;
  bool _isPromoApplied = false;

  // Simulated available points
  int _availablePoints = 0;

  String? _currentStandard;
  bool _isLoading = true;
  bool _isGuest = false;
  bool _isPaid = true;

  RazorpayHelper? _razorpayHelper;
  final IAPService _iapService = IAPService();

  bool get _isIOS => Platform.isIOS;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
    _fetchBonusPoints();

    if (_isIOS) {
      _iapService.initialize();
      _iapService.onPurchaseSuccess = _handleApplePurchaseSuccess;
      _iapService.onPurchaseError = (error) {
        if (mounted) {
          CustomToast.showError(context, "Purchase Failed: $error");
        }
      };
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
          setState(() {
            _currentStandard = profile['std']?.toString();
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

  Future<void> _fetchBonusPoints() async {
    try {
      // Token managed internally
      final response = await ApiService.getReferralData();
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _availablePoints = data['bonusPoints'] ?? 0;
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching points: $e");
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
      return;
    }

    switch (_selectedStandard) {
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

    _recalculateFinal();
  }

  void _recalculateFinal() {
    setState(() {
      _finalAmount = _originalAmount;
      if (_isPromoApplied) {
        // Promo is 50% discount logic as per previous task
        _promoDiscount = _originalAmount * 0.50;
        _finalAmount -= _promoDiscount;
      } else {
        _promoDiscount = 0;
      }

      _finalAmount -= _pointsDiscount;

      if (_finalAmount < 0) _finalAmount = 0;
    });
  }

  void _applyPromoCode() {
    if (_selectedStandard == null) {
      final l10n = AppLocalizations.of(context)!;
      CustomToast.showError(context, l10n.selectStandardFirst);
      return;
    }
    final code = _promoCodeController.text.trim().toUpperCase();
    final expectedCode = "DMBHATT$_selectedStandard";

    if (code == expectedCode) {
      setState(() {
        _isPromoApplied = true;
      });
      _recalculateFinal();
      final l10n = AppLocalizations.of(context)!;
      CustomToast.showSuccess(context, l10n.promoAppliedSuccess);
    } else {
      setState(() {
        _isPromoApplied = false;
      });
      _recalculateFinal();
      if (code.isNotEmpty) {
        final l10n = AppLocalizations.of(context)!;
        CustomToast.showError(context, l10n.invalidPromoCode);
      }
    }
  }

  void _applyRewardPoints() {
    if (_rewardPointsController.text.isEmpty) {
      setState(() {
        _pointsDiscount = 0;
      });
      _recalculateFinal();
      return;
    }

    int points = int.tryParse(_rewardPointsController.text) ?? 0;

    // Check against available points
    if (points > _availablePoints) {
      final l10n = AppLocalizations.of(context)!;
      CustomToast.showError(context, l10n.insufficientPoints(_availablePoints));
      // Clamp to available
      points = _availablePoints;
      _rewardPointsController.text = points.toString();
    }

    // Calculate current payable before points
    double currentPayable = _originalAmount;
    if (_isPromoApplied) {
      currentPayable -= (_originalAmount * 0.50);
    }

    // Max points usable = payable * 50
    int maxUsablePoints = (currentPayable * 50).ceil();

    if (points > maxUsablePoints) {
      points = maxUsablePoints;
      _rewardPointsController.text = points.toString();
      final l10n = AppLocalizations.of(context)!;
      CustomToast.showSuccess(context, l10n.pointsAdjusted);
    }

    double discount = points / 50.0;

    setState(() {
      _pointsDiscount = discount;
    });
    _recalculateFinal();
    final l10n = AppLocalizations.of(context)!;
    CustomToast.showSuccess(
      context,
      l10n.pointsAppliedAmount(discount.toStringAsFixed(0)),
    );
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
    if ((_selectedStandard == "11" || _selectedStandard == "12") &&
        _selectedStream == null) {
      final l10n = AppLocalizations.of(context)!;
      CustomToast.showError(context, l10n.selectStreamError);
      return;
    }

    if (_isIOS) {
      // iOS: Use Apple In-App Purchase
      _iapService.setPurchaseContext('upgrade', metadata: {
        'newStandard': _selectedStandard!,
        'medium': _selectedMedium!,
        'stream': _selectedStream,
        'amount': _finalAmount,
      });
      await _iapService.purchaseMembership(_selectedStandard!);
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
            name: "Standard Upgrade",
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

  void _handleApplePurchaseSuccess(PurchaseDetails purchaseDetails) async {
    if (!mounted) return;
    try {
      CustomLoader.show(context);
      final metadata = _iapService.purchaseMetadata;
      final response = await ApiService.verifyAppleUpgrade(
        receipt: purchaseDetails.verificationData.serverVerificationData,
        productId: purchaseDetails.productID,
        transactionId: purchaseDetails.purchaseID ?? "",
        newStandard: metadata['newStandard'] ?? _selectedStandard!,
        medium: metadata['medium'] ?? _selectedMedium!,
        stream: metadata['stream'],
        amount: (metadata['amount'] as num?)?.toDouble() ?? _finalAmount,
      );

      if (!mounted) return;
      CustomLoader.hide(context);

      if (response.statusCode == 200) {
        final l10n = AppLocalizations.of(context)!;
        CustomToast.showSuccess(context, l10n.planUpgradeSuccess);
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
              // Promo Code Section (hide on iOS)
              if (!_isIOS) ...[
                Text(
                  "Have a Redeem Code?",
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
                          controller: _promoCodeController,
                          decoration: InputDecoration(
                            hintText: _selectedStandard != null
                                ? l10n.promoHint(_selectedStandard!)
                                : "Enter Promo Code",
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
                      onPressed: _applyPromoCode,
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
                        l10n.apply,
                        style: GoogleFonts.poppins(
                          color: colorScheme.onInverseSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                // Reward Points Section
                Text(
                  l10n.useRewardPoints(_availablePoints),
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
