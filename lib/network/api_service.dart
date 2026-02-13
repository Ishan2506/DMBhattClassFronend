import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart'; // Make sure http_parser is in pubspec
import 'package:image_picker/image_picker.dart';
import 'package:dm_bhatt_tutions/model/registration_payload.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  static Future<http.Response> getExploreProducts() async {
    final uri = Uri.parse("$baseUrl/explore/all");
    return await http.get(uri);
  }

  static Future<http.Response> registerUser({
    required RegistrationPayload payload,
    required String dpin,
    String? referralCode,
  }) async {
    final uri = Uri.parse("$baseUrl/auth/register");
    final request = http.MultipartRequest("POST", uri);
    
    request.headers['Accept'] = 'application/json';
    request.headers['User-Agent'] = 'Flutter-App';
    
    // Add text fields
    final fields = Map<String, String>.from(payload.fields);
    fields["loginCode"] = dpin;
    fields["role"] = payload.role;
    
    // Add referral code if provided
    if (referralCode != null && referralCode.isNotEmpty) {
      fields["referralCode"] = referralCode;
    }
    
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
    return response;
  }

  static Future<http.Response> getProfile() async {
    final uri = Uri.parse("$baseUrl/profile");
    return await http.get(
      uri,
      headers: _addAuth({
        'Accept': 'application/json',
        'User-Agent': 'Flutter-App',
      }),
    );
  }

  static Future<http.Response> updateProfile(Map<String, dynamic> data, {XFile? imageFile}) async {
    final uri = Uri.parse("$baseUrl/profile");
    final request = http.MultipartRequest("PUT", uri);
    
    request.headers.addAll({
      if (_authToken != null) 'Authorization': 'Bearer $_authToken',
      'Accept': 'application/json',
      'User-Agent': 'Flutter-App',
    });
    // Add text fields
    data.forEach((key, value) {
      if (value != null) {
        request.fields[key] = value.toString();
      }
    });

    // Add image file if provided
    if (imageFile != null) {
      final mimeType = _getMimeType(imageFile.name); // FIXED: Use name because path on web is a blob URL without extension
      
      if (kIsWeb) {
        // For Web, we must use fromBytes as MultipartFile.fromPath is not supported
        final bytes = await imageFile.readAsBytes();
        request.files.add(http.MultipartFile.fromBytes(
          'photo',
          bytes,
          filename: imageFile.name,
          contentType: MediaType.parse(mimeType),
        ));
      } else {
        // For Mobile, fromPath is preferred
        request.files.add(await http.MultipartFile.fromPath(
          'photo',
          imageFile.path,
          contentType: MediaType.parse(mimeType),
        ));
      }
    }

    final streamedResponse = await request.send();
    return await http.Response.fromStream(streamedResponse);
  }

  static Future<http.Response> getDashboardData() async {
    final uri = Uri.parse("$baseUrl/dashboard");
    return await http.get(
      uri,
      headers: _addAuth({
        'Accept': 'application/json',
        'User-Agent': 'Flutter-App',
      }),
    );
  }

  static Future<http.Response> submitExamResult({
    required String examId,
    required String title,
    required int obtainedMarks,
    required int totalMarks,
    bool isOnline = true,
  }) async {
    final uri = Uri.parse("$baseUrl/exam/submit");
    return await http.post(
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
    );
  }

  static Future<http.Response> getBoardPapers({
    required String medium,
    required String std,
    String? stream,
    required String year,
  }) async {
    // Construct query parameters
    final queryParams = {
      'medium': medium,
      'std': std,
      'year': year,
      if (stream != null) 'stream': stream,
    };
    
    final uri = Uri.parse("$baseUrl/materials/board-papers").replace(queryParameters: queryParams);
    
    return await http.get(
      uri,
      headers: _addAuth({
        'Accept': 'application/json',
        'User-Agent': 'Flutter-App',
      }),
    );
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
    
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'phoneNum': phone,
      }),
    );
    return response;
  }

  static Future<http.Response> verifyOtp({
    required String phone,
    required String otp,
  }) async {
    final uri = Uri.parse("$baseUrl/auth/verify-otp");
    
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'phoneNum': phone,
        'otp': otp,
      }),
    );
    return response;
  }

  static Future<http.Response> resetPassword({
    required String phone,
    required String newPassword,
  }) async {
    final uri = Uri.parse("$baseUrl/auth/reset-password");
    
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'phoneNum': phone,
        'newPassword': newPassword,
      }),
    );
    return response;
  }
  static Future<http.Response> updatePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final uri = Uri.parse("$baseUrl/auth/update-password");
    
    final response = await http.post(
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
    );
    return response;
  }

  static Future<http.Response> getAllTopRankers() async {
    final uri = Uri.parse("$baseUrl/topRanker/all");
    return await http.get(uri);
  }

  static Future<http.Response> getAllExams() async {
    final uri = Uri.parse("$baseUrl/exam/all");
    return await http.get(uri);
  }

  static Future<http.Response> getExamById(String examId) async {
    final uri = Uri.parse("$baseUrl/exam/$examId");
    return await http.get(uri);
  }

  static Future<http.Response> getAllFiveMinTests() async {
    final uri = Uri.parse("$baseUrl/fiveMinTest/all");
    return await http.get(uri);
  }

  static Future<http.Response> getLeaderboard({
    required String std,
  }) async {
    final uri = Uri.parse("$baseUrl/leaderboard/$std");
    return await http.get(
      uri,
      headers: _addAuth({
        'Accept': 'application/json',
        'User-Agent': 'Flutter-App',
      }),
    );
  }

  static Future<http.Response> getReferralData() async {
    final uri = Uri.parse("$baseUrl/referral/data");
    return await http.get(
      uri,
      headers: _addAuth({
        'Accept': 'application/json',
        'User-Agent': 'Flutter-App',
      }),
    );
  }

  static Future<http.Response> validateReferralCode(String referralCode) async {
    final uri = Uri.parse("$baseUrl/referral/validate");
    return await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'referralCode': referralCode,
      }),
    );
  }

  static Future<http.Response> getAllEvents() async {
    final uri = Uri.parse("$baseUrl/event/all");
    return await http.get(uri);
  }

  // --- Game APIs ---

  static Future<http.Response> getGameQuestions(String gameType) async {
    final uri = Uri.parse("$baseUrl/games/$gameType");
    return await http.get(uri);
  }
}
