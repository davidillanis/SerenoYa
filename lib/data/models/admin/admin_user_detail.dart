class AdminUserDetail {
  const AdminUserDetail({
    required this.id,
    required this.name,
    required this.lastName,
    required this.email,
    required this.address,
    required this.enabled,
    required this.notificationsEnabled,
    required this.roles,
    this.phone,
    this.birthDate,
    this.imageUrl,
  });

  final String id;
  final String name;
  final String lastName;
  final String email;
  final String address;
  final bool enabled;
  final bool notificationsEnabled;
  final List<String> roles;
  final String? phone;
  final DateTime? birthDate;
  final String? imageUrl;

  factory AdminUserDetail.fromJson(Map<String, dynamic> json) {
    return AdminUserDetail(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      enabled: _readBool(json['enabled'], fallback: true),
      notificationsEnabled: _readBool(
        json['notificationsEnabled'],
        fallback: true,
      ),
      roles: _readRoles(json['roles']),
      phone:
          _readOptionalString(json['phone']) ??
          _readOptionalString(json['issoraPhone']),
      birthDate: DateTime.tryParse(json['birthDate']?.toString() ?? ''),
      imageUrl: _readOptionalString(json['imageUrl']),
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
