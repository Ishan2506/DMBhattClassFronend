import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/ai_chat_screen.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/dm_ai_screen.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/student_home_screen.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/explore_screen.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/dmai_screen.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/student_profile.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/more_detail.dart';
import 'package:dm_bhatt_tutions/utils/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';

import 'package:dm_bhatt_tutions/screen/Dashboard/social_media_ad_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  // 1. Track the current active index
  int _selectedIndex = 0;

  // 2. Define the list of bodies/screens
  // These will replace the 'body' area when the index changes
  final List<Widget> _pages = [
    const StudentHomeScreen(),
    const ExploreScreen(),
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
  }

  @override
  void initState() {
    super.initState();
    _checkAndShowAd();
  }

  Future<void> _checkAndShowAd() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Get current date string (YYYY-MM-DD)
    final String todayDate = DateTime.now().toIso8601String().split('T')[0];
    final String? lastAdDate = prefs.getString('social_ad_date');
    
    // If the date has changed, reset the counter
    if (lastAdDate != todayDate) {
      await prefs.setInt('social_ad_count', 0);
      await prefs.setString('social_ad_date', todayDate);
    }

    int activeCount = prefs.getInt('social_ad_count') ?? 0;

    if (activeCount < 3) {
      if (!mounted) return;
      // Show dialog after slight delay ensuring context is ready
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: true, // Allow clicking outside to close
            builder: (context) => const SocialMediaAdDialog(),
          );
          prefs.setInt('social_ad_count', activeCount + 1);
        }
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    // Titles corresponding to each page
    final List<String> titles = [
      l10n.dashboard,
      l10n.explore,
      l10n.dmai,
      l10n.more,
    ];

    return Scaffold(
      backgroundColor: colorScheme.surface, // Dynamic Scaffold Background
      appBar: AppBar(
        backgroundColor: Colors.transparent, // Make background transparent to show gradient
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
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)
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
                MaterialPageRoute(builder: (context) => const StudentProfileScreen()),
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
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed, // Ensure all labels are visible
        backgroundColor: colorScheme.surface, // Dynamic BG for BottomNav
        selectedItemColor: colorScheme.primary, // Dynamic Active Color
        unselectedItemColor: colorScheme.onSurfaceVariant, // Dynamic Inactive Color
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_rounded),
            label: l10n.home,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.grid_view_rounded), // Meaningful Icon for Explore
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
    );
  }
}
