import 'package:dm_bhatt_tutions/constant/app_images.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_loader.dart';
import 'package:dm_bhatt_tutions/screen/authentication/login_screen.dart';
import 'package:dm_bhatt_tutions/utils/app_localizations.dart';
import 'package:dm_bhatt_tutions/utils/custom_toast.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:dm_bhatt_tutions/network/api_service.dart';
import 'package:dm_bhatt_tutions/model/registration_payload.dart';

class GuestRegisterScreen extends StatefulWidget {
  const GuestRegisterScreen({super.key});

  @override
  State<GuestRegisterScreen> createState() => _GuestRegisterScreenState();
}

class _GuestRegisterScreenState extends State<GuestRegisterScreen> {
  bool _isPasswordVisible = false;
  bool _agreedToTerms = false;
  
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final TextEditingController _nameController = TextEditingController();
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
  String? _selectedInstitute;

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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black54),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          AppLocalizations.of(context).guestRegistration, 
          style: GoogleFonts.poppins(color: Colors.black54, fontSize: 16),
        ),
        centerTitle: true,
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
              AppLocalizations.of(context).heyThere,
              style: GoogleFonts.poppins(fontSize: 16, color: Colors.black54),
            ),
            Text(
              AppLocalizations.of(context).welcomeGuest,
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
              hint: AppLocalizations.of(context).name, 
              icon: Icons.person_outline,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  final l10n = AppLocalizations.of(context);
                  return l10n.locale.languageCode == 'hi' ? "कृपया अपना नाम दर्ज करें" : (l10n.locale.languageCode == 'gu' ? "કૃપા કરીને તમારું નામ દાખલ કરો" : 'Please enter your name');
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Phone
             _buildTextField(
              controller: _phoneController,
              hint: AppLocalizations.of(context).phoneNumber, 
              icon: Icons.phone_outlined, 
              inputType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  final l10n = AppLocalizations.of(context);
                  return l10n.locale.languageCode == 'hi' ? "कृपया फोन नंबर दर्ज करें" : (l10n.locale.languageCode == 'gu' ? "કૃપા કરીને ફોન નંબર દાખલ કરો" : 'Please enter phone number');
                }
                if (value.length != 10) {
                  final l10n = AppLocalizations.of(context);
                  return l10n.locale.languageCode == 'hi' ? "फोन नंबर 10 अंकों का होना चाहिए" : (l10n.locale.languageCode == 'gu' ? "ફોન નંબર 10 અંકનો હોવો જોઈએ" : 'Phone number must be 10 digits');
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Password
            _buildTextField(
              controller: _passwordController,
              hint: AppLocalizations.of(context).password,
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
                  final l10n = AppLocalizations.of(context);
                  return l10n.locale.languageCode == 'hi' ? "कृपया पासवर्ड दर्ज करें" : (l10n.locale.languageCode == 'gu' ? "કૃપા કરીને પાસવર્ડ દાખલ કરો" : 'Please enter password');
                }
                if (value.length < 7) {
                  final l10n = AppLocalizations.of(context);
                  return l10n.locale.languageCode == 'hi' ? "पासवर्ड कम से कम 7 वर्णों का होना चाहिए" : (l10n.locale.languageCode == 'gu' ? "પાસવર્ડ ઓછામાં ઓછો 7 અક્ષરોનો હોવો જોઈએ" : 'Password must be at least 7 characters');
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Parent's Mobile
            _buildTextField(
              controller: _parentPhoneController,
              hint: AppLocalizations.of(context).parentPhone, 
              icon: Icons.family_restroom_outlined, 
              inputType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  final l10n = AppLocalizations.of(context);
                  return l10n.locale.languageCode == 'hi' ? "कृपया माता-पिता का मोबाइल नंबर दर्ज करें" : (l10n.locale.languageCode == 'gu' ? "કૃપા કરીને વાલીનો મોબાઈલ નંબર દાખલ કરો" : "Please enter parent's mobile number");
                }
                if (value.length != 10) {
                  final l10n = AppLocalizations.of(context);
                  return l10n.locale.languageCode == 'hi' ? "फोन नंबर 10 अंकों का होना चाहिए" : (l10n.locale.languageCode == 'gu' ? "ફોન નંબર 10 અંકનો હોવો જોઈએ" : 'Phone number must be 10 digits');
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Standard Dropdown
            _buildDropdown(
              hint: AppLocalizations.of(context).standard,
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
                hint: AppLocalizations.of(context).stream,
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
              hint: AppLocalizations.of(context).medium,
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
              hint: AppLocalizations.of(context).state,
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
              hint: AppLocalizations.of(context).city,
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

            // Institute Dropdown
            _buildDropdown(
              hint: AppLocalizations.of(context).locale.languageCode == 'hi' ? "संस्थान का नाम" : (AppLocalizations.of(context).locale.languageCode == 'gu' ? "સંસ્થાનું નામ" : "Institute Name"),
              icon: Icons.business,
              value: _selectedInstitute,
              items: _institutes,
              onChanged: (val) {
                setState(() {
                  _selectedInstitute = val;
                  if (val == "D.M.BHATT Institute") {
                    _schoolNameController.text = "D.M.BHATT Institute";
                  } else {
                    _schoolNameController.text = "";
                  }
                });
              },
            ),
            const SizedBox(height: 16),

             // School Name Autocomplete
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
                    fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
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
                            hintText: AppLocalizations.of(context).schoolName,
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
              const SizedBox(height: 24),
            ],
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
                  AppLocalizations.of(context).agreeTerms,
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54),
                ),
                Text(
                  AppLocalizations.of(context).termsConditions,
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
                      final l10n = AppLocalizations.of(context);
                      CustomToast.showError(context, l10n.locale.languageCode == 'hi' ? 'कृपया नियम और शर्तों से सहमत हों' : (l10n.locale.languageCode == 'gu' ? 'કૃપા કરીને નિયમો અને શરતો સાથે સંમત થાઓ' : 'Please agree to Terms and Conditions'));
                      return;
                    }
                    // Validate Dropdowns
                     if (_selectedStandard == null || _selectedMedium == null || _selectedState == null || _selectedCity == null || _selectedInstitute == null) {
                        final l10n = AppLocalizations.of(context);
                        CustomToast.showError(context, l10n.locale.languageCode == 'hi' ? 'कृपया सभी आवश्यक फ़ील्ड चुनें' : (l10n.locale.languageCode == 'gu' ? 'કૃપા કરીને બધા જરૂરી ક્ષેત્રો પસંદ કરો' : 'Please select all required fields'));
                      return;
                     }
                      if ((_selectedStandard == "11" || _selectedStandard == "12") && _selectedStream == null) {
                         final l10n = AppLocalizations.of(context);
                         CustomToast.showError(context, l10n.locale.languageCode == 'hi' ? 'कृपया स्ट्रीम चुनें' : (l10n.locale.languageCode == 'gu' ? 'કૃપા કરીને સ્ટ્રીમ પસંદ કરો' : 'Please select a stream'));
                      return;
                      }

                    // Split Name
                    final nameParts = _nameController.text.trim().split(' ');
                    final firstName = nameParts.isNotEmpty ? nameParts[0] : '';


                    final payload = RegistrationPayload(
                      role: 'guest',
                      fields: {
                        "firstName": firstName,
                        "phoneNum": _phoneController.text,
                        // Guest doesn't need Std/Medium/School in backend registerGuest?
                        // "const { firstName, middleName, phoneNum, loginCode, schoolName } = req.body;"
                        // It takes schoolName.
                        "schoolName": _schoolNameController.text,
                      },
                      files: [],
                    );

                    try {
                      CustomLoader.show(context); // Show Loader
                      final response = await ApiService.registerUser(
                        payload: payload, 
                        dpin: _passwordController.text
                      );

                      if (!mounted) return;
                      CustomLoader.hide(context); // Hide Loader

                      if (response.statusCode == 201 || response.statusCode == 200) {
                        final l10n = AppLocalizations.of(context);
                        CustomToast.showSuccess(context, l10n.locale.languageCode == 'hi' ? "पंजीकरण सफल" : (l10n.locale.languageCode == 'gu' ? "નોંધણી સફળ" : "Guest Registration Successful"));
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginScreen()),
                        );
                      } else {
                        final l10n = AppLocalizations.of(context);
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
                  AppLocalizations.of(context).registerGuest,
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
