class IncidentCreateRequest {
  final String description;
  final double latitude;
  final double longitude;
  final String referenceAddress;
  final String categoryId;
  final String? imageUrl;

  IncidentCreateRequest({
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.referenceAddress,
    required this.categoryId,
    this.imageUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'referenceAddress': referenceAddress,
      'categoryId': categoryId,
      if (imageUrl != null) 'imageUrl': imageUrl,
    };
  }
}
