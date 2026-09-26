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
  String? get userId => (values['userId'] ?? values['id'])?.toString();
  String? get citizenId => (values['customerId'] ?? values['citizenId'])?.toString();
  String? get officerId => (values['dealerId'] ?? values['officerId'])?.toString();

  DateTime? get expiresAt {
    final seconds = values['exp'];
    if (seconds == null) return null;
    final intSeconds = seconds is int ? seconds : int.tryParse(seconds.toString());
    return intSeconds == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(intSeconds * 1000, isUtc: true);
  }
}
