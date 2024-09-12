import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalPreferencesService extends GetxService {
  final SharedPreferencesWithCache _preferences;

  final RxBool enableGoogleStorage;
  final RxBool enableLocalStorage;
  final Rx<String?> localDataDirectoryOverride;
  final RxBool enableDarkMode;
  final RxBool enablePhysicalDiceMode;

  LocalPreferencesService(this._preferences)
      : enableGoogleStorage =
            (_preferences.getBool('enableGoogleStorage') ?? false).obs,
        enableLocalStorage =
            (_preferences.getBool('enableLocalStorage') ?? true).obs,
        localDataDirectoryOverride =
            _preferences.getString('localDataDirectoryOverride').obs,
        enableDarkMode = (_preferences.getBool('enableDarkMode') ??
                WidgetsBinding.instance.platformDispatcher.platformBrightness ==
                    Brightness.dark)
            .obs,
        enablePhysicalDiceMode =
            (_preferences.getBool('enablePhysicalDiceMode') ?? false).obs;

  @override
  void onInit() {
    super.onInit();

    enableGoogleStorage.listen((value) {
      _preferences.setBool('enableGoogleStorage', value);
    });

    enableLocalStorage.listen((value) {
      _preferences.setBool('enableLocalStorage', value);
    });

    localDataDirectoryOverride.listen((value) {
      if (value != null) {
        _preferences.setString('localDataDirectoryOverride', value);
      } else {
        _preferences.remove('localDataDirectoryOverride');
      }
    });

    enableDarkMode.listen((value) {
      _preferences.setBool('enableDarkMode', value);
    });

    enablePhysicalDiceMode.listen((value) {
      _preferences.setBool('enablePhysicalDiceMode', value);
    });
  }
}

/// Gets whether the physical dice mode is enabled.
bool get getPhysicalDiceModeEnabled =>
    Get.find<LocalPreferencesService>().enablePhysicalDiceMode.value;
