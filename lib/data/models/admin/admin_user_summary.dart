class AdminUserSummary {
  const AdminUserSummary({
    required this.id,
    required this.enabled,
    required this.name,
    required this.lastName,
    required this.dni,
    required this.email,
    this.phone,
  });

  final String id;
  final bool enabled;
  final String name;
  final String lastName;
  final String dni;
  final String email;
  final String? phone;

  factory AdminUserSummary.fromJson(Map<String, dynamic> json) {
    return AdminUserSummary(
      id: json['id']?.toString() ?? '',
      enabled: _readBool(json['enabled'], fallback: true),
      name: json['name']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      dni: json['dni']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: _readOptionalString(json['phone']),
    );
  }

  static bool _readBool(Object? value, {required bool fallback}) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    return switch (value?.toString().toLowerCase()) {
      'true' => true,
      'false' => false,
      _ => fallback,
    };
  }

  static String? _readOptionalString(Object? value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }
}
