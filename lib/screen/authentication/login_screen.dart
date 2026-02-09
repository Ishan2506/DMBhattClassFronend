import 'dart:convert';
import 'package:dm_bhatt_tutions/constant/app_images.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_loader.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/landing_screen.dart';
import 'package:dm_bhatt_tutions/utils/app_localizations.dart';
import 'package:dm_bhatt_tutions/utils/custom_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import services for formatters
import 'package:dm_bhatt_tutions/network/api_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dm_bhatt_tutions/screen/authentication/forgot_password_phone_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isPasswordVisible = false;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black54),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        // title: Text(
        //   "Back",
        //   style: GoogleFonts.poppins(color: Colors.black54, fontSize: 16),
        // ),
       // titleSpacing: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
            const SizedBox(height: 20),
            // Logo
             Container(
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
            const SizedBox(height: 32),

            Text(
              l10n.heyThere,
              style: GoogleFonts.poppins(fontSize: 16, color: Colors.black54),
            ),
            Text(
              l10n.welcomeBack,
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87
              ),
            ),
            const SizedBox(height: 24),

            // Phone Number Field
             _buildTextField(
              controller: _phoneController,
              hint: l10n.phoneNumber,
              icon: Icons.phone_outlined,
              inputType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter phone number';
                }
                if (value.length != 10) {
                  return 'Phone number must be 10 digits';
                }
                return null;
              },
               errorMaxLines: 2,
            ),
            const SizedBox(height: 16),

            // Password Field
            _buildTextField(
              controller: _passwordController,
              hint: l10n.password,
              icon: Icons.lock_outline,
              isPassword: true,
              isVisible: _isPasswordVisible,
              onVisibilityChanged: () {
                setState(() {
                  _isPasswordVisible = !_isPasswordVisible;
                });
              },
               validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter password';
                }
                return null;
              },
               errorMaxLines: 2,
            ),
            const SizedBox(height: 16),

             TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ForgotPasswordPhoneScreen())
                );
              },
              child: Text(
                l10n.forgotPasswordQuestion,
                style: GoogleFonts.poppins(
                  color: Colors.black54,
                  fontWeight: FontWeight.w500,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Login Button
            SizedBox(
              width: double.infinity,
              height: 56.0, // Fixed height for the button
              child: ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    CustomLoader.show(context); // Show Loader
                    try {
                        final response = await ApiService.loginUser(
                          role: 'student',
                          loginCode: _passwordController.text,
                          phoneNum: _phoneController.text,
                        );

                        if (!mounted) return;
                        CustomLoader.hide(context); // Hide Loader

                        if (response.statusCode == 200) {
                            final data = jsonDecode(response.body);
                            final token = data['token'];

                            // Save token
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setString('auth_token', token);
                            await prefs.setString('user_password', _passwordController.text); // Saving password for PDF encryption

                            // Fetch profile data to get std and userId
                            try {
                              final profileResponse = await ApiService.getProfile(token);
                              if (profileResponse.statusCode == 200) {
                                final profileData = jsonDecode(profileResponse.body);
                                final user = profileData['user'];
                                final profile = profileData['profile'];

                                // Save userId and std for leaderboard
                                if (user != null && user['_id'] != null) {
                                  await prefs.setString('userId', user['_id']);
                                }
                                if (profile != null && profile['std'] != null) {
                                  await prefs.setString('std', profile['std']);
                                }
                              }
                            } catch (e) {
                              print('Error fetching profile: $e');
                              // Continue with login even if profile fetch fails
                            }

                            CustomToast.showSuccess(context, "Login Successful");
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const LandingScreen()),
                              (route) => false,
                            );
                        } else {
                           CustomToast.showError(context, "Login Failed: ${response.body}");
                        }
                    } catch (e) {
                      if (mounted) {
                        CustomLoader.hide(context); // Hide Loader on Error
                        CustomToast.showError(context, "Error: $e");
                      }
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700, // Blue Theme
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                    side: const BorderSide(color: Colors.black12),
                  ),
                  elevation: 2,
                ),
                child: Text(
                  l10n.login,
                  style: GoogleFonts.poppins(
                    fontSize: 18.0, // Fixed font size
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String hint,
    required IconData icon,
    TextEditingController? controller,
    bool isPassword = false,
    bool isVisible = false,
    VoidCallback? onVisibilityChanged,
    TextInputType inputType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    int? errorMaxLines,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword && !isVisible,
        keyboardType: inputType,
        inputFormatters: inputFormatters,
        validator: validator,
        style: GoogleFonts.poppins(
          color: Colors.black, // Explicitly Black
          fontWeight: FontWeight.w600, // Bold
          fontSize: 16,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.poppins(color: Colors.grey, fontWeight: FontWeight.normal),
          prefixIcon: Icon(icon, color: Colors.black54),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(isVisible ? Icons.visibility : Icons.visibility_off, color: Colors.grey),
                  onPressed: onVisibilityChanged,
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          errorMaxLines: errorMaxLines,
        ),
      ),
    );
  }
}
