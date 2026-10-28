class R2Config {
  const R2Config({
    required this.accountId,
    required this.accessKeyId,
    required this.secretAccessKey,
    required this.bucket,
    required this.publicBaseUrl,
  });

  factory R2Config.fromEnvironment() {
    return const R2Config(
      accountId: String.fromEnvironment('CLOUDFLARE_R2_ACCOUNT_ID'),
      accessKeyId: String.fromEnvironment('CLOUDFLARE_R2_ACCESS_KEY_ID'),
      secretAccessKey: String.fromEnvironment(
        'CLOUDFLARE_R2_SECRET_ACCESS_KEY',
      ),
      bucket: String.fromEnvironment('CLOUDFLARE_R2_BUCKET'),
      publicBaseUrl: String.fromEnvironment('CLOUDFLARE_R2_PUBLIC_BASE_URL'),
    );
  }

  static const region = 'auto';

  final String accountId;
  final String accessKeyId;
  final String secretAccessKey;
  final String bucket;
  final String publicBaseUrl;

  void validate() {
    final missing = <String>[
      if (accountId.trim().isEmpty) 'CLOUDFLARE_R2_ACCOUNT_ID',
      if (accessKeyId.trim().isEmpty) 'CLOUDFLARE_R2_ACCESS_KEY_ID',
      if (secretAccessKey.trim().isEmpty) 'CLOUDFLARE_R2_SECRET_ACCESS_KEY',
      if (bucket.trim().isEmpty) 'CLOUDFLARE_R2_BUCKET',
      if (publicBaseUrl.trim().isEmpty) 'CLOUDFLARE_R2_PUBLIC_BASE_URL',
    ];
    if (missing.isNotEmpty) {
      throw StateError(
        'Configuración de Cloudflare R2 incompleta: ${missing.join(', ')}',
      );
    }

    final publicUri = Uri.tryParse(publicBaseUrl.trim());
    if (publicUri == null ||
        publicUri.scheme != 'https' ||
        publicUri.host.isEmpty) {
      throw StateError('CLOUDFLARE_R2_PUBLIC_BASE_URL debe ser una URL HTTPS');
    }
  }

  Uri objectUri(String objectKey) {
    validate();
    final encodedPath = _encodeObjectPath('$bucket/$objectKey');
    return Uri.parse(
      'https://${accountId.trim()}.r2.cloudflarestorage.com/$encodedPath',
    );
  }

  Uri publicObjectUri(String objectKey) {
    validate();
    final baseUrl = publicBaseUrl.trim().replaceFirst(RegExp(r'/+$'), '');
    return Uri.parse('$baseUrl/${_encodeObjectPath(objectKey)}');
  }

  static String _encodeObjectPath(String value) {
    return value
        .replaceAll('\\', '/')
        .split('/')
        .where((segment) => segment.isNotEmpty)
        .map(Uri.encodeComponent)
        .join('/');
  }
}
