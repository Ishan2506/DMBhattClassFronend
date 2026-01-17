// models/registration_payload.dart
import 'dart:io';

class RegistrationPayload {
  final String role;
  final Map<String, String> fields;
  final List<File> files;

  RegistrationPayload({
    required this.role,
    required this.fields,
    required this.files,
  });
}
