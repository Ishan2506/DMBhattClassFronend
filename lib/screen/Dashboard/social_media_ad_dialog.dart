import 'package:dm_bhatt_tutions/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class SocialMediaAdDialog extends StatelessWidget {
  const SocialMediaAdDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: contentBox(context, screenWidth),
    );
  }

  Widget contentBox(BuildContext context, double screenWidth) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor, // Theme aware background
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            offset: Offset(0, 10),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Close Button Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.rateUs, 
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).pop();
                },
                child: const Icon(Icons.close, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // WhatsApp Button
          _buildSocialButton(
            context,
            screenWidth,
            l10n.followOnWhatsApp, // Using followOnWhatsApp key
            l10n.clickHere,
            Icons.chat_bubble_outline, // Using chat bubble as generic replacement for WhatsApp if logo unavailable
            [const Color(0xFF25D366), const Color(0xFF128C7E)], // WhatsApp Green Gradients
            "https://wa.me/9106315912",
          ),
          const SizedBox(height: 12),

          // Instagram Button
          _buildSocialButton(
            context,
            screenWidth,
            l10n.followOnInstagram,
            l10n.clickHere,
            FontAwesomeIcons.instagram, // Instagram real logo
            [const Color(0xFF833AB4), const Color(0xFFE1306C), const Color(0xFFF77737)], // Insta Gradients
            "https://www.instagram.com/bondbyte.in/",
          ),
          const SizedBox(height: 12),

          // Facebook Button
          _buildSocialButton(
            context,
            screenWidth,
            l10n.followOnFacebook,
            l10n.clickHere,
            Icons.facebook, // Material Icons usually has facebook, if not fallback to public
            [const Color(0xFF1877F2), const Color(0xFF0D47A1)], // FB Blue Gradients
            "https://www.instagram.com/bondbyte.in/", // As requested by user: same link as insta
          ),
        ],
      ),
    );
  }

  Widget _buildSocialButton(
    BuildContext context,
    double screenWidth,
    String title,
    String subtitle,
    IconData icon,
    List<Color> gradientColors,
    String urlString,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          final Uri url = Uri.parse(urlString);
          if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
            debugPrint('Could not launch $url');
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: gradientColors.first.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: gradientColors.first, // Icon takes primary color of button
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: screenWidth * 0.035,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: screenWidth * 0.025,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
