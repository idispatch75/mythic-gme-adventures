import 'dart:async';

abstract class DataStorage {
  static const appDirectory = 'Mythic GME Adventures';

  bool get isLocal;

  // TODO lock remote write to prevent multiple clients writes
  // TODO backup local file before persisting

  Future<void> save(List<String> directory, String name, String content);

  Future<String?> load(List<String> directory, String name);

  /// Deletes a file.
  ///
  /// No effect if the file does not exist.
  Future<void> delete(List<String> directory, String name);

  /// Loads JSON files content recursively relative to [directory]
  /// and calls [process] for each file with a filePath relative to [directory]
  /// and including the file name.
  Future<void> loadJsonFiles(
    List<String> directory,
    Future<void> Function(List<String> filePath, String json) process, {
    String? absoluteDirectoryPath,
  });
}

class LocalStorageException implements Exception {
  final String filePath;
  final Object? error;

  LocalStorageException(this.filePath, [this.error]);

  @override
  String toString() {
    return '$runtimeType($filePath, $error)';
  }
}

abstract class RemoteStorageException implements Exception {
  final String provider;
  final String filePath;

  RemoteStorageException(this.provider, this.filePath);

  @override
  String toString() {
    return '$runtimeType($provider, $filePath)';
  }
}

class RemoteStorageAuthenticationException extends RemoteStorageException {
  RemoteStorageAuthenticationException(super.provider, super.filePath);
}

class RemoteStorageOperationException extends RemoteStorageException {
  final Object error;

  RemoteStorageOperationException(super.provider, super.filePath, this.error);

  @override
  String toString() {
    return '$runtimeType($provider, $filePath, $error)';
  }
}

class RemoteStorageNetworkException extends RemoteStorageException {
  RemoteStorageNetworkException(super.provider, super.filePath);
}
