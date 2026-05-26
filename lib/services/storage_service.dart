import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/storage_keys.dart';

class StorageService {
  static const _storage = FlutterSecureStorage();

  static Future<void> savePin(String pin) async =>
      _storage.write(key: StorageKeys.userPin, value: pin);

  static Future<String?> getPin() async =>
      _storage.read(key: StorageKeys.userPin);

  static Future<void> deletePin() async =>
      _storage.delete(key: StorageKeys.userPin);

  static Future<void> setBiometrics(bool value) async =>
      _storage.write(key: StorageKeys.useBiometrics, value: value.toString());

  static Future<bool> getBiometrics() async {
    final val = await _storage.read(key: StorageKeys.useBiometrics);
    return val == 'true';
  }

  static Future<void> deleteBiometrics() async =>
      _storage.delete(key: StorageKeys.useBiometrics);

  static Future<void> saveAuthToken(String token) async =>
      _storage.write(key: StorageKeys.authToken, value: token);

  static Future<String?> getAuthToken() async =>
      _storage.read(key: StorageKeys.authToken);

  static Future<void> deleteAuthToken() async =>
      _storage.delete(key: StorageKeys.authToken);

  static Future<void> saveRefreshToken(String token) async =>
      _storage.write(key: StorageKeys.refreshToken, value: token);

  static Future<String?> getRefreshToken() async =>
      _storage.read(key: StorageKeys.refreshToken);

  static Future<void> deleteRefreshToken() async =>
      _storage.delete(key: StorageKeys.refreshToken);

  static Future<void> saveDisplayName(String value) async =>
      _storage.write(key: StorageKeys.userDisplayName, value: value);

  static Future<String?> getDisplayName() async =>
      _storage.read(key: StorageKeys.userDisplayName);

  static Future<void> deleteDisplayName() async =>
      _storage.delete(key: StorageKeys.userDisplayName);

  static Future<void> saveUserId(String value) async =>
      _storage.write(key: StorageKeys.userId, value: value);

  static Future<String?> getUserId() async =>
      _storage.read(key: StorageKeys.userId);

  static Future<void> deleteUserId() async =>
      _storage.delete(key: StorageKeys.userId);

  static Future<void> clearSession() async {
    await deleteAuthToken();
    await deleteRefreshToken();
    await deleteDisplayName();
    await deleteUserId();
  }
}
