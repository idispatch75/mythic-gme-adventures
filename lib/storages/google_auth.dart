import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/googleapis_auth.dart' as googleauth;
import 'package:http/http.dart' as http;
import 'package:loggy/loggy.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:window_manager/window_manager.dart';

class GoogleAuthService extends GetxService {
  final authManager = GetPlatform.isDesktop
      ? DesktopGoogleAuthManager()
      : MobileGoogleAuthManager() as GoogleAuthManager;
}

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

const String _scope = drive.DriveApi.driveFileScope;

class DesktopGoogleAuthManager
    with GoogleAuthLoggy
    implements GoogleAuthManager {
  static const _baseUrl =
      'https://mythic-gme-adventures-auth.azurewebsites.net/api/google';
  static const String _refreshTokenKey = 'refreshToken';

  HttpServer? _redirectServer;

  final _storage = const FlutterSecureStorage(
      aOptions: AndroidOptions(
        encryptedSharedPreferences: true,
        resetOnError: true,
      ),
      iOptions: IOSOptions(
        accessibility: KeychainAccessibility.first_unlock_this_device,
      ));

  _TokenCredentials? _credentials;

  @override
  Future<googleauth.AuthClient> getAuthClient() async {
    final credentials = await _acquireCredentials();

    final googleauth.AccessCredentials googleCredentials =
        googleauth.AccessCredentials(
      googleauth.AccessToken(
        'Bearer',
        credentials.accessToken,
        credentials.expiryDate,
      ),
      null,
      [_scope],
    );

    return googleauth.authenticatedClient(http.Client(), googleCredentials);
  }

  @override
  Future<void> clearAccessToken() {
    _credentials = null;
    return Future.value();
  }

  @override
  Future<void> signOut() {
    _credentials = null;

    return _storage.delete(key: _refreshTokenKey);
  }

  Future<_TokenCredentials> _acquireCredentials() async {
    var credentials = _credentials;

    // if the access token is valid, return it
    if (credentials != null &&
        credentials.expiryDate.isAfter(DateTime.timestamp())) {
      loggy.debug('Using valid access token');

      return credentials;
    }

    // if we have a refresh token, refresh
    final refreshToken =
        credentials?.refreshToken ?? await _storage.read(key: _refreshTokenKey);
    if (refreshToken != null) {
      loggy.debug('Refreshing token');

      credentials = await _refreshCredentials(refreshToken);
    }

    // if we still do not have a token, login
    credentials ??= await _login();

    await _storeCredentials(credentials);

    return credentials;
  }

  Future<_TokenCredentials?> _refreshCredentials(String refreshToken) async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/refresh?refresh_token=$refreshToken'));
      if (response.statusCode == 200) {
        final tokens = jsonDecode(response.body) as Map<String, dynamic>;
        return _TokenCredentials.fromResponse(tokens);
      } else {
        loggy.error('Failed to refresh token: ${response.statusCode}');
      }
    } on TimeoutException {
      throw GoogleSignInNetworkException();
    } on SocketException {
      throw GoogleSignInNetworkException();
    } catch (e) {
      loggy.error('Failed to refresh token', e);
    }

    return null;
  }

  Future<void> _storeCredentials(_TokenCredentials credentials) {
    _credentials = credentials;

    return _storage.write(
      key: _refreshTokenKey,
      value: credentials.refreshToken,
    );
  }

  Future<_TokenCredentials> _login() async {
    loggy.debug('Logging in');

    // start the local server
    await _redirectServer?.close();
    _redirectServer = await HttpServer.bind('localhost', 8099);

    // start the login process in the browser
    await _redirect(
        Uri.parse('$_baseUrl/login?scope=$_scope&forceConsent=true'));

    // wait for the process to finish
    final response = await _listen();

    // return the tokens
    final accessToken = _getAccessTokenFromResponse(response);
    if (accessToken != null) {
      return _TokenCredentials.fromResponse(response);
    }

    final error = response['error'];
    if (error != null) {
      throw GoogleSignInException(error);
    }

    throw GoogleSignInException(
        'Unknown response: ${response.entries.map((e) => '${e.key}=${e.value}').join(',')}');
  }

  /// Launches the URL in the browser
  Future<void> _redirect(Uri authorizationUrl) async {
    if (await canLaunchUrl(authorizationUrl)) {
      await launchUrl(authorizationUrl);
    } else {
      throw GoogleSignInException('Could not launch $authorizationUrl');
    }
  }

  /// Listens to the [_redirectServer]
  /// and returns the query parameters of the first request received by the server.
  Future<Map<String, String>> _listen() async {
    final request = await _redirectServer!.first;
    final params = request.uri.queryParameters;

    // bring the window to the front after successful login
    await windowManager.show();

    // show a simple message to the user
    request.response.statusCode = 200;
    request.response.headers.set('content-type', 'text/plain');

    if (_getAccessTokenFromResponse(params) != null) {
      request.response.writeln('Authenticated! You can close this tab.');
    } else {
      request.response
          .writeln('Authentication failed! You can close this tab.');
    }

    // close the server
    await request.response.close();
    await _redirectServer!.close();
    _redirectServer = null;

    return params;
  }

  String? _getAccessTokenFromResponse(Map<String, String> queryParameters) =>
      queryParameters['access_token'];
}

class MobileGoogleAuthManager
    with GoogleAuthLoggy
    implements GoogleAuthManager {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      _scope,
    ],
    forceCodeForRefreshToken: true,
  );

  @override
  Future<googleauth.AuthClient> getAuthClient() async {
    await _signIn();

    return (await _googleSignIn.authenticatedClient())!;
  }

  @override
  Future<void> clearAccessToken() {
    // nothing to do
    return Future.value();
  }

  @override
  Future<void> signOut() {
    return _googleSignIn.signOut();
  }

  Future<void> _signIn() async {
    final account = await _googleSignIn.signInSilently(suppressErrors: true);

    if (account == null) {
      try {
        await _googleSignIn.signIn();
      } on PlatformException catch (e) {
        loggy.error('Sign-in failed', e);

        switch (e.code) {
          case GoogleSignIn.kNetworkError:
            throw GoogleSignInNetworkException();
          default:
            throw GoogleSignInException(null, e);
        }
      } catch (e) {
        loggy.error('Sign-in failed', e);

        throw GoogleSignInException(null, e);
      }
    }
  }
}

class _TokenCredentials {
  final String accessToken;
  final String refreshToken;
  final DateTime expiryDate;

  _TokenCredentials({
    required this.accessToken,
    required this.refreshToken,
    required this.expiryDate,
  });

  _TokenCredentials.fromResponse(Map<String, dynamic> response)
      : this(
          accessToken: response['access_token'],
          refreshToken: response['refresh_token'],
          expiryDate: DateTime.fromMillisecondsSinceEpoch(
            int.parse(response['expiry_date']),
            isUtc: true,
          ),
        );
}

mixin GoogleAuthLoggy implements LoggyType {
  @override
  Loggy<GoogleAuthLoggy> get loggy => Loggy<GoogleAuthLoggy>('Google Auth');
}
