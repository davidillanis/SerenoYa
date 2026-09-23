class IncidentCreateRequest {
  final String description;
  final double latitude;
  final double longitude;
  final String referenceAddress;
  final String categoryId;

  IncidentCreateRequest({
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.referenceAddress,
    required this.categoryId,
  });

  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'referenceAddress': referenceAddress,
      'categoryId': categoryId,
    };
  }
}
