import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sereno_ya/data/services/api/auth/auth_api_service.dart';
import 'package:sereno_ya/models/auth/auth_failure.dart';

void main() {
  group('AuthApiService error messages', () {
    test('shows a friendly message when the user does not exist', () async {
      final service = _serviceThatRejects(
        statusCode: 401,
        data: {
          'isSuccess': false,
          'message': 'Resource not found',
          'errors': [
            '[404] during [GET] to [http://localhost:8081/api/v1/users/'
                'by-email/citizen%40example.com]: User not found with email',
          ],
          'data': null,
        },
      );

      await expectLater(
        service.login(email: 'citizen@example.com', password: 'secret'),
        throwsA(
          isA<AuthFailure>()
              .having(
                (failure) => failure.code,
                'code',
                AuthFailureCode.invalidCredentials,
              )
              .having(
                (failure) => failure.message,
                'message',
                'El usuario no existe.',
              ),
        ),
      );
    });

    test(
      'does not expose backend details for other unauthorized logins',
      () async {
        final service = _serviceThatRejects(
          statusCode: 401,
          data: {
            'message': 'Authentication failed',
            'errors': ['Bad credentials in AuthenticationProvider'],
          },
        );

        await expectLater(
          service.login(email: 'citizen@example.com', password: 'wrong'),
          throwsA(
            isA<AuthFailure>().having(
              (failure) => failure.message,
              'message',
              'El correo o la contraseña son incorrectos.',
            ),
          ),
        );
      },
    );
  });
}

AuthApiService _serviceThatRejects({
  required int statusCode,
  required Object? data,
}) {
  final dio = Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        handler.reject(
          DioException(
            requestOptions: options,
            response: Response<dynamic>(
              requestOptions: options,
              statusCode: statusCode,
              data: data,
            ),
            type: DioExceptionType.badResponse,
          ),
        );
      },
    ),
  );
  return AuthApiService(dio);
}
