class AdminCreatedUser {
  const AdminCreatedUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.roles,
    this.serenoCode,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final List<String> roles;
  final String? serenoCode;

  String get displayName => '$firstName $lastName'.trim();

  factory AdminCreatedUser.fromJson(Map<String, dynamic> json) {
    return AdminCreatedUser(
      id: json['id']?.toString() ?? '',
      firstName: json['name']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      roles: switch (json['roles']) {
        List<dynamic> values =>
          values.map((value) => value.toString()).toList(),
        _ => const [],
      },
      serenoCode: json['serenoCode']?.toString(),
    );
  }
}
