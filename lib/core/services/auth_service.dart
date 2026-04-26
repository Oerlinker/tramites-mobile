import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:tramites_mobile/core/models/user_model.dart';
import 'package:tramites_mobile/core/services/api_service.dart';

class AuthService {
  AuthService({
    required ApiService apiService,
    required FlutterSecureStorage storage,
  }) : _apiService = apiService,
       _storage = storage;

  final ApiService _apiService;
  final FlutterSecureStorage _storage;

  static const String tokenKey = 'jwt_token';
  static const String roleKey = 'user_role';

  Future<LoginResult> login({
    required String username,
    required String password,
  }) async {
    final response = await _apiService.dio.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'username': username, 'password': password},
    );

    final data = response.data;
    if (data == null) throw const FormatException('Respuesta vacía.');

    final token = (data['token'] ?? '').toString();
    final roles = data['roles'] as List<dynamic>? ?? [];
    final rol = roles.isNotEmpty
        ? roles[0].toString().replaceAll('ROLE_', '')
        : '';

    if (token.isEmpty || rol.isEmpty) {
      throw const FormatException('Formato de respuesta inválido.');
    }

    // Construir usuario desde la misma respuesta (no hay objeto 'usuario')
    final usuarioJson = {
      'id': data['id'] ?? '',
      'username': data['username'] ?? '',
      'email': data['email'] ?? '',
      'rol': rol,
    };

    await _storage.write(key: tokenKey, value: token);
    await _storage.write(key: roleKey, value: rol);

    return LoginResult(
      token: token,
      rol: rol,
      usuario: UserModel.fromJson(usuarioJson),
    );
  }

  Future<UserModel> getMe() async {
    final response = await _apiService.dio.get<Map<String, dynamic>>(
      '/usuarios/me',
    );
    final data = response.data;
    if (data == null) {
      throw const FormatException('No se recibieron datos del usuario.');
    }

    final role = await getStoredRole();
    final userJson = Map<String, dynamic>.from(data);
    userJson['rol'] = role ?? userJson['rol'];

    return UserModel.fromJson(userJson);
  }

  Future<String?> getStoredToken() => _storage.read(key: tokenKey);

  Future<String?> getStoredRole() => _storage.read(key: roleKey);

  Future<void> logout() async {
    await _storage.delete(key: tokenKey);
    await _storage.delete(key: roleKey);
  }

  static String mapError(Object error) {
    if (error is DioException) {
      final serverMessage = error.response?.data;
      if (serverMessage is Map<String, dynamic>) {
        final message = serverMessage['message'] ?? serverMessage['error'];
        if (message != null) {
          return message.toString();
        }
      }
      if (error.response?.statusCode == 401) {
        return 'Credenciales invalidas.';
      }
      return 'Error de conexion con el servidor.';
    }
    if (error is FormatException) {
      return error.message;
    }
    return 'Ocurrio un error inesperado.';
  }
}

class LoginResult {
  const LoginResult({
    required this.token,
    required this.rol,
    required this.usuario,
  });

  final String token;
  final String rol;
  final UserModel usuario;
}
