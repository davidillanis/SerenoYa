import 'dart:convert';

class JwtClaims {
  JwtClaims._(this.values);

  factory JwtClaims.decode(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return JwtClaims._(const {});
      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      final decoded = jsonDecode(payload);
      return decoded is Map<String, dynamic>
          ? JwtClaims._(decoded)
          : JwtClaims._(const {});
    } on Object {
      return JwtClaims._(const {});
    }
  }

  final Map<String, dynamic> values;

  String get email =>
      values['email']?.toString() ?? values['sub']?.toString() ?? '';
  Object? get authorities => values['authorities'] ?? values['roles'];
  int? get userId => _toInt(values['userId'] ?? values['id']);
  int? get citizenId => _toInt(values['customerId'] ?? values['citizenId']);
  int? get officerId => _toInt(values['dealerId'] ?? values['officerId']);

  DateTime? get expiresAt {
    final seconds = _toInt(values['exp']);
    return seconds == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(seconds * 1000, isUtc: true);
  }

  static int? _toInt(Object? value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '');
  }
}
