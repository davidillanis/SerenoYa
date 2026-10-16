class AdminCategoryUpdateRequest {
  const AdminCategoryUpdateRequest({
    required this.name,
    required this.description,
    required this.enabled,
  });

  final String name;
  final String description;
  final bool enabled;

  Map<String, dynamic> toJson() => {
    'name': name.trim(),
    'description': description.trim(),
    'enabled': enabled,
  };
}
