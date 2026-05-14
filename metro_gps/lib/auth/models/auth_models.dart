class RegistroInput {
  const RegistroInput({
    required this.nombreCompleto,
    required this.rol,
    required this.email,
    required this.password,
  });

  final String nombreCompleto;
  final String rol;
  final String email;
  final String password;

  Map<String, dynamic> toJson() => {
        'nombre_completo': nombreCompleto,
        'rol': rol,
        'email': email,
        'password': password,
      };
}

class LoginInput {
  const LoginInput({
    required this.email,
    required this.password,
  });

  final String email;
  final String password;

  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
      };
}
