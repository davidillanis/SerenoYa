import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sereno_ya/data/models/route/route_compare.dart';
import 'package:sereno_ya/data/services/api/route_api_service.dart';

const _request = RouteCompareRequest(
  origin: RouteCoordinate(latitude: -12.046374, longitude: -77.042793),
  destination: RouteCoordinate(latitude: -13.6519, longitude: -73.365),
);

List<Map<String, dynamic>> _option(
  String mode,
  double distanceKm,
  int duration, [
  int? traffic,
]) => [
  {
    'mode': mode,
    'distanceKm': distanceKm,
    'durationMinutes': duration,
    'trafficDurationMinutes': traffic,
    'polyline': 'poly-$mode',
  },
];

void main() {
  test(
    'compara rutas con el contrato del backend y conserva el orden',
    () async {
      late RequestOptions capturedRequest;
      final service = _serviceThatResponds(
        onRequest: (request) => capturedRequest = request,
        data: [
          ..._option('DRIVE', 5.23, 12, 15),
          ..._option('TWO_WHEELER', 5.1, 14, 16),
          ..._option('BICYCLE', 4.9, 20),
          ..._option('WALK', 4.8, 55),
        ],
      );

      final response = await service.compare(_request);

      final body = Map<String, dynamic>.from(capturedRequest.data as Map);
      final origin = Map<String, dynamic>.from(body['originCoordinate'] as Map);
      final destination = Map<String, dynamic>.from(
        body['destinationCoordinate'] as Map,
      );
      expect(capturedRequest.method, 'POST');
      expect(capturedRequest.path, '/route/compare');
      expect(origin, {'latitude': -12.046374, 'longitude': -77.042793});
      expect(destination, {'latitude': -13.6519, 'longitude': -73.365});

      final options = response.data!;
      expect(response.isSuccess, isTrue);
      expect(options, hasLength(4));
      // La primera es la más rápida según el backend.
      expect(options.first.mode, RouteMode.drive);
      expect(options.map((option) => option.mode), [
        RouteMode.drive,
        RouteMode.twoWheeler,
        RouteMode.bicycle,
        RouteMode.walk,
      ]);

      final drive = options.first;
      expect(drive.distanceKm, 5.23);
      expect(drive.durationMinutes, 12);
      expect(drive.trafficDurationMinutes, 15);
      expect(drive.effectiveMinutes, 15);
      expect(drive.polyline, 'poly-DRIVE');

      // Bicicleta y a pie no traen tráfico: usan la duración base.
      expect(options[2].trafficDurationMinutes, isNull);
      expect(options[2].effectiveMinutes, 20);
      expect(options[3].effectiveMinutes, 55);
    },
  );

  test('mapea modos desconocidos sin inventar datos', () {
    expect(RouteMode.parse('DRIVE'), RouteMode.drive);
    expect(RouteMode.parse('TWO_WHEELER'), RouteMode.twoWheeler);
    expect(RouteMode.parse('BICYCLE'), RouteMode.bicycle);
    expect(RouteMode.parse('WALK'), RouteMode.walk);
    expect(RouteMode.parse('FLY'), RouteMode.unknown);
    expect(RouteOption.fromJson(const {}).mode, RouteMode.unknown);
    expect(RouteOption.fromJson(const {}).effectiveMinutes, 0);
  });
}

RouteApiService _serviceThatResponds({
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
  return RouteApiService(dio);
}
