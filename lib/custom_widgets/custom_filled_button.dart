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
    return SizedBox(
      width: double.infinity,
      height: S.s48,
      child: icon == null
          ? FilledButton(
              onPressed: isLoading ? null : onPressed,
              style: _buttonStyle(),
              child: _buildChild(context),
            )
          : FilledButton.icon(
              onPressed: isLoading ? null : onPressed,
              style: _buttonStyle(),
              label: _buildChild(context),
              icon: isLoading
                  ? const SizedBox.shrink()
                  : Icon(icon, size: S.s20),
            ),
    );
  }

  Widget _buildChild(BuildContext context) {
    if (isLoading) {
      return SizedBox(
        height: S.s24,
        width: S.s24,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    return Text(
      label,
      style: const TextStyle(letterSpacing: 0.5, fontSize: S.s16),
    );
  }

  ButtonStyle _buttonStyle() {
    return FilledButton.styleFrom(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(S.s12)),
    );
  }
}
