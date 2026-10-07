class UserProfileUpdateRequest {
  const UserProfileUpdateRequest({
    this.name,
    this.lastName,
    this.phone,
    this.address,
    this.notificationsEnabled,
  });

  final String? name;
  final String? lastName;
  final String? phone;
  final String? address;
  final bool? notificationsEnabled;

  Map<String, dynamic> toJson() {
    return {
      if (name != null) 'name': name,
      if (lastName != null) 'lastName': lastName,
      if (phone != null) 'phone': phone,
      if (address != null) 'address': address,
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
