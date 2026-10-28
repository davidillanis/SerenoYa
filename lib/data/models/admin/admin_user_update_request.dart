class AdminUserUpdateRequest {
  const AdminUserUpdateRequest({
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

  Map<String, dynamic> toJson() => {
    if (name != null) 'name': name,
    if (lastName != null) 'lastName': lastName,
    if (phone != null) 'phone': phone,
    if (imageUrl != null) 'imageUrl': imageUrl,
    if (enabled != null) 'enabled': enabled,
    if (notificationsEnabled != null)
      'notificationsEnabled': notificationsEnabled,
  };
}
