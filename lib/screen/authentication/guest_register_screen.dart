import 'package:dm_bhatt_tutions/constant/app_images.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_loader.dart';
import 'package:dm_bhatt_tutions/screen/authentication/login_screen.dart';
import 'package:dm_bhatt_tutions/l10n/app_localizations.dart';
import 'package:dm_bhatt_tutions/utils/custom_toast.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:dm_bhatt_tutions/network/api_service.dart';
import 'package:dm_bhatt_tutions/model/registration_payload.dart';
import 'package:dm_bhatt_tutions/utils/validation_utils.dart';

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
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _parentPhoneController = TextEditingController();
  final TextEditingController _schoolNameController = TextEditingController(text: "D.M.BHATT Institute");

  // Selection States
  String? _selectedStandard;
  String? _selectedMedium;
  String? _selectedStream;
  String? _selectedState;
  String? _selectedCity;
  String? _selectedInstitute = "D.M.BHATT Institute";
  String? _selectedBoard;
  String? _selectedRole = "Student";

  // Data Lists
  final List<String> _standards = ["6", "7", "8", "9", "10", "11", "12"];
  final List<String> _institutes = ["D.M.BHATT Institute", "Other"];

  final List<String> _mediums = ["English", "Gujarati"];
  final List<String> _streams = ["Science", "Commerce"];
  final List<String> _boards = ["GSEB", "CBSE"];
  final List<String> _roles = ["Student", "Teacher"];
  
  final Map<String, List<String>> _stateCityMap = {
    "Gujarat": ["Ahmedabad", "Surat", "Vadodara", "Rajkot"],
    "Maharashtra": ["Mumbai", "Pune", "Nagpur", "Nashik"],
    "Rajasthan": ["Jaipur", "Udaipur", "Jodhpur", "Kota"],
    "Rajasthan": ["Jaipur", "Udaipur", "Jodhpur", "Kota"],
  };

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Terms and Conditions", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Text(
            "1. By registering as a guest, you agree to abide by the rules and regulations of DM Bhatt Classes.\n\n"
            "2. Ensure all provided information is accurate and up-to-date.\n\n"
            "3. The institute reserves the right to modify the curriculum and schedule as needed.\n\n"
            "4. Respectful behavior towards staff and fellow students is mandatory.\n\n"
            "5. Unauthorized sharing of study material is strictly prohibited.\n\n",
            style: GoogleFonts.poppins(fontSize: 14),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Close", style: GoogleFonts.poppins(color: Colors.blue)),
          ),
        ],
      ),
    );
  }

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
    final l10n = AppLocalizations.of(context)!;
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
          AppLocalizations.of(context)!.guestRegistration, 
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
              AppLocalizations.of(context)!.heyThere,
              style: GoogleFonts.poppins(fontSize: 16, color: Colors.black54),
            ),
            Text(
              AppLocalizations.of(context)!.welcomeGuest,
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
              hint: AppLocalizations.of(context)!.name, 
              icon: Icons.person_outline,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  final l10n = AppLocalizations.of(context)!;
                  return l10n.pleaseEnterName;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Email
            _buildTextField(
              controller: _emailController,
              hint: AppLocalizations.of(context)!.email, 
              icon: Icons.email_outlined,
              inputType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return AppLocalizations.of(context)!.pleaseEnterEmail;
                }
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                  return AppLocalizations.of(context)!.pleaseEnterValidEmail;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Phone
             _buildTextField(
              controller: _phoneController,
              hint: AppLocalizations.of(context)!.phoneNumber, 
              icon: Icons.phone_outlined, 
              inputType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              validator: ValidationUtils.validateIndianPhoneNumber,
            ),
            const SizedBox(height: 16),

            // Password
            _buildTextField(
              controller: _passwordController,
              hint: AppLocalizations.of(context)!.password,
              icon: Icons.lock_outline,
              isPassword: true,
              isVisible: _isPasswordVisible,
              onVisibilityChanged: () {
                setState(() {
                  _isPasswordVisible = !_isPasswordVisible;
                });
              },
              validator: (value) => ValidationUtils.noFieldError(value, l10n),
            ),
            const SizedBox(height: 16),

            // Parent's Mobile
            _buildTextField(
              controller: _parentPhoneController,
              hint: AppLocalizations.of(context)!.parentPhone, 
              icon: Icons.family_restroom_outlined, 
              inputType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              validator: ValidationUtils.validateIndianPhoneNumber,
            ),
            const SizedBox(height: 16),
            
            // Standard Dropdown
            _buildDropdown(
              context,
              hint: AppLocalizations.of(context)!.standard,
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
                context,
                hint: AppLocalizations.of(context)!.stream,
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
              context,
              hint: AppLocalizations.of(context)!.medium,
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

            // Board Dropdown
            _buildDropdown(
              context,
              hint: AppLocalizations.of(context)!.board,
              icon: Icons.dashboard_outlined,
              value: _selectedBoard,
              items: _boards,
              onChanged: (val) {
                setState(() {
                  _selectedBoard = val;
                });
              },
            ),

            const SizedBox(height: 16),

            // State Dropdown
            _buildDropdown(
              context,
              hint: AppLocalizations.of(context)!.state,
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
              context,
              hint: AppLocalizations.of(context)!.city,
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
            // _buildDropdown(
            //   context,
            //   hint: AppLocalizations.of(context)!.instituteName,
            //   icon: Icons.business,
            //   value: _selectedInstitute,
            //   items: _institutes,
            //   onChanged: (val) {
            //     setState(() {
            //       _selectedInstitute = val;
            //       if (val == "D.M.BHATT Institute") {
            //         _schoolNameController.text = "D.M.BHATT Institute";
            //       } else {
            //         _schoolNameController.text = "";
            //       }
            //     });
            //   },
            // ),
            // const SizedBox(height: 16),

             // School Name Autocomplete
             if (_selectedInstitute == "Other")
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
                            hintText: AppLocalizations.of(context)!.schoolName,
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
            // Login As Dropdown
            // _buildDropdown(
            //   context,
            //   hint: AppLocalizations.of(context)!.loginAs,
            //   icon: Icons.person_pin_outlined,
            //   value: _selectedRole,
            //   items: _roles,
            //   onChanged: (val) {
            //     setState(() {
            //       _selectedRole = val;
            //     });
            //   },
            // ),
            // const SizedBox(height: 24),

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
                  AppLocalizations.of(context)!.agreeTerms,
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54),
                ),
                GestureDetector(
                  onTap: _showTermsDialog,
                  child: Text(
                    AppLocalizations.of(context)!.termsConditions,
                    style: GoogleFonts.poppins(
                      fontSize: 12, 
                      color: Colors.blue.shade700, 
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                    ),
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
                    // Password Complexity Validation
                    final passwordError = ValidationUtils.validatePasswordForToast(_passwordController.text, l10n);
                    if (passwordError != null) {
                      CustomToast.showError(context, passwordError);
                      return;
                    }

                    if (!_agreedToTerms) {
                      CustomToast.showError(context, l10n.pleaseAgreeTerms);
                      return;
                    }
                    // Validate Dropdowns
                     if (_selectedStandard == null || _selectedMedium == null || _selectedState == null || _selectedCity == null || _selectedInstitute == null || _selectedBoard == null || _selectedRole == null) {
                        CustomToast.showError(context, l10n.pleaseSelectAllFields);
                      return;
                     }
                    if ((_selectedStandard == "11" || _selectedStandard == "12") && _selectedStream == null) {
                         CustomToast.showError(context, l10n.pleaseSelectStream);
                      return;
                      }

                    // Validate Phone != Parent Phone
                    // Validate Phone != Parent Phone
                    if (_phoneController.text.trim() == _parentPhoneController.text.trim()) {
                      CustomToast.showError(context, l10n.phoneNumbersCannotBeSame);
                      return;
                    }

                    // Split Name
                    final nameParts = _nameController.text.trim().split(' ');
                    final firstName = nameParts.isNotEmpty ? nameParts[0] : '';


                    final payload = RegistrationPayload(
                      role: 'guest',
                      fields: {
                        "firstName": firstName,
                        "email": _emailController.text,
                        "phoneNum": _phoneController.text,
                        "parentPhone": _parentPhoneController.text,
                        "std": _selectedStandard!,
                        "medium": _selectedMedium!,
                        "board": _selectedBoard!,
                        "loginAs": _selectedRole!,
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
                        final l10n = AppLocalizations.of(context)!;
                        CustomToast.showSuccess(context, l10n.guestRegistrationSuccessful);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginScreen()),
                        );
                      } else {
                        final l10n = AppLocalizations.of(context)!;
                        CustomToast.showError(context, l10n.registrationFailed + response.body);
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
                  AppLocalizations.of(context)!.registerGuest,
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

  Widget _buildDropdown(BuildContext context, {
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
              final l10n = AppLocalizations.of(context)!;
              String label = item;
              if (item == "Student") label = l10n.student;
              if (item == "Teacher") label = l10n.teacher;
              return Align(
                 alignment: Alignment.centerLeft,
                 child: Row(
                   children: [
                     Icon(icon, color: Colors.black54), 
                     const SizedBox(width: 12),
                     Text(
                       label,
                       style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.bold), 
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
