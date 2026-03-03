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
  //  static const String baseUrl = "http://localhost:5000/api";
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
        // Schedule navigation to the next frame to avoid build conflicts
        Future.delayed(const Duration(milliseconds: 100), () {
             navigatorKey.currentState?.pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const WelcomeScreen()),
              (route) => false,
            );
        });
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

  static Future<http.Response> createPaymentOrder(double amount) async {
    final uri = Uri.parse("$baseUrl/payment/create-order");
    return _handleSession(await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'amount': amount,
        'currency': 'INR',
      }),
    ));
  }

  static Future<http.Response> registerUser({
    required RegistrationPayload payload,
    required String dpin,
    String? referralCode, 
    String? razorpayPaymentId,
    String? razorpayOrderId,
    String? razorpaySignature,
    double? amount,

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
    if (razorpayPaymentId != null) {
      fields["razorpay_payment_id"] = razorpayPaymentId;
      fields["razorpay_order_id"] = razorpayOrderId!;
      fields["razorpay_signature"] = razorpaySignature!;
      fields["amount"] = amount.toString();
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

  static Future<Map<String, String>> _getDefaultQueryParams() async {
    final prefs = await SharedPreferences.getInstance();
    final std = prefs.getString('std');
    final medium = prefs.getString('medium');
    final board = prefs.getString('board');
    final stream = prefs.getString('stream');
    
    final params = <String, String>{};
    if (std != null && std.isNotEmpty) params['std'] = std;
    if (medium != null && medium.isNotEmpty) params['medium'] = medium;
    if (board != null && board.isNotEmpty) params['board'] = board;
    if (stream != null && stream.isNotEmpty && stream != "None" && stream != "-") params['stream'] = stream;
    
    return params;
  }

  static Future<http.Response> getBoardPapers({
    required String medium,
    required String std,
    String? stream,
    required String year,
  }) async {
    final queryParams = await _getDefaultQueryParams();
    queryParams['type'] = 'BoardPaper';
    queryParams['year'] = year;
    // std, medium, stream might be overridden here if explicitly required
    if (std.isNotEmpty) queryParams['std'] = std;
    if (medium.isNotEmpty) queryParams['medium'] = medium;
    if (stream != null && stream.isNotEmpty && stream != "None" && stream != "-") queryParams['stream'] = stream;
    
    final uri = Uri.parse("$baseUrl/material/all").replace(queryParameters: queryParams);
    
    return _handleSession(await http.get(
      uri,
      headers: _addAuth({
        'Accept': 'application/json',
        'User-Agent': 'Flutter-App',
      }),
    ));
  }

  static Future<http.Response> getSchoolPapers({
    String? subject,
  }) async {
    final queryParams = await _getDefaultQueryParams();
    queryParams['type'] = 'SchoolPaper';
    if (subject != null) queryParams['subject'] = subject;
    
    final uri = Uri.parse("$baseUrl/material/all").replace(queryParameters: queryParams);
    
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

  static Future<http.Response> getAllExams({String? std, String? medium, String? subject}) async {
    final queryParams = await _getDefaultQueryParams();
    if (std != null && std.isNotEmpty) queryParams['std'] = std;
    if (medium != null && medium.isNotEmpty) queryParams['medium'] = medium;
    if (subject != null && subject.isNotEmpty) queryParams['subject'] = subject;

    final uri = Uri.parse("$baseUrl/exam/all").replace(queryParameters: queryParams);
    return _handleSession(await http.get(uri));
  }

  static Future<http.Response> getExamById(String examId) async {
    final uri = Uri.parse("$baseUrl/exam/$examId");
    return _handleSession(await http.get(uri));
  }

  static Future<http.Response> getAllFiveMinTests() async {
    final queryParams = await _getDefaultQueryParams();
    final uri = Uri.parse("$baseUrl/fiveMinTest/all").replace(queryParameters: queryParams);
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

  // --- Product Purchase & History ---

  static Future<http.Response> createProductOrder(String productId, double amount) async {
    final uri = Uri.parse("$baseUrl/payment/product/create-order");
    return _handleSession(await http.post(
      uri,
      headers: _addAuth({
        'Content-Type': 'application/json',
      }),
      body: jsonEncode({
        'productId': productId,
        'amount': amount,
        'currency': 'INR',
      }),
    ));
  }

  static Future<http.Response> verifyProductPayment({
    required String productId,
    required String razorpayPaymentId,
    required String razorpayOrderId,
    required String razorpaySignature,
    required double amount,
  }) async {
    final uri = Uri.parse("$baseUrl/payment/product/verify");
    return _handleSession(await http.post(
      uri,
      headers: _addAuth({
        'Content-Type': 'application/json',
      }),
      body: jsonEncode({
        'productId': productId,
        'razorpay_payment_id': razorpayPaymentId,
        'razorpay_order_id': razorpayOrderId,
        'razorpay_signature': razorpaySignature,
        'amount': amount,
      }),
    ));
  }

  static Future<http.Response> getPurchasedProducts() async {
    final uri = Uri.parse("$baseUrl/profile/purchased-products");
    return _handleSession(await http.get(
      uri,
      headers: _addAuth({
        'Accept': 'application/json',
      }),
    ));
  }

  // --- Plan Upgrade ---

  static Future<http.Response> createUpgradeOrder({
    required double amount,
    required String newStandard,
    required String medium,
    String? stream,
  }) async {
    final uri = Uri.parse("$baseUrl/payment/upgrade/create-order");
    return _handleSession(await http.post(
      uri,
      headers: _addAuth({
        'Content-Type': 'application/json',
      }),
      body: jsonEncode({
        'amount': amount,
        'newStandard': newStandard,
        'medium': medium,
        'stream': stream,
      }),
    ));
  }

  static Future<http.Response> verifyUpgradePayment({
    required String razorpayPaymentId,
    required String razorpayOrderId,
    required String razorpaySignature,
    required double amount,
    required String newStandard,
    required String medium,
    String? stream,
  }) async {
    final uri = Uri.parse("$baseUrl/payment/upgrade/verify");
    return _handleSession(await http.post(
      uri,
      headers: _addAuth({
        'Content-Type': 'application/json',
      }),
      body: jsonEncode({
        'razorpay_payment_id': razorpayPaymentId,
        'razorpay_order_id': razorpayOrderId,
        'razorpay_signature': razorpaySignature,
        'amount': amount,
        'newStandard': newStandard,
        'medium': medium,
        'stream': stream,
      }),
    ));
  }

  static Future<http.Response> getUpgradeHistory() async {
    final uri = Uri.parse("$baseUrl/profile/upgrade-history");
    return _handleSession(await http.get(
      uri,
      headers: _addAuth({
        'Accept': 'application/json',
      }),
    ));
  }

  // --- Mind Map ---
  static Future<http.Response> getAllMindMaps() async {
    final queryParams = await _getDefaultQueryParams();
    final uri = Uri.parse("$baseUrl/mindmap/all").replace(queryParameters: queryParams);
    return _handleSession(await http.get(uri));
  }

  // --- One Liner Exam ---
  static Future<http.Response> getAllOneLinerExams({String? std, String? medium, String? subject}) async {
    final queryParams = await _getDefaultQueryParams();
    if (std != null && std.isNotEmpty) queryParams['std'] = std;
    if (medium != null && medium.isNotEmpty) queryParams['medium'] = medium;
    if (subject != null && subject.isNotEmpty) queryParams['subject'] = subject;

    final uri = Uri.parse("$baseUrl/onelinerexam/all").replace(queryParameters: queryParams);
    return _handleSession(await http.get(
      uri,
      headers: _addAuth({
        'Accept': 'application/json',
        'User-Agent': 'Flutter-App',
      }),
    ));
  }

  static Future<http.Response> getOneLinerExamById(String examId) async {
    final uri = Uri.parse("$baseUrl/onelinerexam/$examId");
    return _handleSession(await http.get(
      uri,
      headers: _addAuth({
        'Accept': 'application/json',
        'User-Agent': 'Flutter-App',
      }),
    ));
  }

  static Future<http.Response> getMaterialImages({
    required String subject,
    required String unit,
  }) async {
    final queryParams = await _getDefaultQueryParams();
    queryParams['type'] = 'ImageMaterial';
    queryParams['subject'] = subject;
    queryParams['unit'] = unit;
    
    final uri = Uri.parse("$baseUrl/material/all").replace(queryParameters: queryParams);
    return _handleSession(await http.get(
      uri,
      headers: _addAuth({
        'Accept': 'application/json',
        'User-Agent': 'Flutter-App',
      }),
    ));
  }
}
