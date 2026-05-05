import 'package:metro_gps/core/network/api_client.dart';
import 'package:metro_gps/features/auth/domain/models/user_model.dart';

class AuthService {
  AuthService(this._apiClient);

  final ApiClient _apiClient;

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final data = await _apiClient.post(
      '/auth/login',
      body: {
        'email': email,
        'password': password,
      },
    );
    return UserModel.fromJson(data);
  }

  Future<UserModel> register({
    required String nombre,
    required String apellidos,
    required String rol,
    required String email,
    required String password,
  }) async {
    final data = await _apiClient.post(
      '/auth/register',
      body: {
        'nombre': nombre,
        'apellidos': apellidos,
        'rol': rol,
        'email': email,
        'password': password,
      },
    );

    if (data.containsKey('id_usuario')) {
      return UserModel.fromJson(data);
    }

    // Fallback comun: endpoints que responden solo "ok" en register.
    return login(email: email, password: password);
  }
}
