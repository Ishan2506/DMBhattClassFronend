import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:flutter/material.dart';
import 'package:dm_bhatt_tutions/utils/custom_toast.dart';

class RazorpayHelper {
  final Razorpay _razorpay = Razorpay();
  final BuildContext context;
  final Function(PaymentSuccessResponse) onSuccess;
  final Function(PaymentFailureResponse) onFailure;

  // Key provided by user
  static const String _keyId = 'rzp_test_RlEXP3KcdFxaDU';

  RazorpayHelper({
    required this.context,
    required this.onSuccess,
    required this.onFailure,
  }) {
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    onSuccess(response);
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    onFailure(response);
    CustomToast.showError(context, "Payment Failed: ${response.message}");
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    CustomToast.showSuccess(context, "External Wallet: ${response.walletName}");
  }

  void openCheckout({
    required double amount, 
    required String name,
    required String description,
    required String contact,
    required String email,
    String? orderId,
  }) {
    var options = {
      'key': _keyId,
      'amount': (amount * 100).toInt(),
      'name': name,
      'description': description,
      'retry': {'enabled': true, 'max_count': 1},
      'send_sms_hash': true,
      'prefill': {
        if (contact.isNotEmpty) 'contact': contact,
        if (email.isNotEmpty) 'email': email,
      },
      if (orderId != null) 'order_id': orderId,
      'external': {
        'wallets': ['paytm']
      }
    };

    debugPrint("Razorpay Opening with options: $options");

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint('Error: $e');
      CustomToast.showError(context, "Error starting payment: $e");
    }
  }

  void dispose() {
    _razorpay.clear();
  }
}
