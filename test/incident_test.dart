import 'package:flutter_test/flutter_test.dart';
import 'package:sereno_ya/data/models/citizen/incident.dart';

void main() {
  group('Incident.fromJson', () {
    test('convierte createdAt UTC a la zona horaria del dispositivo', () {
      const utcValue = '2026-09-26T23:57:00Z';

      final incident = Incident.fromJson(_incidentJson(createdAt: utcValue));

      expect(incident.createdAt, DateTime.parse(utcValue).toLocal());
      expect(incident.createdAt?.isUtc, isFalse);
    });

    test('conserva createdAt local cuando la API no incluye zona horaria', () {
      const localValue = '2026-09-26T18:57:00';

      final incident = Incident.fromJson(_incidentJson(createdAt: localValue));

      expect(incident.createdAt, DateTime.parse(localValue));
      expect(incident.createdAt?.isUtc, isFalse);
    });

    test('usa null cuando createdAt no es una fecha valida', () {
      final incident = Incident.fromJson(_incidentJson(createdAt: 'invalida'));

      expect(incident.createdAt, isNull);
    });

    test('deserializa la evidencia devuelta por el backend', () {
      final incident = Incident.fromJson({
        ..._incidentJson(createdAt: '2026-09-28T10:00:00'),
        'evidences': [
          {
            'id': 'evidence-1',
            'fileUrl': 'https://cdn.example.com/incident.jpg',
            'fileName': 'incident.jpg',
            'fileType': 'image/jpeg',
            'createdAt': '2026-09-28T10:00:01',
          },
        ],
      });

      expect(incident.evidences.single.id, 'evidence-1');
      expect(
        incident.evidence?.fileUrl,
        'https://cdn.example.com/incident.jpg',
      );
      expect(incident.evidence?.fileType, 'image/jpeg');
    });

    test('mantiene compatibilidad con la respuesta singular evidence', () {
      final incident = Incident.fromJson({
        ..._incidentJson(createdAt: '2026-09-28T10:00:00'),
        'evidence': {
          'id': 'evidence-1',
          'fileUrl': 'https://cdn.example.com/incident.jpg',
          'fileName': 'incident.jpg',
          'fileType': 'image/jpeg',
          'createdAt': '2026-09-28T10:00:01',
        },
      });

      expect(incident.evidences.single.id, 'evidence-1');
      expect(incident.evidence?.fileUrl, contains('incident.jpg'));
    });
  });
}

Map<String, dynamic> _incidentJson({required Object? createdAt}) {
  return <String, dynamic>{
    'id': 'incident-1',
    'status': 'REQUESTED',
    'description': 'Incendio',
    'latitude': -13.6519,
    'longitude': -73.365,
    'createdAt': createdAt,
  };
}
