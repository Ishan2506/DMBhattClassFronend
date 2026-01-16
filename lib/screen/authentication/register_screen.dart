import 'package:dm_bhatt_tutions/bloc/authentication/authentication_cubit.dart';
import 'package:dm_bhatt_tutions/constant/string_constant.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_dropdown.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_filled_button.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_text_field.dart';
import 'package:dm_bhatt_tutions/screen/authentication/register_dpin_screen.dart';
import 'package:dm_bhatt_tutions/utils/app_sizes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  String? _selectedStd;
  String? _selectedMedium;

  // --- Student Controllers ---
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _schoolController = TextEditingController();

  // --- Assistant Controllers ---
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _aadharController = TextEditingController();
  final _addressController = TextEditingController();

  final List<String> _stdList = [
    "8th",
    "9th",
    "10th",
    "11th Sci",
    "11th Com",
    "12th Sci",
    "12th Com",
  ];
  final List<String> _mediumList = ["English", "Gujarati"];

  late AuthenticationCubit _authenticationCubit;

  @override
  void initState() {
    _authenticationCubit = BlocProvider.of<AuthenticationCubit>(context);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(lblRegister)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.06),
          child: Column(
            children: [
              _buildUserRoles(),
              blankVerticalSpace32,

              BlocBuilder<AuthenticationCubit, AuthenticationState>(
                buildWhen: (previous, current) =>
                    previous.formState.selectedRegistrationUserRole !=
                    current.formState.selectedRegistrationUserRole,
                builder: (context, state) {
                  if (state.formState.selectedRegistrationUserRole ==
                      UserRole.student) {
                    return _buildStudentForm();
                  } else {
                    return _buildAssistantForm();
                  }
                },
              ),

              blankVerticalSpace32,
              _buildBtnRegister(),
              blankVerticalSpace16,
              _buildTxtBtnBackToLogin(),
            ],
          ),
        ),
      ),
    );
  }

  /// USER ROLES HEADER
  Widget _buildUserRoles() {
    return BlocBuilder<AuthenticationCubit, AuthenticationState>(
      buildWhen: (previous, current) =>
          previous.formState.selectedRegistrationUserRole !=
          current.formState.selectedRegistrationUserRole,
      builder: (context, state) {
        final isStudent =
            state.formState.selectedRegistrationUserRole == UserRole.student;
        return Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: isStudent ? Colors.blue.withOpacity(0.1) : Colors.purple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: isStudent ? Colors.blue : Colors.purple,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isStudent ? Icons.school : Icons.admin_panel_settings,
                  color: isStudent ? Colors.blue : Colors.purple,
                ),
                const SizedBox(width: 12),
                Text(
                  isStudent ? "Student Registration" : "Assistant Registration",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isStudent ? Colors.blue : Colors.purple,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// STUDENT FORM
  Widget _buildStudentForm() {
    return Column(
      children: [
        CustomTextField(
          controller: _firstNameController,
          labelText: "$lblFirstName*",
          hintText: lblEnterFirstName,
        ),
        blankVerticalSpace16,
        CustomTextField(
          controller: _middleNameController,
          labelText: "$lblMiddleName*",
          hintText: lblEnterMiddleName,
        ),
        blankVerticalSpace16,
        CustomTextField(
          controller: _lastNameController,
          labelText: "$lblLastName*",
          hintText: lblEnterLastName,
        ),
        blankVerticalSpace16,
        CustomTextField(
          controller: _phoneController,
          labelText: "$lblPhoneNumber*",
          hintText: lblEnterPhoneNumber,
          prefixIcon: Icons.phone,
        ),
        blankVerticalSpace16,
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // STD DROPDOWN
            Expanded(
              child: CustomDropdown<String>(
                labelText: "$lblSTD*",
                hintText: lblSelectSTD,
                items: _stdList,
                value: _selectedStd,
                itemLabelBuilder: (item) => item,
                onChanged: (val) {
                  setState(() {
                    _selectedStd = val;
                  });
                },
              ),
            ),
            blankHorizontalsSpace16,

            // MEDIUM DROPDOWN
            Expanded(
              child: CustomDropdown<String>(
                labelText: "$lblMedium*",
                hintText: lblSelectMedium,
                items: _mediumList,
                value: _selectedMedium,
                itemLabelBuilder: (item) => item,
                onChanged: (val) {
                  setState(() {
                    _selectedMedium = val;
                  });
                },
              ),
            ),
          ],
        ),
        blankVerticalSpace16,
        CustomTextField(
          controller: _schoolController,
          labelText: "$lblSchool*",
          hintText: lblEnterSchoolName,
          prefixIcon: Icons.business,
        ),
        blankVerticalSpace24,
        _buildUploadButton(
          label: "$lblCapturePhotoWithBackground*",
          icon: Icons.camera_alt_outlined,
          onTap: () {},
        ),
      ],
    );
  }

  /// ASSISTANT FORM
  Widget _buildAssistantForm() {
    return Column(
      children: [
        CustomTextField(
          controller: _nameController,
          labelText: "$lblFullName*",
          hintText: lblEnterFullName,
        ),
        blankVerticalSpace16,
        CustomTextField(
          controller: _emailController,
          labelText: "$lblEmail*",
          hintText: lblTestEmail,
          prefixIcon: Icons.email_outlined,
        ),
        blankVerticalSpace16,
        CustomTextField(
          controller: _phoneController,
          labelText: "$lblPhoneNumber*",
          hintText: lblEnterPhoneNumber,
          prefixIcon: Icons.phone,
          inputType: TextInputType.phone,
        ),
        blankVerticalSpace16,
        CustomTextField(
          controller: _aadharController,
          labelText: "$lblAadharCardNumber*",
          hintText: hintAadharCardNumber,
        ),
        blankVerticalSpace16,
        _buildUploadButton(
          label: "$lblUploadAadharCard*",
          icon: Icons.file_upload_outlined,
          onTap: () {},
        ),
        blankVerticalSpace16,
        CustomTextField(
          controller: _addressController,
          labelText: "$lblAddress*",
          hintText: hintAddress,
        ),
      ],
    );
  }

  /// SHARED UPLOAD BUTTON UI
  Widget _buildUploadButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, S.s50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  /// BUTTON :- REGISTER
  Widget _buildBtnRegister() {
    return CustomFilledButton(
      label: lblRegister.toUpperCase(),
      onPressed: () {
        // Save selected standard to Cubit if it exists
        if (_selectedStd != null &&
            _authenticationCubit.state.formState.selectedRegistrationUserRole ==
                UserRole.student) {
          _authenticationCubit.updateStudentStandard(_selectedStd!);
        }
        
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const RegisterDPINScreen()),
        );
        // Handle logic based on _authenticationCubit.state.formState.selectedUserRole
      },
    );
  }

  /// TEXT BUTTON :- BACK TO LOGIN
  Widget _buildTxtBtnBackToLogin() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(lblAlreadyHaveAnAccount),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            lblLogin,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
