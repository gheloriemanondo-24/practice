import 'package:flutter_test/flutter_test.dart';

import 'package:campuseats/models/models.dart';
import 'package:campuseats/validators.dart';

// Pure unit tests: no widgets, so they run in milliseconds.
void main() {
  group('validateFullName', () {
    test('accepts normal and accented names', () {
      expect(validateFullName('Ana Dela Cruz'), isNull);
      expect(validateFullName("Ma. Niño O'Brien-Reyes"), isNull);
    });
    test('rejects empty, single word, digits and symbols', () {
      expect(validateFullName(''), 'Enter your full name');
      expect(validateFullName('   '), 'Enter your full name');
      expect(validateFullName('Ana'), 'Enter your first and last name');
      expect(validateFullName('Ana 2nd'), isNotNull);
      expect(validateFullName('Ana <b>Cruz'), isNotNull);
    });
  });

  group('validateEmail', () {
    test('accepts valid emails', () {
      expect(validateEmail('ana@campus.edu'), isNull);
      expect(validateEmail('  ana.cruz+food@mail.campus.edu '), isNull);
    });
    test('rejects invalid emails', () {
      expect(validateEmail(''), 'Enter your email');
      for (final bad in ['ana', 'ana@', '@campus.edu', 'ana@campus', 'a b@c.d', 'a@b..c']) {
        expect(validateEmail(bad), 'Enter a valid email address', reason: bad);
      }
    });
  });

  group('validateIdNumber', () {
    test('each role has its own format', () {
      expect(validateIdNumber('2024-00123', UserRole.student), isNull);
      expect(validateIdNumber('FAC-0456', UserRole.teacher), isNull);
      expect(validateIdNumber('fac-0456', UserRole.teacher), isNull); // any case
      expect(validateIdNumber('STF-0789', UserRole.stallStaff), isNull);
    });
    test('a format from another role is rejected', () {
      expect(validateIdNumber('FAC-0456', UserRole.student),
          'Use the format 2024-00123');
      expect(validateIdNumber('2024-00123', UserRole.stallStaff),
          'Use the format STF-0789');
    });
    test('empty uses the role label', () {
      expect(validateIdNumber('', UserRole.student), 'Enter your student id');
      expect(validateIdNumber(null, UserRole.teacher), 'Enter your faculty id');
    });
  });

  group('passwords', () {
    test('validateNewPassword', () {
      expect(validateNewPassword(''), 'Create a password');
      expect(validateNewPassword('abc12'), 'Use at least 8 characters');
      expect(validateNewPassword('abcdefgh'),
          'Include at least one letter and one number');
      expect(validateNewPassword('12345678'),
          'Include at least one letter and one number');
      expect(validateNewPassword('abc 12345'), 'Password cannot contain spaces');
      expect(validateNewPassword('secret123'), isNull);
    });
    test('validateConfirmPassword', () {
      expect(validateConfirmPassword('', 'secret123'), 'Confirm your password');
      expect(validateConfirmPassword('secret12', 'secret123'),
          'Passwords do not match');
      expect(validateConfirmPassword('secret123', 'secret123'), isNull);
    });
    test('passwordStrength levels', () {
      expect(passwordStrength(''), 0);
      expect(passwordStrength('abc'), 1); // rules missing
      expect(passwordStrength('secret123'), 2); // meets rules only
      expect(passwordStrength('Secret123'), 3); // mixed case
      expect(passwordStrength('secret123!'), 3); // symbol
      expect(passwordStrength('secretsecret12'), 3); // long
    });
    test('login only needs something typed', () {
      expect(validatePassword(''), 'Enter your password');
      expect(validatePassword('x'), isNull);
    });
  });
}
