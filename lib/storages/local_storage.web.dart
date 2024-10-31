import 'dart:js_interop';
import 'dart:js_interop_unsafe';

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
    assert(absoluteDirectoryPath == null);
    // TODO web check

    final rootHandle = await _getDirectoryHandle(directory, create: false);
    if (rootHandle == null) {
      return;
    }

    final relativeDirectory = <String>[];

    Future<void> processRec(FileSystemDirectoryHandle directoryHandle) async {
      await for (FileSystemHandle handle in directoryHandle.values()) {
        if (handle.kind == 'file' && handle.name.endsWith('.json')) {
          final file = await (handle as FileSystemFileHandle).getFile().toDart;
          final content = (await file.text().toDart).toDart;

          await process([...relativeDirectory, handle.name], content);
        } else {
          relativeDirectory.add(handle.name);

          await processRec(handle as FileSystemDirectoryHandle);
        }
      }

      if (relativeDirectory.isNotEmpty) {
        relativeDirectory.removeLast();
      }
    }

    return processRec(rootHandle);
  }

  Future<FileSystemDirectoryHandle?> _getDirectoryHandle(
    List<String> directory, {
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

      return directoryHandle;
    } on DOMException catch (e) {
      if (!create && e.name == 'NotFoundError') {
        return null;
      } else {
        throw LocalStorageException(_getFilePath(directory, ''), e);
      }
    } catch (e) {
      throw LocalStorageException(_getFilePath(directory, ''), e);
    }
  }

  Future<({FileSystemDirectoryHandle directory, FileSystemFileHandle file})?>
      _getFileHandle(
    List<String> directory,
    String name, {
    required bool create,
  }) async {
    try {
      final directoryHandle =
          await _getDirectoryHandle(directory, create: create);
      if (directoryHandle == null) {
        return null;
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

extension FileSystemDirectoryHandleEx on FileSystemDirectoryHandle {
  Stream<FileSystemHandle> values() {
    final iterator = callMethod<JSObject>('values'.toJS);

    return _asyncIterator<FileSystemHandle>(iterator);
  }
}

Stream<T> _asyncIterator<T extends JSObject>(JSObject iterator) async* {
  while (true) {
    final next = await iterator.callMethod<JSPromise<T>>('next'.toJS).toDart;

    if (next.getProperty<JSBoolean>('done'.toJS).toDart) {
      break;
    }

    yield next.getProperty<T>('value'.toJS);
  }
}
