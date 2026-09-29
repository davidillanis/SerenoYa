class CitizenProfile {
  const CitizenProfile({
    required this.id,
    this.homeLatitude,
    this.homeLongitude,
    this.createdAt,
  });

  factory CitizenProfile.fromJson(Object? value) {
    if (value is! Map) {
      throw const FormatException('El perfil ciudadano es inválido.');
    }
    final json = Map<String, dynamic>.from(value);
    return CitizenProfile(
      id: json['id']?.toString() ?? '',
      homeLatitude: _readDouble(json['homeLatitude']),
      homeLongitude: _readDouble(json['homeLongitude']),
      createdAt: _parseLocalDateTime(json['createdAt']),
    );
  }

  final String id;
  final double? homeLatitude;
  final double? homeLongitude;
  final DateTime? createdAt;

  static double? _readDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  static DateTime? _parseLocalDateTime(Object? value) {
    if (value is! String) return null;
    return DateTime.tryParse(value)?.toLocal();
  }
}
