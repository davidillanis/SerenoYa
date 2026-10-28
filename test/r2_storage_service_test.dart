import 'dart:typed_data';

import 'package:aws_common/aws_common.dart';
import 'package:aws_signature_v4/aws_signature_v4.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sereno_ya/config/r2_config.dart';
import 'package:sereno_ya/data/services/api/file/image_api_service.dart';

void main() {
  const config = R2Config(
    accountId: 'account-id',
    accessKeyId: 'access-key',
    secretAccessKey: 'secret-key',
    bucket: 'sereno-ya',
    publicBaseUrl: 'https://pub.example.r2.dev',
  );

  test('firma la subida y devuelve la URL pública compatible', () async {
    AWSSignedRequest? capturedRequest;
    final service = StorageService(
      config: config,
      objectIdGenerator: () => 'evidence-id',
      sendRequest: (request) async {
        capturedRequest = request;
        return AWSHttpResponse(statusCode: 200);
      },
    );

    final result = await service.uploadBytes(
      bytes: Uint8List.fromList([1, 2, 3]),
      filename: 'foto.png',
      contentType: 'image/png',
      folder: 'INCIDENTS',
    );

    expect(result.fileKey, 'general/image/evidence-id.png');
    expect(
      result.publicUrl,
      'https://pub.example.r2.dev/general/image/evidence-id.png',
    );
    expect(result.contentType, 'image/png');
    expect(result.sizeBytes, 3);
    expect(result.category, 'INCIDENTS');
    expect(
      capturedRequest?.uri.toString(),
      'https://account-id.r2.cloudflarestorage.com/'
      'sereno-ya/general/image/evidence-id.png',
    );
    expect(capturedRequest?.headers[AWSHeaders.authorization], isNotEmpty);
    expect(capturedRequest?.headers[AWSHeaders.contentType], 'image/png');
  });

  test('convierte una respuesta 403 en un mensaje comprensible', () async {
    final service = StorageService(
      config: config,
      objectIdGenerator: () => 'evidence-id',
      sendRequest: (_) async => AWSHttpResponse(statusCode: 403),
    );

    expect(
      () => service.uploadBytes(
        bytes: Uint8List.fromList([1]),
        filename: 'foto.jpg',
      ),
      throwsA(
        isA<R2UploadException>().having(
          (error) => error.message,
          'message',
          contains('credenciales'),
        ),
      ),
    );
  });

  test('rechaza una imagen vacía antes de crear la solicitud', () async {
    final service = StorageService(
      config: config,
      objectIdGenerator: () => 'evidence-id',
      sendRequest: (_) async => AWSHttpResponse(statusCode: 200),
    );

    expect(
      () => service.uploadBytes(bytes: Uint8List(0), filename: 'foto.jpg'),
      throwsA(isA<R2UploadException>()),
    );
  });
}
