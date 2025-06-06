import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:loggy/loggy.dart';

import 'data_storage.dart';
import 'google_auth.dart';

class GoogleStorage extends DataStorage with GoogleStorageLoggy {
  static const _provider = 'Google Drive';

  final GoogleAuthManager _authManager;

  final Map<String, String> _fileIdCache = {};

  GoogleStorage(this._authManager);

  @override
  bool get isLocal => false;

  @override
  Future<String?> load(List<String> directory, String name) {
    final directoryPath = directory.join('/');

    return _performRequest((api) async {
      final folderId = await _getFolderId(
        api,
        directoryPath,
        createIfMissing: false,
      );
      final folderCacheKey = _getFolderCacheKey(directoryPath);

      if (folderId != null) {
        final fileId = await _getFileInFolder(
          api,
          folderId: folderId,
          fileName: name,
          folderCacheKey: folderCacheKey,
        );

        if (fileId != null) {
          return _getFileContent(api, fileId);
        }
      }

      return null;
    }, _getAppFilePath(directoryPath, name));
  }

  @override
  Future<void> save(List<String> directory, String name, String content) {
    final directoryPath = directory.join('/');

    return _performRequest((api) async {
      final folderId = (await _getFolderId(
        api,
        directoryPath,
        createIfMissing: true,
      ))!;
      final folderCacheKey = _getFolderCacheKey(directoryPath);

      final bytes = utf8.encoder.convert(content);
      final stream = Stream.value(List<int>.from(bytes));
      final media = drive.Media(stream, bytes.length);

      final existingFileId = await _getFileInFolder(
        api,
        folderId: folderId,
        fileName: name,
        folderCacheKey: folderCacheKey,
      );
      if (existingFileId == null) {
        loggy.debug('Creating file "$directoryPath/$name"');

        final newFileId = (await api.files.create(
          drive.File(
            name: name,
            parents: [folderId],
            mimeType: name.endsWith('.json') ? 'application/json' : null,
          ),
          uploadMedia: media,
        )).id!;

        _fileIdCache['$folderCacheKey/$name'] = newFileId;
      } else {
        loggy.debug('Updating file "$directoryPath/$name"');

        await api.files.update(
          drive.File(name: name),
          existingFileId,
          uploadMedia: media,
        );
      }
    }, _getAppFilePath(directoryPath, name));
  }

  @override
  Future<void> deleteDirectory(List<String> directory) async {
    final directoryPath = directory.join('/');

    final folderCacheKey = _getFolderCacheKey(directoryPath);

    await _performRequest((api) async {
      final folderId = await _getFolderId(
        api,
        directoryPath,
        createIfMissing: false,
      );

      if (folderId != null) {
        await api.files.delete(folderId);
      }
    }, _getAppDirectoryPath(directoryPath));

    // clear the cache AFTER, otherwise the cache is updated while looking up the folder
    // and then the folder is deleted and the cache still contains the deleted folder
    _fileIdCache.removeWhere((path, _) => path.startsWith(folderCacheKey));
  }

  @override
  Future<void> delete(List<String> directory, String name) {
    final directoryPath = directory.join('/');

    // remove whatever the result:
    // we don't need to be optimal and it may prevent caching problems
    final folderCacheKey = _getFolderCacheKey(directoryPath);
    final fileCacheKey = _getFileCacheKey(folderCacheKey, name);
    _fileIdCache.remove(fileCacheKey);

    return _performRequest((api) async {
      final folderId = await _getFolderId(
        api,
        directoryPath,
        createIfMissing: false,
      );

      if (folderId != null) {
        final fileId = await _getFileInFolder(
          api,
          folderId: folderId,
          fileName: name,
          folderCacheKey: folderCacheKey,
        );
        if (fileId != null) {
          await api.files.delete(fileId);
        }
      }
    }, _getAppFilePath(directoryPath, name));
  }

  @override
  Future<void> loadJsonFiles(
    List<String> directory,
    Future<void> Function(List<String> filePath, String json) process, {
    String? absoluteDirectoryPath,
  }) async {
    assert(
      absoluteDirectoryPath == null,
      'absoluteDirectoryPath not supported',
    );

    final directoryPath = directory.join('/');

    final startFolderId = await _performRequest((api) async {
      return _getFolderId(api, directoryPath, createIfMissing: false);
    }, _getAppFilePath(directoryPath, '/'));

    if (startFolderId != null) {
      await _loadJsonFiles(startFolderId, [], process);
    }
  }

  Future<void> _loadJsonFiles(
    String parentId,
    List<String> parentPath,
    Future<void> Function(List<String> filePath, String json) process,
  ) async {
    final List<drive.File>? files = await _performRequest((api) async {
      return (await api.files.list(
        q: "trashed = false and '$parentId' in parents",
      )).files;
    }, _getAppFilePath(parentPath.join('/'), ''));

    if (files != null) {
      // collect content requests
      final getContentRequests = <(List<String>, Future<String>)>[];
      for (drive.File file in files) {
        if (file.name != null && file.id != null) {
          final path = List<String>.from(parentPath)..add(file.name!);

          if (file.mimeType == _MimeTypes.folder) {
            await _loadJsonFiles(file.id!, path, process);
          } else if (file.name!.endsWith('.json')) {
            final request = _performRequest(
              (api) => _getFileContent(api, file.id!),
              _getAppFilePath(parentPath.join('/'), file.name!),
            );
            getContentRequests.add((path, request));
          }
        }
      }

      if (getContentRequests.isNotEmpty) {
        // read all contents at once
        final contents = await Future.wait(
          getContentRequests.map((e) => e.$2),
        );

        // process all contents
        for (var i = 0; i < getContentRequests.length; i++) {
          final content = contents[i];
          await process(getContentRequests[i].$1, content);
        }
      }
    }
  }

  Future<String?> _getFolderId(
    drive.DriveApi api,
    String directory, {
    required bool createIfMissing,
  }) async {
    final path = _getAppDirectoryPath(directory);
    final folderCacheKey = _getFolderCacheKey(directory);

    loggy.debug('Looking up folder "$path"');

    if (_fileIdCache.containsKey(folderCacheKey)) {
      return _fileIdCache[folderCacheKey];
    }

    final folderNames = path.split('/')..removeWhere((e) => e.isEmpty);

    // for each folder name
    String? parentId;
    String? folderId;
    for (var i = 0; i < folderNames.length; i++) {
      final folderName = folderNames[i];

      // get from cache
      final folderPath = folderNames.take(i + 1).join('/');
      final folderCacheKey = _getFolderCacheKey(folderPath, absolute: true);
      if (_fileIdCache.containsKey(folderCacheKey)) {
        folderId = _fileIdCache[folderCacheKey];

        // or query google
      } else {
        loggy.debug('Querying folder "$folderName"');

        folderId = (await api.files.list(
          q: _QueryHelper.fileQuery(
            folderName,
            mimeType: _MimeTypes.folder,
            parent: parentId,
          ),
        )).files?.firstOrNull?.id;
      }

      // create if missing
      if (folderId == null && createIfMissing) {
        loggy.debug('Creating folder "$folderName"');

        folderId = (await api.files.create(
          drive.File(
            name: folderName,
            mimeType: _MimeTypes.folder,
            parents: parentId == null ? [] : [parentId],
          ),
        )).id;
      }

      // continue if found, return null otherwise
      if (folderId != null) {
        _fileIdCache[folderCacheKey] = folderId;

        parentId = folderId;
      } else {
        return null;
      }
    }

    return folderId;
  }

  Future<String?> _getFileInFolder(
    drive.DriveApi api, {
    required String folderId,
    required String fileName,
    required String folderCacheKey,
  }) async {
    // get from cache
    final fileCacheKey = _getFileCacheKey(folderCacheKey, fileName);
    var fileId = _fileIdCache[fileCacheKey];

    // or query
    if (fileId == null) {
      loggy.debug(
        'Querying file "$fileName" in folder $folderId ($folderCacheKey)',
      );

      fileId = (await api.files.list(
        q: _QueryHelper.fileQuery(
          fileName,
          parent: folderId,
        ),
      )).files?.firstOrNull?.id;

      if (fileId != null) {
        _fileIdCache[fileCacheKey] = fileId;
      }
    }

    return fileId;
  }

  Future<String> _getFileContent(
    drive.DriveApi api,
    String fileId,
  ) async {
    final media =
        await api.files.get(
              fileId,
              downloadOptions: drive.DownloadOptions.fullMedia,
            )
            as drive.Media;

    return media.stream.transform(utf8.decoder).join();
  }

  Future<T> _performRequest<T>(
    Future<T> Function(drive.DriveApi) request,
    String filePath, {
    bool retryUnauthorized = true,
  }) async {
    try {
      final api = await _getDriveApi();
      return await request(api);
    } on AccessDeniedException catch (e) {
      if (retryUnauthorized) {
        loggy.debug('Access denied', e);

        await _authManager.clearAccessToken();

        return _performRequest(request, filePath, retryUnauthorized: false);
      } else {
        loggy.info('Failed to refresh access token', e);

        await _authManager.signOut();

        throw RemoteStorageAuthenticationException(_provider, filePath);
      }
    } on UserConsentException catch (e) {
      loggy.error('Missing consent', e);

      await _authManager.signOut();

      throw RemoteStorageAuthenticationException(_provider, filePath);
    } on GoogleSignInException catch (e) {
      loggy.error('Sign-in error', e);

      await _authManager.signOut();

      throw RemoteStorageAuthenticationException(_provider, filePath);
    } on GoogleSignInNetworkException catch (e) {
      loggy.error('Sign-in network error', e);

      throw RemoteStorageNetworkException(_provider, filePath);
    } on SocketException {
      throw RemoteStorageNetworkException(_provider, filePath);
    } on ServerRequestFailedException catch (e) {
      loggy.error('Unexpected error', e);
      // TODO analyze status code

      throw RemoteStorageOperationException(_provider, filePath, e);
    } catch (e) {
      loggy.error('Unexpected error', e);

      throw RemoteStorageOperationException(_provider, filePath, e);
    }
  }

  Future<drive.DriveApi> _getDriveApi() async {
    final client = await _authManager.getAuthClient();
    return drive.DriveApi(client);
  }

  String _getAppDirectoryPath(String directory) =>
      '${DataStorage.appDirectory}/$directory';

  String _getAppFilePath(String directory, String name) =>
      '${_getAppDirectoryPath(directory)}/$name';

  String _getFolderCacheKey(String directory, {bool absolute = false}) =>
      absolute ? directory : _getAppDirectoryPath(directory);

  String _getFileCacheKey(String folderCacheKey, String fileName) =>
      '$folderCacheKey/$fileName';
}

mixin GoogleStorageLoggy implements LoggyType {
  @override
  Loggy<GoogleStorageLoggy> get loggy =>
      Loggy<GoogleStorageLoggy>('Google Storage');
}

class _QueryHelper {
  /// Creates a query that searches for a particular file, name, and mimetype.
  static String fileQuery(
    String name, {

    /// The mime type to search for.
    String? mimeType,

    /// The ID of the parent folder
    String? parent,
  }) {
    return "name='$name' and trashed = false"
        " ${parent != null ? "and '$parent' in parents" : ""}"
        " ${mimeType != null ? "and mimeType='$mimeType'" : ""}";
  }
}

class _MimeTypes {
  /// Folders within Google Drive.
  static const folder = 'application/vnd.google-apps.folder';
}
