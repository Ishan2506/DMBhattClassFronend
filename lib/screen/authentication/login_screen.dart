import 'dart:convert';
import 'package:dm_bhatt_tutions/constant/app_images.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_loader.dart';
import 'package:dm_bhatt_tutions/utils/notification_service.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/landing_screen.dart';
import 'package:dm_bhatt_tutions/l10n/app_localizations.dart';
import 'package:dm_bhatt_tutions/utils/custom_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import services for formatters
import 'package:dm_bhatt_tutions/network/api_service.dart';
import 'package:dm_bhatt_tutions/utils/database_helper.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dm_bhatt_tutions/screen/authentication/forgot_password_phone_screen.dart';
import 'package:dm_bhatt_tutions/screen/authentication/welcome_screen.dart';
import 'package:dm_bhatt_tutions/utils/validation_utils.dart';
import 'package:dm_bhatt_tutions/utils/revenue_cat_service.dart';

class LoginScreen extends StatefulWidget {
  final bool isAddAccount;
  const LoginScreen({super.key, this.isAddAccount = false});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isPasswordVisible = false;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _identifierController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  /// True when the server rejected the login because the account is already
  /// signed in on the maximum number of devices.
  bool _isDeviceLimitError(String body) {
    try {
      final decoded = jsonDecode(body);
      return decoded is Map && decoded['code'] == 'DEVICE_LIMIT_REACHED';
    } catch (_) {
      return false;
    }
  }

  /// Lists the devices currently holding a session, so the student knows where
  /// to go and log out.
  List<String> _activeDeviceLabels(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map && decoded['activeDevices'] is List) {
        return (decoded['activeDevices'] as List).map((d) {
          final name = (d['deviceName'] ?? 'Unknown device').toString();
          final lastActive = d['lastActive'];
          if (lastActive == null) return name;
          final when = DateTime.tryParse(lastActive.toString())?.toLocal();
          if (when == null) return name;
          return '$name — last used ${_formatWhen(when)}';
        }).cast<String>().toList();
      }
    } catch (_) {
      // Fall through to an empty list; the message alone is still useful.
    }
    return const [];
  }

  String _formatWhen(DateTime when) {
    final diff = DateTime.now().difference(when);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
  }

  /// [responseBody] is the raw 403 payload, which carries both the message and
  /// the list of devices currently holding a session.
  void _showDeviceLimitDialog(BuildContext context, String responseBody) {
    final colorScheme = Theme.of(context).colorScheme;
    final message = ApiService.getErrorMessage(responseBody);
    final devices = _activeDeviceLabels(responseBody);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        icon: Icon(
          Icons.phonelink_lock_outlined,
          size: 40,
          color: colorScheme.error,
        ),
        title: Text(
          'Already Logged In',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: GoogleFonts.poppins(fontSize: 14),
            ),
            if (devices.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Signed in on:',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              ...devices.map(
                (d) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.smartphone,
                        size: 16,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          d,
                          style: GoogleFonts.poppins(
                            fontSize: 12.5,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Text(
              'Log out from that device and try again. If you no longer have '
              'access to it, please contact your institute for help.',
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'OK',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: colorScheme.onSurfaceVariant),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              // LoginScreen is the only route on the stack (e.g. opened via
              // pushAndRemoveUntil). Popping would leave a black screen, so
              // send the user back to the welcome screen instead.
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const WelcomeScreen(),
                ),
              );
            }
          },
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
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    l10n.welcomeBack,
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Phone Number or Email Field
                  _buildTextField(
                    controller: _identifierController,
                    hint: l10n.phoneOrEmail,
                    icon: Icons.person_outline,
                    inputType: TextInputType.emailAddress,
                    validator: (value) =>
                        ValidationUtils.validatePhoneOrEmail(value, l10n),
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
                        MaterialPageRoute(
                          builder: (context) =>
                              const ForgotPasswordPhoneScreen(),
                        ),
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
                              identifier: _identifierController.text.trim(),
                            );

                            if (!mounted) return;
                            CustomLoader.hide(context); // Hide Loader

                            if (response.statusCode == 200) {
                              final data = jsonDecode(response.body);
                              final token = data['token'];
                              final user = data['user'];

                              // Check Valid Role
                              if (user['role'] != 'student' &&
                                  user['role'] != 'guest') {
                                CustomToast.showError(
                                  context,
                                  "Access Denied: Only Students and Guests can login.",
                                );
                                return;
                              }

                              // Save token
                              final prefs =
                                  await SharedPreferences.getInstance();
                              await ApiService.setAuthToken(token);
                              final revenueCatUserId =
                                  user['_id']?.toString() ??
                                  user['id']?.toString();
                              if (revenueCatUserId != null &&
                                  revenueCatUserId.isNotEmpty) {
                                await RevenueCatService.instance.login(
                                  revenueCatUserId,
                                );
                              }
                              //await prefs.setString('auth_token', token);
                              await prefs.setString(
                                'user_password',
                                _passwordController.text,
                              ); // Saving password for PDF encryption
                              if (user != null) {
                                if (user['phoneNum'] != null)
                                  await prefs.setString(
                                    'user_phone',
                                    user['phoneNum'],
                                  );
                                if (user['email'] != null)
                                  await prefs.setString(
                                    'user_email',
                                    user['email'],
                                  );
                                if (user['firstName'] != null)
                                  await prefs.setString(
                                    'firstName',
                                    user['firstName'],
                                  );
                                if (user['std'] != null)
                                  await prefs.setString(
                                    'std',
                                    user['std'].toString(),
                                  );
                                if (user['medium'] != null)
                                  await prefs.setString(
                                    'medium',
                                    user['medium'],
                                  );
                                if (user['stream'] != null)
                                  await prefs.setString(
                                    'stream',
                                    user['stream'],
                                  );
                                if (user['board'] != null)
                                  await prefs.setString('board', user['board']);
                                if (user['parentPhone'] != null &&
                                    user['parentPhone'].toString().isNotEmpty)
                                  await prefs.setString(
                                    'parentPhone',
                                    user['parentPhone'].toString(),
                                  );
                                if (user['role'] != null)
                                  await prefs.setString('user_role', user['role']);
                              }

                              // Handle Multi-Account Storage
                              final db = DatabaseHelper();
                              if (!widget.isAddAccount) {
                                // Normal Login: Clear other accounts
                                await db.clearAllExcept(
                                  user['_id'] ?? user['id'],
                                );
                              }

                              // Save/Update Current Account in DB
                              await db.saveAccount(
                                userId: user['_id'] ?? user['id'] ?? 'unknown',
                                name:
                                    "${user['firstName'] ?? ''} ${user['lastName'] ?? ''}"
                                        .trim(),
                                token: token,
                                role: user['role'] ?? 'student',
                                phone: user['phoneNum'] ?? _identifierController.text.trim(),
                                userData: jsonEncode(user),
                                profilePic: user['photoPath'] ?? "",
                              );

                              // Subscribe to user-specific and standard-specific notification topics
                              try {
                                final userId = user['_id'] ?? user['id'];
                                if (userId != null && userId.isNotEmpty) {
                                  await NotificationService.instance.subscribeToUserTopic(userId);
                                }

                                final profileResponse =
                                    await ApiService.getProfile();
                                if (profileResponse.statusCode == 200) {
                                  final profileData = jsonDecode(
                                    profileResponse.body,
                                  );
                                  final profile = profileData['profile'];
                                  if (profile != null &&
                                      profile['std'] != null) {
                                    final std = profile['std'].toString();
                                    if (std.isNotEmpty) {
                                      await NotificationService.instance
                                          .subscribeToStandardTopic(std);
                                    }
                                  }
                                }
                              } catch (e) {
                                // Log error but don't block login
                                debugPrint(
                                  "Error subscribing to notification topics: $e",
                                );
                              }

                              CustomToast.showSuccess(
                                context,
                                "Login Successful",
                              );
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const LandingScreen(),
                                ),
                                (route) => false,
                              );
                            } else if (response.statusCode == 403 &&
                                _isDeviceLimitError(response.body)) {
                              // Blocked by the device limit — explain what to do
                              // instead of showing a generic "login failed".
                              _showDeviceLimitDialog(context, response.body);
                            } else {
                              CustomToast.showError(
                                context,
                                "Login Failed: ${ApiService.getErrorMessage(response.body)}",
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              CustomLoader.hide(
                                context,
                              ); // Hide Loader on Error
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
    return TextFormField(
      controller: controller,
      obscureText: isPassword && !isVisible,
      keyboardType: inputType,
      inputFormatters: inputFormatters,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      style: GoogleFonts.poppins(
        color: colorScheme.onSurface, 
        fontWeight: FontWeight.w600, // Bold
        fontSize: 16,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: colorScheme.surfaceContainer,
        hintText: hint,
        hintStyle: GoogleFonts.poppins(
          color: colorScheme.onSurfaceVariant.withOpacity(0.6), 
          fontWeight: FontWeight.normal,
        ),
        prefixIcon: Icon(icon, color: colorScheme.onSurfaceVariant),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(isVisible ? Icons.visibility : Icons.visibility_off, color: colorScheme.onSurfaceVariant),
                onPressed: onVisibilityChanged,
              )
            : null,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        errorMaxLines: errorMaxLines,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
      ),
    );
  }
}
