class IncidentCategory {
  final String id;
  final String name;
  final String description;

  IncidentCategory({
    required this.id,
    required this.name,
    required this.description,
  });

  factory IncidentCategory.fromJson(Map<String, dynamic> json) {
    return IncidentCategory(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
    );
  }
}
