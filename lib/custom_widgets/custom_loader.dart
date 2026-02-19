import 'package:dm_bhatt_tutions/constant/app_images.dart';
import 'package:flutter/material.dart';

class CustomLoader extends StatelessWidget {
  const CustomLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 100, // Slightly larger for better visibility
        height: 100,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 15,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Logo
            Image.asset(
              imgLoaderBot, // Using App Logo (Padhaku)
              width: 50,
              height: 50,
              fit: BoxFit.contain,
            ),
            // Loader Ring
            SizedBox(
              width: 100,
              height: 100,
              child: CircularProgressIndicator(
                strokeWidth: 4,
                valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary), // App Theme Color
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Static method to show loader dialog
  static void show(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.3), // Dimmed background
      builder: (context) {
        return const CustomLoader();
      },
    );
  }

  // Static method to hide loader dialog
  static void hide(BuildContext context) {
    if (Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }
}
