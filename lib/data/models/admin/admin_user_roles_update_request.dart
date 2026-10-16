class AdminUserRolesUpdateRequest {
  const AdminUserRolesUpdateRequest({
    required this.userId,
    required this.roles,
  });

  final String userId;
  final Set<String> roles;

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'roles': roles.toList(growable: false),
  };
}
