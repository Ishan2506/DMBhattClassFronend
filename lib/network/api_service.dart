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
import 'package:dm_bhatt_tutions/utils/connectivity_service.dart';
import 'package:dm_bhatt_tutions/utils/custom_toast.dart';
class ApiService {
  static const String baseUrl = "http://103.212.121.139:5000/api";
  
  /// Helper to get the full URL for a file (image, pdf, etc.)
  static String getFileUrl(String? url) {
    if (url == null || url.isEmpty) return "";
    if (url.startsWith('http')) return url;
    
    // Remove /api from baseUrl to get the server root
    final serverRoot = baseUrl.replaceAll('/api', '');
    
    // If it's a relative path from our server
    if (url.startsWith('uploads/')) {
        return "$serverRoot/$url";
    }
    
    return url;
  }
  static const String guestToken = "DMBHATT_GUEST_ACCESS_TOKEN_2024";
  static String? _authToken;
  static bool _isGuest = false;

  static String? get userToken => _authToken;
  static bool get isGuest => _isGuest;

  static Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('auth_token');
    _isGuest = prefs.getString('user_role') == 'guest';
  }

  static Future<void> setGuestMode(bool guest) async {
    _isGuest = guest;
    final prefs = await SharedPreferences.getInstance();
    if (guest) {
      await prefs.setString('user_role', 'guest');
      await prefs.setBool('is_guest_mode', true);
    } else {
      await prefs.remove('user_role');
      await prefs.remove('is_guest_mode');
    }
  }

  static Future<void> setAuthToken(String token) async {
    _authToken = token;
    _isGuest = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    await prefs.remove('is_guest_mode');
  }

  static Future<void> clearAuthToken() async {
    _authToken = null;
    _isGuest = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_role');
    await prefs.remove('is_guest_mode');
    await prefs.remove('skipped_payment_prompt');
  }

  static Map<String, String> _addAuth(Map<String, String> headers) {
    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    if (_isGuest) {
      headers['X-Guest-Token'] = guestToken;
    }
    return headers;
  }

  static http.Response _handleSession(http.Response response) {
    if (response.statusCode == 401 && !_isGuest) {
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
        final err = decoded['error'];
        final msg = decoded['message'];
        if (err is String && err.isNotEmpty) return err;
        if (msg is String && msg.isNotEmpty) return msg;
        return body;
      }
      return body;
    } catch (_) {
      return body;
    }
  }

  static Future<bool> _checkConnectivity() async {
    final isConnected = await ConnectivityService.isConnected();
    if (!isConnected) {
      if (navigatorKey.currentContext != null) {
        CustomToast.showError(navigatorKey.currentContext!, "Internet connection is required");
      }
      return false;
    }
    return true;
  }

  static Future<http.Response> getExploreProducts() async {
    if (!await _checkConnectivity()) return http.Response('{"error": "No internet connection"}', 503);
    final uri = Uri.parse("$baseUrl/explore/all");
    return _handleSession(await http.get(uri));
  }

  static Future<http.Response> createPaymentOrder(double amount) async {
    if (!await _checkConnectivity()) return http.Response('{"error": "No internet connection"}', 503);
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
    if (!await _checkConnectivity()) return http.Response('{"error": "No internet connection"}', 503);
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
    String? deviceId,
  }) async {
    if (!await _checkConnectivity()) return http.Response('{"error": "No internet connection"}', 503);
    final uri = Uri.parse("$baseUrl/auth/login");
    
    final body = {
      'loginCode': loginCode,
      'phoneNum': phoneNum,
      if (deviceId != null) 'deviceId': deviceId,
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

  static Future<http.Response> logoutUser(String token) async {
    if (!await _checkConnectivity()) return http.Response('{"error": "No internet connection"}', 503);
    final uri = Uri.parse("$baseUrl/auth/logout");
    return await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
  }

  static Future<http.Response> getProfile({bool forceRefresh = false}) async {
    if (!await _checkConnectivity()) return http.Response('{"error": "No internet connection"}', 503);
    var uri = Uri.parse("$baseUrl/profile");
    if (forceRefresh) {
      uri = uri.replace(queryParameters: {'t': DateTime.now().millisecondsSinceEpoch.toString()});
    }
    return _handleSession(await http.get(
      uri,
      headers: _addAuth({
        'Accept': 'application/json',
        'User-Agent': 'Flutter-App',
      }),
    ));
  }

  static Future<http.Response> updateProfile(Map<String, dynamic> data, {XFile? imageFile}) async {
    if (!await _checkConnectivity()) return http.Response('{"error": "No internet connection"}', 503);
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
    if (!await _checkConnectivity()) return http.Response('{"error": "No internet connection"}', 503);
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
    String? type,
    int violationCount = 0,
  }) async {
    if (!await _checkConnectivity()) return http.Response('{"error": "No internet connection"}', 503);
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
        'violationCount': violationCount,
        if (type != null) 'type': type,
      }),
    ));
  }

  static Future<http.Response> updateViolationCount({
    required String examId,
    required String examType,
  }) async {
    if (!await _checkConnectivity()) return http.Response('{"error": "No internet connection"}', 503);
    final uri = Uri.parse("$baseUrl/exam/violation");
    return _handleSession(await http.post(
      uri,
      headers: _addAuth({
        'Content-Type': 'application/json',
        'User-Agent': 'Flutter-App',
      }),
      body: jsonEncode({
        'examId': examId,
        'examType': examType,
      }),
    ));
  }

  static String? _normalizeStd(String? std) {
    if (std == null || std.isEmpty) return std;
    final match = RegExp(r'(\d+)').firstMatch(std);
    return match != null ? match.group(1)! : std;
  }

  static Future<Map<String, String>> _getDefaultQueryParams() async {
    final prefs = await SharedPreferences.getInstance();
    final std = prefs.getString('std');
    final medium = prefs.getString('medium');
    final board = prefs.getString('board');
    final stream = prefs.getString('stream');
    
    final params = <String, String>{};
    if (std != null && std.isNotEmpty) {
      params['std'] = std;
      params['standard'] = std; // Backend uses 'standard' for material filtering
    }
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
    String? subject,
  }) async {
    if (!await _checkConnectivity()) return http.Response('{"error": "No internet connection"}', 503);
    final queryParams = await _getDefaultQueryParams();
    queryParams['type'] = 'BoardPaper';
    queryParams['year'] = year;
    queryParams['standard'] = std;
    queryParams['std'] = std;
    
    if (subject != null && subject.isNotEmpty) queryParams['subject'] = subject;
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
    String? medium,
    String? std,
    String? year,
    String? board,
    String? stream,
  }) async {
    if (!await _checkConnectivity()) return http.Response('{"error": "No internet connection"}', 503);
    final queryParams = await _getDefaultQueryParams();
    queryParams['type'] = 'SchoolPaper';
    
    if (subject != null && subject.isNotEmpty) queryParams['subject'] = subject;
    if (medium != null && medium.isNotEmpty) queryParams['medium'] = medium;
    if (std != null && std.isNotEmpty) {
      final stdValue = _normalizeStd(std)!;
      queryParams['standard'] = stdValue;
      queryParams['std'] = stdValue;
    }
    if (year != null && year.isNotEmpty) queryParams['year'] = year;
    if (board != null && board.isNotEmpty) queryParams['board'] = board;
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

  static Future<http.Response> getNotes({
    String? subject,
  }) async {
    if (!await _checkConnectivity()) return http.Response('{"error": "No internet connection"}', 503);
    final queryParams = await _getDefaultQueryParams();
    queryParams['type'] = 'Notes';
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
    required String email,
  }) async {
    if (!await _checkConnectivity()) return http.Response('{"error": "No internet connection"}', 503);
    final uri = Uri.parse("$baseUrl/auth/forget-password");
    
    return _handleSession(await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': email,
      }),
    ));
  }

  static Future<http.Response> verifyOtp({
    required String email,
    required String otp,
  }) async {
    if (!await _checkConnectivity()) return http.Response('{"error": "No internet connection"}', 503);
    final uri = Uri.parse("$baseUrl/auth/verify-otp");
    
    return _handleSession(await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': email,
        'otp': otp,
      }),
    ));
  }

  static Future<http.Response> resetPassword({
    required String email,
    required String newPassword,
  }) async {
    if (!await _checkConnectivity()) return http.Response('{"error": "No internet connection"}', 503);
    final uri = Uri.parse("$baseUrl/auth/reset-password");
    
    return _handleSession(await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': email,
        'newPassword': newPassword,
      }),
    ));
  }

  static Future<http.Response> updatePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    if (!await _checkConnectivity()) return http.Response('{"error": "No internet connection"}', 503);
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
    if (!await _checkConnectivity()) return http.Response('{"error": "No internet connection"}', 503);
    final uri = Uri.parse("$baseUrl/topRanker/all");
    return _handleSession(await http.get(uri));
  }

  static Future<http.Response> getAllExams({String? std, String? medium, String? subject}) async {
    if (!await _checkConnectivity()) return http.Response('{"error": "No internet connection"}', 503);
    final queryParams = await _getDefaultQueryParams();
    if (std != null && std.isNotEmpty) queryParams['std'] = std;
    if (medium != null && medium.isNotEmpty) queryParams['medium'] = medium;
    if (subject != null && subject.isNotEmpty) queryParams['subject'] = subject;

    final uri = Uri.parse("$baseUrl/exam/all").replace(queryParameters: queryParams);
    return _handleSession(await http.get(uri));
  }

  static Future<http.Response> getExamById(String examId) async {
    if (!await _checkConnectivity()) return http.Response('{"error": "No internet connection"}', 503);
    final uri = Uri.parse("$baseUrl/exam/$examId");
    return _handleSession(await http.get(
      uri,
      headers: _addAuth({
        'Accept': 'application/json',
        'User-Agent': 'Flutter-App',
      }),
    ));
  }

  static Future<http.Response> getAllFiveMinTests() async {
    if (!await _checkConnectivity()) return http.Response('{"error": "No internet connection"}', 503);
    final queryParams = await _getDefaultQueryParams();
    final uri = Uri.parse("$baseUrl/fiveMinTest/all").replace(queryParameters: queryParams);
    return _handleSession(await http.get(uri));
  }

  static Future<http.Response> getFiveMinTestById(String testId) async {
    if (!await _checkConnectivity()) return http.Response('{"error": "No internet connection"}', 503);
    final uri = Uri.parse("$baseUrl/fiveMinTest/$testId");
    return _handleSession(await http.get(uri));
  }

  static Future<http.Response> getLeaderboard({
    required String std,
  }) async {
    if (!await _checkConnectivity()) return http.Response('{"error": "No internet connection"}', 503);
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
    if (!await _checkConnectivity()) return http.Response('{"error": "No internet connection"}', 503);
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
    if (!await _checkConnectivity()) return http.Response('{"error": "No internet connection"}', 503);
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

  static Future<http.Response> validateRedeemCode(String code, {String? targetStd, String? targetBoard, String? targetMedium, String? targetStream}) async {
    if (!await _checkConnectivity()) return http.Response('{"error": "No internet connection"}', 503);
    final uri = Uri.parse("$baseUrl/redeem/validate");
    return _handleSession(await http.post(
      uri,
      headers: _addAuth({
        'Content-Type': 'application/json',
      }),
      body: jsonEncode({
        'code': code,
        if (targetStd != null) 'targetStd': targetStd,
        if (targetBoard != null) 'targetBoard': targetBoard,
        if (targetMedium != null) 'targetMedium': targetMedium,
        if (targetStream != null) 'targetStream': targetStream,
      }),
    ));
  }

  static Future<http.Response> getAllEvents() async {
    if (!await _checkConnectivity()) return http.Response('{"error": "No internet connection"}', 503);
    final uri = Uri.parse("$baseUrl/event/all");
    return _handleSession(await http.get(uri));
  }

  static Future<http.Response> getGameQuestions(String gameType) async {
    if (!await _checkConnectivity()) return http.Response('{"error": "No internet connection"}', 503);
    final uri = Uri.parse("$baseUrl/games/$gameType");
    return _handleSession(await http.get(uri));
  }

  // --- Product Purchase & History ---

  static Future<http.Response> createProductOrder(String productId, double amount) async {
    if (!await _checkConnectivity()) return http.Response('{"error": "No internet connection"}', 503);
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
    if (!await _checkConnectivity()) return http.Response('{"error": "No internet connection"}', 503);
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
    if (!await _checkConnectivity()) return http.Response('{"error": "No internet connection"}', 503);
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
    if (!await _checkConnectivity()) return http.Response('{"error": "No internet connection"}', 503);
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
    if (!await _checkConnectivity()) return http.Response('{"error": "No internet connection"}', 503);
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
    if (!await _checkConnectivity()) return http.Response('{"error": "No internet connection"}', 503);
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
    if (!await _checkConnectivity()) return http.Response('{"error": "No internet connection"}', 503);
    final queryParams = await _getDefaultQueryParams();
    final uri = Uri.parse("$baseUrl/mindmap/all").replace(queryParameters: queryParams);
    return _handleSession(await http.get(uri));
  }

  // --- One Liner Exam ---
  static Future<http.Response> getAllOneLinerExams({String? std, String? medium, String? subject}) async {
    if (!await _checkConnectivity()) return http.Response('{"error": "No internet connection"}', 503);
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
    if (!await _checkConnectivity()) return http.Response('{"error": "No internet connection"}', 503);
    final uri = Uri.parse("$baseUrl/onelinerexam/$examId");
    return _handleSession(await http.get(
      uri,
      headers: _addAuth({
        'Accept': 'application/json',
        'User-Agent': 'Flutter-App',
      }),
    ));
  }

  static Future<http.Response> submitOneLinerExamResult({
    required String examId,
    required String title,
    required int obtainedMarks,
    required int totalMarks,
    required double accuracy,
    String? type,
    int violationCount = 0,
  }) async {
    final uri = Uri.parse("$baseUrl/onelinerexam/submit");
    return _handleSession(await http.post(
      uri,
      headers: _addAuth({
        'Content-Type': 'application/json',
        'User-Agent': 'Flutter-App',
      }),
      body: jsonEncode({
        'examId': examId,
        'title': title,
        'obtainedMarks': obtainedMarks,
        'totalMarks': totalMarks,
        'accuracy': accuracy,
        'violationCount': violationCount,
        if (type != null) 'type': type,
      }),
    ));
  }

  static Future<http.Response> submitFiveMinTestResult({
    required String examId,
    required String title,
    required int obtainedMarks,
    required int totalMarks,
    bool isOnline = true,
    String? type,
    int violationCount = 0,
  }) async {
    final uri = Uri.parse("$baseUrl/fiveMinTest/submit");
    return _handleSession(await http.post(
      uri,
      headers: _addAuth({
        'Content-Type': 'application/json',
        'User-Agent': 'Flutter-App',
      }),
      body: jsonEncode({
        'examId': examId,
        'title': title,
        'obtainedMarks': obtainedMarks,
        'totalMarks': totalMarks,
        'isOnline': isOnline,
        'violationCount': violationCount,
        if (type != null) 'type': type,
      }),
    ));
  }

  static Future<http.Response> getMaterialImages({
    required String subject,
    required String unit,
  }) async {
    if (!await _checkConnectivity()) return http.Response('{"error": "No internet connection"}', 503);
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

  /// Delete Account (Soft Delete)
  static Future<http.Response> deleteAccount() async {
    if (!await _checkConnectivity()) return http.Response('{"error": "No internet connection"}', 503);
    final uri = Uri.parse("$baseUrl/profile");
    return _handleSession(await http.delete(
      uri,
      headers: _addAuth({
        'Accept': 'application/json',
        'User-Agent': 'Flutter-App',
      }),
    ));
  }

  // --- Apple In-App Purchase Verification ---

  static Future<http.Response> verifyAppleMembership({
    required String receipt,
    required String productId,
    required String transactionId,
    required String standard,
    required String medium,
    String? stream,
  }) async {
    if (!await _checkConnectivity()) return http.Response('{"error": "No internet connection"}', 503);
    final uri = Uri.parse("$baseUrl/payment/apple/verify-membership");
    return _handleSession(await http.post(
      uri,
      headers: _addAuth({
        'Content-Type': 'application/json',
      }),
      body: jsonEncode({
        'receipt': receipt,
        'productId': productId,
        'transactionId': transactionId,
        'standard': standard,
        'medium': medium,
        if (stream != null) 'stream': stream,
      }),
    ));
  }

  static Future<http.Response> verifyAppleUpgrade({
    required String receipt,
    required String productId,
    required String transactionId,
    required String newStandard,
    required String medium,
    String? stream,
    required double amount,
  }) async {
    if (!await _checkConnectivity()) return http.Response('{"error": "No internet connection"}', 503);
    final uri = Uri.parse("$baseUrl/payment/apple/verify-upgrade");
    return _handleSession(await http.post(
      uri,
      headers: _addAuth({
        'Content-Type': 'application/json',
      }),
      body: jsonEncode({
        'receipt': receipt,
        'productId': productId,
        'transactionId': transactionId,
        'newStandard': newStandard,
        'medium': medium,
        if (stream != null) 'stream': stream,
        'amount': amount,
      }),
    ));
  }

  static Future<http.Response> verifyAppleProductPurchase({
    required String receipt,
    required String productId,
    required String transactionId,
    required String materialProductId,
    required double amount,
  }) async {
    if (!await _checkConnectivity()) return http.Response('{"error": "No internet connection"}', 503);
    final uri = Uri.parse("$baseUrl/payment/apple/verify-product");
    return _handleSession(await http.post(
      uri,
      headers: _addAuth({
        'Content-Type': 'application/json',
      }),
      body: jsonEncode({
        'receipt': receipt,
        'productId': productId,
        'transactionId': transactionId,
        'materialProductId': materialProductId,
        'amount': amount,
      }),
    ));
  }

  /// Register user with Apple IAP payment (iOS only)
  static Future<http.Response> registerUserWithApple({
    required RegistrationPayload payload,
    required String dpin,
    String? referralCode,
    required String appleReceipt,
    required String appleProductId,
    required String appleTransactionId,
    double? amount,
  }) async {
    if (!await _checkConnectivity()) return http.Response('{"error": "No internet connection"}', 503);
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

    // Apple IAP fields instead of Razorpay fields
    fields["apple_receipt"] = appleReceipt;
    fields["apple_product_id"] = appleProductId;
    fields["apple_transaction_id"] = appleTransactionId;
    if (amount != null) {
      fields["amount"] = amount.toString();
    }

    request.fields.addAll(fields);

    if (payload.files.isNotEmpty) {
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

    final streamedResponse = await request.send();
    return _handleSession(await http.Response.fromStream(streamedResponse));
  }
}
