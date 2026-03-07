import 'dart:convert';
import 'package:dm_bhatt_tutions/constant/app_images.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_loader.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/landing_screen.dart';
import 'package:dm_bhatt_tutions/l10n/app_localizations.dart';
import 'package:dm_bhatt_tutions/utils/custom_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import services for formatters
import 'package:dm_bhatt_tutions/network/api_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dm_bhatt_tutions/screen/authentication/forgot_password_phone_screen.dart';
import 'package:dm_bhatt_tutions/utils/validation_utils.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/student_profile.dart';

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
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: colorScheme.onSurfaceVariant),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
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
                color: colorScheme.primaryContainer,
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
              style: GoogleFonts.poppins(fontSize: 16, color: colorScheme.onSurfaceVariant),
            ),
            Text(
              l10n.welcomeBack,
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface
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
              validator: ValidationUtils.validateIndianPhoneNumber,
               errorMaxLines: 2,
               colorScheme: colorScheme,
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
                  return l10n.pleaseEnterPassword;
                }
                return null;
              },
               errorMaxLines: 2,
               colorScheme: colorScheme,
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
                  color: colorScheme.onSurfaceVariant,
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
                          loginCode: _passwordController.text,
                          phoneNum: _phoneController.text,
                        );

                        if (!mounted) return;
                        CustomLoader.hide(context); // Hide Loader

                        if (response.statusCode == 200) {
                            final data = jsonDecode(response.body);
                            final token = data['token'];
                            final user = data['user'];

                            // Check Valid Role
                            if (user['role'] != 'student' && user['role'] != 'guest') {
                              CustomToast.showError(context, "Access Denied: Only Students and Guests can login.");
                              return;
                            }

                            // Save token
                            final prefs = await SharedPreferences.getInstance();
                            await ApiService.setAuthToken(token);
                            //await prefs.setString('auth_token', token);
                            await prefs.setString('user_password', _passwordController.text); // Saving password for PDF encryption
                            if (user != null) {
                              if (user['phoneNum'] != null) await prefs.setString('user_phone', user['phoneNum']);
                              if (user['email'] != null) await prefs.setString('user_email', user['email']);
                            }

                            // Fetch profile data to get std and userId
                            try {
                              final profileResponse = await ApiService.getProfile();
                              if (profileResponse.statusCode == 200) {
                                final profileData = jsonDecode(profileResponse.body);
                                final user = profileData['user'];
                                final profile = profileData['profile'];

                                // Save userId and std for leaderboard
                                if (user != null && user['_id'] != null) {
                                  await prefs.setString('userId', user['_id']);
                                }
                                if (user != null && user['role'] != null) {
                                  await prefs.setString('user_role', user['role']);
                                }
                                if (user != null && user['firstName'] != null) await prefs.setString('firstName', user['firstName']);
                                if (profile != null) {
                                  if (profile['std'] != null && profile['std'].toString().isNotEmpty) await prefs.setString('std', profile['std']); else await prefs.remove('std');
                                  if (profile['medium'] != null && profile['medium'].toString().isNotEmpty) await prefs.setString('medium', profile['medium']); else await prefs.remove('medium');
                                  if (profile['board'] != null && profile['board'].toString().isNotEmpty) await prefs.setString('board', profile['board']); else await prefs.remove('board');
                                  if (profile['stream'] != null && profile['stream'].toString().isNotEmpty) await prefs.setString('stream', profile['stream']); else await prefs.remove('stream');
                                  if (profile['parentPhone'] != null && profile['parentPhone'].toString().isNotEmpty) await prefs.setString('parentPhone', profile['parentPhone']);
                                }

                                // Sync this account to the saved accounts list
                                await StudentProfileScreen.ensureCurrentAccountSaved(
                                  prefs,
                                  name: "${user['firstName'] ?? ''} ${user['lastName'] ?? ''}".trim(),
                                  phone: user['phoneNum'] ?? "",
                                  pic: user['photoPath'] ?? "",
                                );
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
                           CustomToast.showError(context, "Login Failed: ${ApiService.getErrorMessage(response.body)}");
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
                  backgroundColor: colorScheme.primary, // Blue Theme
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 2,
                ),
                child: Text(
                  l10n.login,
                  style: GoogleFonts.poppins(
                    fontSize: 18.0, // Fixed font size
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onPrimary,
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
    required ColorScheme colorScheme,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword && !isVisible,
        keyboardType: inputType,
        inputFormatters: inputFormatters,
        validator: validator,
        
        style: GoogleFonts.poppins(
          color: colorScheme.onSurface, 
          fontWeight: FontWeight.w600, // Bold
          fontSize: 16,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.poppins(color: colorScheme.onSurfaceVariant.withOpacity(0.6), fontWeight: FontWeight.normal),
          prefixIcon: Icon(icon, color: colorScheme.onSurfaceVariant),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(isVisible ? Icons.visibility : Icons.visibility_off, color: colorScheme.onSurfaceVariant),
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
