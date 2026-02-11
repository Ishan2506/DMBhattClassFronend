import 'package:dm_bhatt_tutions/bloc/theme/theme_cubit.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/update_password_screen.dart';
import 'package:dm_bhatt_tutions/l10n/app_localizations.dart';
import 'package:dm_bhatt_tutions/utils/custom_toast.dart';
import 'package:dm_bhatt_tutions/screen/authentication/welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/landing_screen.dart';
import 'dart:convert';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    
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
                themeText = l10n.light;
              } else if (state.themeMode == ThemeMode.dark) {
                themeText = l10n.dark;
              } else {
                themeText = l10n.system;
              }

              String langText;
              if (state.locale.languageCode == 'gu') langText = l10n.gujarati;
              else if (state.locale.languageCode == 'hi') langText = l10n.hindi;
              else if (state.locale.languageCode == 'ta') langText = l10n.tamil;
              else if (state.locale.languageCode == 'mr') langText = l10n.marathi;
              else langText = l10n.english;

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
                    title: l10n.themeStyle,
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
                    title: l10n.updatePassword,
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
    final l10n = AppLocalizations.of(context)!;

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
                  l10n.themeMode, 
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
                    _buildRadioOption(context, l10n.lightMode, ThemeMode.light),
                    _buildRadioOption(context, l10n.darkMode, ThemeMode.dark),
                    _buildRadioOption(context, l10n.systemDefault, ThemeMode.system),
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
    final l10n = AppLocalizations.of(context)!;
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
                  l10n.selectThemeStyle, 
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
                      _buildStyleOption(context, l10n.classic, AppThemeStyle.classic),
                      _buildStyleOption(context, l10n.ocean, AppThemeStyle.ocean),
                      _buildStyleOption(context, l10n.sunset, AppThemeStyle.sunset),
                      _buildStyleOption(context, l10n.forest, AppThemeStyle.forest),
                      _buildStyleOption(context, l10n.lavender, AppThemeStyle.lavender),
                      _buildStyleOption(context, l10n.midnight, AppThemeStyle.midnight),
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
    final l10n = AppLocalizations.of(context)!;

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
                  l10n.selectLanguage, 
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
                    _buildLangOption(context, l10n.english, const Locale('en')),
                    _buildLangOption(context, l10n.hindi, const Locale('hi')),
                    _buildLangOption(context, l10n.gujarati, const Locale('gu')),
                    _buildLangOption(context, l10n.tamil, const Locale('ta')),
                    _buildLangOption(context, l10n.marathi, const Locale('mr')),
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
    final l10n = AppLocalizations.of(context)!;

    final colorScheme = Theme.of(context).colorScheme;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surfaceContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l10n.signOut, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
        content: Text(
          l10n.areYouSureSignOut, 
          style: GoogleFonts.poppins(color: colorScheme.onSurfaceVariant)
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              l10n.cancel, 
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
                  l10n.signOutSuccess
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
}
