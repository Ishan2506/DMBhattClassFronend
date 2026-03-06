import 'package:dm_bhatt_tutions/constant/string_constant.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_loader.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_filled_button.dart';
import 'package:dm_bhatt_tutions/model/registration_payload.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/landing_screen.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:dm_bhatt_tutions/utils/app_sizes.dart';
import 'package:http_parser/http_parser.dart';
import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import 'package:http/http.dart' as http;

class RegisterDPINScreen extends StatefulWidget {
  final RegistrationPayload payload;
  const RegisterDPINScreen({super.key,required this.payload});

  @override
  State<RegisterDPINScreen> createState() => _RegisterDPINScreenState();
}

class _RegisterDPINScreenState extends State<RegisterDPINScreen> {
  late bool isDarkMode;
  late TextTheme _textTheme;
  String DPIN = '';
  bool isLoading = false;
  @override
  void initState()
  {
    super.initState();
  }
//   Future<void> registerUser({
//   required RegistrationPayload payload,
//   required String dpin,
// }) async {
//   try {
//     final uri = Uri.parse("https://dmbhatt-api.onrender.com/api/auth/register");
//     final request = http.MultipartRequest("POST", uri);
//         // ✅ ADD HEADERS
//     request.headers['Accept'] = 'application/json';
//     //request.headers['Content-Type'] = 'multipart/form-data';
//     // Add all text fields
//     final fields = Map<String, String>.from(payload.fields);
//     fields["loginCode"] = dpin;
//     request.fields.addAll(fields);

//     // Debug text fields
//     debugPrint("=== Debug: Request Fields ===");
//     request.fields.forEach((key, value) => print("$key: $value"));

//     // Determine file key based on role
//     String fileKey = "";
//     switch (payload.role) {
//       case "assistant":
//         fileKey = "aadharFile";
//         break;
//       case "student":
//       case "guest":
//         fileKey = "photo";
//         break;
//       default:
//         fileKey = ""; // admin has no file
//     }

//     if (payload.files.isNotEmpty && fileKey.isNotEmpty) {
//       for (final file in payload.files) {
//         // Determine mime type based on file extension
//         String mimeType = '';
//         final ext = file.path.split('.').last.toLowerCase();
//         switch (ext) {
//           case 'jpg':
//           case 'jpeg':
//             mimeType = 'image/jpeg';
//             break;
//           case 'png':
//             mimeType = 'image/png';
//             break;
//           case 'pdf':
//             mimeType = 'application/pdf';
//             break;
//           default:
//             mimeType = 'application/octet-stream';
//         }

//         print("Adding file: ${file.path} as $fileKey with mimeType: $mimeType");

//         request.files.add(
//           await http.MultipartFile.fromPath(
//             fileKey,
//             file.path,
//             contentType: http.MediaType(mimeType.split('/')[0], mimeType.split('/')[1]),
//           ),
//         );
//       }
//     }else {
//       debugPrint("No files to upload");
//     }

//     // Send request
//     final response = await request.send();
//     final respBody = await response.stream.bytesToString();

//     // Show toast/message based on response
//     if (response.statusCode == 201) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Registered Successfully")),
//       );
//       Navigator.push(context, MaterialPageRoute(builder: (context) => LandingScreen(),));
//     } else {
//       debugPrint("Register Response:- ${respBody}");
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Registration Failed: $respBody")),
//       );
//     }
//   } catch (e) {
//     debugPrint("Register Catch:- ${e.toString()}");
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text("Error: $e")),
//     );
//   }
// }
Future<void> registerUser({
  required RegistrationPayload payload,
  required String dpin,
}) async {
  try {
    CustomLoader.show(context);
    // ✅ FIX 1: Pass role as a Query Parameter so the Backend sees it immediately
    // This solves the 'req.body is empty' issue in Node.js
    final uri = Uri.parse(
      "https://dmbhatt-api.onrender.com/api/auth/register",
    );


    final request = http.MultipartRequest("POST", uri);
    
    // ✅ FIX 2: Standard Headers
    request.headers['Accept'] = 'application/json';
    // Some servers (like Render) prefer a User-Agent to not look like a bot
    request.headers['User-Agent'] = 'Flutter-App';
    
    // Add text fields
    final fields = Map<String, String>.from(payload.fields);
    fields["loginCode"] = dpin;
    fields["role"] = payload.role; // Keep it here too for the validator
    request.fields.addAll(fields);

    // ✅ FIX 3: File Handling
    if (payload.files.isNotEmpty) {
      if (payload.role == "assistant") {
        // Assistant: Backend expects 'aadharFile' (Multiple files allowed)
        for (var file in payload.files) {
          final mimeType = _getMimeType(file.path);
          request.files.add(await http.MultipartFile.fromPath(
            'aadharFile', // Must match uploadAssistantFiles config
            file.path,
            contentType: MediaType.parse(mimeType),
          ));
        }
      } else {
        // Student/Guest: Backend expects 'photo' (Single file)
        final file = payload.files.first;
        final mimeType = _getMimeType(file.path);
        request.files.add(await http.MultipartFile.fromPath(
          'photo', // Must match uploadPhoto config
          file.path,
          contentType: MediaType.parse(mimeType),
        ));
      }
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    debugPrint("Status Code: ${response.statusCode}");
    debugPrint("Response Body: ${response.body}");

    if (!mounted) return;
    CustomLoader.hide(context);

    if (response.statusCode == 201 || response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Success!")));
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LandingScreen()));
    } else {
      // If still failing, the response body will now show the actual Node.js error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error ${response.statusCode}: ${ApiService.getErrorMessage(response.body)}")),
      );
    }
  } catch (e) {
    debugPrint("Register Error: $e");
    if (mounted) {
      CustomLoader.hide(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }
}

String _getMimeType(String path) {
  final ext = path.split('.').last.toLowerCase();
  const mimeTypes = {
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
    'pdf': 'application/pdf',
  };
  return mimeTypes[ext] ?? 'application/octet-stream';
}

  @override
  Widget build(BuildContext context) {
    final brightness = MediaQuery.of(context).platformBrightness;
    isDarkMode = brightness == Brightness.dark;
    _textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: const CustomAppBar(title: lblDPIN),
      body: SafeArea(child: _buildDPINBody()),
      bottomNavigationBar: BottomAppBar(
        elevation: 0,
        color: Colors.transparent,
        child: CustomFilledButton(label: lblSubmit, isLoading: false, onPressed: () async {
          await registerUser(payload: widget.payload, dpin: DPIN);
        }
        ),
      ),
    );
  }

  /// BODY
  Widget _buildDPINBody() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _cardWelcome(),
          blankVerticalSpace8,
          Padding(
            padding: P.all16,
            child: Column(
              children: [
                Align(
                  alignment: AlignmentGeometry.centerLeft,
                  child: Text(
                    lblEnterDPIN,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                blankVerticalSpace8,
                _buildDPINPinPut(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// WELCOME CARD
  Widget _cardWelcome() {
    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: P.all8,
        child: Row(
          spacing: S.s10,
          children: [
            CircleAvatar(radius: S.s32, child: Text('PP')),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Welcome Parshw Patel', style: _textTheme.titleMedium),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text('User ID:', style: _textTheme.titleMedium),
                    Text(' 123456', style: _textTheme.bodyMedium),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// PIN-PUT :- DPIN
  Widget _buildDPINPinPut() {
    return Pinput(
      defaultPinTheme: PinTheme(
        width: S.s56,
        height: S.s56,
        textStyle: Theme.of(context).textTheme.bodyMedium,
        decoration: BoxDecoration(
          border: Border.all(color: isDarkMode ? Colors.white : Colors.black),
          borderRadius: BorderRadius.circular(S.s12),
        ),
      ),
      focusedPinTheme: PinTheme(
        width: S.s56,
        height: S.s56,
        textStyle: Theme.of(context).textTheme.bodyMedium,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(S.s8),
          border: Border.all(
            color: Theme.of(context).colorScheme.surfaceContainer,
          ),
        ),
      ),
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      pinputAutovalidateMode: PinputAutovalidateMode.onSubmit,
      showCursor: true,
      onCompleted: (pin) => DPIN = pin,
    );
  }
}
