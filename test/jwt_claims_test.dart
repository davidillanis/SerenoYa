import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sereno_ya/data/models/auth/jwt_claims.dart';

void main() {
  test('decodes RappiGo JWT claims without treating them as validation', () {
    final token = [
      _encode({'alg': 'none'}),
      _encode({
        'sub': 'citizen@example.com',
        'authorities': 'ROLE_CLIENTE',
        'customerId': 42,
        'exp': 4102444800,
      }),
      'signature',
    ].join('.');

    final claims = JwtClaims.decode(token);

    expect(claims.email, 'citizen@example.com');
    expect(claims.authorities, 'ROLE_CLIENTE');
    expect(claims.citizenId, 42);
    expect(claims.expiresAt, DateTime.utc(2100));
  });

  test('returns empty claims for malformed tokens', () {
    final claims = JwtClaims.decode('invalid-token');

    expect(claims.email, isEmpty);
    expect(claims.authorities, isNull);
    expect(claims.expiresAt, isNull);
  });
}

String _encode(Map<String, Object> value) =>
    base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
