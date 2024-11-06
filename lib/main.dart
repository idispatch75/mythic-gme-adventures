import 'dart:io';
import 'dart:ui';

import 'package:catcher_2/catcher_2.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:loggy/loggy.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

import 'helpers/log_printer.dart';
import 'helpers/secure_storage.dart';
import 'helpers/snack_bar_error_handler.dart';
import 'helpers/utils.dart';
import 'orientation_locker.dart';
import 'persisters/adventure_persister.dart';
import 'persisters/global_settings_persister.dart';
import 'persisters/meaning_tables_persister.dart';
import 'storages/google_auth_oauth2.dart';
import 'storages/google_auth_service.dart';
import 'storages/local_storage.dart';
import 'ui/adventure_index/adventure_index_view.dart';
import 'ui/change_log/change_log.dart';
import 'ui/change_log/change_log_view.dart';
import 'ui/meaning_tables/meaning_table.dart';
import 'ui/preferences/preferences.dart';
import 'ui/styles.dart';

/// The global navigator key of the application.
final kNavigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  // catcher
  final releaseOptions = Catcher2Options(
    SilentReportMode(),
    [
      SnackBarErrorHandler(),
    ],
  );

  final debugOptions = Catcher2Options(
    releaseOptions.reportMode,
    releaseOptions.handlers
      ..add(ConsoleHandler(
        enableDeviceParameters: false,
        enableApplicationParameters: false,
      )),
  );

  Catcher2(
    runAppFunction: _runApp,
    releaseConfig: releaseOptions,
    debugConfig: debugOptions,
    navigatorKey: kNavigatorKey,
  );
}

void _runApp() async {
  // IMPL on the web, Catcher2 runs the app in a guarded zone,
  // which make a call to WidgetsFlutterBinding.ensureInitialized() fail if it is not done in the same zone,
  // e.g. before creating Catcher2.
  // This forces us to pass the run function containing ensureInitialized() to Catcher2 instead of just a widget.

  WidgetsFlutterBinding.ensureInitialized();

  // logging
  Loggy.initLoggy(
    logOptions: const LogOptions(
      kDebugMode ? LogLevel.all : LogLevel.info,
      stackTraceLevel: LogLevel.error,
    ),
    logPrinter: kDebugMode ? const LogPrinter() : const DefaultPrinter(),
  );

  // get preferences
  final sharedPreferences = await SharedPreferencesWithCache.create(
    cacheOptions: const SharedPreferencesWithCacheOptions(
      allowList: {
        ...LocalPreferencesService.keys,
        ...OAuth2GoogleAuthManager.preferenceKeys,
        ..._WindowGeometry.preferenceKeys,
        ...ChangeLogService.keys,
        'isMigrated',
      },
    ),
  );

  await _migratePreferences(sharedPreferences);

  // load the meaning tables
  // (before handling desktop size: waitUntilReadyToShow may not work properly)
  final meaningTableService = MeaningTablesService();
  await meaningTableService.loadFromAssets();
  Get.put(meaningTableService);

  // handle window size for desktop apps
  if (!GetPlatform.isWeb && GetPlatform.isDesktop) {
    await windowManager.ensureInitialized();

    final windowGeometry = _WindowGeometry(sharedPreferences);

    final position = windowGeometry.getPosition();
    final windowOptions = WindowOptions(
      size: windowGeometry.getSize(),
      //size: const Size(1300, 800),
      //size: const Size(900, 800),
      //size: const Size(360, 600),
      center: position == null,
      skipTaskbar: false,
      windowButtonVisibility: true,
      minimumSize: const Size(330, 500),
      titleBarStyle: TitleBarStyle.normal,
      title: (await PackageInfo.fromPlatform()).appName,
    );
    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      if (windowGeometry.isMaximized()) {
        await windowManager.maximize();
      } else if (position != null) {
        await windowManager.setPosition(position);
      }

      await windowManager.show();
      await windowManager.focus();

      windowManager.addListener(windowGeometry);

      // ask confirmation on exit for desktop
      // (for mobile/tablet it is handled with protectClose())
      await windowManager.setPreventClose(true);
      windowManager.addListener(_WindowCloseInterceptor());
    });
  }

  // register services
  final preferences = LocalPreferencesService(sharedPreferences);
  Get.put(preferences);

  Get.put(SecureStorage(sharedPreferences));
  Get.put(GoogleAuthService());
  Get.put(GlobalSettingsPersisterService());
  Get.put(MeaningTablesPersisterService());
  Get.put(AdventurePersisterService());

  final appVersion = (await PackageInfo.fromPlatform()).version;
  final adventureIndex = await AdventurePersister(LocalStorage()).loadIndex();
  Get.put(ChangeLogService(sharedPreferences, appVersion,
      isNewInstall: adventureIndex.adventures.isEmpty));

  // init locale
  final locale = PlatformDispatcher.instance.locale;
  Intl.defaultLocale = locale.toLanguageTag();
  await initializeDateFormatting(Intl.defaultLocale!);

  // add licenses
  _addLicense('Rubik', 'assets/google_fonts/Rubik-OFL.txt');
  _addLicense('Staatliches', 'assets/google_fonts/Staatliches-OFL.txt');

  // start the app
  AppStyles.setBrightness(
    preferences.enableDarkMode() ? Brightness.dark : Brightness.light,
  );

  Widget appWidget = Obx(
    () => GetMaterialApp(
      title: 'Mythic GME Adventures',
      home: ChangeLogWrapper(child: AdventureIndexView()),
      navigatorKey: kNavigatorKey,
      theme: AppStyles.lightTheme,
      darkTheme: AppStyles.darkTheme,
      themeMode:
          preferences.enableDarkMode() ? ThemeMode.dark : ThemeMode.light,
      locale: locale,
      fallbackLocale: const Locale('en'),
      debugShowCheckedModeBanner: false,
    ),
  );

  if (!GetPlatform.isWeb && !GetPlatform.isDesktop) {
    appWidget = OrientationLocker(
      child: appWidget,
    );
  }

  runApp(appWidget);
}

void _addLicense(String package, String asset) {
  LicenseRegistry.addLicense(() {
    return Stream<LicenseEntry>.fromFuture(() async {
      final licenseText = await rootBundle.loadString(asset);
      return LicenseEntryWithLineBreaks([package], licenseText);
    }());
  });
}

class _WindowGeometry extends WindowListener {
  static const preferenceKeys = {
    _widthKey,
    _heightKey,
    _topKey,
    _leftKey,
    _maximizedKey,
  };

  static const String _widthKey = 'windowWidth';
  static const String _heightKey = 'windowHeight';
  static const String _topKey = 'windowTop';
  static const String _leftKey = 'windowLeft';
  static const String _maximizedKey = 'windowMaximized';

  final SharedPreferencesWithCache sharedPreferences;

  _WindowGeometry(this.sharedPreferences);

  @override
  void onWindowResized() {
    windowManager.getSize().then((size) {
      sharedPreferences.setDouble(_widthKey, size.width);
      sharedPreferences.setDouble(_heightKey, size.height);
    });
  }

  @override
  void onWindowMoved() {
    windowManager.getPosition().then((offset) {
      sharedPreferences.setDouble(_topKey, offset.dy);
      sharedPreferences.setDouble(_leftKey, offset.dx);
    });
  }

  @override
  void onWindowMaximize() {
    sharedPreferences.setBool(_maximizedKey, true);
  }

  @override
  void onWindowUnmaximize() {
    sharedPreferences.setBool(_maximizedKey, false);
  }

  Size getSize() {
    final width = sharedPreferences.getDouble(_widthKey) ?? 1300;
    final height = sharedPreferences.getDouble(_heightKey) ?? 800;

    return Size(width, height);
  }

  Offset? getPosition() {
    final top = sharedPreferences.getDouble(_topKey);
    final left = sharedPreferences.getDouble(_leftKey);

    if (top != null && left != null) {
      return Offset(left, top);
    }

    return null;
  }

  bool isMaximized() => sharedPreferences.getBool(_maximizedKey) ?? false;
}

class _WindowCloseInterceptor extends WindowListener {
  @override
  void onWindowClose() async {
    if (await windowManager.isPreventClose()) {
      if (await showCloseAppConfirmation()) {
        exit(0);
      }
    }
  }
}

Future<void> _migratePreferences(
    SharedPreferencesWithCache sharedPreferences) async {
  final oldSharedPreferences = await SharedPreferences.getInstance();

  final isMigrated = sharedPreferences.getBool('isMigrated');
  if (isMigrated ?? false) {
    return;
  }

  final enableGoogleStorage =
      oldSharedPreferences.getBool('enableGoogleStorage');
  if (enableGoogleStorage != null) {
    await sharedPreferences.setBool('enableGoogleStorage', enableGoogleStorage);
  }

  final enableLocalStorage = oldSharedPreferences.getBool('enableLocalStorage');
  if (enableLocalStorage != null) {
    await sharedPreferences.setBool('enableLocalStorage', enableLocalStorage);
  }

  final localDataDirectoryOverride =
      oldSharedPreferences.getString('localDataDirectoryOverride');
  if (localDataDirectoryOverride != null) {
    await sharedPreferences.setString(
        'localDataDirectoryOverride', localDataDirectoryOverride);
  }

  final enableDarkMode = oldSharedPreferences.getBool('enableDarkMode');
  if (enableDarkMode != null) {
    await sharedPreferences.setBool('enableDarkMode', enableDarkMode);
  }

  await sharedPreferences.setBool('isMigrated', true);
}
