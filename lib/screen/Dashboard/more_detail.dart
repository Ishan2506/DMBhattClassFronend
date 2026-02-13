import 'package:dm_bhatt_tutions/screen/Dashboard/student_product_history_screen.dart';
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
import 'package:dm_bhatt_tutions/screen/Dashboard/ready_reporting_card_screen.dart';

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
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section 1: Student Activities
            _MoreScreenItem(
              title: l10n.studentActivities,
              value: "",
              icon: Icons.school,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const _StudentActivitiesScreen()),
                );
              },
            ),

            // Section 2: App Information
            _MoreScreenItem(
              title: l10n.appInformation,
              value: "",
              icon: Icons.info_outline_rounded,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const _AppInfoScreen()),
                );
              },
            ),

            const SizedBox(height: 30),

            // Meet Our Influencer Section
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
            _MoreScreenItem(
              title: l10n.events,
              value: "",
              icon: Icons.event,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const EventsScreen()),
                );
              },
            ),
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
              title: l10n.schoolPapers,
              value: "",
              icon: Icons.note_alt_outlined,
              onTap: () {
                 Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const SchoolPapersScreen()),
                );
              },
            ),
            _MoreScreenItem(
              title: l10n.boardPapers,
              value: "",
              icon: Icons.assignment_outlined,
              onTap: () {
                 Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const BoardPaperScreen()),
                );
              },
            ),
            _MoreScreenItem(
              title: "Ready Reporting Card", // TODO: Add to l10n
              value: "",
              icon: Icons.bar_chart_rounded,
              onTap: () {
                 Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ReadyReportingCardScreen()),
                );
              },
            ),
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
            _MoreScreenItem(
              title: l10n.upgradePlan,
              value: "",
              icon: Icons.upgrade_rounded,
               onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const UpgradePlanScreen()), // Navigate to Upgrade Plan
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
                  const Color(0xFF1565C0), // Deep Blue
                  const Color(0xFF42A5F5), // Lighter Blue
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
                const Icon(Icons.star_rounded, color: Colors.white, size: 48),
                const SizedBox(height: 8),
                Text(
                  l10n.rateYourExperience,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.white,
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
                              style: const TextStyle(fontSize: 32),
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
                        GoogleFonts.poppins(fontSize: 13, color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
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
                                color: Colors.grey, fontWeight: FontWeight.w600)),
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
                                color: Colors.white,
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
  // Timer is implicitly handled by recursive Future loop.

  
  @override
  void initState() {
    super.initState();
    // Auto-scroll logic
    // We need to import dart:async for Timer if not already imported. 
    // It is likely not imported or masked. Let's rely on standard Timer availability or add import if needed.
    // However, I can't add imports easily without scrolling up. 
    // I'll assume dart:async is available or I'll implement a simple Future loop or just use Future.delayed recursively.
    // Recursive Future.delayed is safer if I'm unsure about Timer imports.
    _startAutoScroll();
  }

  void _startAutoScroll() async {
    while (mounted) {
      await Future.delayed(const Duration(seconds: 3));
      if (mounted) {
        int nextPage = _currentPage + 1;
        if (nextPage >= 3) {
          nextPage = 0;
          _pageController.animateToPage(
            nextPage,
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeIn, 
            // Jump to 0 for continuous loop effect ? Or animate back. Animate back is standard.
          );
        } else {
          _pageController.animateToPage(
            nextPage,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
          );
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
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              AppLocalizations.of(context)!.meetOurInfluencer.toUpperCase(),
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface.withOpacity(0.6),
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 250, // Height for the content
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: [
                  _buildInfluencerContent(
                    context, 
                    name: "D.M. Bhatt Sir", 
                    imagePath: imgInfluencerDmBhattNew, 
                    instagramUrl: "https://www.instagram.com/dmbhattsir/"
                  ),
                  _buildInfluencerContent(
                    context, 
                    name: "Ankit Sir", 
                    imagePath: imgInfluencerAnkit, 
                    instagramUrl: "https://www.instagram.com/ak94sir/"
                  ),
                  _buildInfluencerContent(
                    context, 
                    name: "Keyur Sir", 
                    imagePath: imgInfluencerKeyur, 
                    instagramUrl: "https://www.instagram.com/keyur.s.99/"
                  ),
                ],
              ),
            ),
             // Page Indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentPage == index
                        ? colorScheme.primary
                        : colorScheme.outlineVariant,
                  ),
                );
              }),
            ),
          ],
        ),
      );
  }

  Widget _buildInfluencerContent(BuildContext context, {required String name, required String imagePath, required String instagramUrl}) {
     final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () async {
        if (await canLaunchUrl(Uri.parse(instagramUrl))) {
          await launchUrl(Uri.parse(instagramUrl), mode: LaunchMode.externalApplication);
        }
      },
      child: Column(
        children: [
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: colorScheme.surface, width: 3),
              image: DecorationImage(
                image: AssetImage(imagePath),
                fit: BoxFit.cover,
              ),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            name,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.link, size: 18,
                    color: colorScheme.onPrimaryContainer),
                const SizedBox(width: 8),
                Text(
                  "Follow on Instagram",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
