import 'dart:async';
import 'dart:convert';
import 'package:dm_bhatt_tutions/network/api_service.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_loader.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/student_start_exam_form.dart';
import 'package:dm_bhatt_tutions/l10n/app_localizations.dart';
import 'package:dm_bhatt_tutions/utils/app_sizes.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/student_dashboard_widgets.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/five_min_test_screens.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/one_liner_selection_screen.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/true_false_selection_screen.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/match_following_selection_screen.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/student_profile.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/upgrade_plan_screen.dart';
import 'package:dm_bhatt_tutions/utils/guest_utils.dart';

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
    'trueFalseExam': 0,
  };
  bool _isLoading = true;

  late PageController _pageController;
  int _currentSlide = 0;
  Timer? _sliderTimer;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
    _pageController = PageController(viewportFraction: 0.85, initialPage: 0);
    _startAutoSlider();
  }

  @override
  void dispose() {
    _sliderTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoSlider() {
    _sliderTimer?.cancel();
    _sliderTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients) {
        int nextPage = _pageController.page!.round() + 1;
        if (nextPage >= 4) {
          nextPage = 0;
        }
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutCubic,
        );
      }
    });
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
                'trueFalseExam': data['examCounts']['trueFalseExam'] ?? 0,
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
      return const CustomLoader();
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

          // Auto-Playing Exam Cards Slider
          SizedBox(
            height: 195,
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentSlide = index;
                });
                _startAutoSlider(); // Reset timer on manual swipe
              },
              itemCount: 4,
              itemBuilder: (context, index) {
                final isActive = index == _currentSlide;
                
                Widget card;
                if (index == 0) {
                  card = _buildHorizontalCard(
                    context,
                    title: "Main Board Exam",
                    subtitle: "Your next exam is waiting for you.",
                    buttonText: "Start Exam",
                    imageAsset: 'assets/images/robot_logo.png',
                    fallbackIcon: Icons.quiz_outlined,
                    isActive: isActive,
                    onTap: () async {
                      if (!await GuestUtils.canGuestAccessExam(context, 'REGULAR')) return;
                      if (context.mounted) {
                        _checkAndNavigate('mainExam', const StudentStartExamForm());
                      }
                    },
                  );
                } else if (index == 1) {
                  card = _buildHorizontalCard(
                    context,
                    title: l10n.fiveMinRapidTest,
                    subtitle: l10n.studyForFiveMins,
                    buttonText: l10n.startNow,
                    imageAsset: 'assets/images/app_logo.png',
                    fallbackIcon: Icons.timer_outlined,
                    isActive: isActive,
                    onTap: () async {
                      if (!await GuestUtils.canGuestAccessExam(context, 'FIVEMIN')) return;
                      if (context.mounted) {
                        _checkAndNavigate('fiveMinTest', const FiveMinTestSelectionScreen());
                      }
                    },
                  );
                } else if (index == 2) {
                  card = _buildHorizontalCard(
                    context,
                    title: "One-Liner Exam",
                    subtitle: "Speak your answer and test your knowledge!",
                    buttonText: "Start Speaking",
                    imageAsset: 'assets/images/student_boy.png',
                    fallbackIcon: Icons.mic_external_on,
                    isActive: isActive,
                    onTap: () async {
                      if (!await GuestUtils.canGuestAccessExam(context, 'ONELINER')) return;
                      if (context.mounted) {
                        _checkAndNavigate('oneLinerExam', const OneLinerSelectionScreen());
                      }
                    },
                  );
                } else {
                  card = _buildHorizontalCard(
                    context,
                    title: "Match the Following",
                    subtitle: "Connect the correct pairs!",
                    buttonText: "Start Now",
                    imageAsset: 'assets/images/student_girl.png',
                    fallbackIcon: Icons.drag_indicator,
                    isActive: isActive,
                    onTap: () async {
                      if (!await GuestUtils.canGuestAccessExam(context, 'MATCHFOLLOWING')) return;
                      if (context.mounted) {
                        _checkAndNavigate('matchFollowingExam', const MatchFollowingSelectionScreen());
                      }
                    },
                  );
                }

                return AnimatedScale(
                  scale: isActive ? 1.0 : 0.92,
                  duration: const Duration(milliseconds: 350),
                  child: AnimatedOpacity(
                    opacity: isActive ? 1.0 : 0.75,
                    duration: const Duration(milliseconds: 350),
                    child: card,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          // Page Indicator Dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (index) {
              final isActive = index == _currentSlide;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: 8,
                width: isActive ? 20 : 8,
                decoration: BoxDecoration(
                  color: isActive ? colorScheme.primary : colorScheme.primary.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
          blankVerticalSpace24,
          SizedBox(height: screenHeight * 0.05),
        ],
      ),
    );
  }

  Widget _buildHorizontalCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String buttonText,
    required String imageAsset,
    required IconData fallbackIcon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      width: screenWidth * 0.82,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary,
            colorScheme.primary.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(isActive ? 0.35 : 0.15),
            blurRadius: isActive ? 14 : 6,
            offset: Offset(0, isActive ? 8 : 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16, 
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.85),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: onTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: colorScheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: Text(
                    buttonText,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            height: 90,
            width: 75,
            clipBehavior: Clip.hardEdge,
            decoration: const BoxDecoration(), 
            child: Image.asset(
              imageAsset, 
              fit: BoxFit.contain,
              alignment: Alignment.bottomCenter,
              errorBuilder: (context, error, stackTrace) => 
                Icon(fallbackIcon, size: 50, color: Colors.white.withOpacity(0.8)),
            ),
          ),
        ],
      ),
    );
  }
}
