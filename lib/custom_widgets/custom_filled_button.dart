import 'package:dm_bhatt_tutions/utils/app_sizes.dart';
import 'package:flutter/material.dart';

class CustomFilledButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;

  const CustomFilledButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    
    return SizedBox(
      width: double.infinity,
      height: screenHeight * 0.06, // Responsive height (approx 48-56 depending on screen)
      child: icon == null
          ? FilledButton(
              onPressed: isLoading ? null : onPressed,
              style: _buttonStyle(),
              child: _buildChild(context, screenWidth),
            )
          : FilledButton.icon(
              onPressed: isLoading ? null : onPressed,
              style: _buttonStyle(),
              label: _buildChild(context, screenWidth),
              icon: isLoading
                  ? const SizedBox.shrink()
                  : Icon(icon, size: S.s20),
            ),
    );
  }

  Widget _buildChild(BuildContext context, double screenWidth) {
    if (isLoading) {
      return const SizedBox(
        height: S.s24,
        width: S.s24,
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
      );
    }
    return Text(
      label,
      style: TextStyle(
        letterSpacing: 0.5, 
        fontSize: screenWidth * 0.04, // Responsive font size
        fontWeight: FontWeight.bold,
      ),
    );
  }

  ButtonStyle _buttonStyle() {
    return FilledButton.styleFrom(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(S.s12)),
    );
  }
}
