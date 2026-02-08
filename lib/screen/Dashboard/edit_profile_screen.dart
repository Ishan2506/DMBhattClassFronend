import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dm_bhatt_tutions/constant/app_images.dart';
import 'package:dm_bhatt_tutions/network/api_service.dart';
import 'package:dm_bhatt_tutions/utils/custom_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_loader.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isUpdating = false;
  
  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _parentPhoneController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _schoolNameController = TextEditingController();

  // Selection States
  String? _selectedStandard;
  String? _selectedMedium;
  String? _selectedStream; 
  String? _selectedState = "Gujarat";
  String? _selectedInstitute;

  XFile? _imageFile;
  String? _currentPhotoPath;
  final ImagePicker _picker = ImagePicker();

   // Data Lists
  final List<String> _standards = ["6", "7", "8", "9", "10", "11", "12"];
  final List<String> _institutes = ["D.M.BHATT Institute", "Other"];

  final List<String> _mediums = ["English", "Gujarati"];
  final List<String> _streams = ["Science", "Commerce"];
  
  final Map<String, List<String>> _stateCityMap = {
    "Gujarat": ["Ahmedabad", "Surat", "Vadodara", "Rajkot"],
    "Maharashtra": ["Mumbai", "Pune", "Nagpur", "Nashik"],
    "Rajasthan": ["Jaipur", "Udaipur", "Jodhpur", "Kota"],
  };

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        setState(() => _isLoading = false);
        return;
      }

      final response = await ApiService.getProfile(token);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final user = data['user'];
        final profile = data['profile'];

        setState(() {
           _nameController.text = user['firstName'] ?? "";
           _emailController.text = user['email'] ?? "";
           _phoneController.text = user['phoneNum'] ?? "";
           _cityController.text = user['address']?['city'] ?? "";
           
            if (profile != null) {
               _selectedStandard = profile['std'];
               _selectedMedium = profile['medium'];
               _schoolNameController.text = profile['school'] ?? (profile['schoolName'] ?? "");
               _parentPhoneController.text = profile['parentPhone'] ?? "";
               
               if (_schoolNameController.text == "D.M.BHATT Institute") {
                 _selectedInstitute = "D.M.BHATT Institute";
               } else if (_schoolNameController.text.isNotEmpty) {
                 _selectedInstitute = "Other";
               }
            }
            _currentPhotoPath = user['photoPath'];
            _isLoading = false;
        });
      } else {
        CustomToast.showError(context, "Failed to fetch profile");
        setState(() => _isLoading = false);
      }
    } catch (e) {
      CustomToast.showError(context, "Error: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isUpdating = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        CustomToast.showError(context, "Session expired");
        setState(() => _isUpdating = false);
        return;
      }

      final Map<String, dynamic> data = {
        'firstName': _nameController.text,
        'email': _emailController.text,
        'phoneNum': _phoneController.text,
        'school': _schoolNameController.text,
        'std': _selectedStandard,
        'medium': _selectedMedium,
        'city': _cityController.text,
        'parentPhone': _parentPhoneController.text,
      };

      final response = await ApiService.updateProfile(token, data, imageFile: _imageFile);

      if (response.statusCode == 200) {
        CustomToast.showSuccess(context, 'Profile Updated Successfully');
        Navigator.pop(context, true); // Pass true to indicate update happened
      } else {
        CustomToast.showError(context, "Update Failed: ${response.body}");
      }
    } catch (e) {
      CustomToast.showError(context, "Error: $e");
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  Future<List<String>> _fetchSchools(String query) async {
    final cityToSearch = _cityController.text.isNotEmpty ? _cityController.text : "Ahmedabad";

    if (query.isEmpty) return [];
    
    final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=$query+school+in+$cityToSearch&format=json&limit=5');
    
    try {
      final response = await http.get(url, headers: {
        'User-Agent': 'DMBhattClasses/1.0', 
      });

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        return data.map<String>((e) => e['display_name'] as String).toList();
      }
    } catch (e) {
      debugPrint("Error fetching schools: $e");
    }
    return [];
  }

  Future<void> _pickImage() async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.gallery); // Changed to gallery for better testing
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
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
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
              if (_isLoading)
                const LinearProgressIndicator(minHeight: 2),
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
                            color: isDark ? Colors.grey.shade800 : theme.colorScheme.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: CircleAvatar(
                            radius: 50,
                            backgroundColor: theme.cardColor,
                            backgroundImage: _imageFile != null 
                                ? (kIsWeb 
                                    ? NetworkImage(_imageFile!.path) 
                                    : FileImage(File(_imageFile!.path))) as ImageProvider
                                : (_currentPhotoPath != null && _currentPhotoPath!.isNotEmpty)
                                    ? NetworkImage(_currentPhotoPath!)
                                    : const AssetImage("assets/images/user_placeholder.png") as ImageProvider,
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
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
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
                       if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(val)) return "Invalid Email";
                       return null;
                    },
                  ),
                  const SizedBox(height: 16),
    
                  // Phone
                  _buildTextField(
                    context,
                    controller: _phoneController,
                    hint: "Phone Number", 
                    icon: Icons.phone_outlined, 
                    inputType: TextInputType.phone,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
                    validator: (val) => val!.length != 10 ? "Invalid phone" : null,
                  ),
                  const SizedBox(height: 16),
    
                  // Parent's Mobile
                  _buildTextField(
                    context,
                    controller: _parentPhoneController,
                    hint: "Parent's Mobile Number", 
                    icon: Icons.family_restroom_outlined, 
                    inputType: TextInputType.phone,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
                  ),
                  const SizedBox(height: 16),
    
                  // Standard
                  _buildDropdown(
                    context,
                    hint: "Standard",
                    icon: Icons.school_outlined,
                    value: _selectedStandard,
                    items: _standards,
                    onChanged: (val) => setState(() => _selectedStandard = val),
                  ),
                  const SizedBox(height: 16),
    
                  // Medium
                  _buildDropdown(
                    context,
                    hint: "Medium",
                    icon: Icons.language,
                    value: _selectedMedium,
                    items: _mediums,
                    onChanged: (val) => setState(() => _selectedMedium = val),
                  ),
                   const SizedBox(height: 16),
                   
                   // Stream (Only if relevant)
                   if (_selectedStandard == "11" || _selectedStandard == "12") ...[
                     _buildDropdown(
                      context,
                      hint: "Stream",
                      icon: Icons.science_outlined,
                      value: _selectedStream,
                      items: _streams,
                      onChanged: (val) => setState(() => _selectedStream = val),
                    ),
                    const SizedBox(height: 16),
                   ],
    
    
                   // State 
                  _buildDropdown(
                    context,
                    hint: "State",
                    icon: Icons.map_outlined,
                    value: _selectedState,
                    items: _stateCityMap.keys.toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedState = val;
                       // _selectedCity = null; 
                      });
                    },
                  ),
                  const SizedBox(height: 16),
    
                  // City
                   _buildTextField(
                    context,
                    controller: _cityController,
                    hint: "City",
                    icon: Icons.location_city,
                  ),
                  const SizedBox(height: 16),
    
                  // Institute Dropdown
                  _buildDropdown(
                    context,
                    hint: "Institute Name",
                    icon: Icons.business,
                    value: _selectedInstitute,
                    items: _institutes,
                    onChanged: (val) {
                      setState(() {
                        _selectedInstitute = val;
                        if (val == "D.M.BHATT Institute") {
                          _schoolNameController.text = "D.M.BHATT Institute";
                        } else {
                          // Keep existing text if switching to Other, or clear it?
                          // Better to clear if it was "D.M.BHATT Institute" before
                          if (_schoolNameController.text == "D.M.BHATT Institute") {
                            _schoolNameController.text = "";
                          }
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // School Name Autocomplete (Visible only if Other is selected)
                  if (_selectedInstitute == "Other") ...[
                    LayoutBuilder(
                      builder: (context, constraints) {
                        return Autocomplete<String>(
                          optionsBuilder: (TextEditingValue textEditingValue) {
                            if (textEditingValue.text == '') {
                              return const Iterable<String>.empty();
                            }
                            return _fetchSchools(textEditingValue.text);
                          },
                          onSelected: (String selection) {
                            _schoolNameController.text = selection;
                          },
                          initialValue: TextEditingValue(text: _schoolNameController.text), 
                          fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                             // Sync back to controller immediately when typing manually
                             textEditingController.addListener(() {
                                 _schoolNameController.text = textEditingController.text;
                             });
                            
                             // If pre-filled value exists, ensure it's shown
                             if (_schoolNameController.text.isNotEmpty && textEditingController.text.isEmpty && _schoolNameController.text != "D.M.BHATT Institute") {
                                 textEditingController.text = _schoolNameController.text;
                             }
      
                            return Container(
                              decoration: BoxDecoration(
                                color: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
                              ),
                              child: TextFormField(
                                controller: textEditingController,
                                focusNode: focusNode,
                                 validator: (val) => val == null || val.isEmpty ? "Required" : null,
                                style: GoogleFonts.poppins(color: theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.bold), 
                                decoration: InputDecoration(
                                  hintText: "School Name",
                                  hintStyle: GoogleFonts.poppins(color: isDark ? Colors.grey.shade400 : Colors.grey),
                                  prefixIcon: Icon(Icons.school_outlined, color: isDark ? Colors.grey : Colors.black54),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                ),
                              ),
                            );
                          },
                          optionsViewBuilder: (context, onSelected, options) {
                            return Align(
                              alignment: Alignment.topLeft,
                              child: Material(
                                elevation: 4.0,
                                 borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  width: constraints.maxWidth,
                                  constraints: const BoxConstraints(maxHeight: 200),
                                  decoration: BoxDecoration(
                                     color: theme.cardColor,
                                      borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: ListView.builder(
                                    padding: EdgeInsets.zero,
                                    shrinkWrap: true,
                                    itemCount: options.length,
                                    itemBuilder: (BuildContext context, int index) {
                                      final String option = options.elementAt(index);
                                      final displayName = option.split(',')[0]; 
                                      return InkWell(
                                        onTap: () {
                                          onSelected(option);
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Text(displayName, style: GoogleFonts.poppins(color: theme.textTheme.bodyLarge?.color)),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      }
                    ),
                    const SizedBox(height: 16),
                  ],
    
    
                  const SizedBox(height: 32),
    
                  // Update Button
                  SizedBox(
                    width: double.infinity,
                    height: MediaQuery.of(context).size.height * 0.07,
                    child: ElevatedButton(
                      onPressed: _isUpdating ? null : _updateProfile,
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
                          fontSize: MediaQuery.of(context).size.width * 0.045,
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
          
          if (_isUpdating)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CustomLoader(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField(BuildContext context, {
    required String hint, 
    required IconData icon, 
    TextEditingController? controller,
    bool isPassword = false, 
    bool isVisible = false,
    VoidCallback? onVisibilityChanged,
    TextInputType inputType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword && !isVisible,
        keyboardType: inputType,
        inputFormatters: inputFormatters,
        validator: validator,
        style: GoogleFonts.poppins(color: theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.bold), 
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.poppins(color: isDark ? Colors.grey.shade400 : Colors.grey),
          prefixIcon: Icon(icon, color: isDark ? Colors.grey : Colors.black54),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildDropdown(BuildContext context, {
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
        border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          hint: Row(
            children: [
              Icon(icon, color: isDark ? Colors.grey : Colors.black54),
              const SizedBox(width: 12),
              Text(hint, style: GoogleFonts.poppins(color: isDark ? Colors.grey.shade400 : Colors.grey)),
            ],
          ),
          value: value,
          icon: isReadOnly ? const SizedBox() : Icon(Icons.keyboard_arrow_down, color: isDark ? Colors.grey : Colors.black54), // Hide icon if read-only
          dropdownColor: theme.cardColor, 
          style: GoogleFonts.poppins(color: theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.bold),
          selectedItemBuilder: (BuildContext context) {
            return items.map<Widget>((String item) {
              return Align(
                 alignment: Alignment.centerLeft,
                 child: Row(
                   children: [
                     Icon(icon, color: isDark ? Colors.grey : Colors.black54), 
                     const SizedBox(width: 12),
                     Text(
                       item,
                       style: GoogleFonts.poppins(color: theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.bold), 
                     ),
                   ],
                 ),
              );
            }).toList();
          },
          items: items.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: isReadOnly ? null : onChanged, // Disable interaction
        ),
      ),
    );
  }
}
