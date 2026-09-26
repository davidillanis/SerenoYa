class AuthResponseDto {
  const AuthResponseDto({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.accessToken,
    required this.refreshToken,
    this.imageUrl,
    this.phone,
  });

  factory AuthResponseDto.fromJson(Object? value) {
    if (value is! Map) {
      throw const FormatException('Respuesta de autenticación inválida.');
    }
    final json = Map<String, dynamic>.from(value);
    final accessToken = json['accessToken']?.toString() ?? '';
    final refreshToken = json['refreshToken']?.toString() ?? '';
    if (accessToken.isEmpty || refreshToken.isEmpty) {
      throw const FormatException('La respuesta no contiene tokens válidos.');
    }

    return AuthResponseDto(
      id: json['id']?.toString() ?? '',
      firstName: json['name']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString(),
      phone: json['phone']?.toString(),
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }

  final String id;
  final String firstName;
  final String lastName;
  final String? imageUrl;
  final String? phone;
  final String accessToken;
  final String refreshToken;
}
