/// Client-side input safety (§14, §26). Improves UX and reduces junk sent
/// to the server. Backend validation is authoritative — this never replaces
/// server rules, it mirrors them so users get instant feedback.
library;

/// Trim + collapse inner whitespace + strip control characters.
/// Never logs or transmits raw unsanitized input to crash reporters.
String sanitizeText(String input, {int max = 2000}) {
  var s = input.trim().replaceAll(RegExp(r'\s+'), ' ');
  s = s.replaceAll(RegExp(r'[\u0000-\u0008\u000B\u000C\u000E-\u001F]'), '');
  if (s.length > max) s = s.substring(0, max);
  return s;
}

/// Safe server-bound filename: strips paths, keeps alnum + dot/dash,
/// forces lowercase extension. Never trust client file paths (§19).
String safeFilename(String original) {
  var name = original.split(RegExp(r'[\\/]')).last.trim();
  name = name.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
  if (name.isEmpty || name == '.' || name == '..') {
    name = 'upload_${DateTime.now().millisecondsSinceEpoch}';
  }
  if (name.length > 120) {
    final dot = name.lastIndexOf('.');
    final ext = dot > 0 ? name.substring(dot) : '';
    name = '${name.substring(0, 120 - ext.length)}$ext';
  }
  return name;
}

/// Redact secrets before any logging. Call on maps that may carry tokens.
Map<String, dynamic> redactSecrets(Map<String, dynamic> data) {
  const keys = {
    'password',
    'token',
    'refresh_token',
    'authorization',
    'secret',
    'api_key',
    'apikey'
  };
  return data.map((k, v) =>
      MapEntry(k, keys.contains(k.toLowerCase()) ? '***' : v));
}

/// Email normalization: lowercase + trim (prevents duplicate accounts
/// like "User@X.co" vs "user@x.co").
String normalizeEmail(String email) => email.trim().toLowerCase();
