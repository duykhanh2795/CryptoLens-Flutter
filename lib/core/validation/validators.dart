class Validators {
  const Validators._();

  static String? requiredText(String value, String label) {
    return value.trim().isEmpty ? '$label cannot be empty' : null;
  }

  static String? minLength(String value, int minLength, String label) {
    return value.length < minLength
        ? '$label must be at least $minLength characters'
        : null;
  }

  static String? email(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) return 'Email cannot be empty';
    final valid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(normalized);
    return valid ? null : 'Invalid email address';
  }

  static String? matching(String value, String confirmation, String label) {
    return value == confirmation ? null : '$label does not match';
  }

  static String? positiveNumber(String value, String label) {
    final parsed = double.tryParse(value.trim());
    if (parsed == null || parsed <= 0) return '$label must be greater than 0';
    return null;
  }

  static String? exchangeCredentials({
    required String apiKey,
    required String secret,
  }) {
    if (apiKey.trim().isEmpty || secret.trim().isEmpty) {
      return 'API Key and API Secret are required';
    }
    return null;
  }
}
