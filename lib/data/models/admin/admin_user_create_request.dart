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
    required this.dni,
    required this.phone,
    required this.address,
    required this.email,
    required this.password,
    required this.role,
    this.latitude,
    this.longitude,
    this.birthDate,
    this.imageUrl,
  });

  final String firstName;
  final String lastName;
  final String dni;
  final String phone;
  final DateTime? birthDate;
  final String address;
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
      'dni': dni,
      'phone': phone,
      'birthDate': birthDate == null ? null : _dateOnly(birthDate!),
      'address': address,
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

  static String _dateOnly(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }
}
