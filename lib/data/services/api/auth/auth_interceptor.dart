import 'dart:async';

import 'package:dio/dio.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor(
    this._dio,
    this._readAccessToken,
    this._refreshAccessToken,
    this._onSessionExpired,
  );

  static const skipAuthenticationKey = 'skipAuthentication';
  static const retriedAfterRefreshKey = 'retriedAfterRefresh';

  final Dio _dio;
  final Future<String?> Function() _readAccessToken;
  final Future<String?> Function() _refreshAccessToken;
  final Future<void> Function() _onSessionExpired;

  Completer<String?>? _refreshCompleter;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.extra[skipAuthenticationKey] != true) {
      final token = await _readAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final request = err.requestOptions;
    final canRefresh =
        err.response?.statusCode == 401 &&
        request.extra[skipAuthenticationKey] != true &&
        request.extra[retriedAfterRefreshKey] != true;

    if (!canRefresh) {
      handler.next(err);
      return;
    }

    final token = await _refreshOnce();
    if (token == null || token.isEmpty) {
      await _onSessionExpired();
      handler.next(err);
      return;
    }

    request.extra[retriedAfterRefreshKey] = true;
    request.headers['Authorization'] = 'Bearer $token';
    try {
      final response = await _dio.fetch<dynamic>(request);
      handler.resolve(response);
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }

  Future<String?> _refreshOnce() {
    final activeRefresh = _refreshCompleter;
    if (activeRefresh != null) return activeRefresh.future;

    final completer = Completer<String?>();
    _refreshCompleter = completer;
    () async {
      try {
        completer.complete(await _refreshAccessToken());
      } on Object {
        completer.complete(null);
      } finally {
        _refreshCompleter = null;
      }
    }();
    return completer.future;
  }
}
