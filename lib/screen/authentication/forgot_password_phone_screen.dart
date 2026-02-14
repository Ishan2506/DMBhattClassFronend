import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dm_bhatt_tutions/screen/authentication/forgot_password_otp_screen.dart';
import 'package:dm_bhatt_tutions/l10n/app_localizations.dart';
import 'package:dm_bhatt_tutions/constant/app_images.dart';
import 'package:dm_bhatt_tutions/network/api_service.dart';
import 'package:dm_bhatt_tutions/utils/custom_toast.dart';
import 'package:dm_bhatt_tutions/utils/validation_utils.dart';


class ForgotPasswordPhoneScreen extends StatefulWidget {
  const ForgotPasswordPhoneScreen({super.key});

  @override
  State<ForgotPasswordPhoneScreen> createState() => _ForgotPasswordPhoneScreenState();
}

class _ForgotPasswordPhoneScreenState extends State<ForgotPasswordPhoneScreen> {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    // Media Query for responsive sizing
    final screenWidth = MediaQuery.of(context).size.width; 

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [


// ... (Inside Column)
              SizedBox(width: double.infinity), // Force expansion for Center
              const SizedBox(height: 20),
              // Logo
               Center(
                 child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    shape: BoxShape.circle,
                  ),
                   child: Image.asset(
                    imgDmBhattClassesLogo,
                    height: MediaQuery.of(context).size.height * 0.12,
                    width: MediaQuery.of(context).size.height * 0.12,
                  ),
                 ),
               ),
              const SizedBox(height: 32),
              
              Center(
                child: Text(
                  AppLocalizations.of(context)!.dontWorry,
                  style: GoogleFonts.poppins(fontSize: 16, color: Colors.black54),
                ),
              ),
              Center(
                child: Text(
                  AppLocalizations.of(context)!.forgotPasswordHeader,
                  style: GoogleFonts.poppins(
                    fontSize: 24, 
                    fontWeight: FontWeight.bold, 
                    color: Colors.black87
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              Text(
                AppLocalizations.of(context)!.forgotPasswordSubtext,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.black54,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),

              // Phone Number Field
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                style: GoogleFonts.poppins(
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
                validator: ValidationUtils.validateIndianPhoneNumber,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.phoneNumber,
                  labelStyle: GoogleFonts.poppins(color: Colors.grey),
                  hintText: AppLocalizations.of(context)!.enterPhoneHint,
                  hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400, fontSize: 14),
                  prefixIcon: const Icon(Icons.phone_android_rounded, color: Colors.black54),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.blue.shade700, width: 2),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Send OTP Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                       ScaffoldMessenger.of(context).showSnackBar(
                         SnackBar(content: Text(AppLocalizations.of(context)!.sendingOtp)),
                       );
                       
                       ApiService.forgetPassword(phone: _phoneController.text).then((response) {
                          if (response.statusCode == 200) {
                            Navigator.push(
                              context, 
                              MaterialPageRoute(builder: (context) => ForgotPasswordOtpScreen(phone: _phoneController.text)),
                            );
                          } else {
                            CustomToast.showError(context, "Failed to send OTP. User may not exist.");
                          }
                       }).catchError((e) {
                          CustomToast.showError(context, "Error: $e");
                       });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.sendOtp,
                    style: GoogleFonts.poppins(
                      fontSize: screenWidth * 0.045, // Responsive
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
}
