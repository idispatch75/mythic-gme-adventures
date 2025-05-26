import 'dart:io';

import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';

import '../ui/preferences/preferences.dart';
import 'data_storage.dart';

class LocalStorage extends DataStorage {
  @override
  bool get isLocal => true;

  @override
  Future<void> save(List<String> directory, String name, String content) async {
    final file = await _getFile(directory, name);

    try {
      await file.writeAsString(content, flush: true);
    } catch (e) {
      throw LocalStorageException(file.path, e);
    }
  }

  @override
  Future<String?> load(List<String> directory, String name) async {
    final file = await _getFile(directory, name);

    try {
      if (await file.exists()) {
        return await file.readAsString();
      }
    } catch (e) {
      throw LocalStorageException(file.path, e);
    }

    return null;
  }

  @override
  Future<void> deleteDirectory(List<String> directory) async {
    final directoryPath = directory.join(Platform.pathSeparator);

    try {
      final rootDirectory = await _getRootDirectoryPath();
      final dir = Directory(
        '$rootDirectory${Platform.pathSeparator}$directoryPath',
      );

      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    } catch (e) {
      throw LocalStorageException(directoryPath, e);
    }
  }

  @override
  Future<void> delete(List<String> directory, String name) async {
    final file = await _getFile(directory, name);

    try {
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      throw LocalStorageException(file.path, e);
    }
  }

  @override
  Future<void> loadJsonFiles(
    List<String> directory,
    Future<void> Function(List<String> filePath, String json) process, {
    String? absoluteDirectoryPath,
  }) async {
    final startDirectory = Directory(
      absoluteDirectoryPath ??
          await _getRootDirectoryPath() +
              Platform.pathSeparator +
              directory.join(Platform.pathSeparator),
    );

    if (await startDirectory.exists()) {
      final entities = startDirectory.list(recursive: true);

      await for (var entity in entities) {
        if (entity is File && entity.path.endsWith('.json')) {
          final content = await entity.readAsString();

          final path = entity.path
              .substring(startDirectory.path.length + 1)
              .split(Platform.pathSeparator);
          await process(path, content);
        }
      }
    }
  }

  Future<File> _getFile(List<String> directory, String name) async {
    final directoryPath = directory.join(Platform.pathSeparator);

    try {
      final rootDirectory = await _getRootDirectoryPath();
      final fileDirectory = await Directory(
        '$rootDirectory${Platform.pathSeparator}$directoryPath',
      ).create(recursive: true);

      return File('${fileDirectory.path}${Platform.pathSeparator}$name');
    } catch (e) {
      throw LocalStorageException(
        '$directoryPath${Platform.pathSeparator}$name',
        e,
      );
    }
  }

  static Future<String> _getRootDirectoryPath() async {
    return Get.find<LocalPreferencesService>().localDataDirectoryOverride() ??
        await getDefaultRootDirectoryPath();
  }

  static Future<String> getDefaultRootDirectoryPath() async {
    final userDirectory = await getApplicationDocumentsDirectory();
    return '${userDirectory.path}${Platform.pathSeparator}${DataStorage.appDirectory}';
  }
}
