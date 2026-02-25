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

  ChangeLogService(this._preferences);

  List<ChangeLogVersion> getVersions() {
    final versions = <ChangeLogVersion>[];

    final lastViewedVersion = _preferences.getString(_versionKey);

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
                (e) => e.platform == _Platform.all || e.platform == platform,
              )
              .map((e) {
                if (e.platform == _Platform.all) {
                  return e.text;
                } else {
                  return '[${platform.name.capitalize}] ${e.text}';
                }
              })
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
    _preferences.setString(_versionKey, _versions[0].version);
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
  _Version('1.15.1', [
    _Entry(
      _Platform.all,
      'Fixed buggy extraneous Meaning Table.',
    ),
  ]),
  _Version('1.15.0', [
    _Entry(
      _Platform.all,
      'Added Chinese support for Meaning Tables (provided by sennomulo).',
    ),
  ]),
  _Version('1.14.0', [
    _Entry(
      _Platform.android,
      'Added the ability to import Custom Meaning Tables from a zip file.',
    ),
    _Entry(
      _Platform.windows,
      'Added the ability to import Custom Meaning Tables from a zip file.',
    ),
  ]),
  _Version('1.13.1', [
    _Entry(
      _Platform.android,
      'Fixed application not loading. Sorry for the inconvenience.',
    ),
  ]),
  _Version('1.13.0', [
    _Entry(
      _Platform.all,
      'Added Portuguese support for Meaning Tables.'
      ' This uses the Retropunk translation, which does not have the same ordering for table entries as the English version,'
      ' so when you switch to Portuguese, the existing entries in the roll log will be wrong.',
    ),
  ]),
  _Version('1.12.0', [
    _Entry(_Platform.all, 'Added full screen edition for Notes.'),
    _Entry(
      _Platform.all,
      'Added a Combat Clash toggle to force the Chaos Factor to 5 when using Mythic RPG Narrative Combat.'
      ' This can be enabled in the Global Settings.',
    ),
    _Entry(
      _Platform.all,
      'Improved the loading time of an Adventure when using Custom Meaning Tables in Google Drive.',
    ),
    _Entry(_Platform.all, 'Disabled rich-text paste in rich-text editor.'),
  ]),
  _Version('1.11.0', [
    _Entry(_Platform.all, 'Added some missing Meaning tables.'),
  ]),
  _Version('1.10.0', [
    _Entry(
      _Platform.all,
      'Allow to backup Adventures individually for an easier manual synchronization.'
      ' Available in the Adventure menu.',
    ),
  ]),
  _Version('1.9.2', [
    _Entry(
      _Platform.web,
      'Fixed the roll log not being saved properly, resulting in "unknown" entries on other platform.'
      ' Unfortunately, the previous roll log entries will be lost.'
      ' Sorry for the inconvenience.',
    ),
    _Entry(
      _Platform.all,
      'Fixed Random Events with Thread focus being interpreted as Current Context in the roll log when loading an Adventure.',
    ),
  ]),
  _Version('1.9.1', [
    _Entry(
      _Platform.all,
      'Restored the default line height in the Rich text editor for notes.',
    ),
    _Entry(
      _Platform.all,
      'Made full screen editing for Scenes more accessible.',
    ),
  ]),
  _Version('1.9.0', [
    _Entry(
      _Platform.all,
      'Added text formatting options to notes in Scenes, Notes, etc.',
    ),
    _Entry(_Platform.all, 'Allow to clear the Roll Log.'),
  ]),
  _Version('1.8.1', []),
  _Version('1.8.0', [
    _Entry(
      _Platform.all,
      'Added a Help system to give access to some Mythic rules abstracts.'
      ' Help buttons can be disabled in the Global Settings.',
    ),
    _Entry(
      _Platform.all,
      'Fixed incorrect wording "Extreme" instead of "Exceptional" in Fate answers.',
    ),
    _Entry(
      _Platform.all,
      'Lock the counter of Characters/Threads Lists to a maximum of 3, as recommended in the rules.'
      ' Can be toggled in the Global Settings.',
    ),
  ]),
  _Version('1.7.0', [
    _Entry(
      _Platform.all,
      'Added animations to lists, and thread progress track.',
    ),
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
      ' Toggle this in the Adventure Settings.',
    ),
  ]),
  _Version('1.5.0', [
    _Entry(
      _Platform.all,
      'A Web version of the App is available at https://mythic-gme-adventures.idispatch.ovh.'
      ' See the User Manual for more info.',
    ),
    _Entry(
      _Platform.all,
      'If you missed it in previous version, added the Physical dice mode:'
      ' switch to this mode to roll the dice yourself and lookup the result in the App.'
      ' Toggle this in the Adventure menu.',
    ),
    _Entry(_Platform.all, 'Added the ability to backup the local Adventures.'),
    _Entry(
      _Platform.windows,
      'Maybe fixed a crash on Windows 10 when closing the App.',
    ),
  ]),
];
