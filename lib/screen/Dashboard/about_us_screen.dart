import 'package:dm_bhatt_tutions/constant/app_images.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dm_bhatt_tutions/l10n/app_localizations.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: CustomAppBar(
        title: l10n.aboutUs,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Branding Header in Body
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
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Image.asset(imgAppLogo, height: 70),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Excellence in Education",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.primary,
                      letterSpacing: 1.2,
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
                  // Mission Section
                  _buildSectionCard(
                    context,
                    title: l10n.aboutUsHeader,
                    content: l10n.aboutUsDescription,
                    icon: Icons.rocket_launch_rounded,
                  ),
                  
                  const SizedBox(height: 24),

                  // Features Grid
                  Text(
                    "Our Core Values",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildMiniFeature(context, icon: Icons.psychology, label: "Interactive"),
                      _buildMiniFeature(context, icon: Icons.history_edu, label: "Practical"),
                      _buildMiniFeature(context, icon: Icons.auto_awesome, label: "Modern"),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // Unique Staggered Team Section
                  Text(
                    "Our Educational Leaders",
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 24),

                  _buildModernLeaderCard(
                    context,
                    name: l10n.influencerName,
                    role: "Visionary & Lead Educator",
                    description: "Pioneering interactive learning concepts for over a decade.",
                    image: imgInfluencerDmBhattNew,
                    isRightAligned: false,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  _buildModernLeaderCard(
                    context,
                    name: "Hetvi Bhatt",
                    role: "Foundation Specialist",
                    description: "Specializing in building strong academic fundamentals for students.",
                    image: imgInfluencerHetvi, 
                    isRightAligned: true,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  _buildModernLeaderCard(
                    context,
                    name: "Ravi Shah",
                    role: "Modern Tech Educator",
                    description: "Integrating modern technology with traditional teaching methods.",
                    image: imgInfluencerRavi, 
                    isRightAligned: false,
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

  Widget _buildModernLeaderCard(BuildContext context, {
    required String name, 
    required String role, 
    required String description, 
    required String image,
    required bool isRightAligned,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      height: 140,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Stack(
        children: [
          // Background Glow
          Positioned(
            left: isRightAligned ? null : -20,
            right: isRightAligned ? -20 : null,
            top: -20,
            child: CircleAvatar(
              radius: 60,
              backgroundColor: colorScheme.primary.withOpacity(0.05),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              textDirection: isRightAligned ? TextDirection.rtl : TextDirection.ltr,
              children: [
                // Profile Circle with Floating Effect
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withOpacity(0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(image, fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(width: 20),
                // Text Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: isRightAligned ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        role,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        description,
                        textAlign: isRightAligned ? TextAlign.right : TextAlign.left,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(BuildContext context, {required String title, required String content, required IconData icon}) {
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
              Icon(icon, color: colorScheme.primary, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            content,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: colorScheme.onSurfaceVariant,
              height: 1.6,
            ),
            textAlign: TextAlign.justify,
          ),
        ],
      ),
    );
  }

  Widget _buildMiniFeature(BuildContext context, {required IconData icon, required String label}) {
     final colorScheme = Theme.of(context).colorScheme;
     return Expanded(
       child: Column(
         children: [
           Container(
             padding: const EdgeInsets.all(12),
             decoration: BoxDecoration(
               color: colorScheme.surfaceContainerHighest,
               shape: BoxShape.circle,
             ),
             child: Icon(icon, color: colorScheme.primary, size: 24),
           ),
           const SizedBox(height: 8),
           Text(
             label,
             style: GoogleFonts.poppins(
               fontSize: 12,
               fontWeight: FontWeight.w500,
               color: colorScheme.onSurface,
             ),
           ),
         ],
       ),
     );
  }
}
