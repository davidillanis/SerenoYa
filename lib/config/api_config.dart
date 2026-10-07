abstract final class ApiConfig {
  // Carga .env al compilar con --dart-define-from-file=.env.
  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    //defaultValue: 'http://187.33.158.70:8082/api/v1',
    defaultValue: 'http://192.168.0.113:8080/api/v1',
  );

  // Client ID OAuth de tipo web, compartido con la audiencia del backend.
  static const googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue: '',
  );

  static const connectTimeout = Duration(seconds: 20);
  static const receiveTimeout = Duration(seconds: 30);
}
