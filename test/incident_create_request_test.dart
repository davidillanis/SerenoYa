import 'package:flutter_test/flutter_test.dart';
import 'package:sereno_ya/data/models/citizen/incident_create_request.dart';

void main() {
  test('serializa la incidencia con los metadatos de su evidencia', () {
    final request = IncidentCreateRequest(
      description: 'Incendio',
      latitude: -13.6519,
      longitude: -73.365,
      referenceAddress: 'Av. Principal',
      categoryName: 'Incendio',
      evidence: const IncidentEvidenceCreateRequest(
        fileUrl: 'https://storage.example.com/incidents/image.jpg',
        fileName: 'image.jpg',
        fileType: 'image/jpeg',
      ),
    );

    expect(request.toJson(), {
      'description': 'Incendio',
      'latitude': -13.6519,
      'longitude': -73.365,
      'referenceAddress': 'Av. Principal',
      'categoryName': 'Incendio',
      'evidence': {
        'fileUrl': 'https://storage.example.com/incidents/image.jpg',
        'fileName': 'image.jpg',
        'fileType': 'image/jpeg',
      },
    });
  });
}
