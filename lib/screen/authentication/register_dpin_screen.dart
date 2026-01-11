import 'package:dm_bhatt_tutions/constant/string_constant.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_filled_button.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/landing_screen.dart';
import 'package:dm_bhatt_tutions/utils/app_sizes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pinput/pinput.dart';

class RegisterDPINScreen extends StatefulWidget {
  const RegisterDPINScreen({super.key});

  @override
  State<RegisterDPINScreen> createState() => _RegisterDPINScreenState();
}

class _RegisterDPINScreenState extends State<RegisterDPINScreen> {
  late bool isDarkMode;
  late TextTheme _textTheme;

  @override
  Widget build(BuildContext context) {
    final brightness = MediaQuery.of(context).platformBrightness;
    isDarkMode = brightness == Brightness.dark;
    _textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text(lblDPIN)),
      body: SafeArea(child: _buildDPINBody()),
      bottomNavigationBar: BottomAppBar(
        elevation: 0,
        color: Colors.transparent,
        child: CustomFilledButton(label: lblSubmit, onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => LandingScreen(),));
        }),
      ),
    );
  }

  /// BODY
  Widget _buildDPINBody() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _cardWelcome(),
          blankVerticalSpace8,
          Padding(
            padding: P.all16,
            child: Column(
              children: [
                Align(
                  alignment: AlignmentGeometry.centerLeft,
                  child: Text(
                    lblEnterDPIN,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                blankVerticalSpace8,
                _buildDPINPinPut(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// WELCOME CARD
  Widget _cardWelcome() {
    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: P.all8,
        child: Row(
          spacing: S.s10,
          children: [
            CircleAvatar(radius: S.s32, child: Text('PP')),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Welcome Parshw Patel', style: _textTheme.titleMedium),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text('User ID:', style: _textTheme.titleMedium),
                    Text(' 123456', style: _textTheme.bodyMedium),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
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
}
