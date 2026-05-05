class UserModel {
  const UserModel({
    required this.idUsuario,
    required this.nombre,
    required this.apellidos,
    required this.rol,
    required this.email,
    this.password,
  });

  final String idUsuario;
  final String nombre;
  final String apellidos;
  final String rol;
  final String email;
  final String? password;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      idUsuario: json['id_usuario']?.toString() ?? '',
      nombre: json['nombre']?.toString() ?? '',
      apellidos: json['apellidos']?.toString() ?? '',
      rol: json['rol']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      password: json['password']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_usuario': idUsuario,
      'nombre': nombre,
      'apellidos': apellidos,
      'rol': rol,
      'email': email,
      if (password != null) 'password': password,
    };
  }
}
