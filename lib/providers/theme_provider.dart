import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/storage_keys.dart';

// Gestisce lo stato del tema (chiaro/scuro) dell'applicazione.
// Estende ChangeNotifier per notificare i widget quando il tema cambia.
class ThemeProvider with ChangeNotifier {
  // Utilizza una memoria sicura per salvare la preferenza del tema in modo persistente.
  final _storage = const FlutterSecureStorage();
  ThemeMode _themeMode = ThemeMode.system;

  ThemeProvider() {
    _loadThemeFromStorage();
  }

  ThemeMode get themeMode => _themeMode;

  // Carica l'impostazione del tema salvata precedentemente sul dispositivo.
  Future<void> _loadThemeFromStorage() async {
    try {
      final savedMode = await _storage.read(key: StorageKeys.themeMode);
      // Utilizza il pattern matching di Dart 3 per mappare la stringa al tipo ThemeMode.
      _themeMode = switch (savedMode) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
      // Avvisa i widget in ascolto di ricostruirsi con il nuovo tema.
      notifyListeners();
    } catch (_) {
      _themeMode = ThemeMode.system;
      notifyListeners();
    }
  }

  // Alterna tra tema chiaro e scuro e salva la scelta in memoria.
  Future<void> toggleTheme() async {
    if (_themeMode == ThemeMode.system) {
      // Se il tema è impostato su 'sistema', rileva la luminosità attuale del dispositivo.
      final brightness = PlatformDispatcher.instance.platformBrightness;
      _themeMode = brightness == Brightness.dark ? ThemeMode.light : ThemeMode.dark;
    } else {
      _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    }

    notifyListeners();

    // Salva permanentemente la nuova preferenza.
    await _storage.write(
      key: StorageKeys.themeMode,
      value: _themeMode == ThemeMode.light ? 'light' : 'dark',
    );
  }
}
