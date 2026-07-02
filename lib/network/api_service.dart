import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dm_bhatt_tutions/model/registration_payload.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dm_bhatt_tutions/main.dart'; // To access navigatorKey
import 'package:dm_bhatt_tutions/screen/authentication/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:dm_bhatt_tutions/utils/connectivity_service.dart';
import 'package:dm_bhatt_tutions/utils/custom_toast.dart';

class ApiService {
  // static const String baseUrl = "http://localhost:9657/api";
  static const String baseUrl = "http://103.212.121.139:5000/api";

  /// Helper to get the full URL for a file (image, pdf, etc.)
  static String getFileUrl(String? url) {
    if (url == null || url.isEmpty || url == "null") return "";
    if (url.startsWith('http')) return url;

    // Remove /api from baseUrl to get the server root
    final serverRoot = baseUrl.replaceAll('/api', '');

    // Normalize path (ensure no leading slash and forward slashes)
    String path = url;
    if (path.startsWith('/')) path = path.substring(1);
    path = path.replaceAll('\\', '/');

    return "$serverRoot/$path";
  }

  static const String guestToken = "DMBHATT_GUEST_ACCESS_TOKEN_2024";
  static String? _authToken;
  static bool _isGuest = false;

  static String? get userToken => _authToken;
  static bool get isGuest => _isGuest;

  static void _debugPrintFullJson(String label, Map<String, dynamic> body) {
    if (!kDebugMode) return;

    const chunkSize = 900;
    final jsonBody = const JsonEncoder.withIndent('  ').convert(body);
    debugPrint("$label full JSON length: ${jsonBody.length}");
    for (var i = 0; i < jsonBody.length; i += chunkSize) {
      final end = (i + chunkSize < jsonBody.length)
          ? i + chunkSize
          : jsonBody.length;
      final chunkNumber = (i ~/ chunkSize) + 1;
      debugPrint(
        "$label full JSON chunk $chunkNumber: ${jsonBody.substring(i, end)}",
      );
    }
  }

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
      debugPrint("Session expired (401). Redirecting to LoginScreen.");

      // Clear token to prevent infinite loop or persistent bad state
      clearAuthToken();

      // Global Redirection using navigatorKey
      if (navigatorKey.currentState != null) {
        // Schedule navigation to the next frame to avoid build conflicts
        Future.delayed(const Duration(milliseconds: 100), () {
          navigatorKey.currentState?.pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
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

  static Future<http.Response> getPaymentConfig() async {
    if (!await _checkConnectivity())
      return http.Response('{"error": "No internet connection"}', 503);
    final uri = Uri.parse("$baseUrl/config/payment");
    return _handleSession(await http.get(uri));
  }

  static Future<http.Response> getReferralSystemConfig() async {
    if (!await _checkConnectivity())
      return http.Response('{"error": "No internet connection"}', 503);
    final uri = Uri.parse("$baseUrl/config/referral");
    return _handleSession(await http.get(uri, headers: _addAuth({
      'Accept': 'application/json',
    })));
  }

  static Future<bool> _checkConnectivity() async {
    final isConnected = await ConnectivityService.isConnected();
    if (!isConnected) {
      if (navigatorKey.currentContext != null) {
        CustomToast.showError(
          navigatorKey.currentContext!,
          "Internet connection is required",
        );
      }
      return false;
    }
    return true;
  }

  static Future<http.Response> getExploreProducts() async {
    if (!await _checkConnectivity())
      return http.Response('{"error": "No internet connection"}', 503);
    final uri = Uri.parse("$baseUrl/explore/all");
    return _handleSession(
      await http.get(
        uri,
        headers: _addAuth({
          'Accept': 'application/json',
          'User-Agent': 'Flutter-App',
        }),
      ),
    );
  }

  static Future<http.Response> createPaymentOrder(double amount) async {
    if (!await _checkConnectivity())
      return http.Response('{"error": "No internet connection"}', 503);
    final uri = Uri.parse("$baseUrl/payment/create-order");
    debugPrint("[SUBSCRIPTION][Create Order API] POST $uri");
    debugPrint(
      "[SUBSCRIPTION][Create Order API] Request: ${jsonEncode({'amount': amount, 'currency': 'INR'})}",
    );
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'amount': amount, 'currency': 'INR'}),
    );
    debugPrint(
      "[SUBSCRIPTION][Create Order API] Response status: ${response.statusCode}",
    );
    debugPrint(
      "[SUBSCRIPTION][Create Order API] Response body: ${response.body}",
    );
    return _handleSession(response);
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
    if (!await _checkConnectivity())
      return http.Response('{"error": "No internet connection"}', 503);
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

    debugPrint("[SUBSCRIPTION][Register API] POST $uri");
    debugPrint(
      "[SUBSCRIPTION][Register API] Request fields: "
      "${jsonEncode({...fields, if (fields.containsKey('loginCode')) 'loginCode': '***'})}",
    );
    debugPrint(
      "[SUBSCRIPTION][Register API] referralCode: $referralCode, "
      "razorpayPaymentId: $razorpayPaymentId, razorpayOrderId: $razorpayOrderId, "
      "hasSignature: ${razorpaySignature != null}, amount: $amount, "
      "files: ${payload.files.length}",
    );

    if (payload.files.isNotEmpty) {
      if (payload.role == "assistant") {
        for (var file in payload.files) {
          final mimeType = _getMimeType(file.path);
          request.files.add(
            await http.MultipartFile.fromPath(
              'aadharFile',
              file.path,
              contentType: MediaType.parse(mimeType),
            ),
          );
        }
      } else {
        final file = payload.files.first;
        if (file.existsSync()) {
          final mimeType = _getMimeType(file.path);
          request.files.add(
            await http.MultipartFile.fromPath(
              'photo',
              file.path,
              contentType: MediaType.parse(mimeType),
            ),
          );
        }
      }
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    debugPrint(
      "[SUBSCRIPTION][Register API] Response status: ${response.statusCode}",
    );
    debugPrint("[SUBSCRIPTION][Register API] Response body: ${response.body}");
    return _handleSession(response);
  }

  static Future<http.Response> loginUser({
    String? role,
    required String loginCode,
    required String phoneNum,
    String? deviceId,
  }) async {
    if (!await _checkConnectivity())
      return http.Response('{"error": "No internet connection"}', 503);
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
    if (!await _checkConnectivity())
      return http.Response('{"error": "No internet connection"}', 503);
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
    if (!await _checkConnectivity())
      return http.Response('{"error": "No internet connection"}', 503);
    var uri = Uri.parse("$baseUrl/profile");
    if (forceRefresh) {
      uri = uri.replace(
        queryParameters: {
          't': DateTime.now().millisecondsSinceEpoch.toString(),
        },
      );
    }
    final response = _handleSession(
      await http.get(
        uri,
        headers: _addAuth({
          'Accept': 'application/json',
          'User-Agent': 'Flutter-App',
        }),
      ),
    );
    return _applyLocalAppleMembership(response);
  }

  static Future<http.Response> _applyLocalAppleMembership(
    http.Response response,
  ) async {
    if (response.statusCode != 200) return response;

    try {
      final prefs = await SharedPreferences.getInstance();
      final verified = prefs.getBool("apple_membership_verified") == true;
      final verifiedStandard = prefs.getString("apple_membership_standard");
      if (!verified || verifiedStandard == null) return response;

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return response;

      final profile = decoded['profile'];
      final user = decoded['user'];
      final profileStandard = profile is Map
          ? profile['std']?.toString()
          : null;

      if (user is Map<String, dynamic> &&
          profileStandard != null &&
          profileStandard == verifiedStandard) {
        user['isPaid'] = true;
        return http.Response(
          jsonEncode(decoded),
          response.statusCode,
          headers: response.headers,
          request: response.request,
          isRedirect: response.isRedirect,
          persistentConnection: response.persistentConnection,
          reasonPhrase: response.reasonPhrase,
        );
      }
    } catch (e) {
      debugPrint("Error applying local Apple membership: $e");
    }

    return response;
  }

  static Future<http.Response> updateProfile(
    Map<String, dynamic> data, {
    XFile? imageFile,
  }) async {
    if (!await _checkConnectivity())
      return http.Response('{"error": "No internet connection"}', 503);
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
        request.files.add(
          http.MultipartFile.fromBytes(
            'photo',
            bytes,
            filename: imageFile.name,
            contentType: MediaType.parse(mimeType),
          ),
        );
      } else {
        request.files.add(
          await http.MultipartFile.fromPath(
            'photo',
            imageFile.path,
            contentType: MediaType.parse(mimeType),
          ),
        );
      }
    }

    final streamedResponse = await request.send();
    return _handleSession(await http.Response.fromStream(streamedResponse));
  }

  static Future<http.Response> getDashboardData() async {
    if (!await _checkConnectivity())
      return http.Response('{"error": "No internet connection"}', 503);
    final uri = Uri.parse("$baseUrl/dashboard");
    return _handleSession(
      await http.get(
        uri,
        headers: _addAuth({
          'Accept': 'application/json',
          'User-Agent': 'Flutter-App',
        }),
      ),
    );
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
    if (!await _checkConnectivity())
      return http.Response('{"error": "No internet connection"}', 503);
    final uri = Uri.parse("$baseUrl/exam/submit");
    return _handleSession(
      await http.post(
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
      ),
    );
  }

  static Future<http.Response> updateViolationCount({
    required String examId,
    required String examType,
  }) async {
    if (!await _checkConnectivity())
      return http.Response('{"error": "No internet connection"}', 503);
    final uri = Uri.parse("$baseUrl/exam/violation");
    return _handleSession(
      await http.post(
        uri,
        headers: _addAuth({
          'Content-Type': 'application/json',
          'User-Agent': 'Flutter-App',
        }),
        body: jsonEncode({'examId': examId, 'examType': examType}),
      ),
    );
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
      params['standard'] =
          std; // Backend uses 'standard' for material filtering
    }
    if (medium != null && medium.isNotEmpty) params['medium'] = medium;
    if (board != null && board.isNotEmpty) params['board'] = board;
    if (stream != null &&
        stream.isNotEmpty &&
        stream != "None" &&
        stream != "-")
      params['stream'] = stream;

    return params;
  }

  static Future<http.Response> getBoardPapers({
    required String medium,
    required String std,
    String? stream,
    required String year,
    String? subject,
  }) async {
    if (!await _checkConnectivity())
      return http.Response('{"error": "No internet connection"}', 503);
    final queryParams = await _getDefaultQueryParams();
    queryParams['type'] = 'BoardPaper';
    queryParams['year'] = year;
    queryParams['standard'] = std;
    queryParams['std'] = std;

    if (subject != null && subject.isNotEmpty) queryParams['subject'] = subject;
    if (medium.isNotEmpty) queryParams['medium'] = medium;
    if (stream != null &&
        stream.isNotEmpty &&
        stream != "None" &&
        stream != "-")
      queryParams['stream'] = stream;

    final uri = Uri.parse(
      "$baseUrl/material/all",
    ).replace(queryParameters: queryParams);

    return _handleSession(
      await http.get(
        uri,
        headers: _addAuth({
          'Accept': 'application/json',
          'User-Agent': 'Flutter-App',
        }),
      ),
    );
  }

  static Future<http.Response> getSchoolPapers({
    String? subject,
    String? medium,
    String? std,
    String? year,
    String? board,
    String? stream,
  }) async {
    if (!await _checkConnectivity())
      return http.Response('{"error": "No internet connection"}', 503);
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
    if (stream != null &&
        stream.isNotEmpty &&
        stream != "None" &&
        stream != "-")
      queryParams['stream'] = stream;

    final uri = Uri.parse(
      "$baseUrl/material/all",
    ).replace(queryParameters: queryParams);

    return _handleSession(
      await http.get(
        uri,
        headers: _addAuth({
          'Accept': 'application/json',
          'User-Agent': 'Flutter-App',
        }),
      ),
    );
  }

  static Future<http.Response> getNotes({String? subject}) async {
    if (!await _checkConnectivity())
      return http.Response('{"error": "No internet connection"}', 503);
    final queryParams = await _getDefaultQueryParams();
    queryParams['type'] = 'Notes';
    if (subject != null) queryParams['subject'] = subject;

    final uri = Uri.parse(
      "$baseUrl/material/all",
    ).replace(queryParameters: queryParams);

    return _handleSession(
      await http.get(
        uri,
        headers: _addAuth({
          'Accept': 'application/json',
          'User-Agent': 'Flutter-App',
        }),
      ),
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

  static Future<http.Response> forgetPassword({required String email}) async {
    if (!await _checkConnectivity())
      return http.Response('{"error": "No internet connection"}', 503);
    final uri = Uri.parse("$baseUrl/auth/forget-password");

    return _handleSession(
      await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      ),
    );
  }

  static Future<http.Response> verifyOtp({
    required String email,
    required String otp,
  }) async {
    if (!await _checkConnectivity())
      return http.Response('{"error": "No internet connection"}', 503);
    final uri = Uri.parse("$baseUrl/auth/verify-otp");

    return _handleSession(
      await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'otp': otp}),
      ),
    );
  }

  static Future<http.Response> resetPassword({
    required String email,
    required String newPassword,
  }) async {
    if (!await _checkConnectivity())
      return http.Response('{"error": "No internet connection"}', 503);
    final uri = Uri.parse("$baseUrl/auth/reset-password");

    return _handleSession(
      await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'newPassword': newPassword}),
      ),
    );
  }

  static Future<http.Response> updatePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    if (!await _checkConnectivity())
      return http.Response('{"error": "No internet connection"}', 503);
    final uri = Uri.parse("$baseUrl/auth/update-password");

    return _handleSession(
      await http.post(
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
      ),
    );
  }

  static Future<http.Response> getAllTopRankers() async {
    if (!await _checkConnectivity())
      return http.Response('{"error": "No internet connection"}', 503);
    final uri = Uri.parse("$baseUrl/topRanker/all");
    return _handleSession(await http.get(uri));
  }

  static Future<http.Response> getAllExams({
    String? std,
    String? medium,
    String? subject,
  }) async {
    if (!await _checkConnectivity())
      return http.Response('{"error": "No internet connection"}', 503);
    final queryParams = await _getDefaultQueryParams();
    if (std != null && std.isNotEmpty) queryParams['std'] = std;
    if (medium != null && medium.isNotEmpty) queryParams['medium'] = medium;
    if (subject != null && subject.isNotEmpty) queryParams['subject'] = subject;

    final uri = Uri.parse(
      "$baseUrl/exam/all",
    ).replace(queryParameters: queryParams);
    return _handleSession(await http.get(uri));
  }

  static Future<http.Response> getExamById(String examId) async {
    if (!await _checkConnectivity())
      return http.Response('{"error": "No internet connection"}', 503);
    final uri = Uri.parse("$baseUrl/exam/$examId");
    return _handleSession(
      await http.get(
        uri,
        headers: _addAuth({
          'Accept': 'application/json',
          'User-Agent': 'Flutter-App',
        }),
      ),
    );
  }

  static Future<http.Response> getAllFiveMinTests({
    String? std,
    String? medium,
    String? subject,
  }) async {
    if (!await _checkConnectivity())
      return http.Response('{"error": "No internet connection"}', 503);
    final queryParams = await _getDefaultQueryParams();
    if (std != null && std.isNotEmpty) queryParams['std'] = std;
    if (medium != null && medium.isNotEmpty) queryParams['medium'] = medium;
    if (subject != null && subject.isNotEmpty) queryParams['subject'] = subject;

    final uri = Uri.parse(
      "$baseUrl/fiveMinTest/all",
    ).replace(queryParameters: queryParams);
    return _handleSession(await http.get(uri));
  }

  static Future<http.Response> getFiveMinTestById(String testId) async {
    if (!await _checkConnectivity())
      return http.Response('{"error": "No internet connection"}', 503);
    final uri = Uri.parse("$baseUrl/fiveMinTest/$testId");
    return _handleSession(await http.get(uri));
  }

  static Future<http.Response> getLeaderboard({required String std}) async {
    if (!await _checkConnectivity())
      return http.Response('{"error": "No internet connection"}', 503);
    final uri = Uri.parse("$baseUrl/leaderboard/$std");
    return _handleSession(
      await http.get(
        uri,
        headers: _addAuth({
          'Accept': 'application/json',
          'User-Agent': 'Flutter-App',
        }),
      ),
    );
  }

  static Future<http.Response> getReferralData() async {
    if (!await _checkConnectivity())
      return http.Response('{"error": "No internet connection"}', 503);
    final uri = Uri.parse("$baseUrl/referral/data");
    return _handleSession(
      await http.get(
        uri,
        headers: _addAuth({
          'Accept': 'application/json',
          'User-Agent': 'Flutter-App',
        }),
      ),
    );
  }

  static Future<http.Response> validateReferralCode(String referralCode) async {
    if (!await _checkConnectivity())
      return http.Response('{"error": "No internet connection"}', 503);
    final uri = Uri.parse("$baseUrl/referral/validate");
    final body = {'referralCode': referralCode};
    final stopwatch = Stopwatch()..start();
    debugPrint("[SUBSCRIPTION][Referral Validate API] START");
    debugPrint("[SUBSCRIPTION][Referral Validate API] POST $uri");
    debugPrint(
      "[SUBSCRIPTION][Referral Validate API] Request body: ${jsonEncode(body)}",
    );
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    stopwatch.stop();
    debugPrint(
      "[SUBSCRIPTION][Referral Validate API] Response status: ${response.statusCode}",
    );
    debugPrint(
      "[SUBSCRIPTION][Referral Validate API] Response body: ${response.body}",
    );
    debugPrint(
      "[SUBSCRIPTION][Referral Validate API] END ${stopwatch.elapsedMilliseconds}ms",
    );
    return _handleSession(response);
  }

  static Future<http.Response> applyReferralCode(String referralCode) async {
    if (!await _checkConnectivity())
      return http.Response('{"error": "No internet connection"}', 503);
    final uri = Uri.parse("$baseUrl/referral/apply");
    final body = {'referralCode': referralCode};
    final stopwatch = Stopwatch()..start();
    debugPrint("[SUBSCRIPTION][Referral Apply API] START");
    debugPrint("[SUBSCRIPTION][Referral Apply API] POST $uri");
    debugPrint("[SUBSCRIPTION][Referral Apply API] Request: ${jsonEncode(body)}");
    final response = await http.post(
      uri,
      headers: _addAuth({'Content-Type': 'application/json'}),
      body: jsonEncode(body),
    );
    stopwatch.stop();
    debugPrint(
      "[SUBSCRIPTION][Referral Apply API] Response status: ${response.statusCode}",
    );
    debugPrint("[SUBSCRIPTION][Referral Apply API] Response body: ${response.body}");
    debugPrint(
      "[SUBSCRIPTION][Referral Apply API] END ${stopwatch.elapsedMilliseconds}ms",
    );
    return _handleSession(response);
  }

  static Future<http.Response> submitSupportTicket({
    required String category,
    required String description,
    XFile? screenshot,
  }) async {
    if (!await _checkConnectivity())
      return http.Response('{"error": "No internet connection"}', 503);
    final uri = Uri.parse("$baseUrl/support/submit");
    final request = http.MultipartRequest("POST", uri);

    request.headers.addAll(_addAuth({}));
    request.fields["category"] = category;
    request.fields["description"] = description;

    if (screenshot != null) {
      final mimeType = _getMimeType(screenshot.name);
      if (kIsWeb) {
        final bytes = await screenshot.readAsBytes();
        request.files.add(
          http.MultipartFile.fromBytes(
            'screenshot',
            bytes,
            filename: screenshot.name,
            contentType: MediaType.parse(mimeType),
          ),
        );
      } else {
        request.files.add(
          await http.MultipartFile.fromPath(
            'screenshot',
            screenshot.path,
            contentType: MediaType.parse(mimeType),
          ),
        );
      }
    }

    final streamedResponse = await request.send();
    return _handleSession(await http.Response.fromStream(streamedResponse));
  }

  static Future<http.Response> validateRedeemCode(
    String code, {
    String? targetStd,
    String? targetBoard,
    String? targetMedium,
    String? targetStream,
  }) async {
    if (!await _checkConnectivity())
      return http.Response('{"error": "No internet connection"}', 503);
    final uri = Uri.parse("$baseUrl/redeem/validate");
    return _handleSession(
      await http.post(
        uri,
        headers: _addAuth({'Content-Type': 'application/json'}),
        body: jsonEncode({
          'code': code,
          if (targetStd != null) 'targetStd': targetStd,
          if (targetBoard != null) 'targetBoard': targetBoard,
          if (targetMedium != null) 'targetMedium': targetMedium,
          if (targetStream != null) 'targetStream': targetStream,
        }),
      ),
    );
  }

  static Future<http.Response> getAllEvents() async {
    if (!await _checkConnectivity())
      return http.Response('{"error": "No internet connection"}', 503);
    final uri = Uri.parse("$baseUrl/event/all");
    return _handleSession(await http.get(uri));
  }

  static Future<http.Response> getGameQuestions(String gameType) async {
    if (!await _checkConnectivity())
      return http.Response('{"error": "No internet connection"}', 503);
    final uri = Uri.parse("$baseUrl/games/$gameType");
    return _handleSession(await http.get(uri));
  }

  // --- Product Purchase & History ---

  static Future<http.Response> createProductOrder(
    String productId,
    double amount,
  ) async {
    if (!await _checkConnectivity())
      return http.Response('{"error": "No internet connection"}', 503);
    final uri = Uri.parse("$baseUrl/payment/product/create-order");
    return _handleSession(
      await http.post(
        uri,
        headers: _addAuth({'Content-Type': 'application/json'}),
        body: jsonEncode({
          'productId': productId,
          'amount': amount,
          'currency': 'INR',
        }),
      ),
    );
  }

  static Future<http.Response> verifyProductPayment({
    required String productId,
    required String razorpayPaymentId,
    required String razorpayOrderId,
    required String razorpaySignature,
    required double amount,
  }) async {
    if (!await _checkConnectivity())
      return http.Response('{"error": "No internet connection"}', 503);
    final uri = Uri.parse("$baseUrl/payment/product/verify");
    return _handleSession(
      await http.post(
        uri,
        headers: _addAuth({'Content-Type': 'application/json'}),
        body: jsonEncode({
          'productId': productId,
          'razorpay_payment_id': razorpayPaymentId,
          'razorpay_order_id': razorpayOrderId,
          'razorpay_signature': razorpaySignature,
          'amount': amount,
        }),
      ),
    );
  }

  static Future<http.Response> getPurchasedProducts() async {
    if (!await _checkConnectivity())
      return http.Response('{"error": "No internet connection"}', 503);
    final uri = Uri.parse("$baseUrl/profile/purchased-products");
    return _handleSession(
      await http.get(uri, headers: _addAuth({'Accept': 'application/json'})),
    );
  }

  // --- Plan Upgrade ---

  static Future<http.Response> createUpgradeOrder({
    required double amount,
    required String newStandard,
    required String medium,
    String? stream,
  }) async {
    if (!await _checkConnectivity())
      return http.Response('{"error": "No internet connection"}', 503);
    final uri = Uri.parse("$baseUrl/payment/upgrade/create-order");
    return _handleSession(
      await http.post(
        uri,
        headers: _addAuth({'Content-Type': 'application/json'}),
        body: jsonEncode({
          'amount': amount,
          'newStandard': newStandard,
          'medium': medium,
          'stream': stream,
        }),
      ),
    );
  }

  static Future<http.Response> verifyUpgradePayment({
    required String razorpayPaymentId,
    required String razorpayOrderId,
    required String razorpaySignature,
    required double amount,
    required String newStandard,
    required String medium,
    String? stream,
    String? redeemCode,
  }) async {
    if (!await _checkConnectivity())
      return http.Response('{"error": "No internet connection"}', 503);
    final uri = Uri.parse("$baseUrl/payment/upgrade/verify");
    return _handleSession(
      await http.post(
        uri,
        headers: _addAuth({'Content-Type': 'application/json'}),
        body: jsonEncode({
          'razorpay_payment_id': razorpayPaymentId,
          'razorpay_order_id': razorpayOrderId,
          'razorpay_signature': razorpaySignature,
          'amount': amount,
          'newStandard': newStandard,
          'medium': medium,
          'stream': stream,
          if (redeemCode != null) 'redeemCode': redeemCode,
        }),
      ),
    );
  }

  static Future<http.Response> getUpgradeHistory() async {
    if (!await _checkConnectivity())
      return http.Response('{"error": "No internet connection"}', 503);
    final uri = Uri.parse("$baseUrl/profile/upgrade-history");
    return _handleSession(
      await http.get(uri, headers: _addAuth({'Accept': 'application/json'})),
    );
  }

  // --- Subscription Plans ---
  static Future<http.Response> getActivePlans() async {
    if (!await _checkConnectivity())
      return http.Response('{"error": "No internet connection"}', 503);
    final uri = Uri.parse("$baseUrl/plans/active");
    return _handleSession(
      await http.get(uri, headers: _addAuth({'Accept': 'application/json'})),
    );
  }

  static Future<http.Response> getAllPlans() async {
    if (!await _checkConnectivity())
      return http.Response('{"error": "No internet connection"}', 503);
    final uri = Uri.parse("$baseUrl/plans");
    return _handleSession(
      await http.get(uri, headers: _addAuth({'Accept': 'application/json'})),
    );
  }

  static Future<http.Response> getPlanByStandard(String standard) async {
    if (!await _checkConnectivity())
      return http.Response('{"error": "No internet connection"}', 503);
    final uri = Uri.parse("$baseUrl/plans/$standard");
    return _handleSession(
      await http.get(uri, headers: _addAuth({'Accept': 'application/json'})),
    );
  }

  static Future<http.Response> createOrUpdatePlan({
    required String standard,
    required double amount,
    String? description,
    bool? isActive,
  }) async {
    if (!await _checkConnectivity())
      return http.Response('{"error": "No internet connection"}', 503);
    final uri = Uri.parse("$baseUrl/plans");
    final body = {
      'standard': standard,
      'amount': amount,
      if (description != null) 'description': description,
      if (isActive != null) 'isActive': isActive,
    };
    return _handleSession(
      await http.post(
        uri,
        headers: _addAuth({'Content-Type': 'application/json'}),
        body: jsonEncode(body),
      ),
    );
  }

  static Future<http.Response> bulkUpdatePlans(
    List<Map<String, dynamic>> plans,
  ) async {
    if (!await _checkConnectivity())
      return http.Response('{"error": "No internet connection"}', 503);
    final uri = Uri.parse("$baseUrl/plans/bulk-update");
    return _handleSession(
      await http.post(
        uri,
        headers: _addAuth({'Content-Type': 'application/json'}),
        body: jsonEncode({'plans': plans}),
      ),
    );
  }

  static Future<http.Response> deletePlan(String standard) async {
    if (!await _checkConnectivity())
      return http.Response('{"error": "No internet connection"}', 503);
    final uri = Uri.parse("$baseUrl/plans/$standard");
    return _handleSession(
      await http.delete(
        uri,
        headers: _addAuth({'Accept': 'application/json'}),
      ),
    );
  }

  static Future<http.Response> initializeDefaultPlans() async {
    if (!await _checkConnectivity())
      return http.Response('{"error": "No internet connection"}', 503);
    final uri = Uri.parse("$baseUrl/plans/initialize-default");
    return _handleSession(
      await http.post(
        uri,
        headers: _addAuth({'Content-Type': 'application/json'}),
      ),
    );
  }

  // --- Mind Map ---
  static Future<http.Response> getAllMindMaps() async {
    if (!await _checkConnectivity())
      return http.Response('{"error": "No internet connection"}', 503);
    final queryParams = await _getDefaultQueryParams();
    final uri = Uri.parse(
      "$baseUrl/mindmap/all",
    ).replace(queryParameters: queryParams);
    return _handleSession(await http.get(uri));
  }

  // --- One Liner Exam ---
  static Future<http.Response> getAllOneLinerExams({
    String? std,
    String? medium,
    String? subject,
  }) async {
    if (!await _checkConnectivity())
      return http.Response('{"error": "No internet connection"}', 503);
    final queryParams = await _getDefaultQueryParams();
    if (std != null && std.isNotEmpty) queryParams['std'] = std;
    if (medium != null && medium.isNotEmpty) queryParams['medium'] = medium;
    if (subject != null && subject.isNotEmpty) queryParams['subject'] = subject;

    final uri = Uri.parse(
      "$baseUrl/onelinerexam/all",
    ).replace(queryParameters: queryParams);
    return _handleSession(
      await http.get(
        uri,
        headers: _addAuth({
          'Accept': 'application/json',
          'User-Agent': 'Flutter-App',
        }),
      ),
    );
  }

  static Future<http.Response> getOneLinerExamById(String examId) async {
    if (!await _checkConnectivity())
      return http.Response('{"error": "No internet connection"}', 503);
    final uri = Uri.parse("$baseUrl/onelinerexam/$examId");
    return _handleSession(
      await http.get(
        uri,
        headers: _addAuth({
          'Accept': 'application/json',
          'User-Agent': 'Flutter-App',
        }),
      ),
    );
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
    return _handleSession(
      await http.post(
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
      ),
    );
  }

  // --- True/False Exam ---
  static Future<http.Response> getAllTrueFalseExams({
    String? std,
    String? medium,
    String? subject,
  }) async {
    if (!await _checkConnectivity())
      return http.Response('{"error": "No internet connection"}', 503);
    final queryParams = await _getDefaultQueryParams();
    if (std != null && std.isNotEmpty) queryParams['std'] = std;
    if (medium != null && medium.isNotEmpty) queryParams['medium'] = medium;
    if (subject != null && subject.isNotEmpty) queryParams['subject'] = subject;

    final uri = Uri.parse(
      "$baseUrl/truefalseexam/all",
    ).replace(queryParameters: queryParams);
    return _handleSession(
      await http.get(
        uri,
        headers: _addAuth({
          'Accept': 'application/json',
          'User-Agent': 'Flutter-App',
        }),
      ),
    );
  }

  static Future<http.Response> getTrueFalseExamById(String examId) async {
    if (!await _checkConnectivity())
      return http.Response('{"error": "No internet connection"}', 503);
    final uri = Uri.parse("$baseUrl/truefalseexam/$examId");
    return _handleSession(
      await http.get(
        uri,
        headers: _addAuth({
          'Accept': 'application/json',
          'User-Agent': 'Flutter-App',
        }),
      ),
    );
  }

  static Future<http.Response> submitTrueFalseExamResult({
    required String examId,
    required String title,
    required int obtainedMarks,
    required int totalMarks,
    required double accuracy,
    String? type,
    int violationCount = 0,
    List<Map<String, dynamic>>? answers,
  }) async {
    final uri = Uri.parse("$baseUrl/truefalseexam/submit");
    return _handleSession(
      await http.post(
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
          if (answers != null) 'answers': answers,
        }),
      ),
    );
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
    return _handleSession(
      await http.post(
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
      ),
    );
  }

  static Future<http.Response> getMaterialImages({
    required String subject,
    required String unit,
  }) async {
    if (!await _checkConnectivity())
      return http.Response('{"error": "No internet connection"}', 503);
    final queryParams = await _getDefaultQueryParams();
    queryParams['type'] = 'ImageMaterial';
    queryParams['subject'] = subject;
    queryParams['unit'] = unit;

    final uri = Uri.parse(
      "$baseUrl/material/all",
    ).replace(queryParameters: queryParams);
    return _handleSession(
      await http.get(
        uri,
        headers: _addAuth({
          'Accept': 'application/json',
          'User-Agent': 'Flutter-App',
        }),
      ),
    );
  }

  /// Delete Account (Soft Delete)
  static Future<http.Response> deleteAccount() async {
    if (!await _checkConnectivity())
      return http.Response('{"error": "No internet connection"}', 503);
    final uri = Uri.parse("$baseUrl/profile");
    return _handleSession(
      await http.delete(
        uri,
        headers: _addAuth({
          'Accept': 'application/json',
          'User-Agent': 'Flutter-App',
        }),
      ),
    );
  }

  // --- Apple In-App Purchase Verification ---

  static Future<http.Response> verifyAppleMembership({
    required String receipt,
    required String productId,
    String? expectedProductId,
    required String transactionId,
    required String standard,
    required String medium,
    String? stream,
    double? amount,
  }) async {
    if (!await _checkConnectivity())
      return http.Response('{"error": "No internet connection"}', 503);
    final uri = Uri.parse("$baseUrl/payment/apple/verify-membership");
    final body = {
      'receipt': receipt,
      'apple_receipt': receipt,
      'productId': productId,
      'apple_product_id': productId,
      if (expectedProductId != null) 'expectedProductId': expectedProductId,
      if (expectedProductId != null)
        'expected_apple_product_id': expectedProductId,
      'apple_transaction_id': transactionId,
      'transactionId': transactionId,
      'standard': standard,
      'newStandard': standard,
      'medium': medium,
      if (stream != null && stream.isNotEmpty) 'stream': stream,
      if (amount != null) 'amount': amount,
    };
    final receiptPreview = receipt.length <= 24
        ? receipt
        : "${receipt.substring(0, 24)}...";
    debugPrint("[Apple Membership] POST $uri");
    debugPrint(
      "[Apple Membership] Request: ${jsonEncode({...body, 'receipt': "$receiptPreview (${receipt.length} chars)"})}",
    );
    final response = await http.post(
      uri,
      headers: _addAuth({'Content-Type': 'application/json'}),
      body: jsonEncode(body),
    );
    debugPrint("[Apple Membership] Response status: ${response.statusCode}");
    debugPrint("[Apple Membership] Response body: ${response.body}");
    return _handleSession(response);
  }

  static Future<http.Response> verifyAppleUpgrade({
    required String receipt,
    required String productId,
    String? expectedProductId,
    required String transactionId,
    required String newStandard,
    required String medium,
    String? stream,
    required double amount,
  }) async {
    if (!await _checkConnectivity())
      return http.Response('{"error": "No internet connection"}', 503);
    final uri = Uri.parse("$baseUrl/payment/apple/verify-upgrade");
    final body = {
      'receipt': receipt,
      'productId': productId,
      'apple_product_id': productId,
      if (expectedProductId != null) 'expectedProductId': expectedProductId,
      if (expectedProductId != null)
        'expected_apple_product_id': expectedProductId,
      'apple_transaction_id': transactionId,
      'transactionId': transactionId,
      'newStandard': newStandard,
      'medium': medium,
      if (stream != null) 'stream': stream,
      'amount': amount,
    };
    final receiptPreview = receipt.length <= 24
        ? receipt
        : "${receipt.substring(0, 24)}...";
    debugPrint("[Apple Upgrade] POST $uri");
    debugPrint(
      "[Apple Upgrade] Request: ${jsonEncode({...body, 'receipt': "$receiptPreview (${receipt.length} chars)"})}",
    );
    return _handleSession(
      await http.post(
        uri,
        headers: _addAuth({'Content-Type': 'application/json'}),
        body: jsonEncode(body),
      ),
    );
  }

  static Future<http.Response> verifyAppleProductPurchase({
    required String receipt,
    required String productId,
    required String transactionId,
    required String materialProductId,
    required double amount,
  }) async {
    if (!await _checkConnectivity())
      return http.Response('{"error": "No internet connection"}', 503);
    final uri = Uri.parse("$baseUrl/payment/apple/verify-product");
    final body = {
      'receipt': receipt,
      'productId': productId,
      'transactionId': transactionId,
      'materialProductId': materialProductId,
      'amount': amount,
    };
    final receiptPreview = receipt.length <= 24
        ? receipt
        : "${receipt.substring(0, 24)}...";
    debugPrint("[Apple Product] POST $uri");
    debugPrint(
      "[Apple Product] Request: ${jsonEncode({...body, 'receipt': "$receiptPreview (${receipt.length} chars)"})}",
    );
    _debugPrintFullJson("[Apple Product] Request", body);
    return _handleSession(
      await http.post(
        uri,
        headers: _addAuth({'Content-Type': 'application/json'}),
        body: jsonEncode(body),
      ),
    );
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
    if (!await _checkConnectivity())
      return http.Response('{"error": "No internet connection"}', 503);
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
    fields["productId"] = appleProductId;
    fields["apple_transaction_id"] = appleTransactionId;
    fields["transactionId"] = appleTransactionId;
    if (amount != null) {
      fields["amount"] = amount.toString();
    }

    request.fields.addAll(fields);

    if (payload.files.isNotEmpty) {
      final file = payload.files.first;
      if (file.existsSync()) {
        final mimeType = _getMimeType(file.path);
        request.files.add(
          await http.MultipartFile.fromPath(
            'photo',
            file.path,
            contentType: MediaType.parse(mimeType),
          ),
        );
      }
    }

    final streamedResponse = await request.send();
    return _handleSession(await http.Response.fromStream(streamedResponse));
  }

  // --- Match Following Exam APIs ---

  static Future<http.Response> getAllMatchFollowingExams({
    String? std,
    String? medium,
    String? subject,
  }) async {
    if (!await _checkConnectivity()) return http.Response('{"error": "No internet connection"}', 503);
    final queryParams = await _getDefaultQueryParams();
    if (std != null && std.isNotEmpty) queryParams['std'] = std;
    if (medium != null && medium.isNotEmpty) queryParams['medium'] = medium;
    if (subject != null && subject.isNotEmpty) queryParams['subject'] = subject;

    final uri = Uri.parse(
      "$baseUrl/matchfollowingexam/all",
    ).replace(queryParameters: queryParams);
    return _handleSession(await http.get(uri, headers: _addAuth({
      'Content-Type': 'application/json',
    })));
  }

  static Future<http.Response> getMatchFollowingExamById(String id) async {
    if (!await _checkConnectivity()) return http.Response('{"error": "No internet connection"}', 503);
    final uri = Uri.parse("$baseUrl/matchfollowingexam/$id");
    return _handleSession(await http.get(uri, headers: _addAuth({
      'Content-Type': 'application/json',
    })));
  }

  static Future<http.Response> submitMatchFollowingExamResult({
    required String examId,
    required String title,
    required int obtainedMarks,
    required int totalMarks,
    required num accuracy,
    required int violationCount,
    required List<Map<String, dynamic>> answers,
  }) async {
    if (!await _checkConnectivity()) return http.Response('{"error": "No internet connection"}', 503);
    final uri = Uri.parse("$baseUrl/matchfollowingexam/submit");

    return _handleSession(await http.post(
      uri,
      headers: _addAuth({
        'Content-Type': 'application/json',
      }),
      body: jsonEncode({
        "examId": examId,
        "title": title,
        "obtainedMarks": obtainedMarks,
        "totalMarks": totalMarks,
        "accuracy": accuracy,
        "violationCount": violationCount,
        "answers": answers,
      }),
    ));
  }
}
