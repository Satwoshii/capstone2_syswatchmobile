import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureSession {
  SecureSession._();
  static final SecureSession instance = SecureSession._();

  static const String _tokenKey = 'syswatch_mobile_api_token';

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  Future<String?> readToken() => _storage.read(key: _tokenKey);

  Future<void> saveToken(String token) =>
      _storage.write(key: _tokenKey, value: token);

  Future<void> clear() => _storage.delete(key: _tokenKey);
}
