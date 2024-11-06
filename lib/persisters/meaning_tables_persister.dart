import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:get/get.dart';
import 'package:loggy/loggy.dart';

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

  /// Loads the custom meaning tables from remote if available,
  /// or from local otherwise.
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

  /// Replaces in the remote storage with the custom meaning tables in [absoluteDirectoryPath].
  ///
  /// Deletes the tables directory in the remote storage before copying.
  Future<void> importDirectoryToRemote(
      String absoluteDirectoryPath, RxInt progress) async {
    assert(
      localPersister != null && remotePersister != null,
      'Local and remote persisters cannot be null.',
    );

    await localPersister!.copyTo(
      remotePersister!,
      absoluteDirectoryPath: absoluteDirectoryPath,
      progress: progress,
    );

    needsLoading = true;
  }

  /// Replaces the custom meaning tables in the remote storage
  /// with the content of a zip file.
  ///
  /// Deletes the tables directory in the remote storage before copying.
  Future<void> importZipToRemote(Uint8List zipContent, RxInt progress) async {
    assert(
      remotePersister != null,
      'Remote persister cannot be null.',
    );

    await remotePersister!.updateFromZip(zipContent, progress: progress);

    needsLoading = true;
  }

  /// Replaces the custom meaning tables in the local storage
  /// with the tables in the remote storage.
  ///
  /// Deletes the tables directory in the local storage before copying.
  Future<void> importFromRemote(RxInt progress) async {
    assert(
      localPersister != null && remotePersister != null,
      'Local and remote persisters cannot be null.',
    );

    await remotePersister!.copyTo(localPersister!, progress: progress);

    needsLoading = true;
  }

  /// Replaces the custom meaning tables in the local storage
  /// with the content of a zip file.
  ///
  /// Deletes the tables directory in the local storage before copying.
  Future<void> importZipToLocal(Uint8List zipContent) async {
    assert(
      localPersister != null,
      'Local persister cannot be null.',
    );

    await localPersister!.updateFromZip(zipContent);

    needsLoading = true;
  }

  /// Deletes the meaning tables directory in the local storage.
  Future<void> deleteLocal() async {
    assert(
      localPersister != null,
      'Local persister cannot be null.',
    );

    await localPersister!.delete();

    needsLoading = true;
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
        logDebug('Loading table ${filePath.join('/')}');

        meaningTables.addTableFromJson(locale: filePath[0], json: content);
      }

      return Future.value();
    });
  }

  /// Copies the custom meaning tables in this persister
  /// to an [other] persister.
  ///
  /// Deletes the tables directory in [other] before copying.
  ///
  /// If [absoluteDirectoryPath] is not null,
  /// the source of the meaning tables is this directory.
  /// This is valid only if this persister is local.
  Future<void> copyTo(
    MeaningTablesPersister other, {
    required RxInt progress,
    String? absoluteDirectoryPath,
  }) async {
    assert(absoluteDirectoryPath == null || _storage.isLocal);

    // delete the destination
    await other.delete();

    // save to other persister
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

  /// Replaces the custom meaning tables in this persister
  /// with the content of a zip file.
  ///
  /// Deletes the tables directory in this persister before copying.
  Future<void> updateFromZip(
    Uint8List zipContent, {
    RxInt? progress,
  }) async {
    // delete all
    await _storage.deleteDirectory([_directory]);

    // save files
    final archive = ZipDecoder().decodeBytes(zipContent);

    final jsonFiles =
        archive.where((e) => e.isFile && e.name.endsWith('.json'));
    for (final file in jsonFiles) {
      final parts = file.name.split('/');
      if (parts.length == 2) {
        final content = utf8.decoder.convert(file.content as List<int>);
        await _storage.save([_directory, parts[0]], parts[1], content);

        if (progress != null) {
          progress++;
        }
      }
    }
  }

  /// Deletes the custom meaning tables directory.
  Future<void> delete() {
    return _storage.deleteDirectory([_directory]);
  }
}
