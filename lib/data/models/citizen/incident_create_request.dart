class IncidentEvidenceCreateRequest {
  const IncidentEvidenceCreateRequest({
    required this.fileUrl,
    required this.fileName,
    required this.fileType,
  });

  final String fileUrl;
  final String fileName;
  final String fileType;

  Map<String, dynamic> toJson() {
    return {'fileUrl': fileUrl, 'fileName': fileName, 'fileType': fileType};
  }
}

class IncidentCreateRequest {
  final String description;
  final double latitude;
  final double longitude;
  final String referenceAddress;
  final String categoryName;
  final IncidentEvidenceCreateRequest evidence;

  const IncidentCreateRequest({
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.referenceAddress,
    required this.categoryName,
    required this.evidence,
  });

  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'referenceAddress': referenceAddress,
      'categoryName': categoryName,
      'evidence': evidence.toJson(),
    };
  }
}
