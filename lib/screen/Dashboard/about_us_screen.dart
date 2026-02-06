import 'package:dm_bhatt_tutions/constant/app_images.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: const CustomAppBar(
        title: "About Us",
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Image (Optional, using logo for now if no specific header)
             Center(
              child: Container(
                height: 120,
                width: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Image.asset(imgAppLogo),
              ),
            ),
             const SizedBox(height: 24),

            // Description Section
            Text(
              "D. M. Bhatt Tuition Classes",
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Welcome to D. M. Bhatt Tuition Classes, your partner in academic excellence. We are dedicated to providing high-quality education and guidance to students, helping them achieve their potential and secure a bright future.\n\nOur experienced faculty and comprehensive curriculum ensure that every student receives personalized attention and support. Join us to embark on a journey of learning and success.",
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
                height: 1.6,
              ),
              textAlign: TextAlign.justify,
            ),
            
            const SizedBox(height: 40),

            // Meet Our Influencer Section
            Center(
              child: Text(
                "MEET OUR INFLUENCER",
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface.withOpacity(0.6),
                  letterSpacing: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: GestureDetector(
                onTap: () async {
                  const url = 'https://www.instagram.com/dmbhattsir/';
                  if (await canLaunchUrl(Uri.parse(url))) {
                    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                  }
                },
                child: Column(
                  children: [
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        image: const DecorationImage(
                          image: AssetImage(imgInfluencer),
                          fit: BoxFit.cover,
                        ),
                        boxShadow: [
                           BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "D.M. Bhatt Sir",
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.link, size: 16, color: Colors.blue.shade600),
                        const SizedBox(width: 4),
                        Text(
                          "Follow on Instagram",
                          style: GoogleFonts.poppins(
                             fontSize: 14,
                             color: Colors.blue.shade600,
                             fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 40),
            
          ],
        ),
      ),
    );
  }
}
