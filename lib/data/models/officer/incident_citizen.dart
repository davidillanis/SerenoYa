class IncidentCitizen {
  const IncidentCitizen({
    required this.citizenId,
    this.name,
    this.lastName,
    this.phone,
    this.imageUrl,
  });

  factory IncidentCitizen.fromJson(Map<String, dynamic> json) =>
      IncidentCitizen(
        citizenId: json['citizenId']?.toString() ?? '',
        name: json['name']?.toString(),
        lastName: json['lastName']?.toString(),
        phone: json['phone']?.toString(),
        imageUrl: json['imageUrl']?.toString(),
      );

  final String citizenId;
  final String? name;
  final String? lastName;
  final String? phone;
  final String? imageUrl;

  String get fullName => [
    name?.trim(),
    lastName?.trim(),
  ].where((part) => part != null && part.isNotEmpty).join(' ');
}
