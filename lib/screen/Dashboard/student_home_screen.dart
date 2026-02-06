import 'package:dm_bhatt_tutions/constant/app_images.dart';
import 'package:dm_bhatt_tutions/constant/string_constant.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_filled_button.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/student_start_exam_form.dart';
import 'package:dm_bhatt_tutions/utils/app_localizations.dart';
import 'package:dm_bhatt_tutions/utils/app_sizes.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/student_dashboard_widgets.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/five_min_test_screens.dart';
import 'package:url_launcher/url_launcher.dart';

class StudentHomeScreen extends StatelessWidget {
  const StudentHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final l10n = AppLocalizations.of(context);

    return SingleChildScrollView(
      child: Column(
        children: [
          // Company Banner with Gradient
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              vertical: screenHeight * 0.03, 
              horizontal: screenWidth * 0.04
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary,
                  colorScheme.primary.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withOpacity(0.5),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  "DM Bhatt Group Tuition",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: screenWidth * 0.055, // Responsive Font Size
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
                SizedBox(height: screenHeight * 0.01),
                Text(
                  "Excellence in Education",
                  style: GoogleFonts.poppins(
                    fontSize: screenWidth * 0.035, // Responsive Font Size
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),

            
            // Student Achievers Slider
            const SizedBox(height: 24),
            const StudentAchieverSlider(),
            
            // YouTube Ad
            const YouTubeChannelAd(),
           // const SizedBox(height: 18),
            blankVerticalSpace24,

          // Daily Time Table Section
          // Padding(
          //   padding: const EdgeInsets.symmetric(horizontal: 20),
          //   child: Column(
          //     crossAxisAlignment: CrossAxisAlignment.start,
          //     children: [
          //       Row(
          //         children: [
          //           Container(
          //             height: MediaQuery.of(context).size.height * 0.03,
          //             width: 4,
          //             decoration: BoxDecoration(
          //               color: Colors.orange,
          //               borderRadius: BorderRadius.circular(2),
          //             ),
          //           ),
          //           const SizedBox(width: 8),
          //           Text(
          //             l10n.dailyTimeTable,
          //             style: GoogleFonts.poppins(
          //               fontSize: screenWidth * 0.045, // Responsive Font Size
          //               fontWeight: FontWeight.w600,
          //               color: colorScheme.onSurface,
          //             ),
          //           ),
          //         ],
          //       ),
          //       blankVerticalSpace16,
          //       Container(
          //         width: double.infinity,
          //         decoration: BoxDecoration(
          //           color: colorScheme.surfaceContainer, // Dynamic Card
          //           borderRadius: BorderRadius.circular(20),
          //           boxShadow: [
          //             BoxShadow(
          //               color: colorScheme.shadow.withOpacity(0.05),
          //               blurRadius: 20,
          //               offset: const Offset(0, 5),
          //             ),
          //           ],
          //         ),
          //         child: Column(
          //           children: [
          //             _buildTimeTableItem(
          //               context,
          //               "Mathematics",
          //               "10:00 AM - 11:30 AM",
          //               Icons.calculate_outlined,
          //               Colors.blue,
          //             ),
          //             Padding(
          //               padding: const EdgeInsets.symmetric(horizontal: 16),
          //               child: Divider(height: 1, color: colorScheme.outlineVariant.withOpacity(0.2)),
          //             ),
          //             _buildTimeTableItem(
          //               context,
          //               "Physics",
          //               "12:00 PM - 01:30 PM",
          //               Icons.science_outlined,
          //               Colors.purple,
          //             ),
          //           ],
          //         ),
          //       ),
          //     ],
          //   ),
          // ),
          // blankVerticalSpace32,

          // Start Exam Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainer, // Dynamic Card
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: colorScheme.primary.withOpacity(0.2)),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.1), // Subtle theme tint
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.quiz_outlined,
                      size: 32,
                      color: colorScheme.primary,
                    ),
                  ),
                  blankVerticalSpace16,
                  Text(
                    l10n.nextExamWaiting,
                    style: GoogleFonts.poppins(
                      fontSize: screenWidth * 0.04, // Responsive Font Size
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  blankVerticalSpace24,
                  SizedBox(
                    width: double.infinity,
                    height: MediaQuery.of(context).size.height * 0.06,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const StudentStartExamForm(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          l10n.startExam.toUpperCase(),
                          style: GoogleFonts.poppins(
                            fontSize: screenWidth * 0.035, // Responsive Font Size
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          blankVerticalSpace24,

          // 5 Min Test Section
           Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                     colorScheme.primary,
                     colorScheme.primary.withOpacity(0.7)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                   Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.locale.languageCode == 'en' ? "5 Min Rapid Test" : (l10n.locale.languageCode == 'hi' ? "5 मिनट रैपिड टेस्ट" : "5 મિનિટ રેપિડ ટેસ્ટ"),
                          style: GoogleFonts.poppins(
                            fontSize: screenWidth * 0.045, 
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.locale.languageCode == 'en' ? "Study for 5 mins & take a quick quiz!" : (l10n.locale.languageCode == 'hi' ? "5 मिनट तक अध्ययन करें और एक त्वरित प्रश्नोत्तरी लें!" : "5 મિનિટ માટે અભ્યાસ કરો અને ઝડપી ક્વિઝ લો!"),
                          style: GoogleFonts.poppins(
                            fontSize: screenWidth * 0.032,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                         const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                             Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const FiveMinTestSelectionScreen(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.surface,
                            foregroundColor: colorScheme.primary,
                             shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          ),
                          child: Text(l10n.locale.languageCode == 'en' ? "Start Now" : (l10n.locale.languageCode == 'hi' ? "अभी शुरू करें" : "હમણાં શરૂ કરો"), style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                   ),
                   Container(
                     height: 100,
                     width: 90,
                     clipBehavior: Clip.hardEdge,
                     decoration: const BoxDecoration(), // Just for clip
                     child: Image.asset(
                       'assets/images/app_logo.png', 
                       fit: BoxFit.fitWidth,
                       alignment: Alignment.topCenter, // Alignment top to crop bottom text
                       errorBuilder: (context, error, stackTrace) => 
                          Icon(Icons.timer_outlined, size: 60, color: Colors.white.withOpacity(0.8)),
                     ),
                   ),
                ],
              ),
            ),
          ),
          blankVerticalSpace24,

          // Meet Our Influencer Section

          
          SizedBox(height: screenHeight * 0.05),
        ],
      ),
    );
  }

  Widget _buildTimeTableItem(BuildContext context,
      String subject, String time, IconData icon, Color color) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subject,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: colorScheme.onSurface, // Dynamic Text
                  ),
                ),
                Text(
                  time,
                  style: GoogleFonts.poppins(
                    color: colorScheme.onSurfaceVariant, // Dynamic Text
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios, size: 14, color: colorScheme.onSurfaceVariant),
        ],
      ),
    );
  }
}
