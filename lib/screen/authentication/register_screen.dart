import 'package:dm_bhatt_tutions/constant/app_images.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_loader.dart';
import 'package:dm_bhatt_tutions/screen/authentication/login_screen.dart';
import 'package:dm_bhatt_tutions/utils/app_localizations.dart';
import 'package:dm_bhatt_tutions/utils/custom_toast.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dm_bhatt_tutions/network/api_service.dart';
import 'package:dm_bhatt_tutions/model/registration_payload.dart';
import 'package:http/http.dart' as http;

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool _isPasswordVisible = false;
  bool _agreedToTerms = false;
  
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _rollNoController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _parentPhoneController = TextEditingController();
  final TextEditingController _schoolNameController = TextEditingController();

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

  Future<List<String>> _fetchSchools(String query) async {
    if (_selectedCity == null || query.isEmpty) return [];
    
    final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=$query+school+in+$_selectedCity&format=json&limit=5');
    
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black54),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
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
                height: MediaQuery.of(context).size.height * 0.1,
                width: MediaQuery.of(context).size.height * 0.1,
              ),
             ),
            const SizedBox(height: 24),
            
            Text(
              l10n.heyThere,
              style: GoogleFonts.poppins(fontSize: 16, color: Colors.black54),
            ),
            Text(
              l10n.register,
              style: GoogleFonts.poppins(
                fontSize: 24, 
                fontWeight: FontWeight.bold, 
                color: Colors.black87
              ),
            ),
            const SizedBox(height: 32),

          
            const SizedBox(height: 16),

            // Name
            _buildTextField(
              controller: _nameController,
              hint: l10n.name, 
              icon: Icons.person_outline,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return l10n.locale.languageCode == 'hi' ? "कृपया अपना नाम दर्ज करें" : (l10n.locale.languageCode == 'gu' ? "કૃપા કરીને તમારું નામ દાખલ કરો" : 'Please enter your name');
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

             // Roll Number
            _buildTextField(
              controller: _rollNoController,
              hint: l10n.rollNumber, 
              icon: Icons.numbers,
              inputType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return l10n.locale.languageCode == 'hi' ? "कृपया रोल नंबर दर्ज करें" : (l10n.locale.languageCode == 'gu' ? "કૃપા કરીને રોલ નંબર દાખલ કરો" : 'Please enter roll number');
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

             // Email
            _buildTextField(
              controller: _emailController,
              hint: l10n.email, 
              icon: Icons.email_outlined,
              inputType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return l10n.locale.languageCode == 'hi' ? "कृपया ईमेल दर्ज करें" : (l10n.locale.languageCode == 'gu' ? "કૃપા કરીને ઈમેલ દાખલ કરો" : 'Please enter email');
                }
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                  return l10n.locale.languageCode == 'hi' ? "कृपया एक मान्य ईमेल दर्ज करें" : (l10n.locale.languageCode == 'gu' ? "કૃપા કરીને માન્ય ઈમેલ દાખલ કરો" : 'Please enter a valid email');
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Phone
             _buildTextField(
              controller: _phoneController,
              hint: l10n.phoneNumber, 
              icon: Icons.phone_outlined, 
              inputType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return l10n.locale.languageCode == 'hi' ? "कृपया फोन नंबर दर्ज करें" : (l10n.locale.languageCode == 'gu' ? "કૃપા કરીને ફોન નંબર દાખલ કરો" : 'Please enter phone number');
                }
                if (value.length != 10) {
                  return l10n.locale.languageCode == 'hi' ? "फोन नंबर 10 अंकों का होना चाहिए" : (l10n.locale.languageCode == 'gu' ? "ફોન નંબર 10 અંકનો હોવો જોઈએ" : 'Phone number must be 10 digits');
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Password
            _buildTextField(
              controller: _passwordController,
              hint: l10n.password,
              icon: Icons.lock_outline,
              isPassword: true,
              isVisible: _isPasswordVisible,
              onVisibilityChanged: () {
                setState(() {
                  _isPasswordVisible = !_isPasswordVisible;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return l10n.locale.languageCode == 'hi' ? "कृपया पासवर्ड दर्ज करें" : (l10n.locale.languageCode == 'gu' ? "કૃપા કરીને પાસવર્ડ દાખલ કરો" : 'Please enter password');
                }
                if (value.length < 7) {
                  return l10n.locale.languageCode == 'hi' ? "पासवर्ड कम से कम 7 वर्णों का होना चाहिए" : (l10n.locale.languageCode == 'gu' ? "પાસવર્ડ ઓછામાં ઓછો 7 અક્ષરોનો હોવો જોઈએ" : 'Password must be at least 7 characters');
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Parent's Mobile
            _buildTextField(
              controller: _parentPhoneController,
              hint: l10n.parentPhone, 
              icon: Icons.family_restroom_outlined, 
              inputType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return l10n.locale.languageCode == 'hi' ? "कृपया माता-पिता का मोबाइल नंबर दर्ज करें" : (l10n.locale.languageCode == 'gu' ? "કૃપા કરીને વાલીનો મોબાઈલ નંબર દાખલ કરો" : "Please enter parent's mobile number");
                }
                if (value.length != 10) {
                  return l10n.locale.languageCode == 'hi' ? "फोन नंबर 10 अंकों का होना चाहिए" : (l10n.locale.languageCode == 'gu' ? "ફોન નંબર 10 અંકનો હોવો જોઈએ" : 'Phone number must be 10 digits');
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            

  // Standard Dropdown
            _buildDropdown(
              hint: l10n.standard,
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
                hint: l10n.stream,
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
              hint: l10n.medium,
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
              hint: l10n.state,
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

            // City Dropdown (Conditional)
             _buildDropdown(
              hint: l10n.city,
              icon: Icons.location_city,
              value: _selectedCity,
              items: _selectedState != null ? _stateCityMap[_selectedState]! : [],
              onChanged: (val) {
                setState(() {
                  _selectedCity = val;
                });
              },
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
                  fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                    // Sync the internal controller with our _schoolNameController if needed, 
                    // or just use the one provided by Autocomplete. 
                    // We'll use the one provided but sync initial value or changes if logic demands.
                    // For simplicity, we just use the UI builder here.
                    
                    // Note: Autocomplete creates its own controller. 
                    // To validate, we can manually update our _schoolNameController or validte this one?
                    // Better approach: Use onChanged to update our controller.
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
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter school name';
                          }
                          return null;
                        },
                        style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          hintText: l10n.schoolName,
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
                              // Simple display name clean up if it's too long
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
                  l10n.agreeTerms,
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54),
                ),
                Text(
                  l10n.termsConditions,
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
              height: MediaQuery.of(context).size.height * 0.07,
              child: ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    if (!_agreedToTerms) {
                      CustomToast.showError(context, l10n.locale.languageCode == 'hi' ? 'कृपया नियम और शर्तों से सहमत हों' : (l10n.locale.languageCode == 'gu' ? 'કૃપા કરીને નિયમો અને શરતો સાથે સંમત થાઓ' : 'Please agree to Terms and Conditions'));
                      return;
                    }
                    // Validate Dropdowns
                     if (_selectedStandard == null || _selectedMedium == null || _selectedState == null || _selectedCity == null) {
                        CustomToast.showError(context, l10n.locale.languageCode == 'hi' ? 'कृपया सभी आवश्यक फ़ील्ड चुनें' : (l10n.locale.languageCode == 'gu' ? 'કૃપા કરીને બધા જરૂરી ક્ષેત્રો પસંદ કરો' : 'Please select all required fields'));
                      return;
                     }
                      if ((_selectedStandard == "11" || _selectedStandard == "12") && _selectedStream == null) {
                         CustomToast.showError(context, l10n.locale.languageCode == 'hi' ? 'कृपया स्ट्रीम चुनें' : (l10n.locale.languageCode == 'gu' ? 'કૃપા કરીને સ્ટ્રીમ પસંદ કરો' : 'Please select a stream'));
                      return;
                      }

                    // Split Name
                    final nameParts = _nameController.text.trim().split(' ');
                    final firstName = nameParts.isNotEmpty ? nameParts[0] : '';


                    final payload = RegistrationPayload(
                      role: 'student',
                      fields: {
                        "firstName": firstName,
                        "rollNo": _rollNoController.text,
                        "email": _emailController.text,
                        "phoneNum": _phoneController.text,
                        "std": _selectedStandard!,
                        "medium": _selectedMedium!,
                        "school": _schoolNameController.text,
                        // Add parent phone if needed by backend, though backend registerStudent didn't explicitly list it in my check, 
                        // but it's good to checking backend again? 
                        // Backend registerStudent takes: firstName, middleName, phoneNum, std, medium, school, loginCode, rollNo.
                        // It DOES NOT take parentPhone? Or did I miss it?
                        // "const { firstName, middleName, phoneNum, std, medium, school, loginCode, rollNo } = req.body;"
                        // Yes, no parentPhone. I'll ignore it or add it if `User` model supports it.  
                      },
                      files: [], // No photo since UI removed it
                    );

                    try {
                      CustomLoader.show(context); // Show Loader
                      final response = await ApiService.registerUser(
                        payload: payload, 
                        dpin: _passwordController.text // Using password as DPIN/LoginCode
                      );
                      
                      if (!mounted) return;
                      CustomLoader.hide(context); // Hide Loader

                      if (response.statusCode == 201 || response.statusCode == 200) {
                         CustomToast.showSuccess(context, l10n.locale.languageCode == 'hi' ? "पंजीकरण सफल" : (l10n.locale.languageCode == 'gu' ? "નોંધણી સફળ" : "Registration Successful"));
                         Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginScreen()),
                        );
                      } else {
                         CustomToast.showError(context, (l10n.locale.languageCode == 'hi' ? "पंजीकरण विफल: " : (l10n.locale.languageCode == 'gu' ? "નોંધણી નિષ્ફળ: " : "Registration Failed: ")) + response.body);
                      }
                    } catch (e) {
                       if (mounted) {
                         CustomLoader.hide(context);
                         CustomToast.showError(context, "Error: $e");
                       }
                    }
                  }
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
                  l10n.register,
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
