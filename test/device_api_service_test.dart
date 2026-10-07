import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sereno_ya/data/models/divice_model.dart';
import 'package:sereno_ya/data/models/notification_model.dart';
import 'package:sereno_ya/data/services/api/device_api_service.dart';
import 'package:sereno_ya/models/auth/auth_failure.dart';

void main() {
  test('envía los cuatro contratos y decodifica sus respuestas', () async {
    final requests = <RequestOptions>[];
    final service = DeviceApiService(
      _dio((options, handler) {
        requests.add(options);
        final Object data = switch (options.path) {
          '/device/notification/send' => 'message-1',
          '/device/notification/send-any' => {
            'successCount': 1,
            'failureCount': 1,
            'responses': [
              {'successful': true, 'messageId': 'message-2'},
              {
                'successful': false,
                'errorCode': 'UNREGISTERED',
                'errorMessage': 'Dispositivo no registrado',
              },
            ],
          },
          '/device/create' => 'device-1',
          '/device/update/device-1' => 1,
          _ => throw StateError('Ruta inesperada'),
        };
        handler.resolve(
          Response<dynamic>(
            requestOptions: options,
            statusCode: options.path == '/device/create' ? 201 : 200,
            data: {
              'isSuccess': true,
              'message': 'OK',
              'errors': null,
              'data': data,
            },
          ),
        );
      }),
    );

    final single = await service.sendNotification(
      const NotificationRequest(
        token: 'test-token',
        title: 'Aviso',
        body: 'Detalle',
      ),
    );
    final multiple = await service.sendNotificationAll(
      const NotificationAnyRequest(tokens: ['test-a', 'test-b']),
    );
    const device = DeviceRequest(
      deviceId: 'hardware-id',
      deviceModel: 'Modelo',
      fcmToken: 'test-token',
      osType: 'ANDROID',
    );
    final created = await service.createDevice(request: device);
    final updated = await service.updateDevice(
      deviceId: 'device-1',
      request: device,
    );

    expect(requests.map((r) => r.method), ['POST', 'POST', 'POST', 'PUT']);
    expect(requests[0].data, {
      'token': 'test-token',
      'title': 'Aviso',
      'body': 'Detalle',
    });
    expect(requests[1].data, {
      'tokens': ['test-a', 'test-b'],
      'title': null,
      'body': null,
    });
    for (final request in requests.skip(2)) {
      expect(request.data, {
        'deviceId': 'hardware-id',
        'deviceModel': 'Modelo',
        'fcmToken': 'test-token',
        'osType': 'ANDROID',
      });
    }
    expect(single.data, 'message-1');
    expect(created.data, 'device-1');
    expect(updated.data, 1);
    expect(multiple.data?.successCount, 1);
    expect(multiple.data?.failureCount, 1);
    expect(multiple.data?.responses.first.successful, isTrue);
    expect(multiple.data?.responses.first.messageId, 'message-2');
    expect(multiple.data?.responses.first.errorCode, isNull);
    expect(multiple.data?.responses.last.successful, isFalse);
    expect(multiple.data?.responses.last.errorCode, 'UNREGISTERED');
    expect(
      multiple.data?.responses.last.errorMessage,
      'Dispositivo no registrado',
    );
    expect(multiple.data?.responses.last.messageId, isNull);
  });

  test('conserva los errores de negocio y data nulo', () async {
    final service = DeviceApiService(
      _dio((options, handler) {
        handler.resolve(
          Response<dynamic>(
            requestOptions: options,
            data: {
              'isSuccess': false,
              'message': 'VALIDATION_ERROR',
              'errors': ['Token is required'],
              'data': null,
            },
          ),
        );
      }),
    );
    final response = await service.sendNotification(
      const NotificationRequest(token: ''),
    );
    expect(response.isSuccess, isFalse);
    expect(response.message, 'VALIDATION_ERROR');
    expect(response.errors, ['Token is required']);
    expect(response.data, isNull);
  });

  for (final status in [400, 401, 403, 422, 500]) {
    test('maneja error HTTP $status', () async {
      final service = DeviceApiService(
        _dio((options, handler) {
          handler.reject(
            DioException(
              requestOptions: options,
              type: DioExceptionType.badResponse,
              response: Response<dynamic>(
                requestOptions: options,
                statusCode: status,
                data: {
                  'errors': ['Datos inválidos'],
                },
              ),
            ),
          );
        }),
      );
      final expected = switch (status) {
        400 || 422 => AuthFailureCode.validation,
        401 || 403 => AuthFailureCode.unauthorized,
        _ => AuthFailureCode.server,
      };
      await expectLater(
        service.sendNotification(const NotificationRequest(token: 'test')),
        throwsA(isA<AuthFailure>().having((e) => e.code, 'code', expected)),
      );
    });
  }

  test('maneja fallos de conexión', () async {
    final service = DeviceApiService(
      _dio((options, handler) {
        handler.reject(
          DioException(
            requestOptions: options,
            type: DioExceptionType.connectionTimeout,
          ),
        );
      }),
    );
    await expectLater(
      service.sendNotification(const NotificationRequest(token: 'test')),
      throwsA(
        isA<AuthFailure>().having(
          (e) => e.code,
          'code',
          AuthFailureCode.network,
        ),
      ),
    );
  });

  for (final body in <Object>[
    'invalid',
    {'isSuccess': true, 'data': 'not-an-int'},
  ]) {
    test('rechaza respuesta inválida $body', () async {
      final service = DeviceApiService(
        _dio((options, handler) {
          handler.resolve(
            Response<dynamic>(requestOptions: options, data: body),
          );
        }),
      );
      await expectLater(
        service.updateDevice(
          deviceId: 'device-1',
          request: const DeviceRequest(),
        ),
        throwsA(
          isA<AuthFailure>().having(
            (e) => e.code,
            'code',
            AuthFailureCode.server,
          ),
        ),
      );
    });
  }
}

Dio _dio(void Function(RequestOptions, RequestInterceptorHandler) onRequest) {
  return Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'))
    ..interceptors.add(InterceptorsWrapper(onRequest: onRequest));
}
