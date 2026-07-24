import 'package:dm_bhatt_tutions/custom_widgets/custom_loader.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/dm_ai_screen.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/student_home_screen.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/explore_screen.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/student_profile.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/more_detail.dart';
import 'package:dm_bhatt_tutions/screen/authentication/payment_screen.dart';
import 'package:dm_bhatt_tutions/network/api_service.dart';
import 'package:dm_bhatt_tutions/utils/guest_utils.dart';
import 'package:dm_bhatt_tutions/l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'dart:convert';

import 'package:dm_bhatt_tutions/screen/Dashboard/social_media_ad_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:dm_bhatt_tutions/utils/in_app_review_service.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  // 1. Track the current active index
  int _selectedIndex = 0;
  bool _isLoadingMembership = true;

  final GlobalKey<ExploreScreenState> _exploreKey =
      GlobalKey<ExploreScreenState>();

  // 2. Define the list of bodies/screens
  // These will replace the 'body' area when the index changes
  late final List<Widget> _pages = [
    const StudentHomeScreen(),
    ExploreScreen(key: _exploreKey),
    //const DMAIScreen(),
    //AIChatScreen(),
    DMAIChatScreen(),
    const MoreScreen(),
  ];

  // 3. Method to handle the tap
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (index == 1) {
      _exploreKey.currentState?.fetchProducts(showLoader: false);
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await _checkMembershipStatus();
    if (mounted && !_isLoadingMembership) {
      // _checkAndShowAd();
    }
  }

  Future<void> _checkMembershipStatus() async {
    setState(() {
      _isLoadingMembership = true;
    });

    // 1. Check if user is a guest (guests don't pay membership)
    bool isGuest = await GuestUtils.isGuest();
    if (isGuest) {
      if (mounted) {
        setState(() {
          _isLoadingMembership = false;
        });
      }
      return;
    }

    // 2. Fetch profile to check payment status
    try {
      final response = await ApiService.getProfile(forceRefresh: true);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final user = data['user'];
        final profile = data['profile'];

        if (user != null &&
            user['role'] == 'student' &&
            user['isPaid'] == false) {
          final prefs = await SharedPreferences.getInstance();
          final currentStandard =
              _standardNumberFrom(
                _profileValue(profile, const [
                  'std',
                  'standard',
                  'standardId',
                  'class',
                  'className',
                ]),
              ) ??
              prefs.getString('std');
          final currentMedium =
              _cleanProfileValue(_profileValue(profile, const ['medium'])) ??
              prefs.getString('medium');
          final currentStream =
              _cleanProfileValue(_profileValue(profile, const ['stream'])) ??
              prefs.getString('stream');
          final currentBoard =
              _cleanProfileValue(_profileValue(profile, const ['board'])) ??
              prefs.getString('board');
          final verifiedStandard = prefs.getString("apple_membership_standard");
          final hasVerifiedAppleMembership =
              prefs.getBool("apple_membership_verified") == true &&
              currentStandard != null &&
              verifiedStandard == currentStandard;
          if (hasVerifiedAppleMembership) {
            debugPrint(
              "[Apple Membership] Skipping paywall for verified standard $currentStandard.",
            );
            return;
          }

          // Persist data for payment flow
          if (user['firstName'] != null)
            await prefs.setString('firstName', user['firstName']);
          if (currentStandard != null) {
            await prefs.setString('std', currentStandard);
          }
          if (currentMedium != null) {
            await prefs.setString('medium', currentMedium);
          }
          if (currentStream != null) {
            await prefs.setString('stream', currentStream);
          }
          if (currentBoard != null) {
            await prefs.setString('board', currentBoard);
          }

          bool skippedOnce = prefs.getBool('skipped_payment_prompt') ?? false;

          if (skippedOnce) {
            if (mounted)
              setState(() {
                _isLoadingMembership = false;
              });
            return;
          }

          if (!mounted) return;

          // Redirect to Payment Screen with data directly from API
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PaymentScreen(
                std: currentStandard,
                medium: currentMedium,
                phone: user['phoneNum'],
                email: user['email'],
              ),
            ),
          ).then((success) {
            if (success == true) {
              // Refresh if needed
              _checkMembershipStatus();
            }
          });
          return; // Keep loading visible while redirecting
        }
      }
    } catch (e) {
      debugPrint("Error checking membership: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMembership = false;
        });
      }
    }
  }

  dynamic _profileValue(dynamic profile, List<String> keys) {
    if (profile is! Map) return null;
    for (final key in keys) {
      final value = profile[key];
      if (value == null) continue;
      if (value is Map) {
        return value['std'] ??
            value['standard'] ??
            value['name'] ??
            value['title'] ??
            value['value'];
      }
      return value;
    }
    return null;
  }

  String? _standardNumberFrom(dynamic value) {
    if (value == null) return null;
    return RegExp(r"(\d+)").firstMatch(value.toString())?.group(1);
  }

  String? _cleanProfileValue(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    if (text.isEmpty || text.toLowerCase() == "none") return null;
    return text;
  }

  Future<void> _checkAndShowAd() async {
    // Only show if we are on the dashboard (index 0)
    if (_selectedIndex != 0) return;

    final prefs = await SharedPreferences.getInstance();

    // Check if already shown once (ever)
    bool alreadyShown = prefs.getBool('social_ad_shown_once') ?? false;

    if (!alreadyShown) {
      if (!mounted) return;
      // Show dialog after slight delay ensuring context is ready
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && _selectedIndex == 0) {
          showDialog(
            context: context,
            barrierDismissible: true, // Allow clicking outside to close
            builder: (context) => const SocialMediaAdDialog(),
          );
          prefs.setBool('social_ad_shown_once', true);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    // Titles corresponding to each page
    final List<String> titles = [
      l10n.dashboard,
      l10n.explore,
      l10n.dmai,
      l10n.more,
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (InAppReviewService.isAndroidSupported) {
          await InAppReviewService.requestReviewOrOpenStore();
        }
        if (context.mounted) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: colorScheme.surface, // Dynamic Scaffold Background
        appBar: AppBar(
          backgroundColor:
              Colors.transparent, // Make background transparent to show gradient
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary,
                  colorScheme.primary.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          elevation: 0,
          leading: Padding(
            padding: const EdgeInsets.all(8.0),
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: Image.asset("assets/images/robot_logo.png", height: 30),
            ),
          ),
          title: Text(
            titles[_selectedIndex],
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const CircleAvatar(
                backgroundColor: Colors.white24,
                child: Icon(Icons.person, color: Colors.white),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const StudentProfileScreen(),
                  ),
                );
              },
            ),
            const SizedBox(width: 8),
            // IconButton(
            //   icon: const CircleAvatar(
            //     backgroundColor: Colors.white24,
            //     child: Icon(Icons.switch_account, color: Colors.white, size: 20),
            //   ),
            //   onPressed: () => StudentProfileScreen.showSwitchAccountSheet(context),
            // ),
            // const SizedBox(width: 8),
          ],
        ),
        body: _isLoadingMembership
            ? const CustomLoader()
            : IndexedStack(index: _selectedIndex, children: _pages),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed, // Ensure all labels are visible
          backgroundColor: colorScheme.surface, // Dynamic BG for BottomNav
          selectedItemColor: colorScheme.primary, // Dynamic Active Color
          unselectedItemColor:
              colorScheme.onSurfaceVariant, // Dynamic Inactive Color
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home_rounded),
              label: l10n.home,
            ),
            BottomNavigationBarItem(
              icon: const Icon(
                Icons.grid_view_rounded,
              ), // Meaningful Icon for Explore
              label: l10n.explore,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.smart_toy_outlined), // DMAI Icon
              label: l10n.dmai,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.menu),
              label: l10n.more,
            ),
          ],
        ),
      ),
    );
  }
}
