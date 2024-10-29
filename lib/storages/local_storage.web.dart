import 'dart:js_interop';

import 'package:web/web.dart';

import 'data_storage.dart';

class LocalStorage extends DataStorage {
  @override
  bool get isLocal => true;

  @override
  Future<void> save(List<String> directory, String name, String content) async {
    final handle = (await _getFileHandle(directory, name, create: true))!;

    try {
      final writable = await handle.file.createWritable().toDart;
      await writable.write(content.toJS).toDart;
      await writable.close().toDart;
    } catch (e) {
      throw LocalStorageException(_getFilePath(directory, name), e);
    }
  }

  @override
  Future<String?> load(List<String> directory, String name) async {
    final handle = await _getFileHandle(directory, name, create: false);

    if (handle != null) {
      try {
        final file = await handle.file.getFile().toDart;
        return (await file.text().toDart).toDart;
      } catch (e) {
        throw LocalStorageException(_getFilePath(directory, name), e);
      }
    }

    return null;
  }

  @override
  Future<void> delete(List<String> directory, String name) async {
    final handle = await _getFileHandle(directory, name, create: false);

    if (handle != null) {
      try {
        await handle.directory.removeEntry(name).toDart;
      } catch (e) {
        throw LocalStorageException(_getFilePath(directory, name), e);
      }
    }
  }

  @override
  Future<void> loadJsonFiles(
    List<String> directory,
    Future<void> Function(List<String> filePath, String json) process, {
    String? absoluteDirectoryPath,
  }) async {
    // TODO web
  }

  Future<({FileSystemDirectoryHandle directory, FileSystemFileHandle file})?>
      _getFileHandle(
    List<String> directory,
    String name, {
    required bool create,
  }) async {
    try {
      final root = await window.navigator.storage.getDirectory().toDart;
      final createDirectoryOptions =
          FileSystemGetDirectoryOptions(create: create);
      var directoryHandle = root;
      for (final directoryPart in directory) {
        if (directoryPart.isNotEmpty) {
          directoryHandle = await directoryHandle
              .getDirectoryHandle(directoryPart, createDirectoryOptions)
              .toDart;
        }
      }

      final fileHandle = await directoryHandle
          .getFileHandle(name, FileSystemGetFileOptions(create: create))
          .toDart;

      return (directory: directoryHandle, file: fileHandle);
    } on DOMException catch (e) {
      if (!create && e.name == 'NotFoundError') {
        return null;
      } else {
        throw LocalStorageException(_getFilePath(directory, name), e);
      }
    } catch (e) {
      throw LocalStorageException(_getFilePath(directory, name), e);
    }
  }

  static String _getFilePath(List<String> directory, String name) =>
      '${directory.join('/')}/$name';

  static Future<String> getDefaultRootDirectoryPath() {
    throw UnsupportedError('Implementation not found on this platform.');
  }
}
