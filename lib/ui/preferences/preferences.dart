import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalPreferencesService extends GetxService {
  static const _enableGoogleStorageKey = 'enableGoogleStorage';
  static const _enableLocalStorageKey = 'enableLocalStorage';
  static const _localDataDirectoryOverrideKey = 'localDataDirectoryOverride';
  static const _enableDarkModeKey = 'enableDarkMode';
  static const _enablePhysicalDiceModeKey = 'enablePhysicalDiceMode';
  static const _physicalDiceModeExplainedKey = 'physicalDiceModeExplained';

  static const keys = {
    _enableGoogleStorageKey,
    _enableLocalStorageKey,
    _localDataDirectoryOverrideKey,
    _enableDarkModeKey,
    _enablePhysicalDiceModeKey,
    _physicalDiceModeExplainedKey,
  };

  final SharedPreferencesWithCache _preferences;

  final RxBool enableGoogleStorage;
  final RxBool enableLocalStorage;
  final Rx<String?> localDataDirectoryOverride;
  final RxBool enableDarkMode;
  final RxBool enablePhysicalDiceMode;
  final RxBool physicalDiceModeExplained;

  LocalPreferencesService(this._preferences)
      : enableGoogleStorage =
            (_preferences.getBool(_enableGoogleStorageKey) ?? false).obs,
        enableLocalStorage =
            (_preferences.getBool(_enableLocalStorageKey) ?? true).obs,
        localDataDirectoryOverride =
            _preferences.getString(_localDataDirectoryOverrideKey).obs,
        enableDarkMode = (_preferences.getBool(_enableDarkModeKey) ??
                WidgetsBinding.instance.platformDispatcher.platformBrightness ==
                    Brightness.dark)
            .obs,
        enablePhysicalDiceMode =
            (_preferences.getBool(_enablePhysicalDiceModeKey) ?? false).obs,
        physicalDiceModeExplained =
            (_preferences.getBool(_physicalDiceModeExplainedKey) ?? false).obs;

  @override
  void onInit() {
    super.onInit();

    enableGoogleStorage.listen((value) {
      _preferences.setBool(_enableGoogleStorageKey, value);
    });

    enableLocalStorage.listen((value) {
      _preferences.setBool(_enableLocalStorageKey, value);
    });

    localDataDirectoryOverride.listen((value) {
      if (value != null) {
        _preferences.setString(_localDataDirectoryOverrideKey, value);
      } else {
        _preferences.remove(_localDataDirectoryOverrideKey);
      }
    });

    enableDarkMode.listen((value) {
      _preferences.setBool(_enableDarkModeKey, value);
    });

    enablePhysicalDiceMode.listen((value) {
      _preferences.setBool(_enablePhysicalDiceModeKey, value);
    });

    physicalDiceModeExplained.listen((value) {
      _preferences.setBool(_physicalDiceModeExplainedKey, value);
    });
  }
}

/// Gets whether the physical dice mode is enabled.
bool get getPhysicalDiceModeEnabled =>
    Get.find<LocalPreferencesService>().enablePhysicalDiceMode.value;
