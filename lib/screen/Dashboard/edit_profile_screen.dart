import 'dart:convert';
import 'dart:io';
import 'package:dm_bhatt_tutions/constant/app_images.dart';
import 'package:dm_bhatt_tutions/utils/custom_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers (Pre-filled with mock data)
  final TextEditingController _nameController = TextEditingController(text: "Devarsh Shah");
  final TextEditingController _phoneController = TextEditingController(text: "9106315912");
  final TextEditingController _parentPhoneController = TextEditingController(text: "9876543210");
  final TextEditingController _cityController = TextEditingController(text: "Ahmedabad");
  final TextEditingController _schoolNameController = TextEditingController(text: "St. Xavier's High School");

  // Selection States (Fixed)
  String? _selectedStandard = "10";
  String? _selectedMedium = "English";
  String? _selectedStream; // Null for 10th
  String? _selectedState = "Gujarat";

  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

   // Data Lists
  final List<String> _standards = ["6", "7", "8", "9", "10", "11", "12"];
  final List<String> _mediums = ["English", "Gujarati"];
  final List<String> _streams = ["Science", "Commerce"];
  
  final Map<String, List<String>> _stateCityMap = {
    "Gujarat": ["Ahmedabad", "Surat", "Vadodara", "Rajkot"],
    "Maharashtra": ["Mumbai", "Pune", "Nagpur", "Nashik"],
    "Rajasthan": ["Jaipur", "Udaipur", "Jodhpur", "Kota"],
  };

  Future<List<String>> _fetchSchools(String query) async {
    // For edit profile, state/city might be pre-filled 'Gujarat'/'Ahmedabad' but logic should hold.
    // If city logic relies on user selection, ensure _selectedState -> _selectedCity logic is robust.
    // In current Edit Code, city is a Text Field, which complicates specific API search if "Ahmedabad" isn't strictly selected from a list 
    // BUT the prompt implies using similar city-wise logic. 
    // If the user manually edits city text, we use that value.
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
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
      if (photo != null) {
        setState(() {
          _imageFile = File(photo.path);
        });
      }
    } catch (e) {
      CustomToast.showError(context, "Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black54),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Edit Profile",
          style: GoogleFonts.poppins(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
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
                        color: Colors.blue.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white,
                        backgroundImage: _imageFile != null 
                            ? FileImage(_imageFile!) 
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
                            color: Colors.blue.shade700,
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
                controller: _nameController,
                hint: "Name", 
                icon: Icons.person_outline,
                validator: (val) => val!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 16),

              // Phone
              _buildTextField(
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
                controller: _parentPhoneController,
                hint: "Parent's Mobile Number", 
                icon: Icons.family_restroom_outlined, 
                inputType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
                 validator: (val) => val!.length != 10 ? "Invalid phone" : null,
              ),
              const SizedBox(height: 16),

              
               // School Name Removed from here (to be added below City)

              // Standard (Disabled)
              _buildDropdown(
                hint: "Standard",
                icon: Icons.school_outlined,
                value: _selectedStandard,
                items: _standards,
                onChanged: null, // Disabled
                isReadOnly: true,
              ),
              const SizedBox(height: 16),

              // Medium (Disabled)
              _buildDropdown(
                hint: "Medium",
                icon: Icons.language,
                value: _selectedMedium,
                items: _mediums,
                onChanged: null, // Disabled
                isReadOnly: true,
              ),
               const SizedBox(height: 16),
               
               // Stream (Disabled - Only if relevant)
               if (_selectedStandard == "11" || _selectedStandard == "12") ...[
                 _buildDropdown(
                  hint: "Stream",
                  icon: Icons.science_outlined,
                  value: _selectedStream,
                  items: _streams,
                  onChanged: null, // Disabled
                   isReadOnly: true,
                ),
                const SizedBox(height: 16),
               ],


               // State 
              _buildDropdown(
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
                controller: _cityController,
                hint: "City", // Taking simple text for city logic in edit for simplicity
                icon: Icons.location_city,
              ),
              const SizedBox(height: 16),

              // School Name Autocomplete
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
                    initialValue: TextEditingValue(text: _schoolNameController.text), // Pre-fill
                    fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                      // Sync logic needed? 
                      // If it's prefilled, the initialValue handles display. 
                      // User edits update the local textEditingController.
                      // We need to sync back to _schoolNameController on change.
                       textEditingController.addListener(() {
                          _schoolNameController.text = textEditingController.text;
                       });
                      
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: TextFormField(
                          controller: textEditingController,
                          focusNode: focusNode,
                           validator: (val) => val == null || val.isEmpty ? "Required" : null,
                          style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.bold), 
                          decoration: InputDecoration(
                            hintText: "School Name",
                            hintStyle: GoogleFonts.poppins(color: Colors.grey),
                            prefixIcon: const Icon(Icons.school_outlined, color: Colors.black54),
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
                               color: Colors.white,
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
                                    child: Text(displayName, style: GoogleFonts.poppins(color: Colors.black87)),
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


              const SizedBox(height: 32),

              // Update Button
              SizedBox(
                width: double.infinity,
                height: MediaQuery.of(context).size.height * 0.07,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      // Logic to update profile
                      CustomToast.showSuccess(context, 'Profile Updated Successfully');
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 2,
                  ),
                  child: Text(
                    "Update Profile",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
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
    );
  }

  Widget _buildTextField({
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword && !isVisible,
        keyboardType: inputType,
        inputFormatters: inputFormatters,
        validator: validator,
        style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.bold), 
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.poppins(color: Colors.grey),
          prefixIcon: Icon(icon, color: Colors.black54),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String hint,
    required IconData icon,
    required String? value,
    required List<String> items,
    required Function(String?)? onChanged,
    bool isReadOnly = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isReadOnly ? Colors.grey.shade200 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          hint: Row(
            children: [
              Icon(icon, color: Colors.black54),
              const SizedBox(width: 12),
              Text(hint, style: GoogleFonts.poppins(color: Colors.grey)),
            ],
          ),
          value: value,
          icon: isReadOnly ? const SizedBox() : const Icon(Icons.keyboard_arrow_down, color: Colors.black54), // Hide icon if read-only
          dropdownColor: Colors.white, 
          style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.bold),
          selectedItemBuilder: (BuildContext context) {
            return items.map<Widget>((String item) {
              return Align(
                 alignment: Alignment.centerLeft,
                 child: Row(
                   children: [
                     Icon(icon, color: Colors.black54), 
                     const SizedBox(width: 12),
                     Text(
                       item,
                       style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.bold), 
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
