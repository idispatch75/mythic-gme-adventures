import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChangeLogVersion {
  final String version;
  final List<String> entries;

  const ChangeLogVersion(this.version, this.entries);
}

class ChangeLogService extends GetxService {
  static const _versionKey = 'changeLogVersion';

  static const keys = {
    _versionKey,
  };

  final SharedPreferencesWithCache _preferences;
  final String _currentVersion;
  final bool isNewInstall;

  ChangeLogService(
    this._preferences,
    this._currentVersion, {
    required this.isNewInstall,
  });

  List<ChangeLogVersion> getVersions() {
    final versions = <ChangeLogVersion>[];

    var lastViewedVersion = _preferences.getString(_versionKey);

    // TODO remove hack
    if (lastViewedVersion == null && !isNewInstall) {
      lastViewedVersion = '1.4.0';
    }

    if (lastViewedVersion != null) {
      final _Platform platform;
      if (GetPlatform.isWeb) {
        platform = _Platform.web;
      } else if (GetPlatform.isAndroid) {
        platform = _Platform.android;
      } else {
        platform = _Platform.windows;
      }

      for (final version in _versions) {
        if (version.version == lastViewedVersion) {
          break;
        } else {
          final entries = version.entries
              .where(
                  (e) => e.platform == _Platform.all || e.platform == platform)
              .map((e) => e.text)
              .toList();
          if (entries.isNotEmpty) {
            versions.add(ChangeLogVersion(version.version, entries));
          }
        }
      }
    }

    return versions;
  }

  void markRead() {
    _preferences.setString(_versionKey, _currentVersion);
  }
}

enum _Platform {
  all,
  windows,
  android,
  web,
}

class _Entry {
  final _Platform platform;
  final String text;

  const _Entry(this.platform, this.text);
}

class _Version {
  final String version;
  final List<_Entry> entries;

  const _Version(this.version, this.entries);
}

// add the new version before the previous versions
const _versions = [
  _Version('1.8.0', [
    _Entry(_Platform.all,
        'Fixed incorrect wording "Extreme" instead of "Exceptional" in Fate answers.'),
    _Entry(
        _Platform.all,
        'Lock the counter of Characters/Threads list to a maximum of 3, as recommended in the rules.'
        'Can be toggled in the Global Settings.'),
  ]),
  _Version('1.7.0', [
    _Entry(
        _Platform.all, 'Added animations to lists, and thread progress track.'),
    _Entry(_Platform.all, 'Added the ability to sort some lists.'),
    _Entry(_Platform.all, 'Use a more legible font for titles and headers.'),
  ]),
  _Version('1.6.1', [
    _Entry(_Platform.all, 'Fixed Chaos Factor no more available. Sorry.'),
    _Entry(_Platform.all, 'Handle data format upgrades to prevent data loss.'),
  ]),
  _Version('1.6.0', [
    _Entry(
        _Platform.all,
        'Added support for Prepared Adventures, with Adventure Features and adapted Event Focus table.'
        ' Toggle this in the Adventure Settings.'),
  ]),
  _Version('1.5.0', [
    _Entry(
        _Platform.all,
        'A Web version of the App is available at https://mythic-gme-adventures.idispatch.ovh.'
        ' See the User Manual for more info.'),
    _Entry(
        _Platform.all,
        'If you missed it in previous version, added the Physical dice mode:'
        ' switch to this mode to roll the dice yourself and lookup the result in the App.'
        ' Toggle this in the Adventure menu.'),
    _Entry(_Platform.all, 'Added the ability to backup the local Adventures.'),
    _Entry(_Platform.windows,
        'Maybe fixed a crash on Windows 10 when closing the App.'),
  ]),
];
