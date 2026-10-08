import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sereno_ya/data/services/maps/reverse_geocode_service.dart';

void main() {
  test('extrae formatted_address cuando status es OK', () {
    final address = ReverseGeocodeService.parseFormattedAddress({
      'status': 'OK',
      'results': [
        {'formatted_address': 'Jr. Lima 123, San Jerónimo, Perú'},
      ],
    });
    expect(address, 'Jr. Lima 123, San Jerónimo, Perú');
  });

  test('devuelve null ante ZERO_RESULTS o payload inválido', () {
    expect(
      ReverseGeocodeService.parseFormattedAddress({
        'status': 'ZERO_RESULTS',
        'results': [],
      }),
      isNull,
    );
    expect(
      ReverseGeocodeService.parseFormattedAddress({'status': 'OK'}),
      isNull,
    );
    expect(
      ReverseGeocodeService.parseFormattedAddress({
        'status': 'OK',
        'results': [
          {'formatted_address': '  '},
        ],
      }),
      isNull,
    );
  });

  test('llama a Geocoding API con latlng y clave', () async {
    Uri? capturedUri;
    final client = MockClient((request) async {
      capturedUri = request.url;
      return http.Response(
        jsonEncode({
          'status': 'OK',
          'results': [
            {'formatted_address': 'Av. Principal 456, Cusco'},
          ],
        }),
        200,
      );
    });
    final service = ReverseGeocodeService(client: client);

    final address = await service.formattedAddress(
      latitude: -13.6519,
      longitude: -73.365,
      apiKey: 'test-key',
    );

    expect(address, 'Av. Principal 456, Cusco');
    expect(capturedUri?.host, 'maps.googleapis.com');
    expect(capturedUri?.path, '/maps/api/geocode/json');
    expect(capturedUri?.queryParameters['latlng'], '-13.6519,-73.365');
    expect(capturedUri?.queryParameters['key'], 'test-key');
    expect(capturedUri?.queryParameters['language'], 'es');
  });

  test('devuelve null sin clave o ante error de red', () async {
    final okClient = MockClient((_) async => http.Response('{}', 200));
    final service = ReverseGeocodeService(client: okClient);
    expect(
      await service.formattedAddress(
        latitude: -13.65,
        longitude: -73.36,
        apiKey: '',
      ),
      isNull,
    );

    final failing = MockClient((_) async => http.Response('error', 500));
    final failingService = ReverseGeocodeService(client: failing);
    expect(
      await failingService.formattedAddress(
        latitude: -13.65,
        longitude: -73.36,
        apiKey: 'test-key',
      ),
      isNull,
    );
  });
}
