class AdminUserRolesUpdateRequest {
  const AdminUserRolesUpdateRequest({
    required this.userId,
    required this.roles,
    this.officerLatitude,
    this.officerLongitude,
    this.citizenLatitude,
    this.citizenLongitude,
  });

  final String userId;
  final Set<String> roles;
  final double? officerLatitude;
  final double? officerLongitude;
  final double? citizenLatitude;
  final double? citizenLongitude;

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'roles': roles.toList(growable: false),
    'serenoDTO': officerLatitude == null || officerLongitude == null
        ? null
        : {
            'currentLatitude': officerLatitude,
            'currentLongitude': officerLongitude,
          },
    'citizenDTO': citizenLatitude == null || citizenLongitude == null
        ? null
        : {'homeLatitude': citizenLatitude, 'homeLongitude': citizenLongitude},
  };
}
