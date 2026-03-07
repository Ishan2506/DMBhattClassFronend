import 'package:dm_bhatt_tutions/screen/Dashboard/student_product_history_screen.dart';
import 'package:dm_bhatt_tutions/network/api_service.dart' as api;
import 'package:dm_bhatt_tutions/screen/Dashboard/upgrade_plan_screen.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/student_exam_history_screen.dart';
import 'package:dm_bhatt_tutions/bloc/theme/theme_cubit.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/settings_screen.dart';
import 'package:dm_bhatt_tutions/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/leaderboard_screen.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/about_us_screen.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/events_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:dm_bhatt_tutions/utils/custom_toast.dart';
import 'package:dm_bhatt_tutions/constant/app_images.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/mind_games_screen.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/refer_and_earn_screen.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/school_papers_screen.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/board_paper_screen.dart';
// import 'package:dm_bhatt_tutions/screen/Dashboard/ready_reporting_card_screen.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/one_liner_selection_screen.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/one_liner_history_screen.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/mind_map_selection_screen.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/material_screen.dart';


class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main Navigation Grid
            Text(
              "Explore Features",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                if (!api.ApiService.isGuest) ...[
                  Expanded(
                    child: _FeatureGridItem(
                      title: l10n.studentActivities,
                      icon: Icons.school_rounded,
                      color: Colors.blue,
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  const _StudentActivitiesScreen())),
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
                Expanded(
                  child: _FeatureGridItem(
                    title: l10n.appInformation,
                    icon: Icons.info_rounded,
                    color: Colors.orange,
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const _AppInfoScreen())),
                  ),
                ),
                if (api.ApiService.isGuest) const Spacer(),
              ],
            ),

            const SizedBox(height: 32),

            // Uniquely Identified Influencer Section
            const _InfluencerCarousel(),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _StudentActivitiesScreen extends StatelessWidget {
  const _StudentActivitiesScreen();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: CustomAppBar(
        title: l10n.studentActivities,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _MoreScreenItem(
              title: l10n.myArea,
              value: "",
              icon: Icons.person_pin,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const _MyAreaScreen()),
                );
              },
            ),
            // _MoreScreenItem(
            //   title: l10n.events,
            //   value: "",
            //   icon: Icons.event,
            //   onTap: () {
            //     Navigator.push(
            //       context,
            //       MaterialPageRoute(
            //           builder: (context) => const EventsScreen()),
            //     );
            //   },
            // ),
            _MoreScreenItem(
              title: l10n.history,
              value: "",
              icon: Icons.history,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const _HistoryMenuScreen()),
                );
              },
            ),
            _MoreScreenItem(
              title: l10n.material,
              value: "",
              icon: Icons.auto_stories_outlined,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const MaterialScreen()),
                );
              },
            ),
            _MoreScreenItem(
              title: l10n.mindGames,
              value: "",
              icon: Icons.games_outlined,
              onTap: () {
                 Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const MindGamesScreen()),
                );
              },
            ),
             _MoreScreenItem(
              title: "Mind Map", 
              value: "",
              icon: Icons.hub_outlined,
              onTap: () {
                 Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const MindMapSelectionScreen()), // Need to ensure it's imported
                );
              },
            ),
            _MoreScreenItem(
              title: l10n.readyReportingCard,
              value: "",
              icon: Icons.bar_chart_rounded,
              onTap: () {
                 CustomToast.showInfo(context, l10n.comingSoon);
              },
            ),
            // _MoreScreenItem(
            //   title: "One-Liner Exam",
            //   value: "",
            //   icon: Icons.mic_external_on,
            //   onTap: () {
            //      Navigator.push(
            //       context,
            //       MaterialPageRoute(
            //           builder: (context) => const OneLinerSelectionScreen()),
            //     );
            //   },
            // ),
          ],
        ),
      ),
    );
  }
}

class _AppInfoScreen extends StatelessWidget {
  const _AppInfoScreen();

  void _shareApp() {
    Share.share(
        'Check out D. M. Bhatt Tuition Classes App! Download now: https://play.google.com/store/apps/details?id=com.dmbhatt.tutions');
  }

  void _showRateUsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _RateUsDialog(),
    );
  }

  void _showFollowUsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.followUsOn,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSocialIcon(
                  context,
                  icon: FontAwesomeIcons.facebook,
                  color: const Color(0xFF1877F2),
                  url: "https://www.facebook.com/dmbhatttutionclasses",
                  label: l10n.facebook,
                ),
                _buildSocialIcon(
                  context,
                  icon: FontAwesomeIcons.instagram,
                  color: const Color(0xFFE4405F),
                  url: "https://www.instagram.com/dmbhatttutions",
                  label: l10n.instagram,
                ),
                _buildSocialIcon(
                  context,
                  icon: FontAwesomeIcons.youtube,
                  color: const Color(0xFFFF0000),
                  url: "https://www.youtube.com/@dmbhatteducationchannel",
                  label: l10n.youtube,
                ),
                _buildSocialIcon(
                  context,
                  icon: FontAwesomeIcons.whatsapp,
                  color: const Color(0xFF25D366),
                  url: "https://wa.me/919876543210",
                  label: l10n.whatsapp,
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      );
      },
    );
  }

  Widget _buildSocialIcon(BuildContext context,
      {required IconData icon,
      required Color color,
      required String url,
      required String label}) {
    return InkWell(
      onTap: () async {
        final Uri uri = Uri.parse(url);
        if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
          debugPrint('Could not launch $url');
        }
      },
      borderRadius: BorderRadius.circular(50),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: FaIcon(icon, color: color, size: 30),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.poppins(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: CustomAppBar(
        title: l10n.appInformation,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _MoreScreenItem(
              title: l10n.aboutUs,
              value: "",
              icon: Icons.info_outline,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const AboutUsScreen()),
                );
              },
            ),
            if (!api.ApiService.isGuest) ...[
              _MoreScreenItem(
                title: l10n.upgradePlan,
                value: "",
                icon: Icons.upgrade_rounded,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const UpgradePlanScreen()),
                  );
                },
              ),
              _MoreScreenItem(
                title: l10n.referAndEarn,
                value: "",
                icon: Icons.diversity_3,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ReferAndEarnScreen()),
                  );
                },
              ),
            ],
          
            _MoreScreenItem(
              title: l10n.shareApp,
              value: "",
              icon: Icons.share,
              onTap: _shareApp,
            ),
            _MoreScreenItem(
              title: l10n.rateUs,
              value: "",
              icon: Icons.star_rate_rounded,
              onTap: () => _showRateUsDialog(context),
            ),
            _MoreScreenItem(
              title: l10n.followUs,
              value: "",
              icon: Icons.rss_feed_rounded,
              onTap: () => _showFollowUsSheet(context),
            ),
              _MoreScreenItem(
              title: l10n.settings,
              value: "",
              icon: Icons.settings,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const SettingsScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _RateUsDialog extends StatefulWidget {
  @override
  State<_RateUsDialog> createState() => _RateUsDialogState();
}

class _RateUsDialogState extends State<_RateUsDialog> {
  int _selectedRating = -1;
  final TextEditingController _feedbackController = TextEditingController();

  List<Map<String, dynamic>> _emojis(AppLocalizations l10n) => [
    {"icon": "😡", "label": l10n.terrible, "score": 1},
    {"icon": "🙁", "label": l10n.bad, "score": 2},
    {"icon": "😐", "label": l10n.okay, "score": 3},
    {"icon": "🙂", "label": l10n.good, "score": 4},
    {"icon": "😍", "label": l10n.great, "score": 5},
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final emojis = _emojis(l10n);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: colorScheme.surface,
      insetPadding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20),
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
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                Icon(Icons.star_rounded, color: colorScheme.onPrimary, size: 48),
                const SizedBox(height: 8),
                Text(
                  l10n.rateYourExperience,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: colorScheme.onPrimary,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(
                  l10n.howDoYouFeel,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                      color: colorScheme.onSurfaceVariant, fontSize: 14),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: emojis.map((e) {
                    final isSelected = _selectedRating == e['score'];
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedRating = e['score'];
                        });
                      },
                      child: AnimatedScale(
                        scale: isSelected ? 1.2 : 1.0,
                        duration: const Duration(milliseconds: 200),
                        child: Column(
                          children: [
                            Text(
                              e['icon'],
                              style: TextStyle(
                                fontSize: 32,
                                color: isSelected ? null : colorScheme.onSurface.withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                if (_selectedRating != -1)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      emojis[_selectedRating - 1]['label'],
                      style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary),
                    ),
                  ),
                const SizedBox(height: 24),
                TextField(
                  controller: _feedbackController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: l10n.feedbackHint,
                    hintStyle:
                        GoogleFonts.poppins(fontSize: 13, color: colorScheme.onSurfaceVariant.withOpacity(0.6)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colorScheme.outlineVariant),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colorScheme.primary),
                    ),
                    filled: true,
                    fillColor: colorScheme.surfaceContainer,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(l10n.cancel,
                            style: GoogleFonts.poppins(
                                color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (_selectedRating != -1) {
                            CustomToast.showSuccess(
                                context, l10n.thankYouFeedback);
                            Navigator.pop(context);
                          } else {
                            CustomToast.showError(
                                context, l10n.selectRatingError);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          elevation: 0,
                          shape:
                              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(l10n.submit,
                            style: GoogleFonts.poppins(
                                color: colorScheme.onPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MyAreaScreen extends StatelessWidget {
  const _MyAreaScreen();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: CustomAppBar(
        title: l10n.myArea,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _MoreScreenItem(
                title: l10n.leaderboard,
                value: "",
                icon: Icons.leaderboard,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const LeaderboardScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryMenuScreen extends StatelessWidget {
  const _HistoryMenuScreen();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: CustomAppBar(
        title: l10n.history,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _MoreScreenItem(
                title: l10n.examHistory,
                value: "",
                icon: Icons.history_edu,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const StudentExamHistoryScreen()),
                  );
                },
              ),
              _MoreScreenItem(
                title: l10n.productHistory,
                value: "",
                icon: Icons.shopping_bag,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            const StudentProductHistoryScreen()),
                  );
                },
              ),
              _MoreScreenItem(
                title: "One-Liner History",
                value: "",
                icon: Icons.history_rounded,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const OneLinerHistoryScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoreScreenItem extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  const _MoreScreenItem({
    required this.title,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainer, // Dynamic Card Color
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
                  color: colorScheme.onSurface, // Dynamic Text
                ),
              ),
            ),
            if (value.isNotEmpty) ...[
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: colorScheme.onSurfaceVariant, // Dynamic Text
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
            ],
            Icon(Icons.arrow_forward_ios,
                size: 14, color: colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _InfluencerCarousel extends StatefulWidget {
  const _InfluencerCarousel();

  @override
  State<_InfluencerCarousel> createState() => _InfluencerCarouselState();
}

class _InfluencerCarouselState extends State<_InfluencerCarousel> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _teamMembers = [
    {
      "name": "D.M.BHATT",
      "role": "Visionary & Mentor",
      "description": "Inspiring Excellence in Education",
      "imagePath": imgInfluencerDmBhattNew,
      "instagramUrl": "https://www.instagram.com/dmbhattsir/"
    },
    {
      "name": "Hetvi Bhatt",
      "role": "Academic Specialist",
      "description": "Mastering Foundation Learning",
      "imagePath": imgInfluencerHetvi, // TODO: Update image if available
      "instagramUrl": "https://www.instagram.com/hetvee_bhatt_/"
    },
    {
      "name": "Keyur Suthar",
      "role": "Academic Specialist",
      "description": "Mastering Foundation Learning",
      "imagePath": imgInfluencerKeyur,
      "instagramUrl": "https://www.instagram.com/keyur.s.99/"
    },
    {
      "name": "Ravi Shah",
      "role": "Academic Specialist",
      "description": "Mastering Foundation Learning",
      "imagePath": imgInfluencerRavi, // TODO: Update image if available
      "instagramUrl": "https://www.instagram.com/ravi_maths_/"
    },
    {
      "name": "Ankit Kayastha",
      "role": "Digital Educator",
      "description": "Engaging Future Technology Experts",
      "imagePath": imgInfluencerAnkit,
      "instagramUrl": "https://www.instagram.com/ak94sir/"
    },
  ];

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
  }

  void _startAutoScroll() async {
    while (mounted) {
      await Future.delayed(const Duration(seconds: 4));
      if (mounted) {
        int nextPage = _currentPage + 1;
        if (nextPage >= _teamMembers.length) {
          nextPage = 0;
          if (_pageController.hasClients) {
            _pageController.animateToPage(
              nextPage,
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeIn,
            );
          }
        } else {
          if (_pageController.hasClients) {
            _pageController.animateToPage(
              nextPage,
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeInOut,
            );
          }
        }
        setState(() {
          _currentPage = nextPage;
        });
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: colorScheme.primary.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "OUR EDUCATIONAL TEAM",
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: colorScheme.primary,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 280,
            child: PageView.builder(
              controller: _pageController,
              itemCount: _teamMembers.length,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemBuilder: (context, index) {
                final member = _teamMembers[index];
                return _buildUniqueInfluencerCard(
                  context,
                  name: member["name"]!,
                  role: member["role"]!,
                  description: member["description"]!,
                  imagePath: member["imagePath"]!,
                  instagramUrl: member["instagramUrl"]!,
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          // Modern Dot Indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_teamMembers.length, (index) {
              bool isActive = _currentPage == index;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: isActive ? 20 : 8,
                height: 6,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: isActive
                      ? colorScheme.primary
                      : colorScheme.primary.withOpacity(0.2),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildUniqueInfluencerCard(BuildContext context, {
    required String name, 
    required String role,
    required String description,
    required String imagePath, 
    required String instagramUrl
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // Outer glow
            Container(
              width: 135,
              height: 135,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.primary.withOpacity(0.05),
              ),
            ),
            // Decorative ring
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: colorScheme.primary.withOpacity(0.2),
                  width: 1,
                ),
              ),
            ),
            // Profile image with thick border
            Container(
              width: 105,
              height: 105,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withOpacity(0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  )
                ],
              ),
              child: ClipOval(
                child: Image.asset(imagePath, fit: BoxFit.cover),
              ),
            ),
            // Verified Badge
            Positioned(
              bottom: 5,
              right: 5,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 10),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          name,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        Text(
          role,
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: colorScheme.onSurface.withOpacity(0.8),
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: () async {
            if (await canLaunchUrl(Uri.parse(instagramUrl))) {
              await launchUrl(Uri.parse(instagramUrl), mode: LaunchMode.externalApplication);
            }
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colorScheme.primary, colorScheme.primary.withOpacity(0.8)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(FontAwesomeIcons.instagram, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text(
                  "Connect",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FeatureGridItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _FeatureGridItem({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        height: 130,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
