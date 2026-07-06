import 'package:dm_bhatt_tutions/constant/app_images.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dm_bhatt_tutions/l10n/app_localizations.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: CustomAppBar(
        title: l10n.privacyPolicy,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Branding/Security Header in Body
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primary.withOpacity(0.05),
                    colorScheme.surface,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.shield_outlined,
                      size: 60,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Your Privacy Matters",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Last updated: July 2026",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionCard(
                    context,
                    title: "1. Introduction",
                    content:
                        "Welcome to Padhaku – The Learning App. Your privacy is important to us. This Privacy Policy explains how we collect, use, store, and protect your personal information when you use our app.",
                    icon: Icons.info_outline,
                  ),
                  const SizedBox(height: 16),
                  _buildSectionCard(
                    context,
                    title: "2. Information We Collect",
                    content:
                        "We may collect your name, email address, mobile number, profile details, learning progress, quiz results, and basic device information to provide and improve our educational services.",
                    icon: Icons.assignment_outlined,
                  ),
                  const SizedBox(height: 16),
                  _buildSectionCard(
                    context,
                    title: "3. How We Use Your Information",
                    content:
                        "Your information is used to create your account, deliver learning content, track your progress, personalize your experience, provide customer support, send important notifications, and improve our services.",
                    icon: Icons.settings_suggest_outlined,
                  ),
                  const SizedBox(height: 16),
                  _buildSectionCard(
                    context,
                    title: "4. Data Sharing & Security",
                    content:
                        "We do not sell your personal information. Your data may only be shared with trusted service providers or when required by law. We use reasonable security measures to protect your information, although no online system is completely secure.",
                    icon: Icons.lock_outline_rounded,
                  ),
                  const SizedBox(height: 16),
                  _buildSectionCard(
                    context,
                    title: "5. Your Rights",
                    content:
                        "You can update or delete your account at any time through the app. Upon request, your personal data will be deleted within a reasonable period, except where we are required to retain it by law.",
                    icon: Icons.person_outline,
                  ),
                  const SizedBox(height: 16),
                  _buildSectionCard(
                    context,
                    title: "6. Policy Updates",
                    content:
                        "We may update this Privacy Policy from time to time. Any changes will be posted within the app, and your continued use of Padhaku means you accept the updated policy.",
                    icon: Icons.update_rounded,
                  ),
                  const SizedBox(height: 16),
                  _buildSectionCard(
                    context,
                    title: "7. Contact Us",
                    content:
                        "If you have any questions or concerns about this Privacy Policy or your personal information, please contact us at support@padhaku.in.",
                    icon: Icons.mail_outline_rounded,
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(BuildContext context, {
    required String title,
    required String content,
    required IconData icon,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.primary.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: colorScheme.primary, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: colorScheme.onSurfaceVariant,
              height: 1.6,
            ),
            textAlign: TextAlign.justify,
          ),
        ],
      ),
    );
  }
}
