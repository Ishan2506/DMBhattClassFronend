import 'dart:convert';
import 'package:dm_bhatt_tutions/constant/app_images.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_loader.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/landing_screen.dart';
import 'package:dm_bhatt_tutions/l10n/app_localizations.dart';
import 'package:dm_bhatt_tutions/utils/custom_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dm_bhatt_tutions/network/api_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dm_bhatt_tutions/screen/authentication/register_screen.dart';

class AddAccountScreen extends StatefulWidget {
  const AddAccountScreen({super.key});

  @override
  State<AddAccountScreen> createState() => _AddAccountScreenState();
}

class _AddAccountScreenState extends State<AddAccountScreen> {
  bool _isPasswordVisible = false;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      CustomLoader.show(context);
      try {
        final response = await ApiService.loginUser(
          loginCode: _passwordController.text,
          phoneNum: _phoneController.text,
        );

        if (!mounted) return;
        CustomLoader.hide(context);

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final user = data['user'];

           // Check Valid Role
           if (user['role'] != 'student' && user['role'] != 'guest') {
             CustomToast.showError(context, "Access Denied: Only Students and Guests can login.");
             return;
           }

          final token = data['token'];
          
          // IMPORTANT: Set this new token as active BEFORE fetching profile
          // Otherwise getProfile() will use the OLD token and return the OLD user's data!
          await ApiService.setAuthToken(token);
          
          // Fetch profile to get name and details
          String name = "User";
          String std = "";
          String medium = "";
          String board = "";
          String stream = "";
          String userId = "";
          String profilePic = "";

          try {
             final profileResponse = await ApiService.getProfile();
             if (profileResponse.statusCode == 200) {
               final profileData = jsonDecode(profileResponse.body);
               final user = profileData['user'];
               final profile = profileData['profile'];
               
               if (user != null) {
                 // Prioritize firstName as seen in StudentProfileScreen, fallback to fname
                 name = "${user['firstName'] ?? user['fname'] ?? 'User'} ${user['lastName'] ?? ''}".trim();
                 if (name.isEmpty) name = "User";
                 userId = user['_id'] ?? "";
               }
               if (profile != null) {
                 std = profile['std'] ?? "";
                 medium = profile['medium'] ?? "";
                 board = profile['board'] ?? "";
                 stream = profile['stream'] ?? "";
                 profilePic = profile['profile_pic'] ?? (user != null ? user['photoPath'] : "") ?? "";
               }
             }
          } catch (e) {
            print("Error fetching profile: $e");
          }

          // Save to saved_accounts
          final prefs = await SharedPreferences.getInstance();
          List<String> savedAccountsStr = prefs.getStringList('saved_accounts') ?? [];
          List<Map<String, dynamic>> accounts = savedAccountsStr.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();

          // Check if already exists
          final existingIndex = accounts.indexWhere((acc) => acc['phone'] == _phoneController.text);
          
          final newAccount = {
            'token': token,
            'password': _passwordController.text,
            'phone': _phoneController.text,
            'name': name,
            'userId': userId,
            'std': std,
            'medium': medium,
            'board': board,
            'stream': stream,
            'profilePic': profilePic,
          };

          if (existingIndex != -1) {
            accounts[existingIndex] = newAccount; // Update
          } else {
             if (accounts.length >= 3) {
               CustomToast.showError(context, "Maximum 3 accounts allowed.");
               return;
             }
             accounts.add(newAccount);
          }

          await prefs.setStringList('saved_accounts', accounts.map((e) => jsonEncode(e)).toList());

          // Switch to this new account (Update root prefs)
          await prefs.setString('auth_token', token);
          await prefs.setString('user_password', _passwordController.text);
          if (userId.isNotEmpty) await prefs.setString('userId', userId); else await prefs.remove('userId');
          if (std.isNotEmpty) await prefs.setString('std', std); else await prefs.remove('std');
          if (medium.isNotEmpty) await prefs.setString('medium', medium); else await prefs.remove('medium');
          if (board.isNotEmpty) await prefs.setString('board', board); else await prefs.remove('board');
          if (stream.isNotEmpty) await prefs.setString('stream', stream); else await prefs.remove('stream');

          if (mounted) {
            CustomToast.showSuccess(context, "Account Added & Switched");
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const LandingScreen()),
              (route) => false,
            );
          }

        } else {
           // Parse error message
           try {
             final errData = jsonDecode(response.body);
             CustomToast.showError(context, errData['message'] ?? "Login Failed");
           } catch (_) {
             CustomToast.showError(context, "Login Failed");
           }
        }
      } catch (e) {
        if (mounted) {
          CustomLoader.hide(context);
          CustomToast.showError(context, "Error: $e");
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.primary.withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
        title: Text(l10n.addAccount, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Logo in a Container
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? theme.colorScheme.primary.withOpacity(0.1) : theme.colorScheme.primary.withOpacity(0.05),
                  shape: BoxShape.circle
                ),
                child: Image.asset(imgDmBhattClassesLogo, height: 80, width: 80),
              ),
              const SizedBox(height: 32),

              // Title Header (Matching Login/Register style)
              Text(
                l10n.heyThere,
                style: GoogleFonts.poppins(fontSize: 16, color: colorScheme.onSurfaceVariant),
              ),
              Text(
                l10n.addAnotherAccount,
                style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.enterDetailsToAdd,
                style: GoogleFonts.poppins(fontSize: 14, color: isDark ? Colors.grey.shade400 : Colors.black54),
              ),
              const SizedBox(height: 40),

               _buildTextField(
                context: context,
                controller: _phoneController,
                hint: l10n.phoneNumber, 
                icon: Icons.phone_outlined, 
                inputType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) return l10n.pleaseEnterPhone;
                  if (value.length != 10) return l10n.phoneMustBeTenDigits;
                  return null;
                },
                colorScheme: colorScheme,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                context: context,
                controller: _passwordController,
                hint: l10n.password,
                icon: Icons.lock_outline,
                isPassword: true,
                isVisible: _isPasswordVisible,
                onVisibilityChanged: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                validator: (value) => (value == null || value.isEmpty) ? l10n.pleaseEnterPassword : null,
                colorScheme: colorScheme,
              ),
               
              const SizedBox(height: 40),

              // Action Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    elevation: 2,
                  ),
                  child: Text(
                    l10n.loginAndAdd,
                    style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: colorScheme.onPrimary),
                  ),
                ),
              ),

              const SizedBox(height: 24),
              
              // Register Link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("${l10n.dontHaveAccount} ", style: GoogleFonts.poppins(color: isDark ? Colors.grey.shade400 : Colors.black54)),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const RegisterScreen()),
                      );
                    },
                    child: Text(
                      l10n.register,
                      style: GoogleFonts.poppins(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildTextField({
    required BuildContext context,
    required String hint, 
    required IconData icon, 
    TextEditingController? controller,
    bool isPassword = false, 
    bool isVisible = false,
    VoidCallback? onVisibilityChanged,
    TextInputType inputType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    required ColorScheme colorScheme,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword && !isVisible,
        keyboardType: inputType,
        inputFormatters: inputFormatters,
        validator: validator,
        style: GoogleFonts.poppins(color: theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.w600, fontSize: 16),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.poppins(color: isDark ? Colors.grey.shade400 : Colors.grey, fontWeight: FontWeight.normal),
          prefixIcon: Icon(icon, color: isDark ? Colors.grey : Colors.black54),
          suffixIcon: isPassword 
              ? IconButton(
                  icon: Icon(isVisible ? Icons.visibility : Icons.visibility_off, color: isDark ? Colors.grey.shade400 : Colors.grey),
                  onPressed: onVisibilityChanged,
                ) 
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}
