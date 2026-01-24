import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/student_home_screen.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/explore_screen.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/dmai_screen.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/student_profile.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/more_detail.dart';
import 'package:flutter/material.dart';

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
    const DMAIScreen(),
    const MoreScreen(),
  ];

  // 3. Method to handle the tap
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }


  // Titles corresponding to each page
  final List<String> _titles = [
    "Dashboard",
    "Explore",
    "DMAI",
    "More",
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface, // Dynamic Scaffold Background
      appBar: AppBar(
        backgroundColor: Colors.transparent, // Make background transparent to show gradient
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade900, Colors.blue.shade700], // Keeping Brand Header
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
            child: Image.asset("assets/app_icons/dm_bhatt_classes_logo.png", height: 24),
          ),
        ),
        title: Text(_titles[_selectedIndex], style: const TextStyle(color: Colors.white)),
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
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_rounded), // Meaningful Icon for Explore
            label: 'Explore',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.smart_toy_outlined), // DMAI Icon
            label: 'DMAI',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu),
            label: 'More',
          ),
        ],
      ),
    );
  }
}
