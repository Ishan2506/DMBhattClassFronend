import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/payment_config.dart';
import '../network/api_service.dart';

class PurchaseConfig {
  static final PurchaseConfig instance = PurchaseConfig._internal();
  PurchaseConfig._internal();

  PaymentConfig? _config;

  PaymentConfig get config => _config ?? PaymentConfig(razorpayKeyId: '');

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load from cache first
    final cached = prefs.getString('payment_config');
    if (cached != null) {
      try {
        _config = PaymentConfig.fromJson(jsonDecode(cached));
      } catch (_) {}
    }

    // Fetch from API
    try {
      final response = await ApiService.getPaymentConfig();
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _config = PaymentConfig.fromJson(data);
        await prefs.setString('payment_config', response.body);
      }
    } catch (e) {
      print('Error fetching payment config: $e');
    }
  }
}
