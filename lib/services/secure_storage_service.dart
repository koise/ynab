import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure PIN storage using flutter_secure_storage.
/// Replaces KeychainService.swift.
class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _pinKey = 'ynab_pin_hash';

  // ─── PIN ──────────────────────────────────

  static Future<void> savePIN(String pinHash) async {
    await _storage.write(key: _pinKey, value: pinHash);
  }

  static Future<String?> loadPIN() async {
    return await _storage.read(key: _pinKey);
  }

  static Future<void> deletePIN() async {
    await _storage.delete(key: _pinKey);
  }

  static Future<bool> hasPIN() async {
    final pin = await _storage.read(key: _pinKey);
    return pin != null && pin.isNotEmpty;
  }
}
