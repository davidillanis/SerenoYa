class ApiResponseDto<T> {
  const ApiResponseDto({
    required this.isSuccess,
    this.message,
    this.data,
    this.errors = const [],
  });

  factory ApiResponseDto.fromJson(
    Map<String, dynamic> json,
    T Function(Object? value) decodeData,
  ) {
    final rawErrors = json['errors'];
    return ApiResponseDto<T>(
      isSuccess: json['isSuccess'] == true,
      message: json['message']?.toString(),
      data: json['data'] == null ? null : decodeData(json['data']),
      errors: rawErrors is List
          ? rawErrors.map((error) => error.toString()).toList(growable: false)
          : const [],
    );
  }

  final bool isSuccess;
  final String? message;
  final T? data;
  final List<String> errors;

  String get errorMessage => errors.isNotEmpty
      ? errors.first
      : message ?? 'La operación no pudo completarse.';
}
