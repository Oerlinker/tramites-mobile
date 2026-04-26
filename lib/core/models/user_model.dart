class UserModel {
  const UserModel({
    required this.id,
    required this.username,
    required this.rol,
    this.nombre,
    this.email,
  });

  final String id;
  final String username;
  final String rol;
  final String? nombre;
  final String? email;

  String get nombreMostrado {
    if (nombre != null && nombre!.trim().isNotEmpty) {
      return nombre!.trim();
    }
    return username;
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: (json['id'] ?? '').toString(),
      username: (json['username'] ?? json['usuario'] ?? '').toString(),
      rol: (json['rol'] ?? '').toString(),
      nombre: json['nombre']?.toString(),
      email: json['email']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'rol': rol,
      'nombre': nombre,
      'email': email,
    };
  }
}
