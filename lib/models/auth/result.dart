import 'package:sereno_ya/models/auth/auth_failure.dart';

class Result<T> {
  const Result._({this.data, this.failure});

  factory Result.success(T data) => Result._(data: data);
  factory Result.failure(AuthFailure failure) => Result._(failure: failure);

  final T? data;
  final AuthFailure? failure;

  bool get isSuccess => failure == null;
}
