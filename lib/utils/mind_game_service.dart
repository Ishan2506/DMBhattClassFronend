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
    final today = "${now.year}-${now.month}-${now.day}";

    if (_todayStr != today) {
      // New Day, Reset
      _todayStr = today;
      _dailyUsageSeconds = 0;
      await prefs.setString('mind_game_date', today);
      await prefs.setInt('mind_game_seconds', 0);
    } else {
      // Load usage
      _dailyUsageSeconds = prefs.getInt('mind_game_seconds') ?? 0;
    }
  }

  bool canPlay() {
    return _dailyUsageSeconds < _maxDailySeconds;
  }

  String getRemainingTime() {
    int remaining = _maxDailySeconds - _dailyUsageSeconds;
    if (remaining < 0) remaining = 0;
    int mins = (remaining / 60).ceil();
    return "$mins mins left";
  }

  void startSession(BuildContext context) {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
       _dailyUsageSeconds++;
       
       // Save every minute to avoid heavy IO
       if (_dailyUsageSeconds % 60 == 0) {
         final prefs = await SharedPreferences.getInstance();
         await prefs.setInt('mind_game_seconds', _dailyUsageSeconds);
       }

       // Checks
       if (_dailyUsageSeconds >= _maxDailySeconds) {
         _stopAndExit(context);
       } else if (_dailyUsageSeconds > _warningThresholdSeconds) {
         // Check if we just hit a 10 min marker relative to start (or just absolute markers)
         // requirement: "after 30 min every 10 min" -> 30, 40, 50.
         int excess = _dailyUsageSeconds;
         if (excess == 1800 || excess == 2400 || excess == 3000) {
            _showWarning(context, (60 - (excess/60).round()));
         }
       }
    });
  }

  void stopSession() {
    _timer?.cancel();
    _saveProgress();
  }

  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('mind_game_seconds', _dailyUsageSeconds);
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
