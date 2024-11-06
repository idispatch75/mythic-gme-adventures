import 'dart:async';

import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/googleapis_auth.dart' as googleauth;
import 'package:loggy/loggy.dart';

abstract class GoogleAuthManager {
  Future<googleauth.AuthClient> getAuthClient();
  Future<void> clearAccessToken();
  Future<void> signOut();
}

class GoogleSignInException implements Exception {
  final String? message;
  final Object? error;

  GoogleSignInException([this.message, this.error]);

  @override
  String toString() {
    return [
      message ?? runtimeType.toString(),
      if (error != null) error.toString(),
    ].join(' - ');
  }
}

class GoogleSignInNetworkException implements Exception {}

const String googleDriveScope = drive.DriveApi.driveFileScope;

mixin GoogleAuthLoggy implements LoggyType {
  @override
  Loggy<GoogleAuthLoggy> get loggy => Loggy<GoogleAuthLoggy>('Google Auth');
}
