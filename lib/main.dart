import 'package:dm_bhatt_tutions/bloc/authentication/authentication_cubit.dart';
import 'package:dm_bhatt_tutions/bloc/theme/theme_cubit.dart';
import 'package:dm_bhatt_tutions/screen/authentication/splash_screen.dart';
import 'package:dm_bhatt_tutions/utils/app_theme.dart';
import 'package:dm_bhatt_tutions/utils/text_theme.dart';
import 'package:dm_bhatt_tutions/utils/app_theme_extensions.dart'; // Import extension
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:screen_protector/screen_protector.dart';
import 'constant/app_constant.dart';
import 'package:dm_bhatt_tutions/l10n/app_localizations.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:dm_bhatt_tutions/utils/notification_service.dart';
import 'package:dm_bhatt_tutions/utils/purchase_config.dart';
import 'package:dm_bhatt_tutions/utils/revenue_cat_service.dart';
import 'package:dm_bhatt_tutions/utils/academic_constants.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  debugPaintBaselinesEnabled = false;
  debugPaintSizeEnabled = false;

  // Load academic constants from server
  await AcademicConstants.loadFromServer();

  if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
    // Initialize sqflite for desktop
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  final prefs = await SharedPreferences.getInstance();

  // Initialize Firebase and Push Notifications
  try {
    await Firebase.initializeApp();
    await NotificationService.instance.initialize();
  } catch (e) {
    if (kDebugMode) {
      print('Firebase initialization failed: $e');
    }
  }

  // Request Microphone permission at start
  await _requestPermissions();

  // Initialize Payment Config & RevenueCat
  await PurchaseConfig.instance.initialize();
  await RevenueCatService.instance.init();

  await _secureScreen();
  runApp(MyApp(prefs: prefs));
}

Future<void> _requestPermissions() async {
  await Permission.microphone.request();
}

Future<void> _secureScreen() async {
  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    try {
      // await ScreenProtector.preventScreenshotOn();
    } catch (e) {
      if (kDebugMode) {
        print('Error setting screen protection: $e');
      }
    }
  }
}

class MyApp extends StatelessWidget {
  final SharedPreferences prefs;
  const MyApp({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    final textTheme = createTextTheme();
    final theme = MaterialTheme(textTheme);

    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthenticationCubit>(
          create: (context) => AuthenticationCubit(),
        ),
        BlocProvider<ThemeCubit>(create: (context) => ThemeCubit(prefs)),
      ],
      child: BlocBuilder<ThemeCubit, ThemeState>(
        builder: (context, state) {
          // Determine the style name from enum
          final styleName = state.selectedStyle.name;

          return MaterialApp(
            navigatorKey: navigatorKey,
            useInheritedMediaQuery: true,
            // locale: DevicePreview.locale(context),
            // builder: DevicePreview.appBuilder,
            debugShowCheckedModeBanner: false,
            title: appName,
            // Use extension method to get theme based on style and brightness
            theme: theme.getThemeForStyle(styleName, false), // Light
            darkTheme: theme.getThemeForStyle(styleName, true), // Dark
            themeMode: state.themeMode,
            // only english language currenyly we are working on
            locale: state.locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
