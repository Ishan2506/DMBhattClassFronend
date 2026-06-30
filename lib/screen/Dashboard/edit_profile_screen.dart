import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dm_bhatt_tutions/network/api_service.dart';
import 'package:dm_bhatt_tutions/utils/custom_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_loader.dart';
import 'package:dm_bhatt_tutions/l10n/app_localizations.dart';
import 'package:dm_bhatt_tutions/utils/validation_utils.dart';
import 'package:dm_bhatt_tutions/utils/states_cities_data.dart';
import 'package:intl/intl.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _selectedDob;

  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _parentPhoneController = TextEditingController();
  final TextEditingController _customCityController = TextEditingController();

  // Selection States
  String? _selectedStandard;
  String? _selectedMedium;
  String? _selectedStream;
  String? _selectedState = "Gujarat";
  String? _selectedCity;
  String? _selectedBoard;
  String? _selectedRole;

  XFile? _imageFile;
  String? _currentPhotoPath;
  final ImagePicker _picker = ImagePicker();

  // Data Lists
  final List<String> _standards = ["6", "7", "8", "9", "10", "11", "12"];

  final List<String> _mediums = ["English", "Gujarati"];
  final List<String> _streams = ["Science", "Commerce"];
  final List<String> _boards = ["GSEB", "CBSE"];
  final List<String> _roles = ["Student", "Teacher"];

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) CustomLoader.show(context);
    });
    try {
      // Token is managed internally by ApiService

      debugPrint("token ${ApiService.userToken}");
      final response = await ApiService.getProfile();

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final user = data['user'];
        final profile = data['profile'];

        setState(() {
          _nameController.text =
              "${user['firstName'] ?? ""} ${user['middleName'] ?? ""} ${user['lastName'] ?? ""}"
                  .trim();
          _emailController.text = user['email'] ?? (profile?['email'] ?? "");
          _phoneController.text = user['phoneNum'] ?? "";
          
          final rawDob = user['dob'];
          if (rawDob != null && rawDob.toString().isNotEmpty) {
            try {
              _selectedDob = DateTime.parse(rawDob.toString());
            } catch (e) {
              debugPrint("Error parsing DOB in edit profile: $e");
            }
          }
          
          final city =
              user['city'] ??
              profile?['city'] ??
              user['address']?['city'] ??
              "";
          // Check if city exists in the known list for the state; otherwise use "Other" + text field
          final bool cityKnown = city.isNotEmpty &&
              _selectedState != null &&
              (indiaStatesCities[_selectedState]?.contains(city) ?? false);
          if (city.isNotEmpty && !cityKnown) {
            _selectedCity = "Other";
            _customCityController.text = city;
          } else {
            _selectedCity = city.isNotEmpty ? city : null;
          }

          if (profile != null) {
            _selectedStandard = profile['std'];

            if (_selectedStandard != null && _selectedStandard!.contains(' ')) {
              final parts = _selectedStandard!.split(' ');
              _selectedStandard = parts[0];
              _selectedStream = parts.skip(1).join(' ');
            }
            if (!_standards.contains(_selectedStandard)) {
              _selectedStandard = null;
            }

            _selectedMedium = profile['medium'];
            if (!_mediums.contains(_selectedMedium)) _selectedMedium = null;

            _selectedStream = profile['stream'] ?? _selectedStream;
            if (!_streams.contains(_selectedStream)) _selectedStream = null;

            _parentPhoneController.text =
                profile['parentPhone'] ??
                (profile['parentNo'] ?? (user['parentPhone'] ?? ""));
            _selectedBoard = profile['board'];
            if (!_boards.contains(_selectedBoard)) _selectedBoard = null;

            _selectedRole = user['loginAs'];
            if (!_roles.contains(_selectedRole)) _selectedRole = null;

            _selectedState =
                user['state'] ??
                profile['state'] ??
                user['address']?['state'] ??
                "Gujarat";
            if (!indiaStatesCities.keys.contains(_selectedState)) {
              _selectedState = "Gujarat";
            }

            // Validate city against state (allow "Other" for custom cities)
            if (_selectedCity != null &&
                _selectedCity != "Other" &&
                indiaStatesCities[_selectedState] != null &&
                !indiaStatesCities[_selectedState]!.contains(_selectedCity)) {
              _selectedCity = "Other";
              _customCityController.text = _selectedCity ?? "";
            }
          }
          _currentPhotoPath = user['photoPath'];
        });
      } else {
        CustomToast.showError(
          context,
          "Failed to fetch profile: ${ApiService.getErrorMessage(response.body)}",
        );
      }
    } catch (e) {
      CustomToast.showError(context, "Error: $e");
    } finally {
      CustomLoader.hide(context);
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final l10n = AppLocalizations.of(context)!;
    if (_phoneController.text.trim() == _parentPhoneController.text.trim()) {
      CustomToast.showError(context, l10n.phoneNumbersCannotBeSame);
      return;
    }

    CustomLoader.show(context);

    try {
      // Token is managed internally

      final Map<String, dynamic> data = {
        'firstName': _nameController.text.trim(),
        'middleName': '',
        'lastName': '',
        'email': _emailController.text,
        'phoneNum': _phoneController.text,
        'std': _selectedStandard,
        'stream': _selectedStream,
        'medium': _selectedMedium,
        'board': _selectedBoard,
        'loginAs': _selectedRole,
        'city': _selectedCity == "Other"
            ? _customCityController.text.trim()
            : _selectedCity,
        'state': _selectedState,
        'parentPhone': _parentPhoneController.text,
      };

      final response = await ApiService.updateProfile(
        data,
        imageFile: _imageFile,
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        // Sync SharedPreferences with new values immediately
        final prefs = await SharedPreferences.getInstance();
        final updatedUser = responseData['user'];
        if (updatedUser != null) {
          final fullName =
              "${updatedUser['firstName'] ?? ''} ${updatedUser['middleName'] ?? ''} ${updatedUser['lastName'] ?? ''}"
                  .trim();
          await prefs.setString('userName', fullName);
          if (updatedUser['phoneNum'] != null) {
            await prefs.setString('userPhone', updatedUser['phoneNum']);
          }
          if (updatedUser['photoPath'] != null) {
            await prefs.setString('userPic', updatedUser['photoPath']);
          }
        }

        final updatedProfile = responseData['profile'];
        if (updatedProfile != null) {
          if (updatedProfile['std'] != null) {
            await prefs.setString('std', updatedProfile['std'].toString());
          }
          if (updatedProfile['medium'] != null) {
            await prefs.setString(
              'medium',
              updatedProfile['medium'].toString(),
            );
          }
          if (updatedProfile['board'] != null) {
            await prefs.setString('board', updatedProfile['board'].toString());
          }
          if (updatedProfile['stream'] != null) {
            await prefs.setString(
              'stream',
              updatedProfile['stream'].toString(),
            );
          }
        }

        if (!mounted) return;
        CustomLoader.hide(context); // Hide loader before popping
        CustomToast.showSuccess(context, "Profile updated successfully!");
        debugPrint("Popping with data: $responseData");
        Navigator.pop(
          context,
          responseData,
        ); // Return the full data to StudentProfileScreen
      } else {
        CustomLoader.hide(context); // Hide loader on failure too
        CustomToast.showError(
          context,
          "Update Failed: ${ApiService.getErrorMessage(response.body)}",
        );
      }
    } catch (e) {
      if (mounted) {
        CustomLoader.hide(context);
        CustomToast.showError(context, "Error: $e");
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.gallery,
      ); // Changed to gallery for better testing
      if (photo != null) {
        setState(() {
          _imageFile = photo;
        });
      }
    } catch (e) {
      CustomToast.showError(context, "Error picking image: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor, // Dynamic
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Edit Profile",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.primary.withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Profile Image
                        Center(
                          child: Stack(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.grey.shade800
                                      : theme.colorScheme.primary.withOpacity(
                                          0.1,
                                        ),
                                  shape: BoxShape.circle,
                                ),
                                child: CircleAvatar(
                                  radius: 50,
                                  backgroundColor: theme.cardColor,
                                  backgroundImage: _imageFile != null
                                      ? (kIsWeb
                                                ? NetworkImage(_imageFile!.path)
                                                : FileImage(
                                                    File(_imageFile!.path),
                                                  ))
                                            as ImageProvider
                                      : (_currentPhotoPath != null &&
                                            _currentPhotoPath!.isNotEmpty)
                                      ? NetworkImage(_currentPhotoPath!)
                                      : const AssetImage(
                                              "assets/images/user_placeholder.png",
                                            )
                                            as ImageProvider,
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: _pickImage,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Name
                        _buildTextField(
                          context,
                          controller: _nameController,
                          hint: "Name",
                          icon: Icons.person_outline,
                          validator: (val) => val!.isEmpty ? "Required" : null,
                        ),
                        const SizedBox(height: 16),

                        // Email
                        _buildTextField(
                          context,
                          controller: _emailController,
                          hint: "Email ID",
                          icon: Icons.email_outlined,
                          inputType: TextInputType.emailAddress,
                          validator: (val) {
                            if (val == null || val.isEmpty) return "Required";
                            if (!RegExp(
                              r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                            ).hasMatch(val)) {
                              return "Invalid Email";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Phone (ReadOnly)
                        _buildTextField(
                          context,
                          controller: _phoneController,
                          hint: "Phone Number",
                          icon: Icons.phone_outlined,
                          readOnly: true,
                          inputType: TextInputType.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(10),
                          ],
                          validator: ValidationUtils.validateIndianPhoneNumber,
                        ),
                        const SizedBox(height: 16),

                        // Parent's Mobile (ReadOnly)
                        _buildTextField(
                          context,
                          controller: _parentPhoneController,
                          hint: "Parent's Mobile Number",
                          icon: Icons.family_restroom_outlined,
                          readOnly: true,
                          inputType: TextInputType.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(10),
                          ],
                          validator: ValidationUtils.validateIndianPhoneNumber,
                        ),
                        const SizedBox(height: 16),

                        // Date of Birth (ReadOnly)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.cake_rounded, color: isDark ? Colors.grey : Colors.black54),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _selectedDob == null
                                      ? "Not Provided"
                                      : "${DateFormat('dd/MM/yyyy').format(_selectedDob!)}",
                                  style: GoogleFonts.poppins(
                                    color: theme.textTheme.bodyLarge?.color,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Standard
                        _buildDropdown(
                          context,
                          hint: "Standard",
                          icon: Icons.school_outlined,
                          value: _selectedStandard,
                          items: _standards,
                          onChanged: (val) =>
                              setState(() => _selectedStandard = val),
                          isReadOnly: true,
                        ),
                        const SizedBox(height: 16),

                        // Medium
                        _buildDropdown(
                          context,
                          hint: "Medium",
                          icon: Icons.language,
                          value: _selectedMedium,
                          items: _mediums,
                          onChanged: (val) =>
                              setState(() => _selectedMedium = val),
                          isReadOnly: true,
                        ),
                        const SizedBox(height: 16),

                        // Board Dropdown
                        _buildDropdown(
                          context,
                          hint: l10n.board,
                          icon: Icons.dashboard_outlined,
                          value: _selectedBoard,
                          items: _boards,
                          onChanged: (val) =>
                              setState(() => _selectedBoard = val),
                          isReadOnly: true,
                        ),
                        const SizedBox(height: 16),

                        // Stream (Only if relevant)
                        if (_selectedStandard == "11" ||
                            _selectedStandard == "12") ...[
                          _buildDropdown(
                            context,
                            hint: "Stream",
                            icon: Icons.science_outlined,
                            value: _selectedStream,
                            items: _streams,
                            onChanged: (val) =>
                                setState(() => _selectedStream = val),
                            isReadOnly: true,
                          ),
                          const SizedBox(height: 16),
                        ],

                        // State
                        _buildDropdown(
                          context,
                          hint: "State",
                          icon: Icons.map_outlined,
                          value: _selectedState,
                          items: indiaStatesCities.keys.toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedState = val;
                              _selectedCity = null; // Reset city when state changes
                              _customCityController.clear();
                            });
                          },
                        ),
                        const SizedBox(height: 16),

                        // City
                        _buildDropdown(
                          context,
                          hint: "City",
                          icon: Icons.location_city,
                          value: _selectedCity,
                          items: _selectedState != null ? (indiaStatesCities[_selectedState] ?? []) : [],
                          onChanged: (val) {
                            setState(() {
                              _selectedCity = val;
                              if (val != "Other") _customCityController.clear();
                            });
                          },
                        ),
                        if (_selectedCity == "Other") ...[
                          const SizedBox(height: 16),
                          _buildTextField(
                            context,
                            hint: "Enter City Name",
                            icon: Icons.location_city_outlined,
                            controller: _customCityController,
                            validator: (val) {
                              if (_selectedCity == "Other" && (val == null || val.trim().isEmpty)) {
                                return "Please enter your city name";
                              }
                              return null;
                            },
                          ),
                        ],
                        const SizedBox(height: 16),

                        const SizedBox(height: 16),

                        // Login As Dropdown
                        /*
                  _buildDropdown(
                    context,
                    hint: l10n.loginAs,
                    icon: Icons.person_pin_outlined,
                    value: _selectedRole,
                    items: _roles,
                    onChanged: (val) => setState(() => _selectedRole = val),
                  ),
                  */

                        // Update Button
                        SizedBox(
                          width: double.infinity,
                          height: MediaQuery.of(context).size.height * 0.07,
                          child: ElevatedButton(
                            onPressed: _updateProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              elevation: 2,
                            ),
                            child: Text(
                              "Update Profile",
                              style: GoogleFonts.poppins(
                                fontSize:
                                    MediaQuery.of(context).size.width * 0.045,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    BuildContext context, {
    required String hint,
    required IconData icon,
    TextEditingController? controller,
    bool isPassword = false,
    bool isVisible = false,
    bool readOnly = false,
    TextInputType inputType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: readOnly
            ? (isDark ? Colors.grey.shade800 : Colors.grey.shade200)
            : (isDark ? Colors.grey.shade900 : Colors.grey.shade50),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
        ),
      ),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        enableInteractiveSelection: !readOnly,
        obscureText: isPassword && !isVisible,
        keyboardType: inputType,
        inputFormatters: inputFormatters,
        validator: readOnly ? null : validator,
        style: GoogleFonts.poppins(
          color: theme.textTheme.bodyLarge?.color,
          fontWeight: FontWeight.bold,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.poppins(
            color: isDark ? Colors.grey.shade400 : Colors.grey,
          ),
          prefixIcon: Icon(icon, color: isDark ? Colors.grey : Colors.black54),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown(
    BuildContext context, {
    required String hint,
    required IconData icon,
    required String? value,
    required List<String> items,
    required Function(String?)? onChanged,
    bool isReadOnly = false,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isReadOnly
            ? (isDark ? Colors.grey.shade800 : Colors.grey.shade200)
            : (isDark ? Colors.grey.shade900 : Colors.grey.shade50),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          hint: Row(
            children: [
              Icon(icon, color: isDark ? Colors.grey : Colors.black54),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  hint,
                  style: GoogleFonts.poppins(
                    color: isDark ? Colors.grey.shade400 : Colors.grey,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
          value: value,
          icon: isReadOnly
              ? const SizedBox()
              : Icon(
                  Icons.keyboard_arrow_down,
                  color: isDark ? Colors.grey : Colors.black54,
                ), // Hide icon if read-only
          dropdownColor: theme.cardColor,
          style: GoogleFonts.poppins(
            color: theme.textTheme.bodyLarge?.color,
            fontWeight: FontWeight.bold,
          ),
          selectedItemBuilder: (BuildContext context) {
            final l10n = AppLocalizations.of(context)!;
            return items.map<Widget>((String item) {
              String label = item;
              if (item == "Student") label = l10n.student;
              if (item == "Teacher") label = l10n.teacher;
              return Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    Icon(icon, color: isDark ? Colors.grey : Colors.black54),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        label,
                        style: GoogleFonts.poppins(
                          color: theme.textTheme.bodyLarge?.color,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              );
            }).toList();
          },
          items: items.map((String value) {
            final l10n = AppLocalizations.of(context)!;
            String label = value;
            if (value == "Student") label = l10n.student;
            if (value == "Teacher") label = l10n.teacher;
            return DropdownMenuItem<String>(
              value: value,
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            );
          }).toList(),
          onChanged: isReadOnly ? null : onChanged, // Disable interaction
        ),
      ),
    );
  }
}
