class AdminUserSummary {
  const AdminUserSummary({
    required this.id,
    required this.enabled,
    required this.notificationsEnabled,
    required this.roles,
    this.phone,
    this.imageUrl,
  });

  final String id;
  final bool enabled;
  final bool notificationsEnabled;
  final String? phone;
  final String? imageUrl;
  final List<String> roles;

  AdminUserSummary copyWith({List<String>? roles}) => AdminUserSummary(
    id: id,
    enabled: enabled,
    notificationsEnabled: notificationsEnabled,
    phone: phone,
    imageUrl: imageUrl,
    roles: roles ?? this.roles,
  );

  factory AdminUserSummary.fromJson(Map<String, dynamic> json) {
    return AdminUserSummary(
      id: json['id']?.toString() ?? '',
      enabled: _readBool(json['enabled'], fallback: true),
      notificationsEnabled: _readBool(
        json['notificationsEnabled'],
        fallback: true,
      ),
      phone: _readOptionalString(json['phone']),
      imageUrl: _readOptionalString(json['imageUrl']),
      roles: _readRoles(json['roles']),
    );
  }

  static List<String> _readRoles(Object? value) {
    if (value is! List) return const [];
    return value
        .map((item) {
          if (item is Map) return item['role']?.toString();
          return item?.toString();
        })
        .whereType<String>()
        .where((role) => role.isNotEmpty)
        .toSet()
        .toList(growable: false);
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
