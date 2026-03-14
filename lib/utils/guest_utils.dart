import 'package:dm_bhatt_tutions/screen/authentication/login_screen.dart';
import 'package:dm_bhatt_tutions/screen/authentication/register_screen.dart';
import 'package:dm_bhatt_tutions/screen/authentication/welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

class GuestUtils {
  static const int maxGuestExams = 1;
  static const String keyMainExam = 'guest_main_exam_count';
  static const String keyFiveMinTest = 'guest_five_min_test_count';
  static const String keyOneLinerExam = 'guest_one_liner_exam_count';

  static Future<bool> isGuest() async {
    final prefs = await SharedPreferences.getInstance();

    // If we have an auth token, we are definitively NOT a guest
    final token = prefs.getString('auth_token');
    if (token != null && token.isNotEmpty) return false;

    final isGuestMode = prefs.getBool('is_guest_mode') ?? false;
    final role = prefs.getString('user_role');
    return isGuestMode || role == 'guest';
  }

  static Future<int> getGuestExamCount(String type) async {
    final prefs = await SharedPreferences.getInstance();
    String key = _getKeyForType(type);
    return prefs.getInt(key) ?? 0;
  }

  static Future<void> incrementGuestExamCount(String type) async {
    final prefs = await SharedPreferences.getInstance();
    String key = _getKeyForType(type);
    final currentCount = await getGuestExamCount(type);
    await prefs.setInt(key, currentCount + 1);
  }

  static String _getKeyForType(String type) {
    switch (type.toUpperCase()) {
      case 'REGULAR':
      case 'MAIN':
        return keyMainExam;
      case 'QUIZ':
      case 'FIVEMIN':
        return keyFiveMinTest;
      case 'ONELINER':
        return keyOneLinerExam;
      default:
        return 'guest_other_count';
    }
  }

  static Future<bool> canGuestAccessExam(
    BuildContext context,
    String type,
  ) async {
    if (!await isGuest()) return true;

    final count = await getGuestExamCount(type);
    if (count < maxGuestExams) {
      return true; // Allow first attempt for this type
    }

    if (context.mounted) {
      String typeLabel = _getTypeLabel(type);
      showGuestRestrictionDialog(
        context,
        message:
            "You have already used your 1 free $typeLabel attempt. Please login or register to continue for unlimited access.",
      );
    }
    return false;
  }

  static Future<bool> canGuestPurchase(BuildContext context) async {
    if (!await isGuest()) return true;

    if (context.mounted) {
      showGuestRestrictionDialog(
        context,
        message:
            "Purchasing materials is only available for registered students. Please login or register to continue.",
      );
    }
    return false;
  }

  static String _getTypeLabel(String type) {
    switch (type.toUpperCase()) {
      case 'REGULAR':
      case 'MAIN':
        return "Main Exam";
      case 'QUIZ':
      case 'FIVEMIN':
        return "5-Min Rapid Test";
      case 'ONELINER':
        return "One-Liner Exam";
      default:
        return "exam";
    }
  }

  static void showGuestRestrictionDialog(
    BuildContext context, {
    String? message,
  }) {
    final width = MediaQuery.of(context).size.width;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 15,
        ),
        title: Row(
          children: [
            const Icon(Icons.lock_person, color: Colors.orange),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                "Access Restricted",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: width > 400 ? 18 : width * 0.045,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message ??
              "This feature is only available for registered students. Please login or register to continue.",
          style: GoogleFonts.poppins(
            fontSize: width > 400 ? 14 : width * 0.035,
          ),
        ),
        actionsPadding: const EdgeInsets.only(bottom: 15, right: 10, left: 10),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(
                width: width * 0.16,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    "Later",
                    style: GoogleFonts.poppins(
                      color: Colors.grey,
                      fontSize: width > 400 ? 14 : width * 0.032,
                    ),
                    maxLines: 1,
                  ),
                ),
              ),
              SizedBox(
                width: width * 0.24,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(
                      context,
                    ).primaryColor.withOpacity(0.1),
                    foregroundColor: Theme.of(context).primaryColor,
                    elevation: 0,
                    side: BorderSide(color: Theme.of(context).primaryColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 36),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    "Login",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: width > 400 ? 14 : width * 0.032,
                    ),
                    maxLines: 1,
                  ),
                ),
              ),
              SizedBox(
                width: width * 0.28,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RegisterScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 36),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    "Register",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: width > 400 ? 14 : width * 0.032,
                    ),
                    maxLines: 1,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
