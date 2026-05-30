import 'package:local_auth/local_auth.dart';

// Gestisce l'interfaccia con i sensori biometrici del dispositivo (impronta, Face ID, ecc.).
// Utilizza il pacchetto local_auth per astrarre le API native di Android e iOS.
class BiometricService {
  static final _localAuth = LocalAuthentication();

  // Verifica se l'hardware del dispositivo supporta l'autenticazione biometrica.
  static Future<bool> canCheckBiometrics() async {
    final canCheck = await _localAuth.canCheckBiometrics;
    final isSupported = await _localAuth.isDeviceSupported();
    return canCheck || isSupported;
  }

  // Richiede all'utente l'autenticazione tramite biometria.
  static Future<bool> authenticate(String reason) async {
    try {
      return await _localAuth.authenticate(
        localizedReason: reason,
        biometricOnly: true, // Impedisce il fallback al PIN di sistema per questa chiamata.
      );
    } catch (_) {
      return false;
    }
  }
}
