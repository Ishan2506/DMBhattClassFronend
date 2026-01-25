import 'package:dm_bhatt_tutions/bloc/authentication/authentication_cubit.dart';
import 'package:dm_bhatt_tutions/bloc/theme/theme_cubit.dart';
import 'package:dm_bhatt_tutions/screen/authentication/splash_screen.dart';
import 'package:dm_bhatt_tutions/utils/app_theme.dart';
import 'package:dm_bhatt_tutions/utils/text_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_windowmanager/flutter_windowmanager.dart';

import 'constant/app_constant.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _secureScreen();
  runApp(const MyApp());
}

Future<void> _secureScreen() async {
  try {
    await FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
  } catch (e) {
    debugPrint("Error securing screen: $e");
  }
}

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
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: appName,
            theme: theme.light(),
            darkTheme: theme.dark(),
            themeMode: state.themeMode,
            locale: state.locale,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
