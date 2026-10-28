class UserProfileUpdateRequest {
  const UserProfileUpdateRequest({
    this.name,
    this.lastName,
    this.phone,
    this.imageUrl,
    this.enabled,
    this.notificationsEnabled,
  });

  final String? name;
  final String? lastName;
  final String? phone;
  final String? imageUrl;
  final bool? enabled;
  final bool? notificationsEnabled;

  Map<String, dynamic> toJson() {
    return {
      if (name != null) 'name': name,
      if (lastName != null) 'lastName': lastName,
      if (phone != null) 'phone': phone,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (enabled != null) 'enabled': enabled,
      if (notificationsEnabled != null)
        'notificationsEnabled': notificationsEnabled,
    };
  }
}

class CitizenProfileUpdateRequest {
  const CitizenProfileUpdateRequest({
    required this.homeLatitude,
    required this.homeLongitude,
  });

  final double homeLatitude;
  final double homeLongitude;

  Map<String, dynamic> toJson() {
    return {'homeLatitude': homeLatitude, 'homeLongitude': homeLongitude};
  }
}
