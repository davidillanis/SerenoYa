import 'dart:async';
import 'dart:typed_data';

import 'package:aws_common/aws_common.dart';
import 'package:aws_signature_v4/aws_signature_v4.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sereno_ya/config/r2_config.dart';

typedef R2RequestSender = Future<AWSBaseHttpResponse> Function(
  AWSSignedRequest request,
);

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
}

class StorageService {
  StorageService({
    R2Config? config,
    R2RequestSender? sendRequest,
    String Function()? objectIdGenerator,
  }) : _config = config ?? R2Config.fromEnvironment(),
       _sendRequest = sendRequest ?? _send,
       _objectIdGenerator = objectIdGenerator ?? _newObjectId;

  static const _uploadTimeout = Duration(seconds: 45);
  static const _objectPrefix = 'general/image';

  final R2Config _config;
  final R2RequestSender _sendRequest;
  final String Function() _objectIdGenerator;

  Future<ImageUploadResponse> uploadBytes({
    required Uint8List bytes,
    required String filename,
    String? contentType,
    String bucket = 'SERENO_YA',
    String folder = 'GENERAL',
  }) async {
    _config.validate();
    if (bytes.isEmpty) {
      throw const R2UploadException('La imagen seleccionada está vacía');
    }

    final resolvedContentType = _resolveContentType(filename, contentType);
    final extension = _resolveExtension(filename, resolvedContentType);
    final objectKey = '$_objectPrefix/${_objectIdGenerator()}.$extension';
    final request = AWSHttpRequest.put(
      _config.objectUri(objectKey),
      body: bytes,
      headers: {AWSHeaders.contentType: resolvedContentType},
    );
    final signer = AWSSigV4Signer(
      credentialsProvider: AWSCredentialsProvider(
        AWSCredentials(_config.accessKeyId, _config.secretAccessKey),
      ),
    );
    final signedRequest = await signer.sign(
      request,
      credentialScope: AWSCredentialScope(
        region: R2Config.region,
        service: AWSService.s3,
      ),
      serviceConfiguration: S3ServiceConfiguration(),
    );

    late final AWSBaseHttpResponse response;
    try {
      response = await _sendRequest(signedRequest).timeout(_uploadTimeout);
    } on TimeoutException {
      throw const R2UploadException(
        'La subida tardó demasiado. Revisa tu conexión e intenta nuevamente.',
      );
    } catch (_) {
      throw const R2UploadException(
        'No se pudo conectar con el almacenamiento de evidencias.',
      );
    }

    await response.bodyBytes;
    await response.close();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw R2UploadException(_messageForStatus(response.statusCode));
    }

    return ImageUploadResponse(
      fileKey: objectKey,
      publicUrl: _config.publicObjectUri(objectKey).toString(),
      contentType: resolvedContentType,
      sizeBytes: bytes.length,
      category: folder.trim().isEmpty ? 'GENERAL' : folder.toUpperCase(),
    );
  }

  /// Sube un archivo elegido con `image_picker` en móvil y web.
  Future<ImageUploadResponse> uploadXFile({
    required XFile file,
    String bucket = 'SERENO_YA',
    String folder = 'GENERAL',
  }) async {
    final bytes = await file.readAsBytes();
    return uploadBytes(
      bytes: bytes,
      filename: file.name,
      contentType: file.mimeType,
      bucket: bucket,
      folder: folder,
    );
  }

  static Future<AWSBaseHttpResponse> _send(AWSSignedRequest request) async {
    return request.send().operation.value;
  }

  static String _newObjectId() => uuid(secure: true);

  static String _resolveContentType(String filename, String? contentType) {
    final normalized = contentType?.trim().toLowerCase();
    if (normalized != null && normalized.startsWith('image/')) {
      return normalized;
    }

    return switch (_filenameExtension(filename)) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      'gif' => 'image/gif',
      'heic' => 'image/heic',
      'heif' => 'image/heif',
      _ => 'image/jpeg',
    };
  }

  static String _resolveExtension(String filename, String contentType) {
    final extension = _filenameExtension(filename);
    const supportedExtensions = {
      'jpg',
      'jpeg',
      'png',
      'webp',
      'gif',
      'heic',
      'heif',
    };
    if (supportedExtensions.contains(extension)) {
      return extension == 'jpeg' ? 'jpg' : extension;
    }

    return switch (contentType) {
      'image/png' => 'png',
      'image/webp' => 'webp',
      'image/gif' => 'gif',
      'image/heic' => 'heic',
      'image/heif' => 'heif',
      _ => 'jpg',
    };
  }

  static String _filenameExtension(String filename) {
    final normalized = filename.trim().toLowerCase();
    final separator = normalized.lastIndexOf('.');
    if (separator < 0 || separator == normalized.length - 1) return '';
    return normalized.substring(separator + 1);
  }

  static String _messageForStatus(int statusCode) {
    return switch (statusCode) {
      401 || 403 =>
        'Cloudflare R2 rechazó las credenciales o los permisos del bucket.',
      413 => 'La imagen supera el tamaño permitido por Cloudflare R2.',
      _ => 'Cloudflare R2 rechazó la subida (código $statusCode).',
    };
  }
}

class R2UploadException implements Exception {
  const R2UploadException(this.message);

  final String message;

  @override
  String toString() => message;
}
