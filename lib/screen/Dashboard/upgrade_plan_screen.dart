import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:dm_bhatt_tutions/utils/custom_toast.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_loader.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'dart:convert'; // Added for jsonDecode
import 'package:dm_bhatt_tutions/network/api_service.dart'; // Added for API
import 'package:shared_preferences/shared_preferences.dart'; // Added for Token

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
  final int _availablePoints = 6000; 

  bool _isLoading = true; // Added loading state
  DateTime? _registrationDate; // Added to store real date
  bool _isEligible = false; // Added to store eligibility status
  DateTime? _eligibleDate; // Added to store calculated eligible date

  @override
  void initState() {
    super.initState();
    _fetchUserRegistrationDate();
  }

  Future<void> _fetchUserRegistrationDate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        if (mounted) {
           CustomToast.showError(context, "Session expired. Please login again.");
           Navigator.pop(context);
        }
        return;
      }

      final response = await ApiService.getProfile(token);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final user = data['user'];
        
        // Assuming 'createdAt' is the field. Adjust if backend differs.
        final String? createdAtStr = user['createdAt']; 
        
        if (createdAtStr != null) {
          _registrationDate = DateTime.parse(createdAtStr);
        } else {
           // Fallback if date is missing (e.g. old users)
           _registrationDate = DateTime.now(); 
        }

        _calculateEligibility();

      } else {
        if (mounted) {
           CustomToast.showError(context, "Failed to load profile. Please try again.");
           Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
         CustomToast.showError(context, "Error fetching data: $e");
         Navigator.pop(context);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _calculateEligibility() {
     if (_registrationDate == null) return;

     // Logic: Eligible after 1st March of the NEXT year
     // Example: Registered Sept 2025 -> Eligible March 1st, 2026.
     _eligibleDate = DateTime(_registrationDate!.year + 1, 3, 1);
     final DateTime now = DateTime.now();

     setState(() {
       _isEligible = now.isAfter(_eligibleDate!);
     });
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
      CustomToast.showError(context, "Please select standard first");
      return;
    }
    final code = _promoCodeController.text.trim().toUpperCase();
    final expectedCode = "DMBHATT$_selectedStandard";

    if (code == expectedCode) {
      setState(() {
        _isPromoApplied = true;
      });
      _recalculateFinal();
      CustomToast.showSuccess(context, "Promo code applied successfully!");
    } else {
      setState(() {
        _isPromoApplied = false;
      });
      _recalculateFinal();
      if (code.isNotEmpty) {
        CustomToast.showError(context, "Invalid promo code");
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
      CustomToast.showError(context, "You only have $_availablePoints points");
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
       CustomToast.showSuccess(context, "Points adjusted to max payable amount");
    }

    double discount = points / 50.0;
    
    setState(() {
      _pointsDiscount = discount;
    });
    _recalculateFinal();
    CustomToast.showSuccess(context, "Points applied: ₹${discount.toStringAsFixed(0)} off");
  }

  Future<void> _processUpgrade() async {
    if (_selectedStandard == null || _selectedMedium == null) {
       CustomToast.showError(context, "Please select Standard and Medium");
       return;
    }
    if ((_selectedStandard == "11" || _selectedStandard == "12") && _selectedStream == null) {
       CustomToast.showError(context, "Please select Stream");
       return;
    }

    try {
      CustomLoader.show(context);
      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));
      
      if (!mounted) return;
      CustomLoader.hide(context);

      CustomToast.showSuccess(context, "Plan Upgraded Successfully!");
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
    final colorScheme = Theme.of(context).colorScheme;
    
    if (_isLoading) {
       return Scaffold(
         backgroundColor: colorScheme.surface,
         appBar: CustomAppBar(title: "Upgrade Plan", centerTitle: true),
         body: const Center(child: CustomLoader()),
       );
    }
    
    // Safety check just in case valid date wasn't found
    if (_eligibleDate == null) {
       return Scaffold(
         body: Center(child: Text("Unable to verify eligibility.", style: GoogleFonts.poppins())),
       );
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: CustomAppBar(
        title: "Upgrade Plan",
        centerTitle: true,
      ),
      body: !_isEligible 
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_clock, size: 80, color: colorScheme.secondary),
                    const SizedBox(height: 24),
                    Text(
                      "Upgrade Not Available Yet",
                      style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "You can upgrade your plan after ${_formatDate(_eligibleDate!)}.",
                      style: GoogleFonts.poppins(fontSize: 16, color: colorScheme.onSurfaceVariant),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                     ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      ),
                      child: Text("Go Back", style: GoogleFonts.poppins(color: colorScheme.onPrimary, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            )
          : SingleChildScrollView(
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
                    label: "Standard",
                    value: _selectedStandard,
                    items: _standards,
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
                      label: "Stream",
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
                    label: "Medium",
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
                    _buildSummaryRow("Base Amount", "₹$_originalAmount", colorScheme),
                    if (_isPromoApplied)
                      _buildSummaryRow("Promo Discount (50%)", "-₹${_promoDiscount.toStringAsFixed(0)}", colorScheme, isDiscount: true),
                    if (_pointsDiscount > 0)
                      _buildSummaryRow("Points Discount", "-₹${_pointsDiscount.toStringAsFixed(0)}", colorScheme, isDiscount: true),
                    const Divider(),
                     _buildSummaryRow("Total Payable", "₹${_finalAmount.toStringAsFixed(0)}", colorScheme, isTotal: true),
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
                          hintText: "Enter Code",
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

              // Reward Points Section
               Text("Use Reward Points (Available: $_availablePoints)", style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
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
                          hintText: "Enter points to use",
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
                      backgroundColor: colorScheme.inverseSurface,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                    ),
                    child: Text("Use", style: GoogleFonts.poppins(color: colorScheme.onInverseSurface, fontWeight: FontWeight.bold)),
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
                    "Pay ₹${_finalAmount.toStringAsFixed(0)} & Upgrade",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimary,
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
              hint: Text("Select $label", style: GoogleFonts.poppins(color: colorScheme.onSurfaceVariant)),
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

  String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }
}
