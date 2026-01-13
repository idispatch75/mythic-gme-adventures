import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecureStorage extends GetxService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  final SharedPreferencesWithCache _sharedPreferences;

  SecureStorage(this._sharedPreferences);

  Future<void> write(String key, String value) {
    if (kIsWeb) {
      return _sharedPreferences.setString(key, value);
    } else {
      return _secureStorage.write(key: key, value: value);
    }
  }

  Future<String?> read(String key) async {
    if (kIsWeb) {
      return _sharedPreferences.getString(key);
    } else {
      return _secureStorage.read(key: key);
    }
  }

  Future<void> delete(String key) async {
    if (kIsWeb) {
      return _sharedPreferences.remove(key);
    } else {
      if (await _secureStorage.containsKey(key: key)) {
        return _secureStorage.delete(key: key);
      }
    }
  }
}
