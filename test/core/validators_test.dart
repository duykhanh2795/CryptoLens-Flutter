import 'package:flutter_test/flutter_test.dart';

import 'package:cryptolens_flutter/core/validation/validators.dart';

void main() {
  group('Validators', () {
    test('validates email and password length', () {
      expect(Validators.email('user@example.com'), isNull);
      expect(Validators.email('bad'), 'Invalid email address');
      expect(Validators.email(''), 'Email cannot be empty');

      expect(Validators.minLength('abcdef', 6, 'Password'), isNull);
      expect(
        Validators.minLength('abc', 6, 'Password'),
        'Password must be at least 6 characters',
      );
    });

    test('validates required fields, matching values, and exchange keys', () {
      expect(Validators.requiredText('  ', 'Name'), 'Name cannot be empty');
      expect(
        Validators.matching('a', 'b', 'Password'),
        'Password does not match',
      );
      expect(
        Validators.exchangeCredentials(apiKey: '', secret: 'secret'),
        'API Key and API Secret are required',
      );
      expect(
        Validators.exchangeCredentials(apiKey: 'key', secret: 'secret'),
        isNull,
      );
    });
  });
}
