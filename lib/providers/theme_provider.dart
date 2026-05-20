import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ThemeProvider with ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  final _storage = const FlutterSecureStorage();
  
  // Di default impostiamo su system per rilevare la modalità globale all'avvio
  ThemeMode _themeMode = ThemeMode.system;

  ThemeProvider() {
    _loadThemeFromStorage();
  }

  ThemeMode get themeMode => _themeMode;

  /// Carica la preferenza salvata dall'utente, se presente
  Future<void> _loadThemeFromStorage() async {
    try {
      final savedMode = await _storage.read(key: _themeKey);
      if (savedMode == 'light') {
        _themeMode = ThemeMode.light;
      } else if (savedMode == 'dark') {
        _themeMode = ThemeMode.dark;
      } else {
        _themeMode = ThemeMode.system;
      }
      notifyListeners();
    } catch (e) {
      // In caso di errore, rimaniamo su ThemeMode.system
      _themeMode = ThemeMode.system;
      notifyListeners();
    }
  }

  /// Cambia il tema e salva la preferenza in modo persistente
  Future<void> toggleTheme() async {
    if (_themeMode == ThemeMode.system) {
      // Se è impostato su sistema, rileviamo la luminosità attuale per invertirla
      final brightness = PlatformDispatcher.instance.platformBrightness;
      _themeMode = brightness == Brightness.dark ? ThemeMode.light : ThemeMode.dark;
    } else {
      _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    }

    // Notifichiamo subito per un'UI reattiva
    notifyListeners();

    // Salviamo la scelta in modo asincrono
    await _storage.write(
      key: _themeKey,
      value: _themeMode == ThemeMode.light ? 'light' : 'dark',
    );
  }
}
