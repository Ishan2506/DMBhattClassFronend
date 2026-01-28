import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomToast {
  static void showSuccess(BuildContext context, String message) {
    _showToast(context, message, Colors.green.shade600, Icons.check_circle_outline);
  }

  static void showError(BuildContext context, String message) {
    _showToast(context, message, Colors.red.shade600, Icons.error_outline);
  }

  static void showInfo(BuildContext context, String message) {
    _showToast(context, message, Colors.blue.shade600, Icons.info_outline);
  }

  static void _showToast(BuildContext context, String message, Color color, IconData icon) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: color, // Slightly darkened base color
        elevation: 6,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colors.white24, width: 1), // Subtle border
        ),
        content: Row(
          mainAxisSize: MainAxisSize.min, // Wrap content
          children: [
            Container(
               padding: const EdgeInsets.all(4),
               decoration: BoxDecoration(
                 color: Colors.white.withOpacity(0.2),
                 shape: BoxShape.circle,
               ),
               child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
