import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/storage_keys.dart';

class StorageService {
  static const _storage = FlutterSecureStorage();

  static Future<void> savePin(String pin) async =>
      await _storage.write(key: StorageKeys.userPin, value: pin);

  static Future<String?> getPin() async =>
      await _storage.read(key: StorageKeys.userPin);

  static Future<void> deletePin() async =>
      await _storage.delete(key: StorageKeys.userPin);

  static Future<void> setBiometrics(bool value) async => await _storage.write(
    key: StorageKeys.useBiometrics,
    value: value.toString(),
  );

  static Future<bool> getBiometrics() async {
    final val = await _storage.read(key: StorageKeys.useBiometrics);
    return val == 'true';
  }

  static Future<void> deleteBiometrics() async =>
      await _storage.delete(key: StorageKeys.useBiometrics);
}
