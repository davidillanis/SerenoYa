import 'package:dio/dio.dart';
import 'package:sereno_ya/config/api_config.dart';

class ApiClient {
  ApiClient()
    : dio = Dio(
        BaseOptions(
          baseUrl: ApiConfig.baseUrl,
          connectTimeout: ApiConfig.connectTimeout,
          receiveTimeout: ApiConfig.receiveTimeout,
          headers: const {'Content-Type': 'application/json'},
        ),
      );

  final Dio dio;
}
