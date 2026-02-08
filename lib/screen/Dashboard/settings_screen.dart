import 'package:dm_bhatt_tutions/bloc/theme/theme_cubit.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/update_password_screen.dart';
import 'package:dm_bhatt_tutions/utils/app_localizations.dart';
import 'package:dm_bhatt_tutions/utils/custom_toast.dart';
import 'package:dm_bhatt_tutions/screen/authentication/welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/add_account_screen.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/landing_screen.dart';
import 'dart:convert';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: CustomAppBar(
        title: l10n.settings,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
         padding: const EdgeInsets.all(16),
         child: BlocBuilder<ThemeCubit, ThemeState>(
            builder: (context, state) {
              String themeText;
              if (state.themeMode == ThemeMode.light) {
                themeText = l10n.locale.languageCode == 'hi' ? "प्रकाश" : (l10n.locale.languageCode == 'gu' ? "પ્રકાશ" : "Light");
              } else if (state.themeMode == ThemeMode.dark) {
                themeText = l10n.locale.languageCode == 'hi' ? "डार्क" : (l10n.locale.languageCode == 'gu' ? "ડાર્ક" : "Dark");
              } else {
                themeText = l10n.locale.languageCode == 'hi' ? "सिस्टम" : (l10n.locale.languageCode == 'gu' ? "સિસ્ટમ" : "System");
              }

              String langText;
              if (state.locale.languageCode == 'gu') langText = "Gujarati";
              else if (state.locale.languageCode == 'hi') langText = "Hindi";
              else langText = "English";

              return Column(
                children: [
                  _buildSettingsItem(
                    context,
                    title: l10n.themeMode,
                    value: themeText,
                    icon: Icons.dark_mode_outlined,
                    onTap: () => _showThemeSelector(context),
                  ),
                  _buildSettingsItem(
                    context,
                    title: "Theme Style",
                    value: state.selectedStyle.name.toUpperCase(),
                    icon: Icons.palette_outlined,
                    onTap: () => _showStyleSelector(context),
                  ),
                  _buildSettingsItem(
                    context,
                    title: l10n.language,
                    value: langText,
                    icon: Icons.language,
                    onTap: () => _showLanguageSelector(context),
                  ),
                  _buildSettingsItem(
                    context, 
                    title: "Switch Account", 
                    value: "", 
                    icon: Icons.switch_account, 
                    onTap: () => _showSwitchAccountSheet(context),
                  ),
                  _buildSettingsItem(
                    context,
                    title: l10n.locale.languageCode == 'hi' ? "पासवर्ड अपडेट करें" : (l10n.locale.languageCode == 'gu' ? "પાસવર્ડ અપડેટ કરો" : "Update Password"),
                    value: "",
                    icon: Icons.lock_reset,
                      onTap: () {
                       Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const UpdatePasswordScreen()),
                      );
                    },
                  ),
                  _buildSettingsItem(
                    context,
                    title: l10n.signOut,
                    value: "",
                    icon: Icons.logout,
                    onTap: () => _handleSignOut(context),
                  ),
                ],
              );
            }
         ),
      ),
    );
  }

  Widget _buildSettingsItem(BuildContext context, {required String title, required String value, required IconData icon, required VoidCallback onTap}) {
     final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainer, 
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: colorScheme.primary, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface, 
                ),
              ),
            ),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: colorScheme.onSurfaceVariant, 
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward_ios, size: 14, color: colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  void _showThemeSelector(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.primary.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Text(
                  l10n.locale.languageCode == 'hi' ? "थीम चुनें" : (l10n.locale.languageCode == 'gu' ? "થીમ પસંદ કરો" : "Select Theme"), 
                  style: GoogleFonts.poppins(
                    fontSize: 18, 
                    fontWeight: FontWeight.bold,
                    color: Colors.white
                  )
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _buildRadioOption(context, l10n.locale.languageCode == 'hi' ? "लाइट मोड" : (l10n.locale.languageCode == 'gu' ? "લાઇટ મોડ" : "Light Mode"), ThemeMode.light),
                    _buildRadioOption(context, l10n.locale.languageCode == 'hi' ? "डार्क मोड" : (l10n.locale.languageCode == 'gu' ? "ડાર્ક મોડ" : "Dark Mode"), ThemeMode.dark),
                    _buildRadioOption(context, l10n.locale.languageCode == 'hi' ? "सिस्टम डिफ़ॉल्ट" : (l10n.locale.languageCode == 'gu' ? "સિસ્ટમ ડિફોલ્ટ" : "System Default"), ThemeMode.system),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showStyleSelector(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.primary.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Text(
                  "Select Theme Style", 
                  style: GoogleFonts.poppins(
                    fontSize: 18, 
                    fontWeight: FontWeight.bold,
                    color: Colors.white
                  )
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      _buildStyleOption(context, "Classic", AppThemeStyle.classic),
                      _buildStyleOption(context, "Ocean (Teal)", AppThemeStyle.ocean),
                      _buildStyleOption(context, "Sunset (Orange)", AppThemeStyle.sunset),
                      _buildStyleOption(context, "Forest (Green)", AppThemeStyle.forest),
                      _buildStyleOption(context, "Lavender (Purple)", AppThemeStyle.lavender),
                      _buildStyleOption(context, "Midnight (Deep Blue)", AppThemeStyle.midnight),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStyleOption(BuildContext context, String label, AppThemeStyle style) {
    final currentStyle = context.read<ThemeCubit>().state.selectedStyle;
    return RadioListTile<AppThemeStyle>(
      title: Text(label, style: GoogleFonts.poppins()),
      value: style,
      groupValue: currentStyle,
      activeColor: Theme.of(context).colorScheme.primary,
      onChanged: (val) {
        if (val != null) {
          context.read<ThemeCubit>().changeStyle(val);
          Navigator.pop(context);
        }
      },
    );
  }

  Widget _buildRadioOption(BuildContext context, String label, ThemeMode mode) {
    final currentMode = context.read<ThemeCubit>().state.themeMode;
    return RadioListTile<ThemeMode>(
      title: Text(label, style: GoogleFonts.poppins()),
      value: mode,
      groupValue: currentMode,
      activeColor: Colors.blue.shade700,
      onChanged: (val) {
        if (val != null) {
          context.read<ThemeCubit>().changeTheme(val);
          Navigator.pop(context);
        }
      },
    );
  }

  void _showLanguageSelector(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.primary.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Text(
                  l10n.locale.languageCode == 'hi' ? "भाषा चुनें" : (l10n.locale.languageCode == 'gu' ? "ભાષા પસંદ કરો" : "Select Language"), 
                  style: GoogleFonts.poppins(
                    fontSize: 18, 
                    fontWeight: FontWeight.bold,
                    color: Colors.white
                  )
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                 padding: const EdgeInsets.symmetric(horizontal: 16),
                 child: Column(
                  children: [
                    _buildLangOption(context, "English", const Locale('en')),
                    _buildLangOption(context, "Hindi", const Locale('hi')),
                    _buildLangOption(context, "Gujarati", const Locale('gu')),
                  ],
                 ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLangOption(BuildContext context, String label, Locale locale) {
    final currentLocale = context.read<ThemeCubit>().state.locale;
    return RadioListTile<Locale>(
      title: Text(label, style: GoogleFonts.poppins()),
      value: locale,
      groupValue: currentLocale,
      activeColor: Colors.blue.shade700,
      onChanged: (val) {
        if (val != null) {
          context.read<ThemeCubit>().changeLocale(val);
          Navigator.pop(context);
        }
      },
    );
  }

  Future<void> _handleSignOut(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surfaceContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l10n.signOut, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
        content: Text(
          l10n.locale.languageCode == 'hi' ? "क्या आप वाकई साइन आउट करना चाहते हैं?" : (l10n.locale.languageCode == 'gu' ? "શું તમે ખરેખર સાઇન આઉટ કરવા માંગો છો?" : "Are you sure you want to sign out?"), 
          style: GoogleFonts.poppins(color: colorScheme.onSurfaceVariant)
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              l10n.locale.languageCode == 'hi' ? "रद्द करें" : (l10n.locale.languageCode == 'gu' ? "રદ કરો" : "Cancel"), 
              style: GoogleFonts.poppins(color: colorScheme.onSurface, fontWeight: FontWeight.w600)
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              
              // Clear session
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              
              // Navigate to Welcome Screen
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const WelcomeScreen()),
                  (route) => false,
                );
                CustomToast.showSuccess(
                  context, 
                  l10n.locale.languageCode == 'hi' ? "सफलतापूर्वक साइन आउट किया गया" : (l10n.locale.languageCode == 'gu' ? "સફળતાપૂર્વક સાઇન આઉટ થયું" : "Signed out successfully")
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: Text(
              l10n.signOut, 
              style: GoogleFonts.poppins(color: colorScheme.onPrimary, fontWeight: FontWeight.bold)
            ),
          ),
        ],
      ),
    );
  }
  Future<void> _showSwitchAccountSheet(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Ensure current user is in the list
    await _ensureCurrentAccountSaved(prefs);

    List<String> savedContexts = prefs.getStringList('saved_accounts') ?? [];
    List<Map<String, dynamic>> accounts = savedContexts.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
    String currentToken = prefs.getString('auth_token') ?? "";

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24))
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Switch Account", style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...accounts.map((acc) {
               bool isActive = acc['token'] == currentToken;
               return ListTile(
                 leading: CircleAvatar(
                   backgroundColor: isActive ? Colors.blue : Colors.grey.shade200,
                   backgroundImage: (acc['profilePic'] != null && acc['profilePic'].toString().isNotEmpty) 
                       ? NetworkImage(acc['profilePic']) 
                       : null,
                   child: (acc['profilePic'] == null || acc['profilePic'].toString().isEmpty)
                       ? Text(acc['name'][0].toUpperCase(), style: TextStyle(color: isActive ? Colors.white : Colors.grey))
                       : null,
                 ),
                 title: Text(acc['name'], style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                 subtitle: Text(acc['phone'], style: GoogleFonts.poppins(fontSize: 12)),
                 trailing: isActive ? const Icon(Icons.check_circle, color: Colors.blue) : null,
                 onTap: () {
                   Navigator.pop(context);
                   if (!isActive) _switchUser(context, acc);
                 },
               );
            }).toList(),
            
            if (accounts.length < 3)
              ListTile(
                 leading: CircleAvatar(
                   backgroundColor: Colors.grey.shade100,
                   child: const Icon(Icons.add, color: Colors.black),
                 ),
                 title: Text("Add Account", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                 onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const AddAccountScreen()));
                 },
              ),
              
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _ensureCurrentAccountSaved(SharedPreferences prefs) async {
    String token = prefs.getString('auth_token') ?? "";
    if (token.isEmpty) return;
    
    List<String> savedContexts = prefs.getStringList('saved_accounts') ?? [];
    List<Map<String, dynamic>> accounts = savedContexts.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();

    // Check if current token exists in accounts
    bool exists = accounts.any((acc) => acc['token'] == token);
    
    if (!exists) {
       // We need to add the current user. But we might not have all details if they logged in before this feature.
       // We'll try to use what we have or fetch? 
       // For now, let's use placeholders or fetch if possible. 
       // But fetching here is async and might block UI.
       // Let's rely on basic data if available or just save token/phone if we stored it?
       // The Login screen now stores password and userId.
       // We don't have name/phone readily available in prefs usually unless we stored it.
       // Let's assume we can survive with "Student" name until they re-login or use AddAccount.
       // OR, better, we simply don't add them if we lack info, forcing them to re-login via Add Account?
       // No, that's bad UX.
       // Let's create a partial entry.
       accounts.add({
         'token': token,
         'name': "Current User", // We could fetch this via API if we want to be fancy, but keeping it simple.
         'phone': "Signed In",
         'password': prefs.getString('user_password') ?? "",
         'userId': prefs.getString('userId') ?? "",
         'std': prefs.getString('std') ?? "",
       });
       await prefs.setStringList('saved_accounts', accounts.map((e) => jsonEncode(e)).toList());
    }
  }

  Future<void> _switchUser(BuildContext context, Map<String, dynamic> account) async {
     final prefs = await SharedPreferences.getInstance();
     
     // Set new active session
     await prefs.setString('auth_token', account['token']);
     if (account['password'] != null) await prefs.setString('user_password', account['password']);
     if (account['userId'] != null) await prefs.setString('userId', account['userId']);
     if (account['std'] != null) await prefs.setString('std', account['std']);
     
     CustomToast.showSuccess(context, "Switched to ${account['name']}");
     
     Navigator.pushAndRemoveUntil(
       context,
       MaterialPageRoute(builder: (context) => const LandingScreen()),
       (route) => false,
     );
  }
}
