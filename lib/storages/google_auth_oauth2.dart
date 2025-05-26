import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:googleapis_auth/googleapis_auth.dart' as googleauth;
import 'package:http/http.dart' as http;

import '../helpers/json_utils.dart';
import '../helpers/secure_storage.dart';
import 'google_auth.dart';

abstract class OAuth2GoogleAuthManager
    with GoogleAuthLoggy
    implements GoogleAuthManager {
  static const preferenceKeys = [
    _refreshTokenKey,
  ];

  static const baseUrl =
      'https://mythic-gme-adventures-auth.azurewebsites.net/api/google';
  static const String _refreshTokenKey = 'refreshToken';

  final SecureStorage _storage;

  _TokenCredentials? _credentials;

  OAuth2GoogleAuthManager(this._storage);

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
          [googleDriveScope],
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

    return _storage.delete(_refreshTokenKey);
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
        credentials?.refreshToken ?? await _storage.read(_refreshTokenKey);
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
      final response = await http.get(
        Uri.parse(
          '$baseUrl/refresh?refresh_token=${Uri.encodeComponent(refreshToken)}',
        ),
      );
      if (response.statusCode == 200) {
        final tokens = jsonDecode(response.body) as JsonObj;
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
      _refreshTokenKey,
      credentials.refreshToken,
    );
  }

  Future<Map<String, String>> startLogin();

  Future<_TokenCredentials> _login() async {
    loggy.debug('Logging in');

    // login and get the oauth response
    final response = await startLogin();

    // return the tokens
    final accessToken = response['access_token'];
    if (accessToken != null) {
      return _TokenCredentials.fromResponse(response);
    }

    final error = response['error'];
    final errorDescription = response['error_description'];
    if (error != null) {
      throw GoogleSignInException(error, errorDescription);
    }

    throw GoogleSignInException(
      'Unknown response: ${response.entries.map((e) => '${e.key}=${e.value}').join(',')}',
    );
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
