//Request
class NotificationRequest {
  const NotificationRequest({required this.token, this.title, this.body});

  final String token;
  final String? title;
  final String? body;

  Map<String, dynamic> toJson() => {
    'token': token,
    'title': title,
    'body': body,
  };
}

class NotificationAnyRequest {
  const NotificationAnyRequest({required this.tokens, this.title, this.body});

  final List<String> tokens;
  final String? title;
  final String? body;

  Map<String, dynamic> toJson() => {
    'tokens': tokens,
    'title': title,
    'body': body,
  };
}
