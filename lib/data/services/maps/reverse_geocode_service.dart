import 'dart:convert';

import 'package:http/http.dart' as http;

/// Geocodificación inversa con Google Geocoding API.
///
/// La clave se inyecta por `--dart-define` (ver [MapsConfig.apiKey]);
/// nunca se hardcodea aquí. Si la clave está vacía, [formattedAddress]
/// devuelve `null` para no interrumpir el flujo del reporte.
class ReverseGeocodeService {
  ReverseGeocodeService({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  Future<String?> formattedAddress({
    required double latitude,
    required double longitude,
    required String apiKey,
  }) async {
    if (apiKey.isEmpty) return null;
    final uri = Uri.https('maps.googleapis.com', '/maps/api/geocode/json', {
      'latlng': '$latitude,$longitude',
      'key': apiKey,
      'language': 'es',
    });
    try {
      final response = await _client
          .get(uri)
          .timeout(const Duration(seconds: 15));
      if (response.statusCode < 200 || response.statusCode >= 300) return null;
      final body = jsonDecode(response.body);
      if (body is! Map<String, dynamic>) return null;
      return parseFormattedAddress(body);
    } catch (_) {
      return null;
    }
  }

  /// Extrae `results[0].formatted_address` cuando `status == OK`.
  /// Devuelve `null` ante `ZERO_RESULTS`, errores o payload inválido.
  static String? parseFormattedAddress(Map<String, dynamic> json) {
    if (json['status'] != 'OK') return null;
    final results = json['results'];
    if (results is! List || results.isEmpty) return null;
    final first = results.first;
    if (first is! Map) return null;
    final address = first['formatted_address'];
    if (address is! String || address.trim().isEmpty) return null;
    return address;
  }
}
