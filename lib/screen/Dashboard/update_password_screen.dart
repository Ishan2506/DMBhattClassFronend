import 'dart:convert';
import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_loader.dart';
import 'package:dm_bhatt_tutions/network/api_service.dart';
import 'package:dm_bhatt_tutions/utils/custom_toast.dart';
import 'package:flutter/material.dart';
import 'package:dm_bhatt_tutions/l10n/app_localizations.dart';
import 'package:dm_bhatt_tutions/utils/validation_utils.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UpdatePasswordScreen extends StatefulWidget {
  const UpdatePasswordScreen({super.key});

  @override
  State<UpdatePasswordScreen> createState() => _UpdatePasswordScreenState();
}

class _UpdatePasswordScreenState extends State<UpdatePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isOldVisible = false;
  bool _isNewVisible = false;
  bool _isConfirmVisible = false;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: const CustomAppBar(
        title: "Update Password",
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildPasswordField(
                    context,
                    controller: _oldPasswordController,
                    hint: "Old Password",
                    isVisible: _isOldVisible,
                    onVisibilityChanged: () => setState(() => _isOldVisible = !_isOldVisible),
                  ),
                  const SizedBox(height: 16),
                  _buildPasswordField(
                    context,
                    controller: _newPasswordController,
                    hint: "New Password",
                    isVisible: _isNewVisible,
                    onVisibilityChanged: () => setState(() => _isNewVisible = !_isNewVisible),
                    validator: (val) => ValidationUtils.noFieldError(val, AppLocalizations.of(context)!),
                  ),
                  const SizedBox(height: 16),
                  _buildPasswordField(
                    context,
                    controller: _confirmPasswordController,
                    hint: "Confirm Password",
                    isVisible: _isConfirmVisible,
                    onVisibilityChanged: () => setState(() => _isConfirmVisible = !_isConfirmVisible),
                    validator: (val) {
                      if (val != _newPasswordController.text) return "Passwords do not match";
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : () async {
                        if (_formKey.currentState!.validate()) {
                          final l10n = AppLocalizations.of(context)!;

                          // Password Complexity Validation
                          final passwordError = ValidationUtils.validatePasswordForToast(_newPasswordController.text, l10n);
                          if (passwordError != null) {
                            CustomToast.showError(context, passwordError);
                            return;
                          }

                          if (_oldPasswordController.text == _newPasswordController.text) {
                            CustomToast.showError(context, "New Password cannot be same as Old Password");
                            return;
                          }

                          setState(() => _isLoading = true);
                          try {
                            final response = await ApiService.updatePassword(
                              oldPassword: _oldPasswordController.text,
                              newPassword: _newPasswordController.text,
                            );

                            if (response.statusCode == 200) {
                              CustomToast.showSuccess(context, "Password Updated Successfully");
                              if (mounted) Navigator.pop(context);
                            } else {
                               CustomToast.showError(context, "Failed to update password: ${ApiService.getErrorMessage(response.body)}");
                            }
                          } catch (e) {
                             debugPrint("Update Password Error: $e");
                             CustomToast.showError(context, "An error occurred");
                          } finally {
                             if (mounted) setState(() => _isLoading = false);
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      child: Text(
                        "Update Password",
                        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: colorScheme.onPrimary),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            const Center(child: CustomLoader()),
        ],
      ),
    );
  }

  Widget _buildPasswordField(
    BuildContext context, {
    required TextEditingController controller,
    required String hint,
    required bool isVisible,
    required VoidCallback onVisibilityChanged,
    String? Function(String?)? validator,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: !isVisible,
        validator: validator ?? (val) => val!.isEmpty ? "Required" : null,
        style: GoogleFonts.poppins(fontWeight: FontWeight.w500, color: colorScheme.onSurface),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.poppins(color: colorScheme.onSurfaceVariant),
          prefixIcon: Icon(Icons.lock_outline, color: colorScheme.onSurfaceVariant),
          suffixIcon: IconButton(
            icon: Icon(isVisible ? Icons.visibility : Icons.visibility_off, color: colorScheme.onSurfaceVariant),
            onPressed: onVisibilityChanged,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}
