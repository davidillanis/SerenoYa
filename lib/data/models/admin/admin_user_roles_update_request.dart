class AdminUserRolesUpdateRequest {
  const AdminUserRolesUpdateRequest({
    required this.userId,
    required this.roles,
    this.serenoCode,
    this.serenoLatitude,
    this.serenoLongitude,
    this.citizenLatitude,
    this.citizenLongitude,
  });

  final String userId;
  final Set<String> roles;
  final String? serenoCode;
  final double? serenoLatitude;
  final double? serenoLongitude;
  final double? citizenLatitude;
  final double? citizenLongitude;

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'roles': roles.toList(growable: false),
    if (roles.contains('OFFICER_SERENO'))
      'serenoDTO': {
        'codeSereno': serenoCode,
        'currentLatitude': serenoLatitude,
        'currentLongitude': serenoLongitude,
      },
    if (roles.contains('CITIZEN'))
      'citizenDTO': {
        'homeLatitude': citizenLatitude,
        'homeLongitude': citizenLongitude,
      },
  };
}
