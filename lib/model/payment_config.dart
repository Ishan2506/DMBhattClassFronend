class PaymentConfig {
  final String razorpayKeyId;

  PaymentConfig({
    required this.razorpayKeyId,
  });

  factory PaymentConfig.fromJson(Map<String, dynamic> json) {
    return PaymentConfig(
      razorpayKeyId: json['razorpayKeyId'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'razorpayKeyId': razorpayKeyId,
    };
  }
}
