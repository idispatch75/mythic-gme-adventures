import 'data_storage.dart';

class LocalStorage extends DataStorage {
  @override
  Future<void> delete(List<String> directory, String name) {
    throw UnsupportedError('Implementation not found on this platform.');
  }

  @override
  bool get isLocal =>
      throw UnsupportedError('Implementation not found on this platform.');

  @override
  Future<String?> load(List<String> directory, String name) {
    throw UnsupportedError('Implementation not found on this platform.');
  }

  @override
  Future<void> loadJsonFiles(
    List<String> directory,
    Future<void> Function(List<String> filePath, String json) process, {
    String? absoluteDirectoryPath,
  }) {
    throw UnsupportedError('Implementation not found on this platform.');
  }

  @override
  Future<void> save(List<String> directory, String name, String content) {
    throw UnsupportedError('Implementation not found on this platform.');
  }

  static Future<String> getDefaultRootDirectoryPath() {
    throw UnsupportedError('Implementation not found on this platform.');
  }
}
