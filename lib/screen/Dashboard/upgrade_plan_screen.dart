import 'package:dm_bhatt_tutions/utils/guest_utils.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:dm_bhatt_tutions/utils/custom_toast.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_loader.dart';
import 'package:dm_bhatt_tutions/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'dart:convert';
import 'package:dm_bhatt_tutions/network/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  final List<String> _standards = ["7", "8", "9", "10", "11", "12"];
  final List<String> _mediums = ["English", "Gujarati"];
  final List<String> _streams = ["Science", "Commerce"];

  double _originalAmount = 0;
  double _finalAmount = 0;
  double _promoDiscount = 0;
  double _pointsDiscount = 0;
  bool _isPromoApplied = false;
  
  // Simulated available points (In real app, fetch from user profile)
  int _availablePoints = 0; 
  
  String? _currentStandard;
  bool _isLoading = true;
  bool _isGuest = false;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
    _fetchBonusPoints();
  }

  Future<void> _fetchUserProfile() async {
    try {
      // Token managed internally
      final response = await ApiService.getProfile();

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final profile = data['profile'];
        
        if (profile != null) {
          _currentStandard = profile['std'];
        }
      }
    } catch (e) {
      if (mounted) {
         final l10n = AppLocalizations.of(context)!;
         CustomToast.showError(context, "${l10n.registrationFailed} $e");
      }
    } finally {
      if (mounted) {
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
    CustomToast.showSuccess(context, l10n.pointsAppliedAmount(discount.toStringAsFixed(0)));
  }

  Future<void> _processUpgrade() async {
    if (_isGuest) {
       GuestUtils.showGuestRestrictionDialog(
         context,
         message: "Guests cannot upgrade plans. Please register as a full student to access premium features."
       );
       return;
    }
    if (_selectedStandard == null || _selectedMedium == null) {
       final l10n = AppLocalizations.of(context)!;
       CustomToast.showError(context, l10n.selectStandardMediumError);
       return;
    }
    if ((_selectedStandard == "11" || _selectedStandard == "12") && _selectedStream == null) {
       final l10n = AppLocalizations.of(context)!;
       CustomToast.showError(context, l10n.selectStreamError);
       return;
    }

    try {
      CustomLoader.show(context);
      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));
      
      if (!mounted) return;
      CustomLoader.hide(context);

      final l10n = AppLocalizations.of(context)!;
      CustomToast.showSuccess(context, l10n.planUpgradeSuccess);
      Navigator.pop(context);
    } catch (e) {
       if (mounted) {
         CustomLoader.hide(context);
         CustomToast.showError(context, "Error: $e");
       }
    }
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
      ),
      body: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
            // Selection Card
            Container(
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
                children: [
                   _buildDropdown(
                    label: l10n.standard,
                    value: _selectedStandard,
                    items: _filteredStandards, // Use filtered list
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
                  const SizedBox(height: 16),
                  if (_selectedStandard == "11" || _selectedStandard == "12") ...[
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
                    const SizedBox(height: 16),
                  ],
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
             const SizedBox(height: 24),
            
            if (_selectedStandard != null) ...[
              // Amount Breakdown
              Container(
                padding: const EdgeInsets.all(20),
                 decoration: BoxDecoration(
                  color: colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
                ),
                child: Column(
                  children: [
                    _buildSummaryRow(l10n.baseAmount, "₹$_originalAmount", colorScheme),
                    if (_isPromoApplied)
                      _buildSummaryRow(l10n.promoDiscount, "-₹${_promoDiscount.toStringAsFixed(0)}", colorScheme, isDiscount: true),
                    if (_pointsDiscount > 0)
                      _buildSummaryRow(l10n.pointsDiscount, "-₹${_pointsDiscount.toStringAsFixed(0)}", colorScheme, isDiscount: true),
                    const Divider(),
                     _buildSummaryRow(l10n.totalPayable, "₹${_finalAmount.toStringAsFixed(0)}", colorScheme, isTotal: true),
                  ],
                ),
              ),
               const SizedBox(height: 24),

               // Promo Code Section
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
                          hintText: _selectedStandard != null 
                              ? l10n.promoHint(_selectedStandard!)
                              : l10n.promoHint("8"), // Dynamic Hint
                          hintStyle: GoogleFonts.poppins(color: colorScheme.onSurfaceVariant.withOpacity(0.5)),
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
                      backgroundColor: colorScheme.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                    ),
                    child: Text(l10n.apply, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Reward Points Section
               Text(l10n.useRewardPoints(_availablePoints), style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
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
                        controller: _rewardPointsController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: l10n.pointsHint,
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
                    onPressed: _applyRewardPoints,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                    ),
                    child: Text(l10n.use, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
               const SizedBox(height: 32),

              // Pay Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _processUpgrade,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    elevation: 4,
                    shadowColor: colorScheme.primary.withOpacity(0.4),
                  ),
                  child: Text(
                    l10n.payAndUpgrade(_finalAmount.toStringAsFixed(0)),
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
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
        Text(label, style: GoogleFonts.poppins(fontSize: 14, color: colorScheme.onSurfaceVariant)),
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
              hint: Text("${l10n.selectSubject} $label", style: GoogleFonts.poppins(color: colorScheme.onSurfaceVariant)), // Assuming selectSubject is "Select" or using l10n.selectStandard etc? Actually I added selectStandard key. Let's use a generic one if I have or specific.
              dropdownColor: colorScheme.surface, // Or any distinct surface
              items: items.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(item, style: GoogleFonts.poppins(color: colorScheme.onSurface)),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value, ColorScheme colorScheme, {bool isDiscount = false, bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.poppins(
            fontSize: isTotal ? 18 : 16, 
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isDiscount ? Colors.green : colorScheme.onSurface
          )),
          Text(value, style: GoogleFonts.poppins(
            fontSize: isTotal ? 20 : 16,
             fontWeight: isTotal ? FontWeight.bold : FontWeight.bold,
             color: isDiscount ? Colors.green : (isTotal ? colorScheme.primary : colorScheme.onSurface)
          )),
        ],
      ),
    );
  }
}


