enum AdminAssignableRole {
  citizen('CITIZEN'),
  officer('OFFICER_SERENO'),
  administrator('OFFICER_ADMINISTRADOR'),
  developer('DEVELOPMENT');

  const AdminAssignableRole(this.apiValue);

  final String apiValue;

  bool get requiresLocation =>
      this == AdminAssignableRole.officer ||
      this == AdminAssignableRole.citizen;
}

class AdminUserCreateRequest {
  const AdminUserCreateRequest({
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.email,
    required this.password,
    required this.role,
    this.latitude,
    this.longitude,
    this.imageUrl,
  });

  final String firstName;
  final String lastName;
  final String phone;
  final String email;
  final String password;
  final String? imageUrl;
  final AdminAssignableRole role;
  final double? latitude;
  final double? longitude;

  Map<String, dynamic> toJson() => {
    'userDTO': {
      'name': firstName,
      'lastName': lastName,
      'phone': phone,
      'email': email,
      'password': password,
      if (imageUrl != null && imageUrl!.trim().isNotEmpty)
        'imageUrl': imageUrl!.trim(),
      'application': const ['SerenoGo'],
      'roles': [role.apiValue],
    },
    'serenoDTO': role == AdminAssignableRole.officer
        ? {'currentLatitude': latitude, 'currentLongitude': longitude}
        : null,
    'citizenDTO': role == AdminAssignableRole.citizen
        ? {'homeLatitude': latitude, 'homeLongitude': longitude}
        : null,
  };
}
