class UserProfileUpdateRequest {
  const UserProfileUpdateRequest({
    required this.name,
    required this.lastName,
    required this.phone,
    required this.address,
  });

  final String name;
  final String lastName;
  final String phone;
  final String address;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'lastName': lastName,
      'phone': phone,
      'address': address,
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
