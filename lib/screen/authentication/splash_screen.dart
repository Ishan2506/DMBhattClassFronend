import 'dart:async';
import 'package:dm_bhatt_tutions/constant/app_images.dart';
import 'package:dm_bhatt_tutions/screen/authentication/welcome_screen.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/landing_screen.dart'; // Import LandingScreen
import 'package:dm_bhatt_tutions/utils/app_sizes.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import SharedPreferences
import 'package:dm_bhatt_tutions/network/api_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    // Initialize Animation
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1.0), // Start from bottom
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );

    _controller.forward();
    
    // Start Login Check independently
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    // Wait for animation + extra time (total ~4 seconds)
    await Future.delayed(const Duration(seconds: 4));
    
    if (!mounted) return;

    await ApiService.loadToken();
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token != null && token.isNotEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LandingScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const WelcomeScreen()),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface, // Dynamic background
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SlideTransition(
              position: _slideAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  children: [
                    Image.asset(
                      imgAppLogo,
                      width: S.s250, 
                    ),
                    const SizedBox(height: 16),
                    // Theme-aware text
                  //  Text(
                     // "Student App", // Context provided by user request
                     // style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                     //   color: Theme.of(context).colorScheme.onSurface,
                       // fontWeight: FontWeight.bold,
                  //    ),
                  //  ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}