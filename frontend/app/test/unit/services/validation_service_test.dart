import 'package:flutter_test/flutter_test.dart';
import 'package:voteready/core/services/validation_service.dart';

void main() {
  late ValidationService svc;

  setUp(() => svc = ValidationService());

  // ── Required ────────────────────────────────────────────────────────────
  group('required validation', () {
    test('empty string fails', () {
      final r = svc.validateField('', ValidationService.nameRules);
      expect(r.isValid, isFalse);
      expect(r.errorMessage, isNotNull);
    });

    test('whitespace-only string fails', () {
      final r = svc.validateField('   ', ValidationService.nameRules);
      expect(r.isValid, isFalse);
    });
  });

  // ── Email ───────────────────────────────────────────────────────────────
  group('email validation', () {
    test('valid email passes', () {
      expect(svc.validateField('user@example.com', ValidationService.emailRules).isValid, isTrue);
    });

    test('missing @ fails', () {
      expect(svc.validateField('userexample.com', ValidationService.emailRules).isValid, isFalse);
    });

    test('missing domain fails', () {
      expect(svc.validateField('user@', ValidationService.emailRules).isValid, isFalse);
    });
  });

  // ── Phone ───────────────────────────────────────────────────────────────
  group('phone validation (Indian)', () {
    test('valid 10-digit number starting with 9 passes', () {
      expect(svc.validateField('9876543210', ValidationService.phoneRules).isValid, isTrue);
    });

    test('number starting with 5 fails', () {
      expect(svc.validateField('5876543210', ValidationService.phoneRules).isValid, isFalse);
    });

    test('9-digit number fails', () {
      expect(svc.validateField('987654321', ValidationService.phoneRules).isValid, isFalse);
    });
  });

  // ── Password ────────────────────────────────────────────────────────────
  group('password validation', () {
    test('8+ chars with letters and digits passes', () {
      expect(svc.validateField('Pass1234', ValidationService.passwordRules).isValid, isTrue);
    });

    test('7 chars fails', () {
      expect(svc.validateField('Pass123', ValidationService.passwordRules).isValid, isFalse);
    });

    test('letters only fails', () {
      expect(svc.validateField('Password', ValidationService.passwordRules).isValid, isFalse);
    });

    test('digits only fails', () {
      expect(svc.validateField('12345678', ValidationService.passwordRules).isValid, isFalse);
    });
  });

  // ── Age ─────────────────────────────────────────────────────────────────
  group('age validation', () {
    test('18 passes', () {
      expect(svc.validateField('18', ValidationService.ageRules).isValid, isTrue);
    });

    test('17 fails', () {
      expect(svc.validateField('17', ValidationService.ageRules).isValid, isFalse);
    });

    test('120 passes', () {
      expect(svc.validateField('120', ValidationService.ageRules).isValid, isTrue);
    });

    test('121 fails', () {
      expect(svc.validateField('121', ValidationService.ageRules).isValid, isFalse);
    });

    test('non-numeric fails', () {
      expect(svc.validateField('abc', ValidationService.ageRules).isValid, isFalse);
    });
  });

  // ── Pincode ─────────────────────────────────────────────────────────────
  group('pincode validation', () {
    test('6-digit pincode passes', () {
      expect(svc.validateField('110001', ValidationService.pincodeRules).isValid, isTrue);
    });

    test('5-digit pincode fails', () {
      expect(svc.validateField('11000', ValidationService.pincodeRules).isValid, isFalse);
    });

    test('letters fail', () {
      expect(svc.validateField('11000A', ValidationService.pincodeRules).isValid, isFalse);
    });
  });

  // ── Aadhaar ─────────────────────────────────────────────────────────────
  group('Aadhaar validation', () {
    test('12-digit number passes', () {
      expect(svc.validateField('123456789012', ValidationService.aadhaarRules).isValid, isTrue);
    });

    test('formatted with spaces passes', () {
      expect(svc.validateField('1234 5678 9012', ValidationService.aadhaarRules).isValid, isTrue);
    });

    test('11 digits fails', () {
      expect(svc.validateField('12345678901', ValidationService.aadhaarRules).isValid, isFalse);
    });
  });

  // ── Voter ID ────────────────────────────────────────────────────────────
  group('Voter ID validation', () {
    test('valid EPIC format passes', () {
      expect(svc.validateField('ABC1234567', ValidationService.voterIdRules).isValid, isTrue);
    });

    test('lowercase is normalised and passes', () {
      expect(svc.validateField('abc1234567', ValidationService.voterIdRules).isValid, isTrue);
    });

    test('only 2 letters fails', () {
      expect(svc.validateField('AB1234567', ValidationService.voterIdRules).isValid, isFalse);
    });
  });

  // ── ValidationResult helpers ────────────────────────────────────────────
  group('ValidationResult', () {
    test('success() has isValid true and no message', () {
      final r = ValidationResult.success();
      expect(r.isValid, isTrue);
      expect(r.errorMessage, isNull);
    });

    test('error() has isValid false and a message', () {
      final r = ValidationResult.error('bad input');
      expect(r.isValid, isFalse);
      expect(r.errorMessage, 'bad input');
    });
  });

  // ── Custom validator ────────────────────────────────────────────────────
  group('custom validator', () {
    test('custom bool validator returning false fails', () {
      final rule = ValidationRule(
        type: ValidationType.required,
        customValidator: (String v) => v != 'forbidden' ? true : false,
        errorMessage: 'forbidden word',
      );
      final r = svc.validateField('forbidden', [rule]);
      expect(r.isValid, isFalse);
    });

    test('custom string validator returning message fails', () {
      final rule = ValidationRule(
        type: ValidationType.required,
        customValidator: (String v) => v.length > 3 ? null : 'too short',
      );
      final r = svc.validateField('ab', [rule]);
      expect(r.isValid, isFalse);
    });
  });
}
