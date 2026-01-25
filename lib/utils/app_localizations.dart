import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    // This is a simplified way to access localizations directly if injected or just by passing locale
    // Ideally we would use Localizations.of<AppLocalizations>(context, AppLocalizations)!;
    // But for this quick implementation, we will use a static look up based on the injected locale in main/cubit.
    // However, getting the locale from context needs Localizations widget.
    // Let's rely on a simpler Map lookup for now.
    return AppLocalizations(Localizations.localeOf(context));
  }

  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'dashboard': 'Dashboard',
      'explore': 'Explore',
      'dmai': 'DMAI',
      'more': 'More',
      'home': 'Home',
      'daily_time_table': 'Daily Time Table',
      'start_exam': 'START EXAM',
      'next_exam_waiting': 'Your next exam is waiting for you.',
      'reports': 'Reports',
      'settings': 'Settings',
      'theme_mode': 'Theme Mode',
      'language': 'Language',
      'sign_out': 'Sign Out',
      'profile': 'Profile',
      'academic_performance': 'Academic Performance',
      'total_reward_points': 'Total Reward Points',
    },
    'hi': {
      'dashboard': 'डैशबोर्ड',
      'explore': 'खोजें',
      'dmai': 'डीएम एआई',
      'more': 'अधिक',
      'home': 'होम',
      'daily_time_table': 'दैनिक समय सारिणी',
      'start_exam': 'परीक्षा शुरू करें',
      'next_exam_waiting': 'आपकी अगली परीक्षा आपका इंतजार कर रही है।',
      'reports': 'रिपोर्ट',
      'settings': 'सेटिंग्स',
      'theme_mode': 'थीम मोड',
      'language': 'भाषा',
      'sign_out': 'साइन आउट',
      'profile': 'प्रोफ़ाइल',
      'academic_performance': 'शैक्षणिक प्रदर्शन',
      'total_reward_points': 'कुल इनाम अंक',
    },
    'gu': {
      'dashboard': 'ડેશબોર્ડ',
      'explore': 'અન્વેષણ',
      'dmai': 'ડીએમ એઆઈ',
      'more': 'વધુ',
      'home': 'હોમ',
      'daily_time_table': 'દૈનિક સમયપત્રક',
      'start_exam': 'પરીક્ષા શરૂ કરો',
      'next_exam_waiting': 'તમારી આગામી પરીક્ષા તમારી રાહ જોઈ રહી છે.',
      'reports': 'અહેવાલો',
      'settings': 'સેટિંગ્સ',
      'theme_mode': 'થીમ મોડ',
      'language': 'ભાષા',
      'sign_out': 'સાઇન આઉટ',
      'profile': 'પ્રોફાઇલ',
      'academic_performance': 'શૈક્ષણિક પ્રદર્શન',
      'total_reward_points': 'કુલ પુરસ્કાર પોઈન્ટ',
    },
  };

  String get dashboard => _localizedValues[locale.languageCode]!['dashboard']!;
  String get explore => _localizedValues[locale.languageCode]!['explore']!;
  String get dmai => _localizedValues[locale.languageCode]!['dmai']!;
  String get more => _localizedValues[locale.languageCode]!['more']!;
  String get home => _localizedValues[locale.languageCode]!['home']!;
  String get dailyTimeTable => _localizedValues[locale.languageCode]!['daily_time_table']!;
  String get startExam => _localizedValues[locale.languageCode]!['start_exam']!;
  String get nextExamWaiting => _localizedValues[locale.languageCode]!['next_exam_waiting']!;
  String get reports => _localizedValues[locale.languageCode]!['reports']!;
  String get settings => _localizedValues[locale.languageCode]!['settings']!;
  String get themeMode => _localizedValues[locale.languageCode]!['theme_mode']!;
  String get language => _localizedValues[locale.languageCode]!['language']!;
  String get signOut => _localizedValues[locale.languageCode]!['sign_out']!;
  String get profile => _localizedValues[locale.languageCode]!['profile']!;
  String get academicPerformance => _localizedValues[locale.languageCode]!['academic_performance']!;
  String get totalRewardPoints => _localizedValues[locale.languageCode]!['total_reward_points']!;
  
  // Method to get by key if needed
  String getString(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }
}
