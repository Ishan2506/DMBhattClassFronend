import 'dart:convert';
import 'package:dm_bhatt_tutions/network/api_service.dart';
import 'package:dm_bhatt_tutions/constant/app_images.dart';
import 'package:dm_bhatt_tutions/constant/string_constant.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_filled_button.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_loader.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/student_start_exam_form.dart';
import 'package:dm_bhatt_tutions/l10n/app_localizations.dart';
import 'package:dm_bhatt_tutions/utils/app_sizes.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/student_dashboard_widgets.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/five_min_test_screens.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/one_liner_exam_screen.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/one_liner_selection_screen.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/mind_map_selection_screen.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/upgrade_plan_screen.dart';
import 'package:dm_bhatt_tutions/utils/guest_utils.dart';
import 'package:dm_bhatt_tutions/utils/custom_toast.dart';
import 'package:url_launcher/url_launcher.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  bool _isPaid = false;
  bool _isGuest = false;
  Map<String, int> _examCounts = {
    'mainExam': 0,
    'fiveMinTest': 0,
    'oneLinerExam': 0,
  };
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final response = await ApiService.getProfile(forceRefresh: true);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            debugPrint("[DEBUG] Home Profile Data: $data");
            _isPaid = data['user']?['isPaid'] ?? false;
            _isGuest = ApiService.isGuest;
            if (data['examCounts'] != null) {
              _examCounts = {
                'mainExam': data['examCounts']['mainExam'] ?? 0,
                'fiveMinTest': data['examCounts']['fiveMinTest'] ?? 0,
                'oneLinerExam': data['examCounts']['oneLinerExam'] ?? 0,
              };
              debugPrint("[DEBUG] Home _examCounts: $_examCounts");
            }
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching profile: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _checkAndNavigate(String type, Widget targetScreen) {
    if (!_isGuest && !_isPaid && (_examCounts[type] ?? 0) >= 1) {
      _showUpgradeDialog();
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => targetScreen),
    ).then((_) => _fetchProfile()); // Refresh counts after returning
  }

  void _showUpgradeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Limit Reached",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          "You have already used your 1 free attempt for this exam. Please upgrade your plan for unlimited access.",
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Later", style: GoogleFonts.poppins(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UpgradePlanScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text("Upgrade Now", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final colorScheme = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final l10n = AppLocalizations.of(context)!;

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
                  l10n.dmBhattGroupTuition,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: screenWidth * 0.055, 
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
                SizedBox(height: screenHeight * 0.01),
                Text(
                  l10n.excellenceInEducation,
                  style: GoogleFonts.poppins(
                    fontSize: screenWidth * 0.035, 
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          const QuickAccessCategories(),
          const YouTubeChannelAd(),
          blankVerticalSpace24,

          // Start Exam Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainer,
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
                      color: colorScheme.primary.withOpacity(0.1),
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
                      fontSize: screenWidth * 0.04,
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  blankVerticalSpace24,
                  SizedBox(
                    width: double.infinity,
                    height: screenHeight * 0.06,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (!await GuestUtils.canGuestAccessExam(context, 'REGULAR')) return;
                        if (context.mounted) {
                          _checkAndNavigate('mainExam', const StudentStartExamForm());
                        }
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
                            fontSize: screenWidth * 0.035,
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
                          l10n.fiveMinRapidTest,
                          style: GoogleFonts.poppins(
                            fontSize: screenWidth * 0.045, 
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.studyForFiveMins,
                          style: GoogleFonts.poppins(
                            fontSize: screenWidth * 0.032,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () async {
                            if (!await GuestUtils.canGuestAccessExam(context, 'FIVEMIN')) return;
                            if (context.mounted) {
                              _checkAndNavigate('fiveMinTest', const FiveMinTestSelectionScreen());
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.surface,
                            foregroundColor: colorScheme.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          ),
                          child: Text(l10n.startNow, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    height: 100,
                    width: 90,
                    clipBehavior: Clip.hardEdge,
                    decoration: const BoxDecoration(), 
                    child: Image.asset(
                      'assets/images/app_logo.png', 
                      fit: BoxFit.fitWidth,
                      alignment: Alignment.topCenter,
                      errorBuilder: (context, error, stackTrace) => 
                        Icon(Icons.timer_outlined, size: 60, color: Colors.white.withOpacity(0.8)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          blankVerticalSpace24,

          // One-Liner Exam Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.orange.shade700,
                    Colors.orange.shade400
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.3),
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
                          "One-Liner Exam",
                          style: GoogleFonts.poppins(
                            fontSize: screenWidth * 0.045, 
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Speak your answer and test your knowledge!",
                          style: GoogleFonts.poppins(
                            fontSize: screenWidth * 0.032,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () async {
                            if (!await GuestUtils.canGuestAccessExam(context, 'ONELINER')) return;
                            if (context.mounted) {
                              _checkAndNavigate('oneLinerExam', const OneLinerSelectionScreen());
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.orange.shade700,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          ),
                          child: Text("Start Speaking", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 100,
                    width: 90,
                    child: Icon(Icons.mic_external_on, size: 60, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
          blankVerticalSpace24,
          SizedBox(height: screenHeight * 0.05),
        ],
      ),
    );
  }
}
