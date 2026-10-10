import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sereno_ya/data/models/citizen/incident_create_request.dart';
import 'package:sereno_ya/data/services/api/citizen/incidents_api_service.dart';

void main() {
  test(
    'crea una incidencia con categoryName y deserializa su evidencia',
    () async {
      late RequestOptions capturedRequest;
      final service = _serviceThatResponds(
        onRequest: (request) => capturedRequest = request,
        data: {
          'id': 'incident-1',
          'description': 'Incendio',
          'status': 'REQUESTED',
          'createdAt': '2026-09-28T10:00:00',
          'evidences': [
            {
              'id': 'evidence-1',
              'fileUrl': 'https://cdn.example.com/incident.jpg',
              'fileName': 'incident.jpg',
              'fileType': 'image/jpeg',
              'createdAt': '2026-09-28T10:00:01',
            },
          ],
        },
      );

      final response = await service.createIncident(
        const IncidentCreateRequest(
          description: 'Incendio',
          latitude: -13.6519,
          longitude: -73.365,
          referenceAddress: 'Av. Principal',
          categoryName: 'Incendio',
          evidences: [
            IncidentEvidenceCreateRequest(
              fileUrl: 'https://cdn.example.com/incident.jpg',
              fileName: 'incident.jpg',
              fileType: 'image/jpeg',
            ),
          ],
        ),
      );

      final requestData = Map<String, dynamic>.from(
        capturedRequest.data as Map,
      );
      final evidences = (requestData['evidences'] as List)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
      final evidence = evidences.single;
      expect(capturedRequest.method, 'POST');
      expect(capturedRequest.path, '/incidents/create');
      expect(requestData['categoryName'], 'Incendio');
      expect(requestData, isNot(contains('categoryId')));
      expect(requestData, isNot(contains('evidence')));
      expect(evidence['fileType'], 'image/jpeg');
      expect(evidence, isNot(contains('mimeType')));
      expect(response.data?.id, 'incident-1');
      expect(response.data?.evidence?.fileType, 'image/jpeg');
    },
  );

  test('lista las incidencias del ciudadano con paginación', () async {
    late RequestOptions capturedRequest;
    final service = _serviceThatResponds(
      onRequest: (request) => capturedRequest = request,
      data: {
        'content': [
          {
            'id': 'incident-1',
            'description': 'Incendio',
            'status': 'REQUESTED',
            'latitude': -13.6519,
            'longitude': -73.365,
            'createdAt': '2026-09-28T10:00:00',
          },
        ],
        'page': 1,
        'size': 20,
        'totalElements': 21,
        'totalPages': 2,
      },
    );

    final response = await service.listMyIncidents(page: 1, size: 20);

    expect(capturedRequest.path, '/incidents/me/list');
    expect(capturedRequest.queryParameters['page'], 1);
    expect(capturedRequest.queryParameters['size'], 20);
    expect(capturedRequest.queryParameters, isNot(contains('citizenId')));
    expect(response.data?.content.single.id, 'incident-1');
    expect(response.data?.totalPages, 2);
  });

  test('obtiene el detalle con la evidencia de la incidencia', () async {
    late RequestOptions capturedRequest;
    final service = _serviceThatResponds(
      onRequest: (request) => capturedRequest = request,
      data: {
        'id': 'incident-1',
        'description': 'Incendio',
        'status': 'REQUESTED',
        'latitude': -13.6519,
        'longitude': -73.365,
        'createdAt': '2026-09-28T10:00:00',
        'evidences': [
          {
            'id': 'evidence-1',
            'fileUrl': 'https://cdn.example.com/incident.jpg',
            'fileName': 'incident.jpg',
            'fileType': 'image/jpeg',
            'createdAt': '2026-09-28T10:00:01',
          },
        ],
      },
    );

    final response = await service.getIncidentById('incident-1');

    expect(capturedRequest.path, '/incidents/byId/incident-1');
    expect(
      capturedRequest.queryParameters['fields'],
      contains('category.name'),
    );
    expect(response.data?.evidence?.fileUrl, contains('incident.jpg'));
  });
}

IncidentsApiService _serviceThatResponds({
  required void Function(RequestOptions request) onRequest,
  required Object? data,
}) {
  final dio = Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        onRequest(options);
        handler.resolve(
          Response<dynamic>(
            requestOptions: options,
            statusCode: 200,
            data: {
              'isSuccess': true,
              'message': 'Successful operation',
              'errors': null,
              'data': data,
            },
          ),
        );
      },
    ),
  );
  return IncidentsApiService(dio);
}
