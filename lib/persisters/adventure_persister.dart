import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:get/get.dart';
import 'package:loggy/loggy.dart';
import 'package:rxdart/rxdart.dart';

import '../helpers/get_extensions.dart';
import '../helpers/json_utils.dart';
import '../storages/data_storage.dart';
import '../ui/adventure/adventure.dart';
import '../ui/adventure_index/adventure_index.dart';
import '../ui/chaos_factor/chaos_factor.dart';
import '../ui/characters/character.dart';
import '../ui/characters/characters_list.dart';
import '../ui/dice_roller/dice_roller.dart';
import '../ui/features/feature.dart';
import '../ui/keyed_scenes/keyed_scene.dart';
import '../ui/notes/note.dart';
import '../ui/player_characters/player_character.dart';
import '../ui/roll_log/roll_log.dart';
import '../ui/scenes/scene.dart';
import '../ui/threads/thread.dart';
import '../ui/threads/threads_list.dart';
import 'persister.dart';

class AdventurePersisterService extends PersisterService<AdventurePersister> {
  StreamSubscription<bool>? _saveRequestsSubscription;

  /// Save results triggered by [saveCurrentAdventure] and [saveNewAdventure].
  Stream<SaveResult> get saveResults => _saveResults.stream;
  final _saveResults = PublishSubject<SaveResult>();

  @override
  AdventurePersister createPersister(DataStorage storage) {
    return AdventurePersister(storage);
  }

  /// Saves the adventures index and the current adventure if there is one.
  Future<void> saveCurrentAdventure() {
    if (!Get.isRegistered<AdventureService>()) {
      return Future.value();
    }

    return _saveAdventure(
      Get.find<AdventureService>(),
      Get.find<ChaosFactorService>(),
      Get.find<CharactersService>(),
      Get.find<ThreadsService>(),
      Get.find<PlayerCharactersService>(),
      Get.find<ScenesService>(),
      Get.find<KeyedScenesService>(),
      Get.find<FeaturesService>(),
      Get.find<NotesService>(),
      Get.find<RollLogService>(),
      Get.find<DiceRollerService>(),
    );
  }

  /// Adds the new [adventure] to the index and saves the adventure and the index.
  Future<void> saveNewAdventure(AdventureService adventure) async {
    Get.find<AdventureIndexService>().addAdventure(
      IndexAdventure(id: adventure.id, name: adventure.name()),
    );

    return _saveAdventure(
      adventure,
      ChaosFactorService(),
      CharactersService(),
      ThreadsService(),
      PlayerCharactersService(),
      ScenesService(),
      KeyedScenesService(),
      FeaturesService(),
      NotesService(),
      RollLogService(),
      DiceRollerService(),
    );
  }

  Future<void> _saveAdventure(
    AdventureService adventure,
    ChaosFactorService chaosFactorService,
    CharactersService charactersService,
    ThreadsService threadsService,
    PlayerCharactersService playerCharactersService,
    ScenesService scenesService,
    KeyedScenesService keyedScenesService,
    FeaturesService featuresService,
    NotesService notesService,
    RollLogService rollLogService,
    DiceRollerService diceRollerService,
  ) async {
    assert(
      localPersister != null || remotePersister != null,
      'Local and remote persisters cannot both be null.',
    );

    try {
      final saveTimestamp = DateTime.timestamp().millisecondsSinceEpoch;

      final indexAdventure = Get.find<AdventureIndexService>()
              .adventures
              .firstWhereOrNull((e) => e.id == adventure.id) ??
          IndexAdventure(id: adventure.id, name: adventure.name());
      if (localPersister != null) {
        indexAdventure.localSaveTimestamp = saveTimestamp;
      }
      if (remotePersister != null) {
        indexAdventure.remoteSaveTimestamp = saveTimestamp;
      }

      Future<void> persist(AdventurePersister? persister) async {
        if (persister != null) {
          // save the adventure
          await persister.saveAdventure(
            adventure,
            chaosFactorService,
            charactersService,
            threadsService,
            playerCharactersService,
            scenesService,
            keyedScenesService,
            featuresService,
            notesService,
            rollLogService,
            diceRollerService,
            saveTimestamp,
          );

          //  update and save the index
          indexAdventure.name = adventure.name();
          indexAdventure.saveTimestamp = adventure.saveTimestamp();

          await persister.saveIndex();
        }
      }

      await persist(localPersister);
      await persist(remotePersister);

      _saveResults.add(SaveResult.success());
    } catch (e) {
      _saveResults.add(SaveResult.error(e));
      rethrow;
    }
  }

  Future<void> loadIndex() async {
    assert(
      localPersister != null || remotePersister != null,
      'Local and remote persisters cannot both be null.',
    );

    final local = await localPersister?.loadIndex();
    final remote = await remotePersister?.loadIndex();

    // merge adventures from both sources
    List<IndexAdventure> adventures;
    if (local != null) {
      adventures = local.adventures;

      if (remote != null) {
        for (final remoteAdventure in remote.adventures) {
          // if the remote adventure is newer than an existing local,
          // replace the local adventure with the remote one
          final localAdventure =
              adventures.firstWhereOrNull((e) => e.id == remoteAdventure.id);
          if (localAdventure != null) {
            if (remoteAdventure.remoteSaveTimestamp >
                localAdventure.localSaveTimestamp) {
              // mark the remote adventure as being also present in local storage
              remoteAdventure.localSaveTimestamp =
                  localAdventure.localSaveTimestamp;

              adventures.remove(localAdventure);
            } else {
              // mark the local adventure as being also present in remote storage
              localAdventure.remoteSaveTimestamp =
                  remoteAdventure.remoteSaveTimestamp;
              continue;
            }
          }

          adventures.add(remoteAdventure);
        }
      }
    } else {
      adventures = remote!.adventures;
    }

    // TODO purge old deleted adventures

    Get.replaceForced(AdventureIndexService(adventures: adventures));
  }

  Future<void> loadAdventure(int id) async {
    assert(
      localPersister != null || remotePersister != null,
      'Local and remote persisters cannot both be null.',
    );

    final local = await localPersister?.loadAdventure(id);
    final remote = await remotePersister?.loadAdventure(id);

    if (local != null) {
      if (remote == null || (local.saveTimestamp) > remote.saveTimestamp) {
        local.publisher();
      } else {
        remote.publisher();
      }
    } else if (remote != null) {
      remote.publisher();
    } else {
      throw Exception('Adventure $id not found');
    }

    // save the current adventure when a save is requested by an adventure service
    await _saveRequestsSubscription?.cancel();

    _saveRequestsSubscription = MergeStream([
      Get.find<AdventureService>().saveRequests,
      Get.find<ChaosFactorService>().saveRequests,
      Get.find<CharactersService>().saveRequests,
      Get.find<ThreadsService>().saveRequests,
      Get.find<PlayerCharactersService>().saveRequests,
      Get.find<ScenesService>().saveRequests,
      Get.find<KeyedScenesService>().saveRequests,
      Get.find<FeaturesService>().saveRequests,
      Get.find<NotesService>().saveRequests,
      Get.find<RollLogService>().saveRequests,
      Get.find<DiceRollerService>().saveRequests,
    ]).debounceTime(const Duration(seconds: 5)).listen((value) async {
      try {
        await saveCurrentAdventure();
      } catch (e) {
        // ignore
        logDebug('Failed to save Adventure $id', e);
      }
    });
  }

  /// Deletes an adventure.
  ///
  /// No effect if the adventure does not exist.
  Future<void> deleteAdventure(int id) async {
    assert(
      localPersister != null || remotePersister != null,
      'Local and remote persisters cannot both be null.',
    );

    final saveTimestamp = DateTime.timestamp().millisecondsSinceEpoch;

    final indexAdventure = Get.find<AdventureIndexService>()
            .adventures
            .firstWhereOrNull((e) => e.id == id) ??
        IndexAdventure(id: id, name: 'deleted');

    Future<void> persist(AdventurePersister? persister) async {
      if (persister != null) {
        // delete the adventure
        await persister.deleteAdventure(id);

        // update and save the index
        indexAdventure.isDeleted = true;
        indexAdventure.saveTimestamp = saveTimestamp;

        await persister.saveIndex();
      }
    }

    await persist(localPersister);
    await persist(remotePersister);
  }

  Future<void> synchronizeAdventures() async {
    assert(
      localPersister != null && remotePersister != null,
      'Local and remote persister cannot be null.',
    );

    // sync adventures with different timestamps
    final adventures = Get.find<AdventureIndexService>().adventures;
    final synchronizations = <Future<void>>[];
    for (final adventure in adventures) {
      // if the remote version is newer, update the local version
      if (adventure.remoteSaveTimestamp > adventure.localSaveTimestamp) {
        if (adventure.isDeleted) {
          if (adventure.localSaveTimestamp > 0) {
            synchronizations.add(localPersister!.deleteAdventure(adventure.id));
          }
        } else {
          synchronizations
              .add(remotePersister!.pushTo(adventure.id, localPersister!));
        }
        // if the local version is newer, update the remote version
      } else if (adventure.remoteSaveTimestamp < adventure.localSaveTimestamp) {
        if (adventure.isDeleted) {
          if (adventure.remoteSaveTimestamp > 0) {
            synchronizations
                .add(remotePersister!.deleteAdventure(adventure.id));
          }
        } else {
          synchronizations
              .add(localPersister!.pushTo(adventure.id, remotePersister!));
        }
      }
    }

    if (synchronizations.isNotEmpty) {
      await Future.wait(synchronizations);

      // save indexes
      final cleanedUpAdventures =
          adventures.where((e) => !e.isDeleted).toList();
      for (final adventure in cleanedUpAdventures) {
        adventure.saveTimestamp =
            max(adventure.remoteSaveTimestamp, adventure.localSaveTimestamp);
        adventure.localSaveTimestamp = adventure.saveTimestamp!;
        adventure.remoteSaveTimestamp = adventure.localSaveTimestamp;
      }
      await Future.wait([
        localPersister!.saveIndexAdventures(cleanedUpAdventures),
        remotePersister!.saveIndexAdventures(cleanedUpAdventures),
      ]);
    }
  }

  Future<void> restoreAdventure(
    JsonObj json,
    int adventureId,
  ) async {
    final saveTimestamp = DateTime.timestamp().millisecondsSinceEpoch;

    // update the adventure file with the ID of the destination adventure
    json['id'] = adventureId;
    json['saveTimestamp'] = saveTimestamp;

    // save the adventure
    final adventure = AdventureService.fromJson(json);
    final adventures = Get.find<AdventureIndexService>().adventures;
    final indexAdventure = adventures.firstWhere((e) => e.id == adventureId);
    indexAdventure.name = adventure.name();
    indexAdventure.saveTimestamp = adventure.saveTimestamp();

    Future<void> persist(AdventurePersister? persister) async {
      if (persister != null) {
        await persister.saveAdventureContent(adventureId, jsonEncode(json));

        await persister.saveIndex();
      }
    }

    await persist(localPersister);
    await persist(remotePersister);
  }
}

class AdventurePersister {
  static const directory = 'adventures';
  static const _indexFileName = 'index.json';

  final DataStorage _storage;

  AdventurePersister(this._storage);

  Future<void> saveIndex() {
    return _saveIndex(Get.find<AdventureIndexService>());
  }

  Future<void> saveIndexAdventures(List<IndexAdventure> adventures) {
    return _saveIndex(AdventureIndexService(adventures: adventures));
  }

  Future<void> _saveIndex(AdventureIndexService index) {
    final json = index.toJson(_storage.isLocal);

    const encoder = JsonEncoder.withIndent('  ');
    final prettyIndex = encoder.convert(json);

    return _storage.save([directory], _indexFileName, prettyIndex);
  }

  Future<AdventureIndexService> loadIndex() async {
    final content = await _storage.load([directory], _indexFileName);

    if (content != null) {
      final json = jsonDecode(content) as JsonObj;

      final index = AdventureIndexService.fromJson(json);
      if (index.schemaVersion > AdventureIndexService.supportedSchemaVersion) {
        throw const UnsupportedSchemaVersionException(fileName: _indexFileName);
      }

      if (_storage.isLocal) {
        for (var adventure in index.adventures) {
          adventure.localSaveTimestamp = adventure.saveTimestamp ?? 0;
        }
      } else {
        for (var adventure in index.adventures) {
          adventure.remoteSaveTimestamp = adventure.saveTimestamp ?? 0;
        }
      }

      return index;
    } else {
      return AdventureIndexService(adventures: []);
    }
  }

  Future<void> saveAdventure(
    AdventureService adventure,
    ChaosFactorService chaosFactorService,
    CharactersService charactersService,
    ThreadsService threadsService,
    PlayerCharactersService playerCharactersService,
    ScenesService scenesService,
    KeyedScenesService keyedScenesService,
    FeaturesService featuresService,
    NotesService notesService,
    RollLogService rollLogService,
    DiceRollerService diceRollerService,
    int saveTimestamp,
  ) async {
    final json = adventure.toJson();
    json['saveTimestamp'] = saveTimestamp;

    json.addAll(chaosFactorService.toJson());
    json.addAll(charactersService.toJson());
    json.addAll(threadsService.toJson());
    json.addAll(playerCharactersService.toJson());
    json.addAll(scenesService.toJson());
    json.addAll(keyedScenesService.toJson());
    json.addAll(featuresService.toJson());
    json.addAll(notesService.toJson());
    json.addAll(rollLogService.toJson());
    json.addAll(diceRollerService.toJson());

    await saveAdventureContent(
      adventure.id,
      jsonEncode(json),
    );

    // update the timestamp in memory only if the adventure was saved successfully
    adventure.saveTimestamp(saveTimestamp);
  }

  Future<void> saveAdventureContent(int adventureId, String content) {
    return _storage.save(
      [directory],
      _adventureFileName(adventureId),
      content,
    );
  }

  Future<({int saveTimestamp, void Function() publisher})?> loadAdventure(
      int id) async {
    final fileName = _adventureFileName(id);
    final content = await _storage.load([directory], fileName);

    if (content != null) {
      final json = jsonDecode(content) as JsonObj;
      final adventure = AdventureService.fromJson(json);
      if (adventure.schemaVersion > AdventureService.supportedSchemaVersion) {
        throw UnsupportedSchemaVersionException(
            fileName: '$directory/$fileName');
      }

      return (
        saveTimestamp: adventure.saveTimestamp()!,
        publisher: () {
          Get.replaceForced(adventure);
          Get.replaceForced(ChaosFactorService.fromJson(json));
          Get.replaceForced(CharactersService.fromJson(json));
          Get.replaceForced(CharactersListController());
          Get.replaceForced(ThreadsService.fromJson(json));
          Get.replaceForced(ThreadsListController());
          Get.replaceForced(PlayerCharactersService.fromJson(json));
          Get.replaceForced(ScenesService.fromJson(json));
          Get.replaceForced(KeyedScenesService.fromJson(json));
          Get.replaceForced(FeaturesService.fromJson(json));
          Get.replaceForced(NotesService.fromJson(json));
          Get.replaceForced(RollLogService.fromJson(json));
          Get.replaceForced(DiceRollerService.fromJson(json));
        },
      );
    }

    return null;
  }

  /// Deletes an adventure.
  ///
  /// No effect if the adventure does not exist.
  Future<void> deleteAdventure(int id) {
    return _storage.delete([directory], _adventureFileName(id));
  }

  /// Copies an adventure from this persister to another persister.
  Future<void> pushTo(int adventureId, AdventurePersister other) async {
    final fileName = _adventureFileName(adventureId);

    final content = await _storage.load([directory], fileName);
    if (content != null) {
      await other._storage.save([directory], fileName, content);
    }
  }

  String _adventureFileName(int id) => '$id.json';
}
