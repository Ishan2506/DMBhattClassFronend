import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart'; // Make sure http_parser is in pubspec
import 'package:dm_bhatt_tutions/model/registration_payload.dart';

class ApiService {
  static const String baseUrl = "https://dmbhatt-api.onrender.com/api";

  static Future<http.Response> registerUser({
    required RegistrationPayload payload,
    required String dpin,
  }) async {
    final uri = Uri.parse("$baseUrl/auth/register");
    final request = http.MultipartRequest("POST", uri);
    
    request.headers['Accept'] = 'application/json';
    request.headers['User-Agent'] = 'Flutter-App';
    
    // Add text fields
    final fields = Map<String, String>.from(payload.fields);
    fields["loginCode"] = dpin;
    fields["role"] = payload.role; 
    request.fields.addAll(fields);

    // File Handling
    if (payload.files.isNotEmpty) {
      if (payload.role == "assistant") {
        for (var file in payload.files) {
          final mimeType = _getMimeType(file.path);
          request.files.add(await http.MultipartFile.fromPath(
            'aadharFile', 
            file.path,
            contentType: MediaType.parse(mimeType),
          ));
        }
      } else {
        // For student/guest, photo is optional. Check if file exists.
        final file = payload.files.first;
        if (file.existsSync()) {
             final mimeType = _getMimeType(file.path);
             request.files.add(await http.MultipartFile.fromPath(
              'photo',
              file.path,
              contentType: MediaType.parse(mimeType),
            ));
        }
      }
    }

    final streamedResponse = await request.send();
    return await http.Response.fromStream(streamedResponse);
  }

  static Future<http.Response> loginUser({
    required String role,
    required String loginCode,
    required String phoneNum,
  }) async {
    final uri = Uri.parse("$baseUrl/auth/login");
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'User-Agent': 'Flutter-App',
      },
      body: jsonEncode({
        'role': role,
        'loginCode': loginCode,
        'phoneNum': phoneNum,
      }),
    );
    return response;
  }

  static Future<http.Response> getProfile(String token) async {
    final uri = Uri.parse("$baseUrl/profile");
    return await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
  }

  static Future<http.Response> updateProfile(String token, Map<String, dynamic> data) async {
    final uri = Uri.parse("$baseUrl/profile");
    return await http.put(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );
  }

  static String _getMimeType(String path) {
    final ext = path.split('.').last.toLowerCase();
    const mimeTypes = {
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'pdf': 'application/pdf',
    };
    return mimeTypes[ext] ?? 'application/octet-stream';
  }
}
