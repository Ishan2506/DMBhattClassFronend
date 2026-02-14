class ValidationUtils {
  /// Validates Indian phone numbers:
  /// - Exactly 10 digits
  /// - Starts with 6, 7, 8, or 9
  static String? validateIndianPhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return "Phone number is required";
    }
    
    // Exactly 10 digits
    if (value.length != 10) {
      return "Phone number must be 10 digits";
    }
    
    // Starts with 6, 7, 8, or 9
    final phoneRegex = RegExp(r'^[6789]\d{9}$');
    if (!phoneRegex.hasMatch(value)) {
      return "Invalid Indian phone number (must start with 6-9)";
    }
    
    return null;
  }
}
