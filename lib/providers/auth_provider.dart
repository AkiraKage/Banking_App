import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class AuthProvider with ChangeNotifier {
  bool _isAuthenticated = false;
  String _userName = 'Ospite';
  String? _lastError;

  bool get isAuthenticated => _isAuthenticated;

  String get userName => _userName;

  String? get lastError => _lastError;

  Future<bool> login(String username, String password) async {
    try {
      _lastError = null;
      final data = await ApiService.login(
        username: username.trim(),
        password: password,
      );

      final token = data['token'].toString();
      final refreshToken = data['refresh_token'].toString();
      final user = Map<String, dynamic>.from(data['user']);
      final name = (user['name'] ?? username).toString();

      await StorageService.saveAuthToken(token);
      await StorageService.saveRefreshToken(refreshToken);
      await StorageService.saveDisplayName(name);
      await StorageService.saveUserId((user['id'] ?? '').toString());

      _isAuthenticated = true;
      _userName = name;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _lastError = e.message;
      return false;
    } catch (_) {
      _lastError = 'Errore imprevisto durante il login.';
      return false;
    }
  }

  void loginWithPin(String savedName) {
    _isAuthenticated = true;
    _userName = savedName;
    _lastError = null;
    notifyListeners();
  }

  Future<void> logout() async {
    try {
      await ApiService.logout();
    } catch (_) {}

    await StorageService.deletePin();
    await StorageService.deleteBiometrics();
    await StorageService.clearSession();

    _isAuthenticated = false;
    _userName = 'Ospite';
    _lastError = null;
    notifyListeners();
  }
}
