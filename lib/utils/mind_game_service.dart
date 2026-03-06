import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dm_bhatt_tutions/utils/custom_toast.dart';

class MindGameService {
  static final MindGameService _instance = MindGameService._internal();
  factory MindGameService() => _instance;
  MindGameService._internal();

  Timer? _timer;
  int _dailyUsageSeconds = 0;
  String _todayStr = "";
  
  static const int _maxDailySeconds = 3600; // 60 minutes
  static const int _warningThresholdSeconds = 1800; // 30 minutes
  static const int _warningIntervalSeconds = 600; // 10 minutes

  // Initialize and load saved data
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    // Get current user ID to make the limit user-specific
    final userId = prefs.getString('userId') ?? "guest"; 
    
    // Key format: mind_game_date_{userId}
    // This ensues each user gets their own daily tracking.
    final String dateKey = 'mind_game_date_$userId';
    final String usageKey = 'mind_game_seconds_$userId';

    final String storedDate = prefs.getString(dateKey) ?? "";
    final String today = "${now.year}-${now.month}-${now.day}";

    if (storedDate != today) {
      // New Day for THIS user, Reset
      _todayStr = today;
      _dailyUsageSeconds = 0;
      await prefs.setString(dateKey, today);
      await prefs.setInt(usageKey, 0);
    } else {
      // Load usage for THIS user
      _todayStr = today;
      _dailyUsageSeconds = prefs.getInt(usageKey) ?? 0;
    }
  }

  bool canPlay() {
    return true; // Unlimited play
  }

  String getRemainingTime() {
    return ""; // No remaining time to display
  }

  void startSession(BuildContext context) {
    // Timer logic removed to allow unlimited play without tracking
  }

  void stopSession() {
    // Logic removed
  }

  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId') ?? "guest";
    await prefs.setInt('mind_game_seconds_$userId', _dailyUsageSeconds);
  }

  void _showWarning(BuildContext context, int minsLeft) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Time Warning"),
        content: Text("You have used Mind Games for a while. Only $minsLeft minutes remaining for today."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text("OK")
          )
        ],
      ),
    );
  }

  void _stopAndExit(BuildContext context) {
    stopSession();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Daily Limit Reached"),
        content: const Text("You have reached the 1 hour daily limit for Mind Games. Please come back tomorrow!"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close Dialog
              Navigator.pop(context); // Exit Game Screen
            }, 
            child: const Text("Exit")
          )
        ],
      ),
    );
  }
}
