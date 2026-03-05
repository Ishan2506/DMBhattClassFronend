import 'package:dm_bhatt_tutions/screen/authentication/login_screen.dart';
import 'package:dm_bhatt_tutions/screen/authentication/register_screen.dart';
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

    if (context.mounted) {
      showGuestRestrictionDialog(
        context,
        message: "Please login or register first to give an exam.",
      );
    }
    return false;
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
            Text("Access Restricted", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          message ?? "This feature is only available for registered students. Please login or register to continue.",
          style: GoogleFonts.poppins(),
        ),
        actionsOverflowButtonSpacing: 8,
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Later", style: GoogleFonts.poppins(color: Colors.grey)),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                  foregroundColor: Theme.of(context).primaryColor,
                  elevation: 0,
                  side: BorderSide(color: Theme.of(context).primaryColor),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text("Login", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const RegisterScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text("Register", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
