import 'package:dm_bhatt_tutions/screen/authentication/welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

class GuestUtils {
  static const int maxGuestExams = 3;
  static const String guestExamCountKey = 'guest_exam_count';

  static Future<bool> isGuest() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('user_role');
    return role == 'guest';
  }

  static Future<int> getGuestExamCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(guestExamCountKey) ?? 0;
  }

  static Future<void> incrementGuestExamCount() async {
    final prefs = await SharedPreferences.getInstance();
    final currentCount = await getGuestExamCount();
    await prefs.setInt(guestExamCountKey, currentCount + 1);
  }

  static Future<bool> canGuestAccessExam(BuildContext context) async {
    if (!await isGuest()) return true;

    final count = await getGuestExamCount();
    if (count >= maxGuestExams) {
      if (context.mounted) {
        showGuestRestrictionDialog(
          context,
          message: "Guests are limited to $maxGuestExams free exams. Please register as a student to unlock unlimited exams.",
        );
      }
      return false;
    }
    return true;
  }

  static void showGuestRestrictionDialog(BuildContext context, {String? message}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.lock_person, color: Colors.orange),
            const SizedBox(width: 10),
            Text("Guest Restriction", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          message ?? "This feature is only available for registered students. Please register to unlock full access.",
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Later", style: GoogleFonts.poppins(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear(); // Clear everything for a fresh registration
              if (!context.mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const WelcomeScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text("Register Now", style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
