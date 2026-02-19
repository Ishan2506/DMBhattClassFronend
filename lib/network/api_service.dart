import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart'; 
import 'package:image_picker/image_picker.dart';
import 'package:dm_bhatt_tutions/model/registration_payload.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dm_bhatt_tutions/main.dart'; // To access navigatorKey
import 'package:dm_bhatt_tutions/screen/authentication/welcome_screen.dart';
import 'package:flutter/material.dart';

class ApiService {
  static const String baseUrl = "https://dmbhatt-api.onrender.com/api";
  static String? _authToken;

  static String? get userToken => _authToken;

  static Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('auth_token');
  }

  static Future<void> setAuthToken(String token) async {
    _authToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  static Future<void> clearAuthToken() async {
    _authToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  static Map<String, String> _addAuth(Map<String, String> headers) {
    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    return headers;
  }

  /// Centralized check for 401 Unauthorized errors
  static http.Response _handleSession(http.Response response) {
    if (response.statusCode == 401) {
      debugPrint("Session expired (401). Redirecting to WelcomeScreen.");
      
      // Clear token to prevent infinite loop or persistent bad state
      clearAuthToken();

      // Global Redirection using navigatorKey
      if (navigatorKey.currentState != null) {
        navigatorKey.currentState!.pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const WelcomeScreen()),
          (route) => false,
        );
      }
    }
    return response;
  }

  /// Parse error message from common backend JSON formats
  static String getErrorMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        return decoded['message'] ?? decoded['error'] ?? body;
      }
      return body;
    } catch (_) {
      return body;
    }
  }

  static Future<http.Response> getExploreProducts() async {
    final uri = Uri.parse("$baseUrl/explore/all");
    return _handleSession(await http.get(uri));
  }

  static Future<http.Response> registerUser({
    required RegistrationPayload payload,
    required String dpin,
    String? referralCode,
    String? paymentId,
  }) async {
    final uri = Uri.parse("$baseUrl/auth/register");
    final request = http.MultipartRequest("POST", uri);
    
    request.headers['Accept'] = 'application/json';
    request.headers['User-Agent'] = 'Flutter-App';
    
    final fields = Map<String, String>.from(payload.fields);
    fields["loginCode"] = dpin;
    fields["role"] = payload.role;
    
    if (referralCode != null && referralCode.isNotEmpty) {
      fields["referralCode"] = referralCode;
    }

    if (paymentId != null && paymentId.isNotEmpty) {
      fields["paymentId"] = paymentId;
    }
    
    request.fields.addAll(fields);

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
    return _handleSession(await http.Response.fromStream(streamedResponse));
  }

  static Future<http.Response> loginUser({
    String? role,
    required String loginCode,
    required String phoneNum,
  }) async {
    final uri = Uri.parse("$baseUrl/auth/login");
    
    final body = {
      'loginCode': loginCode,
      'phoneNum': phoneNum,
    };

    if (role != null) {
      body['role'] = role;
    }

    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'User-Agent': 'Flutter-App',
      },
      body: jsonEncode(body),
    );
    return _handleSession(response);
  }

  static Future<http.Response> getProfile() async {
    final uri = Uri.parse("$baseUrl/profile");
    return _handleSession(await http.get(
      uri,
      headers: _addAuth({
        'Accept': 'application/json',
        'User-Agent': 'Flutter-App',
      }),
    ));
  }

  static Future<http.Response> updateProfile(Map<String, dynamic> data, {XFile? imageFile}) async {
    final uri = Uri.parse("$baseUrl/profile");
    final request = http.MultipartRequest("PUT", uri);
    
    request.headers.addAll({
      if (_authToken != null) 'Authorization': 'Bearer $_authToken',
      'Accept': 'application/json',
      'User-Agent': 'Flutter-App',
    });
    
    data.forEach((key, value) {
      if (value != null) {
        request.fields[key] = value.toString();
      }
    });

    if (imageFile != null) {
      final mimeType = _getMimeType(imageFile.name); 
      
      if (kIsWeb) {
        final bytes = await imageFile.readAsBytes();
        request.files.add(http.MultipartFile.fromBytes(
          'photo',
          bytes,
          filename: imageFile.name,
          contentType: MediaType.parse(mimeType),
        ));
      } else {
        request.files.add(await http.MultipartFile.fromPath(
          'photo',
          imageFile.path,
          contentType: MediaType.parse(mimeType),
        ));
      }
    }

    final streamedResponse = await request.send();
    return _handleSession(await http.Response.fromStream(streamedResponse));
  }

  static Future<http.Response> getDashboardData() async {
    final uri = Uri.parse("$baseUrl/dashboard");
    return _handleSession(await http.get(
      uri,
      headers: _addAuth({
        'Accept': 'application/json',
        'User-Agent': 'Flutter-App',
      }),
    ));
  }

  static Future<http.Response> submitExamResult({
    required String examId,
    required String title,
    required int obtainedMarks,
    required int totalMarks,
    bool isOnline = true,
  }) async {
    final uri = Uri.parse("$baseUrl/exam/submit");
    return _handleSession(await http.post(
      uri,
      headers: _addAuth({
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'User-Agent': 'Flutter-App',
      }),
      body: jsonEncode({
        'examId': examId,
        'title': title,
        'obtainedMarks': obtainedMarks,
        'totalMarks': totalMarks,
        'isOnline': isOnline,
      }),
    ));
  }

  static Future<http.Response> getBoardPapers({
    required String medium,
    required String std,
    String? stream,
    required String year,
  }) async {
    final queryParams = {
      'medium': medium,
      'std': std,
      'year': year,
      if (stream != null) 'stream': stream,
    };
    
    final uri = Uri.parse("$baseUrl/materials/board-papers").replace(queryParameters: queryParams);
    
    return _handleSession(await http.get(
      uri,
      headers: _addAuth({
        'Accept': 'application/json',
        'User-Agent': 'Flutter-App',
      }),
    ));
  }

  static String _getMimeType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    const mimeTypes = {
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'gif': 'image/gif',
      'webp': 'image/webp',
      'pdf': 'application/pdf',
    };
    return mimeTypes[ext] ?? 'application/octet-stream';
  }

  static Future<http.Response> forgetPassword({
    required String phone,
  }) async {
    final uri = Uri.parse("$baseUrl/auth/forget-password");
    
    return _handleSession(await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'phoneNum': phone,
      }),
    ));
  }

  static Future<http.Response> verifyOtp({
    required String phone,
    required String otp,
  }) async {
    final uri = Uri.parse("$baseUrl/auth/verify-otp");
    
    return _handleSession(await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'phoneNum': phone,
        'otp': otp,
      }),
    ));
  }

  static Future<http.Response> resetPassword({
    required String phone,
    required String newPassword,
  }) async {
    final uri = Uri.parse("$baseUrl/auth/reset-password");
    
    return _handleSession(await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'phoneNum': phone,
        'newPassword': newPassword,
      }),
    ));
  }

  static Future<http.Response> updatePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final uri = Uri.parse("$baseUrl/auth/update-password");
    
    return _handleSession(await http.post(
      uri,
      headers: _addAuth({
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'User-Agent': 'Flutter-App',
      }),
      body: jsonEncode({
        'oldPassword': oldPassword,
        'newPassword': newPassword,
      }),
    ));
  }

  static Future<http.Response> getAllTopRankers() async {
    final uri = Uri.parse("$baseUrl/topRanker/all");
    return _handleSession(await http.get(uri));
  }

  static Future<http.Response> getAllExams() async {
    final uri = Uri.parse("$baseUrl/exam/all");
    return _handleSession(await http.get(uri));
  }

  static Future<http.Response> getExamById(String examId) async {
    final uri = Uri.parse("$baseUrl/exam/$examId");
    return _handleSession(await http.get(uri));
  }

  static Future<http.Response> getAllFiveMinTests() async {
    final uri = Uri.parse("$baseUrl/fiveMinTest/all");
    return _handleSession(await http.get(uri));
  }

  static Future<http.Response> getLeaderboard({
    required String std,
  }) async {
    final uri = Uri.parse("$baseUrl/leaderboard/$std");
    return _handleSession(await http.get(
      uri,
      headers: _addAuth({
        'Accept': 'application/json',
        'User-Agent': 'Flutter-App',
      }),
    ));
  }

  static Future<http.Response> getReferralData() async {
    final uri = Uri.parse("$baseUrl/referral/data");
    return _handleSession(await http.get(
      uri,
      headers: _addAuth({
        'Accept': 'application/json',
        'User-Agent': 'Flutter-App',
      }),
    ));
  }

  static Future<http.Response> validateReferralCode(String referralCode) async {
    final uri = Uri.parse("$baseUrl/referral/validate");
    return _handleSession(await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'referralCode': referralCode,
      }),
    ));
  }

  static Future<http.Response> getAllEvents() async {
    final uri = Uri.parse("$baseUrl/event/all");
    return _handleSession(await http.get(uri));
  }

  static Future<http.Response> getGameQuestions(String gameType) async {
    final uri = Uri.parse("$baseUrl/games/$gameType");
    return _handleSession(await http.get(uri));
  }

  /// Checks if a user exists by attempting a login with a dummy password.
  /// Returns YES if user exists (Invalid Credentials/Success), NO if User Not Found.
  static Future<bool> checkUserExists(String phone) async {
    try {
      // using a dummy password that is unlikely to be correct
      final response = await loginUser(
        loginCode: "DUMMY_PASSWORD_CHECK_123", 
        phoneNum: phone
      );

      if (response.statusCode == 200) {
         return true; // Exists (and somehow password matched??)
      } else if (response.statusCode == 404) {
         return false; // User not found
      } else {
         // 400, 401 usually mean Invalid Credentials => User Exists
         // We need to be careful about other errors, but typically:
         // "User not found" is distinctive.
         final body = jsonDecode(response.body);
         if (body['message'] == "User not found") {
           return false;
         }
         return true; // Default to assuming exist if other error (like wrong password)
      }
    } catch (_) {
      return false; // Assume not exist or network error (fail safe to allow try)
    }
  }
}
