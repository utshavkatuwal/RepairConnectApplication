import 'package:uuid/uuid.dart';

final _uuid = Uuid();

String newIdempotencyKey() => _uuid.v4();

bool isEmail(String v) =>
    RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim());

String? emailValidator(String? v) {
  if (v == null || v.trim().isEmpty) return 'Email is required';
  if (!isEmail(v)) return 'Enter a valid email';
  return null;
}

String? passwordValidator(String? v) {
  if (v == null || v.isEmpty) return 'Password is required';
  if (v.length < 8) return 'Minimum 8 characters';
  return null;
}

/// Strong password for signup/reset: min 8 + letter + digit. Server is authoritative.
String? strongPasswordValidator(String? v) {
  final base = passwordValidator(v);
  if (base != null) return base;
  if (!RegExp(r'[A-Za-z]').hasMatch(v!)) return 'Include a letter';
  if (!RegExp(r'[0-9]').hasMatch(v)) return 'Include a number';
  return null;
}

String? confirmPasswordValidator(String? v, String first) {
  if (v == null || v.isEmpty) return 'Confirm your password';
  if (v != first) return 'Passwords do not match';
  return null;
}

/// 6-digit OTP / verification code.
String? otpValidator(String? v) {
  if (v == null || v.trim().isEmpty) return 'Code is required';
  if (!RegExp(r'^\d{6}$').hasMatch(v.trim())) return 'Enter the 6-digit code';
  return null;
}

String? resetTokenValidator(String? v) {
  if (v == null || v.trim().isEmpty) return 'Reset token is required';
  if (v.trim().length < 8) return 'Invalid reset token';
  return null;
}

/// Service/problem description: min 10, max 2000 (mirrors server).
String? descriptionValidator(String? v) {
  if (v == null || v.trim().isEmpty) return 'Description is required';
  if (v.trim().length < 10) {
    return 'Describe the problem (min 10 chars)';
  }
  if (v.trim().length > 2000) return 'Max 2000 characters';
  return null;
}

/// Chat message: non-empty, max 2000.
String? messageValidator(String? v) {
  if (v == null || v.trim().isEmpty) return 'Message is empty';
  if (v.trim().length > 2000) return 'Max 2000 characters';
  return null;
}

/// Preferred date/time must be present and in the future (client UX;
/// server revalidates against its own clock).
String? futureDateValidator(DateTime? v) {
  if (v == null) return 'Date/time is required';
  if (!v.isAfter(DateTime.now())) return 'Must be in the future';
  return null;
}

/// Price/amount guard shared by services and payments.
String? priceValidator(double? v) {
  if (v == null || v.isNaN) return 'Price required';
  if (v <= 0) return 'Price must be positive';
  if (v > 100000) return 'Exceeds single-item limit';
  return null;
}

String? requiredValidator(String? v, [String name = 'This field']) {
  if (v == null || v.trim().isEmpty) return '$name is required';
  return null;
}

String? phoneValidator(String? v) {
  if (v == null || v.trim().isEmpty) return 'Phone is required';
  if (v.trim().length < 7) return 'Enter a valid phone';
  return null;
}
