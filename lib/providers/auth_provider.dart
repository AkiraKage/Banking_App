import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

// Gestisce lo stato dell'autenticazione e i dati dell'utente loggato.
class AuthProvider with ChangeNotifier {
  bool _isAuthenticated = false;
  String _userName = 'Ospite';
  String _userIban = '';
  String? _lastError;

  bool get isAuthenticated => _isAuthenticated;
  String get userName => _userName;
  String get userIban => _userIban;
  String? get lastError => _lastError;

  // Esegue il login tramite API e salva i token di sessione in modo sicuro.
  Future<bool> login(String username, String password) async {
    try {
      _lastError = null;
      // Richiesta al servizio API.
      final data = await ApiService.login(
        username: username.trim(),
        password: password,
      );

      // Estrae token e informazioni utente dalla risposta JSON.
      final token = data['token'].toString();
      final refreshToken = data['refresh_token'].toString();
      final user = Map<String, dynamic>.from(data['user']);
      final name = (user['name'] ?? username).toString();

      // Salva i dati localmente per le sessioni future.
      await StorageService.saveAuthToken(token);
      await StorageService.saveRefreshToken(refreshToken);
      await StorageService.saveDisplayName(name);
      await StorageService.saveUserId((user['id'] ?? '').toString());

      // Recupera l'IBAN reale dell'utente chiamando l'endpoint dedicato.
      try {
        final me = await ApiService.getMe();
        await StorageService.saveIban(me.iban);
        _userIban = me.iban;
      } catch (_) {
        _userIban = '';
      }

      _isAuthenticated = true;
      _userName = name;
      // Notifica l'app che l'utente è ora autenticato.
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

  // Permette il login rapido se esiste già un PIN o un'identità salvata.
  Future<void> loginWithPin(String savedName) async {
    _isAuthenticated = true;
    _userName = savedName;
    _lastError = null;
    _userIban = (await StorageService.getIban()) ?? '';
    notifyListeners();
  }

  // Rimuove tutti i dati della sessione e resetta lo stato dell'app.
  Future<void> logout() async {
    try {
      await ApiService.logout();
    } catch (_) {}

    // Pulisce la memoria sicura del dispositivo.
    await StorageService.deletePin();
    await StorageService.deleteBiometrics();
    await StorageService.clearSession();

    _isAuthenticated = false;
    _userName = 'Ospite';
    _userIban = '';
    _lastError = null;
    notifyListeners();
  }
}