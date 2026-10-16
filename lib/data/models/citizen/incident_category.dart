class IncidentCategory {
  final String id;
  final String name;
  final String description;
  final bool enabled;

  IncidentCategory({
    required this.id,
    required this.name,
    required this.description,
    this.enabled = true,
  });

  factory IncidentCategory.fromJson(Map<String, dynamic> json) {
    return IncidentCategory(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      enabled: json['enabled'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'enabled': enabled,
    };
  }
}
