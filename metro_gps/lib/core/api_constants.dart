/// URL base del backend (sin barra final).
///
/// Puedes sobreescribirla en tiempo de compilación:
/// `flutter run --dart-define=API_BASE_URL=https://tu-servidor.com`
abstract final class ApiConstants {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );
}
