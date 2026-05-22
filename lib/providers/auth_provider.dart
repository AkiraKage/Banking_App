import 'package:flutter/material.dart';
import '../services/storage_service.dart';

class AuthProvider with ChangeNotifier {
  bool _isAuthenticated = false;
  String _userName = 'Ospite';

  bool get isAuthenticated => _isAuthenticated;

  String get userName => _userName;

  Future<bool> login(String username, String password) async {
    // await Future.delayed(const Duration(milliseconds: 800));
    if (username.isNotEmpty) {
      _isAuthenticated = true;
      _userName =
          username[0].toUpperCase() + username.substring(1).toLowerCase();
      notifyListeners();
      return true;
    }
    return false;
  }

  void loginWithPin(String savedName) {
    _isAuthenticated = true;
    _userName = savedName;
    notifyListeners();
  }

  Future<void> logout() async {
    await StorageService.deletePin();
    await StorageService.deleteBiometrics();

    _isAuthenticated = false;
    _userName = 'Ospite';
    notifyListeners();
  }
}
