import 'package:dm_bhatt_tutions/bloc/theme/theme_cubit.dart';
import 'package:dm_bhatt_tutions/constant/app_images.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/leaderboard_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  Future<void> _launchUrl() async {
    const url = 'https://www.youtube.com/@dmbhatteducationchannel';
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Section Header ---
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 12, top: 8),
              child: Text(
                "Reports",
                style: GoogleFonts.poppins(
                  fontSize: screenWidth * 0.045, // Responsive Font Size
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ),

            // --- Reports List (Smaller Individual Cards) ---
            _buildReportItem(
              context, 
              title: "Daily Attendance Report",
              onTap: () {
                // Navigate to attendance report
              },
            ),
             _buildReportItem(
              context, 
              title: "Leaderboard",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LeaderboardScreen()),
                );
              },
            ),
            
            // --- Settings Section ---
            const SizedBox(height: 16),
            _buildSectionHeader("Settings"),
            _buildSettingsItem(
              context,
              title: "Settings", // General Settings Entry
              value: "",
              icon: Icons.settings,
              onTap: () {
                 Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsScreen()),
                );
              },
            ),



            // --- Powered By Section ---
    //         const SizedBox(height: 32),
    //          Center(
    //           child: Text(
    //             "POWERED BY",
    //             style: GoogleFonts.poppins(
    //               fontSize: 14,
    //               fontWeight: FontWeight.w300,
    //               color: colorScheme.onSurfaceVariant,
    //               letterSpacing: 2,
    //             ),
    //           ),
    //         ),
    //         const SizedBox(height: 16),
    //          Padding(
    //           padding: const EdgeInsets.symmetric(horizontal: 20),
    //           child: Container(
    //                // blend mode 'multiply' makes white transparent
    //                child: ColorFiltered(
    //                   colorFilter: const ColorFilter.mode(
    //                     Colors.white,
    //                     BlendMode.darken,
    //                   ),
    //                   child: Image.asset(
    //                     imgPoweredByNew, 
    //                     color: const Color(0xFFF5F5F5),
    //                     colorBlendMode: BlendMode.multiply, 
    //                   ),
    //                ),
    //             ),
    //         ),
    //         const SizedBox(height: 20),
            ],
          ),
       ),
    );
  }

  Widget _buildReportItem(BuildContext context, {required String title, required VoidCallback onTap}) {
    final colorScheme = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: 18),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: screenWidth * 0.038, // Responsive Font Size
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
              ),
            ),
             Icon(Icons.arrow_forward_ios, size: screenWidth * 0.035, color: colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12, top: 24),
      child: Builder(
        builder: (context) {
          final sWidth = MediaQuery.of(context).size.width;
          return Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: sWidth * 0.045, // Responsive Font Size
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          );
        }
      ),
    );
  }

  Widget _buildSettingsItem(BuildContext context, {required String title, required String value, required IconData icon, required VoidCallback onTap}) {
     final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainer, // Dynamic Card Color
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: colorScheme.primary, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface, // Dynamic Text
                ),
              ),
            ),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: colorScheme.onSurfaceVariant, // Dynamic Text
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward_ios, size: 14, color: colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }



  Widget _buildPoweredByItem(BuildContext context, String name, String imagePath, {String? subtitle}) {
     final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56, // Slightly larger for better visibility
            height: 56,
            padding: const EdgeInsets.all(8), // Padding inside the circle
            decoration: BoxDecoration(
              color: Colors.white, // White background for logos
              shape: BoxShape.circle,
              border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.3)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            alignment: Alignment.center,
              child: Image.asset(
                imagePath,
                fit: BoxFit.contain,
                 errorBuilder: (context, error, stackTrace) {
                  return Text(
                    name.substring(0, 1),
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: colorScheme.primary),
                  );
                },
              ),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: GoogleFonts.poppins(
                fontSize: 9,
                color: colorScheme.onSurfaceVariant,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
