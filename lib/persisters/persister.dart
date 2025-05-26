import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:rxdart/rxdart.dart';

import '../storages/data_storage.dart';
import '../storages/google_auth_service.dart';
import '../storages/google_storage.dart';
import '../storages/local_storage.dart';
import '../ui/preferences/preferences.dart';

abstract class PersisterService<TPersister> extends GetxService {
  @protected
  TPersister? localPersister;

  @protected
  TPersister? remotePersister;

  StreamSubscription<bool>? _enableLocalStorageSubscription;
  StreamSubscription<bool>? _enableGoogleStorageSubscription;

  @protected
  TPersister createPersister(DataStorage storage);

  @override
  void onInit() {
    super.onInit();

    final preferences = Get.find<LocalPreferencesService>();
    _enableLocalStorageSubscription = preferences.enableLocalStorage
        .listenAndPump((enable) {
          if (enable) {
            localPersister = createPersister(LocalStorage());
          } else {
            localPersister = null;
          }
        });

    _enableGoogleStorageSubscription = preferences.enableGoogleStorage
        .listenAndPump((enable) {
          if (enable) {
            final authManager = Get.find<GoogleAuthService>().authManager;
            remotePersister = createPersister(GoogleStorage(authManager));
          } else {
            preferences.enableLocalStorage(true);

            remotePersister = null;
          }
        });
  }

  @override
  void onClose() {
    _enableLocalStorageSubscription?.cancel();
    _enableGoogleStorageSubscription?.cancel();

    super.onClose();
  }
}

mixin SavableMixin {
  final _subject = PublishSubject<bool>();

  Stream<bool> get saveRequests => _subject.stream;

  void requestSave() {
    _subject.add(true);
  }
}

class SaveResult {
  final bool isSuccess;
  final Object? error;

  SaveResult.success() : isSuccess = true, error = null;

  SaveResult.error(this.error) : isSuccess = false;
}

class UnsupportedSchemaVersionException implements Exception {
  final String fileName;

  const UnsupportedSchemaVersionException({required this.fileName});

  @override
  String toString() => 'Unsupported schema version for $fileName';
}
