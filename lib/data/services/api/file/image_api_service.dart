import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class ImageUploadResponse {
  final String fileKey;
  final String publicUrl;
  final String contentType;
  final int sizeBytes;
  final String category;

  const ImageUploadResponse({
    required this.fileKey,
    required this.publicUrl,
    required this.contentType,
    required this.sizeBytes,
    required this.category,
  });

  factory ImageUploadResponse.fromJson(Map<String, dynamic> json) {
    return ImageUploadResponse(
      fileKey: json['fileKey'] as String,
      publicUrl: json['publicUrl'] as String,
      contentType: json['contentType'] as String,
      sizeBytes: (json['sizeBytes'] as num).toInt(),
      category: json['category'] as String,
    );
  }
}

class StorageService {
  static const String baseUrl = 'http://187.33.158.70:8083';

  Future<ImageUploadResponse> uploadImage({
    required File file,
    String bucket = 'SERENO_YA',
    String folder = 'GENERAL',
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/image/upload');
    final request = http.MultipartRequest('POST', uri);

    request.fields['bucket'] = bucket;
    request.fields['folder'] = folder;

    request.files.add(await http.MultipartFile.fromPath('file', file.path));
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    final body = jsonDecode(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        _serverMessage(body, 'Error subiendo imagen [${response.statusCode}]'),
      );
    }
    if (body['isSuccess'] != true) {
      throw Exception(_serverMessage(body, 'Error al subir imagen'));
    }
    final data = body['data'];
    if (data is! Map<String, dynamic>) {
      throw Exception('Respuesta inválida del servidor');
    }
    return ImageUploadResponse.fromJson(data);
  }

  static String _serverMessage(dynamic body, String fallback) {
    if (body is Map) {
      final errors = body['errors'];
      if (errors is List && errors.isNotEmpty) {
        return errors.map((error) => error.toString()).join('\n');
      }
      final message = body['message']?.toString();
      if (message != null && message.isNotEmpty) return message;
    }
    return fallback;
  }
}
