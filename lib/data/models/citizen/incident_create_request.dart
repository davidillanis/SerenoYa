class IncidentEvidenceCreateRequest {
  const IncidentEvidenceCreateRequest({
    required this.fileUrl,
    required this.fileName,
    required this.mimeType,
  });

  final String fileUrl;
  final String fileName;
  final String mimeType;

  Map<String, dynamic> toJson() {
    return {'fileUrl': fileUrl, 'fileName': fileName, 'mimeType': mimeType};
  }
}

class IncidentCreateRequest {
  final String description;
  final double latitude;
  final double longitude;
  final String referenceAddress;
  final String categoryId;
  final IncidentEvidenceCreateRequest evidence;

  IncidentCreateRequest({
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.referenceAddress,
    required this.categoryId,
    required this.evidence,
  });

  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'referenceAddress': referenceAddress,
      'categoryId': categoryId,
      'evidence': evidence.toJson(),
    };
  }
}
