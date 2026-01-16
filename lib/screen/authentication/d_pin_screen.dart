import 'package:dm_bhatt_tutions/bloc/authentication/authentication_cubit.dart';
import 'package:dm_bhatt_tutions/constant/app_constant.dart';
import 'package:dm_bhatt_tutions/constant/app_images.dart';
import 'package:dm_bhatt_tutions/constant/string_constant.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_filled_button.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/landing_screen.dart';
import 'package:dm_bhatt_tutions/utils/app_sizes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pinput/pinput.dart';

class DPinScreen extends StatefulWidget {
  const DPinScreen({super.key});

  @override
  State<DPinScreen> createState() => _DPinScreenState();
}

class _DPinScreenState extends State<DPinScreen> {
  late AuthenticationCubit _authenticationCubit;
  late bool isDarkMode;

  @override
  void initState() {
    _authenticationCubit = BlocProvider.of<AuthenticationCubit>(context);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = MediaQuery.of(context).platformBrightness;
    isDarkMode = brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: BlocBuilder<AuthenticationCubit, AuthenticationState>(
          builder: (context, state) {
            final role = state.formState.selectedUserRole;
            final (welcomeText, icon, color) = _getRoleDetails(role);

            return Padding(
              padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.03),
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Dynamic Avatar
                      Hero(
                        tag: 'role_avatar',
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            shape: BoxShape.circle,
                            border: Border.all(color: color.withOpacity(0.3), width: 2),
                          ),
                          child: Icon(icon, size: MediaQuery.of(context).size.width * 0.16, color: color),
                        ),
                      ),
                      blankVerticalSpace32,

                      // Welcome Text
                      Text(
                        welcomeText,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Enter your D-Pin to secure login",
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      blankVerticalSpace48,

                      // D-Pin Section
                      Text(
                        lblEnterDPIN,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      blankVerticalSpace8,
                      _buildDPINPinPut(),
                      blankVerticalSpace16,
                      Align(
                        alignment: AlignmentGeometry.centerRight,
                        child: _buildTxtBtnForgotPassword(),
                      ),
                      blankVerticalSpace32,
                      _buildBtnLogin(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  (String, IconData, Color) _getRoleDetails(UserRole role) {
    switch (role) {
      case UserRole.student:
        return ("Welcome, Student!", Icons.school_rounded, Colors.blue);
      case UserRole.assistant:
        return ("Welcome, Assistant!", Icons.admin_panel_settings_rounded, Colors.purple);
      case UserRole.guest:
        return ("Welcome, Guest!", Icons.person_rounded, Colors.orange);
      default:
        return ("Welcome!", Icons.person_outline, Colors.blue);
    }
  }

  /// APP LOGO
  Widget _buildAppLogo() {
    return Image.asset(imgDmBhattClassesLogo, height: S.s80);
  }

  /// PIN-PUT :- DPIN
  Widget _buildDPINPinPut() {
    return Pinput(
      defaultPinTheme: PinTheme(
        width: S.s56,
        height: S.s56,
        textStyle: Theme.of(context).textTheme.bodyMedium,
        decoration: BoxDecoration(
          border: Border.all(color: isDarkMode ? Colors.white : Colors.black),
          borderRadius: BorderRadius.circular(S.s12),
        ),
      ),
      focusedPinTheme: PinTheme(
        width: S.s56,
        height: S.s56,
        textStyle: Theme.of(context).textTheme.bodyMedium,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(S.s8),
          border: Border.all(
            color: Theme.of(context).colorScheme.surfaceContainer,
          ),
        ),
      ),
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      pinputAutovalidateMode: PinputAutovalidateMode.onSubmit,
      showCursor: true,
      onCompleted: (pin) => print(pin),
    );
  }

  /// TEXT BUTTON :- FORGOT PASSWORD
  Widget _buildTxtBtnForgotPassword() {
    return TextButton(onPressed: () {}, child: const Text(lblForgotDPIN));
  }

  /// BUTTON :- LOGIN
  Widget _buildBtnLogin() {
    return CustomFilledButton(
      label: lblLogin.toUpperCase(),
      onPressed: () {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LandingScreen()),
          (route) => false,
        );
      },
    );
  }
}
