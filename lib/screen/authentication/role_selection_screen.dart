import 'package:dm_bhatt_tutions/bloc/authentication/authentication_cubit.dart';
import 'package:dm_bhatt_tutions/constant/app_constant.dart';
import 'package:dm_bhatt_tutions/constant/app_images.dart';
import 'package:dm_bhatt_tutions/constant/string_constant.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_filled_button.dart';
import 'package:dm_bhatt_tutions/screen/authentication/phone_input_screen.dart';
import 'package:dm_bhatt_tutions/utils/app_sizes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  late AuthenticationCubit _authenticationCubit;

  @override
  void initState() {
    _authenticationCubit = BlocProvider.of<AuthenticationCubit>(context);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: P.all10,
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildAppLogo(),
                  blankVerticalSpace48,
                  Text(
                    "Select Your Role",
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  blankVerticalSpace32,
                  _buildUserRoles(),
                  blankVerticalSpace48,
                  _buildBtnNext(),
                ],
              ),
            ),
          ),
        ),
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

  /// APP LOGO
  Widget _buildAppLogo() {
    return Image.asset(imgDmBhattClassesLogo, height: MediaQuery.of(context).size.height * 0.1);
  }

  /// USER ROLES
  Widget _buildUserRoles() {
    return BlocBuilder<AuthenticationCubit, AuthenticationState>(
      buildWhen: (previous, current) =>
          previous.formState.selectedUserRole !=
          current.formState.selectedUserRole,
      builder: (context, state) {
        return LayoutBuilder(builder: (context, constraints) {
          final cardWidth = (constraints.maxWidth - S.s16) / 2;
          
          return Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildRoleCard(
                      context,
                      state,
                      UserRole.student,
                      lblStudent,
                      Icons.school_outlined,
                    ),
                  ),
                  const SizedBox(width: S.s16),
                  Expanded(
                    child: _buildRoleCard(
                      context,
                      state,
                      UserRole.assistant,
                      lblAssistant,
                      Icons.admin_panel_settings_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: S.s16),
              // Guest Role Centered
              SizedBox(
                width: cardWidth,
                child: _buildRoleCard(
                  context,
                  state,
                  UserRole.guest,
                  lblGuest,
                  Icons.person_outline,
                ),
              ),
            ],
          );
        });
      },
    );
  }

  Widget _buildRoleCard(
    BuildContext context,
    AuthenticationState state,
    UserRole role,
    String label,
    IconData icon,
  ) {
    final isSelected = state.formState.selectedUserRole == role;
    return InkWell(
      onTap: () => _authenticationCubit.toggleUserRoles(role),
      borderRadius: BorderRadius.circular(S.s12),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.1, // Responsive height
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).primaryColor.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(S.s12),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Theme.of(context).colorScheme.outline,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : Theme.of(context).colorScheme.onSurface,
            ),
            const SizedBox(width: S.s8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// BUTTON :- NEXT
  Widget _buildBtnNext() {
    return CustomFilledButton(
      label: "Next".toUpperCase(),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PhoneInputScreen()),
        );
      },
    );
  }
}
