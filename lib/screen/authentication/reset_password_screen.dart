import 'package:dm_bhatt_tutions/screen/authentication/login_screen.dart';
import 'package:dm_bhatt_tutions/utils/custom_toast.dart';
import 'package:dm_bhatt_tutions/network/api_service.dart';
import 'package:dm_bhatt_tutions/l10n/app_localizations.dart';
import 'package:dm_bhatt_tutions/utils/validation_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:dm_bhatt_tutions/constant/app_images.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String phone;
  const ResetPasswordScreen({super.key, required this.phone});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width; 

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black54),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            SizedBox(width: double.infinity), // Force expansion for Center
            const SizedBox(height: 20),
             // Logo
               Center(
                 child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    shape: BoxShape.circle,
                  ),
                   child: Image.asset(
                    imgDmBhattClassesLogo,
                    height: MediaQuery.of(context).size.height * 0.12,
                    width: MediaQuery.of(context).size.height * 0.12,
                  ),
                 ),
               ),
              const SizedBox(height: 32),
              
              Center(
                child: Text(
                  "Secure Account",
                  style: GoogleFonts.poppins(fontSize: 16, color: Colors.black54),
                ),
              ),
              Center(
                child: Text(
                  "Reset Password",
                  style: GoogleFonts.poppins(
                    fontSize: 24, 
                    fontWeight: FontWeight.bold, 
                    color: Colors.black87
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              Text(
                "Your new password must be different from previously used passwords.",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.black54,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),

              // New Password
              _buildTextField(
                controller: _newPasswordController,
                hint: "New Password",
                isPassword: true,
                isVisible: _isPasswordVisible,
                onVisibilityChanged: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
                validator: (value) => ValidationUtils.noFieldError(value, AppLocalizations.of(context)!),
              ),
              const SizedBox(height: 20),

              // Confirm Password
              _buildTextField(
                controller: _confirmPasswordController,
                hint: "Confirm Password",
                isPassword: true,
                isVisible: _isConfirmPasswordVisible,
                onVisibilityChanged: () {
                  setState(() {
                    _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please confirm your password';
                  }
                  if (value != _newPasswordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 40),

              // Reset Password Button
              SizedBox(
                width: double.infinity,
                height: MediaQuery.of(context).size.height * 0.065,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                       final l10n = AppLocalizations.of(context)!;

                       // Password Complexity Validation
                       final passwordError = ValidationUtils.validatePasswordForToast(_newPasswordController.text, l10n);
                       if (passwordError != null) {
                         CustomToast.showError(context, passwordError);
                         return;
                       }

                       // Perform Reset Logic (API call etc)
                       ApiService.resetPassword(phone: widget.phone, newPassword: _newPasswordController.text).then((response) {
                          if (response.statusCode == 200) {
                             CustomToast.showSuccess(context, "Password Reset Successful");
                             
                             Navigator.pushAndRemoveUntil(
                               context, 
                               MaterialPageRoute(builder: (context) => const LoginScreen()),
                               (route) => false
                             );
                          } else {
                             CustomToast.showError(context, "Failed to reset password");
                          }
                       }).catchError((e) {
                          CustomToast.showError(context, "Error: $e");
                       });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                  ),
                  child: Text(
                    "Reset Password",
                    style: GoogleFonts.poppins(
                      fontSize: screenWidth * 0.045, // Responsive
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required String? Function(String?) validator,
    bool isPassword = false,
    bool isVisible = false,
    VoidCallback? onVisibilityChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          hint, 
          style: GoogleFonts.poppins(
            fontSize: 14, 
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700
          )
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: isPassword && !isVisible,
          validator: validator,
          style: GoogleFonts.poppins(
            color: Colors.black, // Explicitly black
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
          decoration: InputDecoration(
            hintText: "Enter $hint",
            hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400, fontWeight: FontWeight.normal),
            filled: true,
            fillColor: Colors.grey.shade50,
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      isVisible ? Icons.visibility : Icons.visibility_off,
                      color: Colors.grey,
                    ),
                    onPressed: onVisibilityChanged,
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.blue.shade700, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }
}
