/// URL base del backend (sin barra final).
///
/// Puedes sobreescribirla en tiempo de compilación:
/// `flutter run --dart-define=API_BASE_URL=https://tu-servidor.com`
abstract final class ApiConstants {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    // Cambia localhost por la IP real de tu PC
    defaultValue: 'http://192.168.56.1:8080', 
  );
}
