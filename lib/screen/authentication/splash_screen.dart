import 'dart:async';
import 'package:dm_bhatt_tutions/constant/app_images.dart';
import 'package:dm_bhatt_tutions/screen/authentication/welcome_screen.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/landing_screen.dart';
import 'package:dm_bhatt_tutions/bloc/theme/theme_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:convert';
import 'package:dm_bhatt_tutions/utils/app_sizes.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import SharedPreferences
import 'package:dm_bhatt_tutions/network/api_service.dart';
import 'package:dm_bhatt_tutions/screen/authentication/force_update_screen.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:http/http.dart' as http;
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
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

    try {
      // 1. Fetch App Config
      final response = await http.get(Uri.parse('${ApiService.baseUrl}/config/app')).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final config = json.decode(response.body);
        
        // 2. Get current app version (Build Number)
        final packageInfo = await PackageInfo.fromPlatform();
        final currentBuildNumber = int.tryParse(packageInfo.buildNumber) ?? 0;
        
        int minBuildNumber = 0;
        String storeUrl = '';
        String message = config['forceUpdateMessage'] ?? 'A new version of the app is available. Please update to continue using the app.';

        if (!kIsWeb) {
          if (Platform.isAndroid) {
              minBuildNumber = int.tryParse(config['studentMinAndroidVersion']?.toString() ?? '0') ?? 0;
              storeUrl = config['studentPlayStoreUrl'] ?? '';
          } else if (Platform.isIOS) {
              minBuildNumber = int.tryParse(config['studentMinIosVersion']?.toString() ?? '0') ?? 0;
              storeUrl = config['studentAppStoreUrl'] ?? '';
          }
        }

        if (!kIsWeb && currentBuildNumber > 0 && minBuildNumber > 0 && currentBuildNumber < minBuildNumber) {
            // Force update
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => ForceUpdateScreen(
                message: message,
                storeUrl: storeUrl,
              )),
            );
            return;
        }
      }
    } catch (e) {
      debugPrint('App Version Check Failed: $e');
    }

    if (!mounted) return;

    await ApiService.loadToken();
    final prefs = await SharedPreferences.getInstance();
    
    _proceedToNextScreen(prefs);
  }


  Future<void> _proceedToNextScreen(SharedPreferences prefs) async {
    final token = prefs.getString('auth_token');
    final isGuest = prefs.getString('user_role') == 'guest';

    if ((token != null && token.isNotEmpty) || isGuest) {
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