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

  /// Full password complexity validation for Toast messages:
  /// - Minimum 6 characters
  /// - At least one capital letter
  /// - At least one digit
  /// - At least one special character
  static String? validatePasswordForToast(String? value, dynamic l10n) {
    if (value == null || value.isEmpty) {
      return l10n.pleaseEnterPassword;
    }

    final trimmed = value.trim();

    if (trimmed.length < 6) {
      return l10n.passwordLengthError;
    }

    // Requirements: 1 Capital, 1 Digit, 1 Special
    bool hasCapital = trimmed.contains(RegExp(r'[A-Z]'));
    bool hasDigit = trimmed.contains(RegExp(r'[0-9]'));
    bool hasSpecial = trimmed.contains(RegExp(r'[!@#\$&*~%^()_+=|{}:;<>?,./\-]'));

    if (!hasCapital || !hasDigit || !hasSpecial) {
      return l10n.passwordComplexityError;
    }

    return null;
  }

  /// Explicitly returns null to disable field-level red error messages
  static String? noFieldError(String? value, dynamic l10n) {
    return null;
  }

  /// Validates email format
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return "Email is required";
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return "Please enter a valid email address";
    }
    return null;
  }
}
