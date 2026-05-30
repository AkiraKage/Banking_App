// Classe astratta che centralizza tutte le chiavi utilizzate per il salvataggio dei dati sul dispositivo.
// L'uso di costanti evita errori di battitura e facilita la manutenzione della memoria locale.
abstract final class StorageKeys {
  // Impostazioni generali dell'app.
  static const String themeMode = 'theme_mode';
  static const String userPin = 'user_pin';
  static const String useBiometrics = 'use_biometrics';

  // Dati relativi alla sessione di autenticazione e al profilo utente.
  static const String authToken = 'auth_token';
  static const String refreshToken = 'refresh_token';
  static const String userDisplayName = 'user_display_name';
  static const String userId = 'user_id';
  static const String userIban = 'user_iban';
}
