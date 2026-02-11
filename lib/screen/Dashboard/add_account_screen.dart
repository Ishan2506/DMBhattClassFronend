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
          
          // Fetch profile to get name and details
          String name = "User";
          String std = "";
          String userId = "";
          String profilePic = "";

          try {
             final profileResponse = await ApiService.getProfile(token);
             if (profileResponse.statusCode == 200) {
               final profileData = jsonDecode(profileResponse.body);
               final user = profileData['user'];
               final profile = profileData['profile'];
               
               if (user != null) {
                 name = user['fname'] ?? "User";
                 userId = user['_id'] ?? "";
               }
               if (profile != null) {
                 std = profile['std'] ?? "";
                 profilePic = profile['profile_pic'] ?? "";
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
          if (userId.isNotEmpty) await prefs.setString('userId', userId);
          if (std.isNotEmpty) await prefs.setString('std', std);

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
    // Reusing styles from LoginScreen
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black54),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(l10n.addAccount, style: GoogleFonts.poppins(color: Colors.black87, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.blue.shade50, shape: BoxShape.circle),
                child: Image.asset(imgDmBhattClassesLogo, height: 80, width: 80),
              ),
              const SizedBox(height: 32),
              Text(
                l10n.addAnotherAccount,
                style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.enterDetailsToAdd,
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 40),

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
                  if (value == null || value.isEmpty) return l10n.pleaseEnterPhone;
                  if (value.length != 10) return l10n.phoneMustBeTenDigits;
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _passwordController,
                hint: l10n.password,
                icon: Icons.lock_outline,
                isPassword: true,
                isVisible: _isPasswordVisible,
                onVisibilityChanged: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                validator: (value) => (value == null || value.isEmpty) ? l10n.pleaseEnterPassword : null,
              ),
               
              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: Text(
                    l10n.loginAndAdd,
                    style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),

              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("${l10n.dontHaveAccount} ", style: GoogleFonts.poppins(color: Colors.black54)),
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
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
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
        style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.w600, fontSize: 16),
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
        ),
      ),
    );
  }
}
