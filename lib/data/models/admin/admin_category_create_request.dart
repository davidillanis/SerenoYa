class AdminCategoryCreateRequest {
  const AdminCategoryCreateRequest({
    required this.name,
    required this.description,
  });

  final String name;
  final String description;

  Map<String, dynamic> toJson() => {
    'name': name.trim(),
    'description': description.trim(),
  };
}
