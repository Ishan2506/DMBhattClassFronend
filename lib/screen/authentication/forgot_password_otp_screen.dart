import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pinput/pinput.dart';
import 'package:dm_bhatt_tutions/screen/authentication/reset_password_screen.dart';
import 'package:dm_bhatt_tutions/constant/app_images.dart';
import 'package:dm_bhatt_tutions/network/api_service.dart';
import 'package:dm_bhatt_tutions/utils/custom_toast.dart';


import 'package:dm_bhatt_tutions/constant/app_images.dart';

class ForgotPasswordOtpScreen extends StatefulWidget {
  final String email;
  const ForgotPasswordOtpScreen({super.key, required this.email});

  @override
  State<ForgotPasswordOtpScreen> createState() => _ForgotPasswordOtpScreenState();
}

class _ForgotPasswordOtpScreenState extends State<ForgotPasswordOtpScreen> {
  final _pinController = TextEditingController();

  String _maskEmail(String email) {
    if (email.contains("@")) {
      final parts = email.split("@");
      final local = parts[0];
      final domain = parts[1];
      if (local.length > 2) {
        return "${local.substring(0, 1)}***${local.substring(local.length - 1)}@$domain";
      }
      return email;
    }
    return email;
  }

  @override
  Widget build(BuildContext context) {
    // Media Query for responsive sizing
    final screenWidth = MediaQuery.of(context).size.width; 

    // Default Theme for Pinput
    final defaultPinTheme = PinTheme(
      width: 56,
      height: 56,
      textStyle: GoogleFonts.poppins(
        fontSize: 20, 
        color: Colors.black, 
        fontWeight: FontWeight.w600
      ),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyDecorationWith(
      border: Border.all(color: Colors.blue.shade700, width: 2),
      borderRadius: BorderRadius.circular(12),
    );

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(width: double.infinity), // Force expansion for Center
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
                  "Verification",
                  style: GoogleFonts.poppins(fontSize: 16, color: Colors.black54),
                ),
              ),
              Center(
                child: Text(
                  "Enter OTP",
                  style: GoogleFonts.poppins(
                    fontSize: 24, 
                    fontWeight: FontWeight.bold, 
                    color: Colors.black87
                  ),
                ),
              ),
              const SizedBox(height: 20),

            Center(
              child: Text(
                "We have sent the verification code to your registered email address ${_maskEmail(widget.email)}",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.black54,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 40),

            // OTP Input
            Center(
              child: Pinput(
                controller: _pinController,
                length: 6,
                defaultPinTheme: defaultPinTheme,
                focusedPinTheme: focusedPinTheme,
                pinputAutovalidateMode: PinputAutovalidateMode.onSubmit,
                showCursor: true,
                onCompleted: (pin) {
                  print("Entered PIN: $pin");
                },
              ),
            ),

            const SizedBox(height: 40),

            // Verify Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                   if (_pinController.text.length == 6) {
                     ApiService.verifyOtp(email: widget.email, otp: _pinController.text).then((response) {
                        if (response.statusCode == 200) {
                           Navigator.push(
                             context,
                             MaterialPageRoute(builder: (context) => ResetPasswordScreen(email: widget.email)),
                           );
                        } else {
                           CustomToast.showError(context, "Invalid OTP");
                        }
                     }).catchError((e) {
                        CustomToast.showError(context, "Error: $e");
                     });
                   } else {
                      CustomToast.showError(context, "Please enter full 6-digit code");
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
                  "Verify",
                  style: GoogleFonts.poppins(
                    fontSize: screenWidth * 0.045, // Responsive
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            
             const SizedBox(height: 24),
              Center(
                child: TextButton(
                onPressed: () {
                     CustomToast.showInfo(context, "Sending new OTP...");
                      ApiService.forgetPassword(email: widget.email).then((response) {
                        if (response.statusCode == 200) {
                           CustomToast.showSuccess(context, "OTP Resent Successfully");
                        } else {
                           CustomToast.showError(context, "Failed to resend OTP");
                        }
                      }).catchError((e) {
                         CustomToast.showError(context, "Error: $e");
                      });
                  },
                  child: Text(
                    "Resend Code",
                    style: GoogleFonts.poppins(
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
