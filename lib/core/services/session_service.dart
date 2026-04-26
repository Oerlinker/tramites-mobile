import 'package:flutter/foundation.dart';
import 'package:tramites_mobile/core/models/user_model.dart';
import 'package:tramites_mobile/core/services/api_service.dart';
import 'package:tramites_mobile/core/services/auth_service.dart';
import 'package:tramites_mobile/core/services/fcm_service.dart';
import 'package:tramites_mobile/main.dart';

class SessionService extends ChangeNotifier {
  SessionService({
    required AuthService authService,
    required ApiService apiService,
  }) : _authService = authService,
       _apiService = apiService;

  final AuthService _authService;
  final ApiService _apiService;

  bool _isInitializing = true;
  bool _isAuthenticated = false;
  String? _role;
  UserModel? _user;

  bool get isInitializing => _isInitializing;
  bool get isAuthenticated => _isAuthenticated;
  String? get role => _role;
  UserModel? get user => _user;

  Future<void> init() async {
    _isInitializing = true;
    notifyListeners();

    final token = await _authService.getStoredToken();
    if (token == null || token.isEmpty) {
      _isAuthenticated = false;
      _role = null;
      _user = null;
      _isInitializing = false;
      notifyListeners();
      return;
    }

    try {
      _role = await _authService.getStoredRole();
      _user = await _authService.getMe();
      _role = _user?.rol.isNotEmpty == true ? _user?.rol : _role;
      _isAuthenticated = true;
      if (_role == 'CLIENTE') {
        FcmService.initialize(_apiService, navigatorKey);
      }
    } catch (_) {
      await _authService.logout();
      _isAuthenticated = false;
      _role = null;
      _user = null;
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  Future<void> login({
    required String username,
    required String password,
  }) async {
    final result = await _authService.login(
      username: username,
      password: password,
    );
    _isAuthenticated = true;
    _role = result.rol;
    _user = result.usuario;
    if (_role == 'CLIENTE') {
      FcmService.initialize(_apiService, navigatorKey);
    }
    notifyListeners();
  }

  Future<void> logout() async {
    await _authService.logout();
    _isAuthenticated = false;
    _role = null;
    _user = null;
    notifyListeners();
  }

  Future<void> handleUnauthorized() async {
    await logout();
  }
}
