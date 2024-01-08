import 'dart:async';

import 'package:get/get.dart';

import '../storages/data_storage.dart';
import '../ui/meaning_tables/meaning_table.dart';
import 'persister.dart';

class MeaningTablesPersisterService
    extends PersisterService<MeaningTablesPersister> {
  bool needsLoading = true;

  @override
  MeaningTablesPersister createPersister(DataStorage storage) {
    return MeaningTablesPersister(storage);
  }

  Future<void> loadTables() async {
    assert(
      localPersister != null || remotePersister != null,
      'Local and remote persisters cannot both be null.',
    );

    if (needsLoading) {
      // load from remote, and default to local
      if (remotePersister != null) {
        await remotePersister!.loadTables();
      } else {
        await localPersister!.loadTables();
      }

      needsLoading = false;
    }
  }

  Future<void> pushToRemote(
      String absoluteDirectoryPath, RxInt progress) async {
    assert(
      localPersister != null && remotePersister != null,
      'Local and remote persisters cannot be null.',
    );

    return localPersister!.pushTo(
      remotePersister!,
      absoluteDirectoryPath: absoluteDirectoryPath,
      progress: progress,
    );
  }

  Future<void> pullFromRemote(RxInt progress) async {
    assert(
      localPersister != null && remotePersister != null,
      'Local and remote persisters cannot be null.',
    );

    return remotePersister!.pushTo(localPersister!, progress: progress);
  }
}

class MeaningTablesPersister {
  static const _directory = 'meaning_tables';

  final DataStorage _storage;

  MeaningTablesPersister(this._storage);

  Future<void> loadTables() async {
    final meaningTables = Get.find<MeaningTablesService>();

    return _storage.loadJsonFiles([_directory], (filePath, content) {
      if (filePath.length == 2) {
        meaningTables.addTableFromJson(locale: filePath[0], json: content);
      }

      return Future.value();
    });
  }

  Future<void> pushTo(
    MeaningTablesPersister other, {
    required RxInt progress,
    String? absoluteDirectoryPath,
  }) async {
    return _storage.loadJsonFiles([_directory], (filePath, content) async {
      if (filePath.length == 2) {
        await other._storage.save(
          [_directory, filePath[0]],
          filePath[1],
          content,
        );

        progress++;
      }
    }, absoluteDirectoryPath: absoluteDirectoryPath);
  }
}
