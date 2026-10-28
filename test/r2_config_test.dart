import 'package:flutter_test/flutter_test.dart';
import 'package:sereno_ya/config/r2_config.dart';

void main() {
  const config = R2Config(
    accountId: 'account-id',
    accessKeyId: 'access-key',
    secretAccessKey: 'secret-key',
    bucket: 'sereno-ya',
    publicBaseUrl: 'https://pub.example.r2.dev/',
  );

  test('construye las URLs privada y pública del objeto', () {
    expect(
      config.objectUri('general/image/evidencia 1.png').toString(),
      'https://account-id.r2.cloudflarestorage.com/'
      'sereno-ya/general/image/evidencia%201.png',
    );
    expect(
      config.publicObjectUri('general/image/evidencia 1.png').toString(),
      'https://pub.example.r2.dev/general/image/evidencia%201.png',
    );
  });

  test('informa las variables faltantes sin exponer secretos', () {
    const incomplete = R2Config(
      accountId: '',
      accessKeyId: '',
      secretAccessKey: '',
      bucket: '',
      publicBaseUrl: '',
    );

    expect(
      incomplete.validate,
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          contains('CLOUDFLARE_R2_ACCOUNT_ID'),
        ),
      ),
    );
  });

  test('rechaza una URL pública que no use HTTPS', () {
    const invalid = R2Config(
      accountId: 'account-id',
      accessKeyId: 'access-key',
      secretAccessKey: 'secret-key',
      bucket: 'sereno-ya',
      publicBaseUrl: 'http://example.com',
    );

    expect(invalid.validate, throwsStateError);
  });
}
