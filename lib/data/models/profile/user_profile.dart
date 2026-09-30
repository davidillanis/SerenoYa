class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    required this.lastName,
    required this.email,
    required this.dni,
    required this.phone,
    required this.address,
    required this.enabled,
    required this.emailVerified,
    this.birthDate,
    this.imageUrl,
  });

  factory UserProfile.fromJson(Object? value) {
    if (value is! Map) {
      throw const FormatException('El perfil de usuario es inválido.');
    }
    final json = Map<String, dynamic>.from(value);
    final localPhone = json['phone']?.toString() ?? '';
    final remotePhone = json['issoraPhone']?.toString() ?? '';
    return UserProfile(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      dni: json['dni']?.toString() ?? '',
      phone: localPhone.isNotEmpty ? localPhone : remotePhone,
      address: json['address']?.toString() ?? '',
      enabled: json['enabled'] == true,
      emailVerified: json['emailVerified'] == true,
      birthDate: _parseDate(json['birthDate']),
      imageUrl: _optionalText(json['imageUrl']),
    );
  }

  final String id;
  final String name;
  final String lastName;
  final String email;
  final String dni;
  final String phone;
  final String address;
  final bool enabled;
  final bool emailVerified;
  final DateTime? birthDate;
  final String? imageUrl;

  String get displayName {
    final value = '$name $lastName'.trim();
    return value.isEmpty ? email : value;
  }

  UserProfile copyWith({
    String? name,
    String? lastName,
    String? phone,
    String? address,
  }) {
    return UserProfile(
      id: id,
      name: name ?? this.name,
      lastName: lastName ?? this.lastName,
      email: email,
      dni: dni,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      enabled: enabled,
      emailVerified: emailVerified,
      birthDate: birthDate,
      imageUrl: imageUrl,
    );
  }

  static DateTime? _parseDate(Object? value) {
    if (value is! String) return null;
    return DateTime.tryParse(value);
  }

  static String? _optionalText(Object? value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }
}
