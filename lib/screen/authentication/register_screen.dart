import 'dart:io';

import 'package:dm_bhatt_tutions/bloc/authentication/authentication_cubit.dart';
import 'package:dm_bhatt_tutions/constant/string_constant.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_dropdown.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_filled_button.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_text_field.dart';
import 'package:dm_bhatt_tutions/model/registration_payload.dart';
import 'package:dm_bhatt_tutions/screen/authentication/register_dpin_screen.dart';
import 'package:dm_bhatt_tutions/utils/app_sizes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

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
  List<File> _assistantAadharFiles = [];  
  File? studentPhoto;

  final ImagePicker _picker = ImagePicker();

  void _openUploadOptions() {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text("Camera"),
            onTap: () {
              Navigator.pop(context);
              _pickFromCamera();
            },
          ),
          ListTile(
            leading: const Icon(Icons.folder),
            title: const Text("Storage"),
            onTap: () {
              Navigator.pop(context);
              _pickFromStorage();
            },
          ),
        ],
      );
    },
  );
}
Future<void> _pickFromCamera() async {
  final front = await _picker.pickImage(source: ImageSource.camera);
  if (front == null) return;

  final back = await _picker.pickImage(source: ImageSource.camera);
  if (back == null) return;

  setState(() {
    _assistantAadharFiles = [
      File(front.path),
      File(back.path),
    ];
  });
}
  Future<void> _pickFromStorage() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );

    if (result == null) return;

    final files =
        result.paths.where((p) => p != null).map((p) => File(p!)).toList();

    // 1 PDF
    if (files.length == 1 && files.first.path.endsWith('.pdf')) {
      setState(() {
        _assistantAadharFiles = files;
      });
      return;
    }

    // 2 Images
    if (files.length == 2 &&
        !files.any((f) => f.path.endsWith('.pdf'))) {
      setState(() {
        _assistantAadharFiles = files;
      });
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Select either 1 PDF or 2 images"),
      ),
    );
  }


  // Map<String, dynamic> buildRegistrationData({
  //   required UserRole role,
  // }) {
  //   switch (role) {

  //     case UserRole.admin:
  //       return {
  //         "role": "admin",
  //         "phoneNum": _phoneController.text.trim(),
  //         "name": _nameController.text.trim(),
  //         "email": _emailController.text.trim(),
  //       };

  //     case UserRole.assistant:
  //       return {
  //         "role": "assistant",
  //         "phoneNum": _phoneController.text.trim(),
  //         "name": _nameController.text.trim(),
  //         "email": _emailController.text.trim(),
  //         "aadharNum": _aadharController.text.trim(),
  //         "address": _addressController.text.trim(),
  //         "aadharFile": _assistantAadharFiles,
  //       };

  //     case UserRole.student:
  //       return {
  //         "role": "student",
  //         "phoneNum": _phoneController.text.trim(),
  //         "firstName": _firstNameController.text.trim(),
  //         "middleName": _middleNameController.text.trim(),
  //         "lastName": _lastNameController.text.trim(),
  //         "std": _selectedStd,
  //         "medium": _selectedMedium,
  //         "school": _schoolController.text.trim(),
  //         //"photo": studentPhotoFile,
  //       };

  //     case UserRole.guest:
  //       return {
  //         "role": "guest",
  //         "phoneNum": _phoneController.text.trim(),
  //         "firstName": _firstNameController.text.trim(),
  //         "middleName": _middleNameController.text.trim(),
  //         "lastName": _lastNameController.text.trim(),
  //         "schoolName": _schoolController.text.trim(),
  //         //"photo": guestPhotoFile,
  //       };
  //   }
  // }
  Future<void> pickStudentPhoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.camera, // or ImageSource.gallery
      imageQuality: 80, // compress
    );

    if (pickedFile != null) {
      setState(() {
        studentPhoto = File(pickedFile.path);
      });
    }
  }
  RegistrationPayload buildRegistrationPayload({
    required UserRole role,
  }) {
    switch (role) {
      case UserRole.admin:
        return RegistrationPayload(
          role: "admin",
          fields: {
            "role": "admin",
            "phoneNum": _phoneController.text.trim(),
            "name": _nameController.text.trim(),
            "email": _emailController.text.trim(),
          },
          files: [],
        );

      case UserRole.assistant:
        return RegistrationPayload(
          role: "assistant",
          fields: {
            "role": "assistant",
            "phoneNum": _phoneController.text.trim(),
            "name": _nameController.text.trim(),
            "email": _emailController.text.trim(),
            "aadharNum": _aadharController.text.trim(),
            "address": _addressController.text.trim(),
          },
          files: _assistantAadharFiles, // PDF OR 2 images
        );

      case UserRole.student:
        return RegistrationPayload(
          role: "student",
          fields: {
            "role": "student",
            "phoneNum": _phoneController.text.trim(),
            "firstName": _firstNameController.text.trim(),
            "middleName": _middleNameController.text.trim(),
            "lastName": _lastNameController.text.trim(),
            "std": _selectedStd ?? "",
            "medium": _selectedMedium ?? "",
            "school": _schoolController.text.trim(),
          },
          files: [?studentPhoto],
        );

      case UserRole.guest:
        return RegistrationPayload(
          role: "guest",
          fields: {
            "role": "guest",
            "phoneNum": _phoneController.text.trim(),
            "firstName": _firstNameController.text.trim(),
            "middleName": _middleNameController.text.trim(),
            "lastName": _lastNameController.text.trim(),
            "schoolName": _schoolController.text.trim(),
          },
          files: [],
        );
    }
  }




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
          onTap: () async {
            await pickStudentPhoto();
          },
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
          onTap: _openUploadOptions,
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
        final registrationData = buildRegistrationPayload(role: _authenticationCubit.state.formState.selectedRegistrationUserRole);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => RegisterDPINScreen(payload: registrationData,)),
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
