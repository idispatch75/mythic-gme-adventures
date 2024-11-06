import 'dart:async';
import 'dart:convert';

import 'package:get/get.dart';
import 'package:loggy/loggy.dart';
import 'package:rxdart/rxdart.dart';

import '../helpers/get_extensions.dart';
import '../helpers/json_utils.dart';
import '../storages/data_storage.dart';
import '../ui/global_settings/global_settings.dart';
import 'persister.dart';

class GlobalSettingsPersisterService
    extends PersisterService<GlobalSettingsPersister> {
  StreamSubscription<bool>? _saveRequestsSubscription;

  /// Save results triggered by [saveSettings].
  Stream<SaveResult> get saveResults => _saveResults.stream;
  final _saveResults = PublishSubject<SaveResult>();

  @override
  GlobalSettingsPersister createPersister(DataStorage storage) {
    return GlobalSettingsPersister(storage);
  }

  Future<void> saveSettings() async {
    assert(
      localPersister != null || remotePersister != null,
      'Local and remote persisters cannot both be null.',
    );

    final saveTimestamp = DateTime.timestamp().millisecondsSinceEpoch;

    await localPersister?.saveSettings(saveTimestamp);
    await remotePersister?.saveSettings(saveTimestamp);
  }

  Future<void> loadSettings() async {
    assert(
      localPersister != null || remotePersister != null,
      'Local and remote persisters cannot both be null.',
    );

    final local = await localPersister?.loadSettings();
    final remote = await remotePersister?.loadSettings();

    final GlobalSettingsService service;
    if (local != null) {
      if (remote == null ||
          (local.saveTimestamp ?? 0) > (remote.saveTimestamp ?? 0)) {
        service = Get.replaceForced(local);
      } else {
        service = Get.replaceForced(remote);
      }
    } else {
      service = Get.replaceForced(remote!);
    }

    // save the current adventure when a save is requested by an adventure service
    await _saveRequestsSubscription?.cancel();

    _saveRequestsSubscription = service.saveRequests
        .debounceTime(const Duration(seconds: 5))
        .listen((value) async {
      try {
        await saveSettings();
      } catch (e) {
        // ignore
        logDebug('Failed to save global settings', e);
      }
    });
  }
}

class GlobalSettingsPersister {
  static const _directory = '';
  static const _fileName = 'settings.json';

  final DataStorage _storage;

  GlobalSettingsPersister(this._storage);

  Future<void> saveSettings(int saveTimestamp) async {
    final settings = Get.find<GlobalSettingsService>();
    final json = settings.toJson();
    json['saveTimestamp'] = saveTimestamp;

    await _storage.save([_directory], _fileName, jsonEncode(json));

    // update the timestamp in memory only if the settings were saved successfully
    settings.saveTimestamp = saveTimestamp;
  }

  Future<GlobalSettingsService> loadSettings() async {
    final content = await _storage.load([_directory], _fileName);

    if (content != null) {
      final json = jsonDecode(content) as JsonObj;

      return GlobalSettingsService.fromJson(json);
    } else {
      return GlobalSettingsService(
        favoriteMeaningTables: {
          'actions',
          'descriptions',
          'characters',
          'locations',
        },
      );
    }
  }
}
