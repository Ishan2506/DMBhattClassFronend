import 'package:dm_bhatt_tutions/constant/app_images.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_loader.dart';
import 'package:dm_bhatt_tutions/network/api_service.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/landing_screen.dart';
import 'package:dm_bhatt_tutions/utils/app_sizes.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GuestSelectionScreen extends StatefulWidget {
  const GuestSelectionScreen({super.key});

  @override
  State<GuestSelectionScreen> createState() => _GuestSelectionScreenState();
}

class _GuestSelectionScreenState extends State<GuestSelectionScreen> {
  String? _selectedStandard;
  String? _selectedMedium;
  String? _selectedBoard;

  final List<String> _standards = ["6", "7", "8", "9", "10", "11", "12"];
  final List<String> _mediums = ["English", "Gujarati"];
  final List<String> _boards = ["GSEB", "CBSE"];

  Future<void> _handleContinue() async {
    if (_selectedStandard == null || _selectedMedium == null || _selectedBoard == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select all fields")),
      );
      return;
    }

    CustomLoader.show(context);
    final prefs = await SharedPreferences.getInstance();
    
    await ApiService.setGuestMode(true);
    await prefs.setBool('is_guest_mode', true);
    await prefs.setString('std', _selectedStandard!);
    await prefs.setString('medium', _selectedMedium!);
    await prefs.setString('board', _selectedBoard!);
    await prefs.setString('stream', 'None');
    
    // Also set guest display name if needed
    await prefs.setString('user_name', 'Guest User');

    if (!mounted) return;
    CustomLoader.hide(context);

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LandingScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Welcome Guest", style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Image.asset(
                imgDmBhattClassesLogo,
                height: 100,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              "Personalize your experience",
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade900,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              "Select your education details to see relevant tests and materials.",
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),

            // Standard
            _buildSelectionGroup(
              title: "Select Standard",
              items: _standards,
              value: _selectedStandard,
              onSelected: (val) => setState(() => _selectedStandard = val),
              icon: Icons.school_outlined,
              colorScheme: colorScheme,
            ),
            const SizedBox(height: 24),

            // Medium
            _buildSelectionGroup(
              title: "Select Medium",
              items: _mediums,
              value: _selectedMedium,
              onSelected: (val) => setState(() => _selectedMedium = val),
              icon: Icons.language,
              colorScheme: colorScheme,
            ),
            const SizedBox(height: 24),

            // Board
            _buildSelectionGroup(
              title: "Select Board",
              items: _boards,
              value: _selectedBoard,
              onSelected: (val) => setState(() => _selectedBoard = val),
              icon: Icons.dashboard_outlined,
              colorScheme: colorScheme,
            ),

            const SizedBox(height: 48),

            ElevatedButton(
              onPressed: _handleContinue,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                elevation: 4,
              ),
              child: Text(
                "Go to Dashboard",
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionGroup({
    required String title,
    required List<String> items,
    required String? value,
    required Function(String) onSelected,
    required IconData icon,
    required ColorScheme colorScheme,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: Colors.blue.shade700),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.blue.shade900),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: items.map((item) {
            final isSelected = value == item;
            return ChoiceChip(
              label: Text(item),
              selected: isSelected,
              onSelected: (_) => onSelected(item),
              selectedColor: Colors.blue.shade700,
              labelStyle: GoogleFonts.poppins(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              backgroundColor: Colors.blue.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: isSelected ? Colors.blue.shade700 : Colors.transparent),
              ),
              checkmarkColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            );
          }).toList(),
        ),
      ],
    );
  }
}
