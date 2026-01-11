import 'package:dm_bhatt_tutions/bloc/authentication/authentication_cubit.dart';
import 'package:dm_bhatt_tutions/constant/app_constant.dart';
import 'package:dm_bhatt_tutions/constant/app_images.dart';
import 'package:dm_bhatt_tutions/constant/string_constant.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_filled_button.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_text_field.dart';
import 'package:dm_bhatt_tutions/screen/authentication/register_screen.dart';
import 'package:dm_bhatt_tutions/utils/app_sizes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pinput/pinput.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneNoController = TextEditingController();
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
      body: SafeArea(
        child: Padding(padding: P.all10, child: _buildLoginBody()),
      ),
      bottomNavigationBar: Padding(
        padding: P.v16,
        child: Text(
          '$lblAppVersion: $appVersion',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelMedium!.copyWith(
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
      ),
    );
  }

  /// BODY
  Widget _buildLoginBody() {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildAppLogo(),

            blankVerticalSpace48,
            _buildUserRoles(),

            blankVerticalSpace32,
            _buildTffEmail(),
            blankVerticalSpace16,
            Align(
              alignment: AlignmentGeometry.centerLeft,
              child: Text(
                lblEnterDPIN,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            blankVerticalSpace8,
            _buildDPINPinPut(),
            Align(
              alignment: AlignmentGeometry.centerRight,
              child: _buildTxtBtnForgotPassword(),
            ),
            blankVerticalSpace16,
            _buildBtnLogin(),
            _buildTxtBtnRegister(),
          ],
        ),
      ),
    );
  }

  /// APP LOGO
  Widget _buildAppLogo() {
    return Image.asset(imgDmBhattClassesLogo, height: S.s80);
  }

  /// USER ROLES
  Widget _buildUserRoles() {
    return BlocBuilder<AuthenticationCubit, AuthenticationState>(
      buildWhen: (previous, current) =>
          previous.formState.selectedUserRole !=
          current.formState.selectedUserRole,
      builder: (context, state) {
        return SegmentedButton(
          segments: const [
            ButtonSegment(
              value: UserRole.admin,
              label: Text(lblAdmin),
              icon: Icon(Icons.admin_panel_settings),
            ),
            ButtonSegment(
              value: UserRole.student,
              label: Text(lblStudent),
              icon: Icon(Icons.person_outline),
            ),
            ButtonSegment(
              value: UserRole.assistant,
              label: Text(lblAssistant),
              icon: Icon(Icons.admin_panel_settings_outlined),
            ),
            ButtonSegment(
              value: UserRole.guest,
              label: Text(lblGuest),
              icon: Icon(Icons.person),
            ),
          ],
          selected: {state.formState.selectedUserRole},
          onSelectionChanged: (Set<UserRole> newSelection) {
            _authenticationCubit.toggleUserRoles(newSelection.first);
          },
        );
      },
    );
  }

  /// TEXT FIELD :- EMAIL
  Widget _buildTffEmail() {
    return CustomTextField(
      controller: _phoneNoController,
      hintText: lblEnterPhoneNumber,
      labelText: lblPhoneNumber,
      prefixIcon: Icons.phone,
      inputType: TextInputType.phone,
    );
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
    return CustomFilledButton(label: lblLogin.toUpperCase(), onPressed: () {});
  }

  /// TEXT BUTTON :- REGISTER
  Widget _buildTxtBtnRegister() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(lblDontHaveAnAccount),
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const RegisterScreen()),
            );
          },
          child: const Text(
            lblRegister,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
