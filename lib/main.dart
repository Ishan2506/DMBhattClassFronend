import 'package:dm_bhatt_tutions/bloc/authentication/authentication_cubit.dart';
import 'package:dm_bhatt_tutions/bloc/theme/theme_cubit.dart';
import 'package:dm_bhatt_tutions/screen/authentication/splash_screen.dart';
import 'package:dm_bhatt_tutions/utils/app_theme.dart';
import 'package:dm_bhatt_tutions/utils/text_theme.dart';
import 'package:dm_bhatt_tutions/utils/app_theme_extensions.dart'; // Import extension
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:flutter_windowmanager/flutter_windowmanager.dart';

import 'constant/app_constant.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:dm_bhatt_tutions/l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await _secureScreen();
  runApp(const MyApp());
}

// Future<void> _secureScreen() async {
//   try {
//     await FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
//   } catch (e) {
//     debugPrint("Error securing screen: $e");
//   }
// }

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = createTextTheme();
    final theme = MaterialTheme(textTheme);

    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthenticationCubit>(
          create: (context) => AuthenticationCubit(),
        ),
        BlocProvider<ThemeCubit>(
          create: (context) => ThemeCubit(),
        ),
      ],
      child: BlocBuilder<ThemeCubit, ThemeState>(
        builder: (context, state) {
          // Determine the style name from enum
          final styleName = state.selectedStyle.name;
          
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: appName,
            // Use extension method to get theme based on style and brightness
            theme: theme.getThemeForStyle(styleName, false), // Light
            darkTheme: theme.getThemeForStyle(styleName, true), // Dark
            themeMode: state.themeMode,
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
