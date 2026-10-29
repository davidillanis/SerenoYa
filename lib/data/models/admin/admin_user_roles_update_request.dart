class AdminUserRolesUpdateRequest {
  const AdminUserRolesUpdateRequest({
    required this.userId,
    required this.roles,
    this.serenoCode,
    this.citizenLatitude,
    this.citizenLongitude,
  });

  final String userId;
  final Set<String> roles;
  final String? serenoCode;
  final double? citizenLatitude;
  final double? citizenLongitude;

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'roles': roles.toList(growable: false),
    if (roles.contains('OFFICER_SERENO'))
      'serenoDTO': {'codeSereno': serenoCode},
    if (roles.contains('CITIZEN'))
      'citizenDTO': {
        'homeLatitude': citizenLatitude,
        'homeLongitude': citizenLongitude,
      },
  };
}
