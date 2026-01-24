import 'package:dm_bhatt_tutions/constant/app_images.dart';
import 'package:dm_bhatt_tutions/screen/authentication/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool _isPasswordVisible = false;
  bool _agreedToTerms = false;
  
  // Selection States
  String? _selectedStandard;
  String? _selectedMedium;
  String? _selectedStream;
  String? _selectedState;
  String? _selectedCity;

  // Data Lists
  final List<String> _standards = ["6", "7", "8", "9", "10", "11", "12"];
  final List<String> _mediums = ["English", "Gujarati"];
  final List<String> _streams = ["Science", "Commerce"];
  
  final Map<String, List<String>> _stateCityMap = {
    "Gujarat": ["Ahmedabad", "Surat", "Vadodara", "Rajkot"],
    "Maharashtra": ["Mumbai", "Pune", "Nagpur", "Nashik"],
    "Rajasthan": ["Jaipur", "Udaipur", "Jodhpur", "Kota"],
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black54),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        // title: Text(
        //   "Back", 
        //   style: GoogleFonts.poppins(color: Colors.black54, fontSize: 16),
        // ),
        // titleSpacing: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Logo
             Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                shape: BoxShape.circle,
              ),
               child: Image.asset(
                imgDmBhattClassesLogo,
                height: 80,
                width: 80,
              ),
             ),
            const SizedBox(height: 24),
            
            Text(
              "Hey there,",
              style: GoogleFonts.poppins(fontSize: 16, color: Colors.black54),
            ),
            Text(
              "Welcome",
              style: GoogleFonts.poppins(
                fontSize: 24, 
                fontWeight: FontWeight.bold, 
                color: Colors.black87
              ),
            ),
            const SizedBox(height: 32),

          
            const SizedBox(height: 16),

            // Name
            _buildTextField(hint: "Name", icon: Icons.person_outline),
            const SizedBox(height: 16),

            // Phone
             _buildTextField(hint: "Phone Number", icon: Icons.phone_outlined, inputType: TextInputType.phone),
            const SizedBox(height: 16),

            // Password
            _buildTextField(
              hint: "Password",
              icon: Icons.lock_outline,
              isPassword: true,
              isVisible: _isPasswordVisible,
              onVisibilityChanged: () {
                setState(() {
                  _isPasswordVisible = !_isPasswordVisible;
                });
              },
            ),
            const SizedBox(height: 16),

            // Parent's Mobile
            _buildTextField(hint: "Parent's Mobile Number", icon: Icons.family_restroom_outlined, inputType: TextInputType.phone),
            const SizedBox(height: 16),
  // Standard Dropdown
            _buildDropdown(
              hint: "Standard",
              icon: Icons.school_outlined,
              value: _selectedStandard,
              items: _standards,
              onChanged: (val) {
                setState(() {
                  _selectedStandard = val;
                  // Reset stream if standard changes to < 11
                  if (val != "11" && val != "12") {
                    _selectedStream = null;
                  }
                });
              },
            ),
            const SizedBox(height: 16),

            // Stream Dropdown (Conditional)
            if (_selectedStandard == "11" || _selectedStandard == "12") ...[
               _buildDropdown(
                hint: "Stream",
                icon: Icons.science_outlined,
                value: _selectedStream,
                items: _streams,
                onChanged: (val) {
                  setState(() {
                    _selectedStream = val;
                  });
                },
              ),
              const SizedBox(height: 16),
            ],

            // Medium Dropdown
            _buildDropdown(
              hint: "Medium",
              icon: Icons.language,
              value: _selectedMedium,
              items: _mediums,
              onChanged: (val) {
                setState(() {
                  _selectedMedium = val;
                });
              },
            ),

            const SizedBox(height: 16),

            // State Dropdown
            _buildDropdown(
              hint: "State",
              icon: Icons.map_outlined,
              value: _selectedState,
              items: _stateCityMap.keys.toList(),
              onChanged: (val) {
                setState(() {
                  _selectedState = val;
                  _selectedCity = null; // Reset city when state changes
                });
              },
            ),
             const SizedBox(height: 16),

            // City Dropdown (Conditional on State)
             _buildDropdown(
              hint: "City",
              icon: Icons.location_city,
              value: _selectedCity,
              items: _selectedState != null ? _stateCityMap[_selectedState]! : [],
              onChanged: (val) {
                setState(() {
                  _selectedCity = val;
                });
              },
            ),
            const SizedBox(height: 24),

            // Terms Checkbox
            Row(
              children: [
                Checkbox(
                  value: _agreedToTerms, 
                  activeColor: Colors.blue.shade700,
                  onChanged: (val) {
                    setState(() {
                      _agreedToTerms = val!;
                    });
                  }
                ),
                Text(
                  "I agree with ",
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54),
                ),
                Text(
                  "Terms and Conditions",
                  style: GoogleFonts.poppins(
                    fontSize: 12, 
                    color: Colors.blue.shade700, 
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Register Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  // Validate inputs...
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                    side: const BorderSide(color: Colors.black12),
                  ),
                  elevation: 2,
                ),
                child: Text(
                  "Register",
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
    );
  }

  Widget _buildTextField({
    required String hint, 
    required IconData icon, 
    bool isPassword = false, 
    bool isVisible = false,
    VoidCallback? onVisibilityChanged,
    TextInputType inputType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextField(
        obscureText: isPassword && !isVisible,
        keyboardType: inputType,
        style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.bold), // Black Bold Input
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.poppins(color: Colors.grey),
          prefixIcon: Icon(icon, color: Colors.black54),
          suffixIcon: isPassword 
              ? IconButton(
                  icon: Icon(isVisible ? Icons.visibility : Icons.visibility_off, color: Colors.grey),
                  onPressed: onVisibilityChanged,
                ) 
              : null,
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
    required Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
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
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black54),
          dropdownColor: Colors.white, // Cleaner White Background
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
              child: Text(
                value, 
                style: GoogleFonts.poppins(color: Colors.black87), // Black text for readability
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
