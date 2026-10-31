class IncidentContactInfo {
  const IncidentContactInfo({
    required this.userId,
    required this.name,
    required this.lastName,
    required this.phone,
    this.imageUrl,
  });

  factory IncidentContactInfo.fromJson(Map<String, dynamic> json) {
    return IncidentContactInfo(
      userId: json['userId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString(),
    );
  }

  final String userId;
  final String name;
  final String lastName;
  final String phone;
  final String? imageUrl;

  String get fullName =>
      [name.trim(), lastName.trim()].where((part) => part.isNotEmpty).join(' ');
}
