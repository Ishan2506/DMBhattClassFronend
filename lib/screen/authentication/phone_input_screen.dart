import 'package:dm_bhatt_tutions/bloc/authentication/authentication_cubit.dart';
import 'package:dm_bhatt_tutions/constant/app_constant.dart';
import 'package:dm_bhatt_tutions/constant/app_images.dart';
import 'package:dm_bhatt_tutions/constant/string_constant.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_filled_button.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_text_field.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:dm_bhatt_tutions/screen/authentication/d_pin_screen.dart';
import 'package:dm_bhatt_tutions/screen/authentication/register_screen.dart';
import 'package:dm_bhatt_tutions/utils/app_sizes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PhoneInputScreen extends StatefulWidget {
  const PhoneInputScreen({super.key});

  @override
  State<PhoneInputScreen> createState() => _PhoneInputScreenState();
}

class _PhoneInputScreenState extends State<PhoneInputScreen> {
  final _phoneNoController = TextEditingController();
  late AuthenticationCubit _authenticationCubit;

  @override
  void initState() {
    _authenticationCubit = BlocProvider.of<AuthenticationCubit>(context);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: BlocBuilder<AuthenticationCubit, AuthenticationState>(
          builder: (context, state) {
            final role = state.formState.selectedUserRole;
            final (welcomeText, icon, color) = _getRoleDetails(role);

            return Padding(
              padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.06),
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
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
                        "Enter your phone number to continue",
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      blankVerticalSpace48,

                      // Phone Input
                      _buildTffEmail(),
                      blankVerticalSpace32,
                      
                      // Next Button
                      _buildBtnNext(),
                      blankVerticalSpace24,
                      
                      // Register Option
                      _buildTxtBtnRegister(),
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

  /// TEXT FIELD :- PHONE NUMBER
  Widget _buildTffEmail() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: CustomTextField(
        controller: _phoneNoController,
        hintText: lblEnterPhoneNumber,
        labelText: lblPhoneNumber,
        prefixIcon: Icons.phone_android_rounded,
        inputType: TextInputType.phone,
        maxLength: 10,
      ),
    );
  }

  /// BUTTON :- NEXT
  Widget _buildBtnNext() {
    return CustomFilledButton(
      label: "ENTER DPIN".toUpperCase(),
      onPressed: () {
        if (_phoneNoController.text.length != 10) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Please enter valid 10 digit phone number"),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const DPinScreen()),
        );
      },
    );
  }

  /// TEXT BUTTON :- REGISTER
  Widget _buildTxtBtnRegister() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          lblDontHaveAnAccount,
          style: TextStyle(color: Colors.grey[600]),
        ),
        TextButton(
          onPressed: () {
            // Logic to auto-select role for registration
            final currentRole =
                _authenticationCubit.state.formState.selectedUserRole;
            if (currentRole == UserRole.assistant) {
              _authenticationCubit.toggleRegisterUserRoles(UserRole.assistant);
            } else {
              // Guest and Student both go to Student registration
              _authenticationCubit.toggleRegisterUserRoles(UserRole.student);
            }
            
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const RegisterScreen()),
            );
          },
          child: const Text(
            lblRegister,
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
