import 'package:auth/auth.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('email', () {
    expect(AuthValidators.email(''), isNotNull);
    expect(AuthValidators.email('foo'), isNotNull);
    expect(AuthValidators.email('foo@bar'), isNotNull);
    expect(AuthValidators.email(' amira@example.com '), isNull);
  });

  test('new password needs 8+ chars with letters and digits', () {
    expect(AuthValidators.newPassword('abc1'), isNotNull);
    expect(AuthValidators.newPassword('abcdefgh'), isNotNull);
    expect(AuthValidators.newPassword('12345678'), isNotNull);
    expect(AuthValidators.newPassword('deutsch1'), isNull);
  });

  test('confirm password', () {
    final v = AuthValidators.confirmPassword(() => 'deutsch1');
    expect(v('deutsch2'), isNotNull);
    expect(v('deutsch1'), isNull);
  });

  test('display name', () {
    expect(AuthValidators.displayName(' a '), isNotNull);
    expect(AuthValidators.displayName('Amira'), isNull);
    expect(AuthValidators.displayName('x' * 41), isNotNull);
  });
}
