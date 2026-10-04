// request
class DeviceRequest {
  const DeviceRequest({
    this.deviceId,
    this.deviceModel,
    this.fcmToken,
    this.osType,
  });

  final String? deviceId;
  final String? deviceModel;
  final String? fcmToken;

  /// Nombre exacto del valor de EOsType definido por el backend.
  final String? osType;

  Map<String, dynamic> toJson() => {
    'deviceId': deviceId,
    'deviceModel': deviceModel,
    'fcmToken': fcmToken,
    'osType': osType,
  };
}

//response
class NotificationAnyResponse {
  const NotificationAnyResponse({
    required this.successCount,
    required this.failureCount,
    required this.responses,
  });

  factory NotificationAnyResponse.fromJson(Object? value) {
    if (value is! Map ||
        value['successCount'] is! int ||
        value['failureCount'] is! int ||
        value['responses'] is! List) {
      throw const FormatException(
        'La API devolvió resultados de envío inválidos.',
      );
    }
    return NotificationAnyResponse(
      successCount: value['successCount'] as int,
      failureCount: value['failureCount'] as int,
      responses: (value['responses'] as List)
          .map(NotificationSendResult.fromJson)
          .toList(growable: false),
    );
  }

  final int successCount;
  final int failureCount;
  final List<NotificationSendResult> responses;
}

class NotificationSendResult {
  const NotificationSendResult({
    required this.successful,
    this.messageId,
    this.errorCode,
    this.errorMessage,
  });

  factory NotificationSendResult.fromJson(Object? value) {
    if (value is! Map ||
        value['successful'] is! bool ||
        (value['messageId'] != null && value['messageId'] is! String) ||
        (value['errorCode'] != null && value['errorCode'] is! String) ||
        (value['errorMessage'] != null && value['errorMessage'] is! String)) {
      throw const FormatException(
        'La API devolvió un resultado de envío inválido.',
      );
    }
    return NotificationSendResult(
      successful: value['successful'] as bool,
      messageId: value['messageId'] as String?,
      errorCode: value['errorCode'] as String?,
      errorMessage: value['errorMessage'] as String?,
    );
  }

  final bool successful;
  final String? messageId;
  final String? errorCode;
  final String? errorMessage;
}
