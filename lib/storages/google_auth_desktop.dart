import 'dart:io';

import 'package:url_launcher/url_launcher.dart';
import 'package:window_manager/window_manager.dart';

import 'google_auth.dart';

class DesktopGoogleAuthManager extends OAuth2GoogleAuthManager {
  HttpServer? _redirectServer;

  @override
  Future<Map<String, String>> startLogin() async {
    // start the local server
    const port = 8099;
    await _redirectServer?.close();
    _redirectServer = await HttpServer.bind('localhost', port);

    // start the login process in the browser
    await _redirect(Uri.parse(
        '${OAuth2GoogleAuthManager.baseUrl}/login?scope=$googleDriveScope&forceConsent=true'
        '&client_redirect_uri=${Uri.encodeComponent('http://localhost:$port')}'));

    // wait for the process to finish
    final response = await _listen();

    return response;
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

    if (params['access_token'] != null) {
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
}



// class DesktopGoogleAuthManager
//     with GoogleAuthLoggy
//     implements GoogleAuthManager {
//   static const _baseUrl =
//       'https://mythic-gme-adventures-auth.azurewebsites.net/api/google';
//   static const String _refreshTokenKey = 'refreshToken';

//   HttpServer? _redirectServer;

//   final _storage = const FlutterSecureStorage(
//       aOptions: AndroidOptions(
//         encryptedSharedPreferences: true,
//         resetOnError: true,
//       ),
//       iOptions: IOSOptions(
//         accessibility: KeychainAccessibility.first_unlock_this_device,
//       ));

//   _TokenCredentials? _credentials;

//   @override
//   Future<googleauth.AuthClient> getAuthClient() async {
//     final credentials = await _acquireCredentials();

//     final googleauth.AccessCredentials googleCredentials =
//         googleauth.AccessCredentials(
//       googleauth.AccessToken(
//         'Bearer',
//         credentials.accessToken,
//         credentials.expiryDate,
//       ),
//       null,
//       [_scope],
//     );

//     return googleauth.authenticatedClient(http.Client(), googleCredentials);
//   }

//   @override
//   Future<void> clearAccessToken() {
//     _credentials = null;
//     return Future.value();
//   }

//   @override
//   Future<void> signOut() {
//     _credentials = null;

//     return _storage.delete(key: _refreshTokenKey);
//   }

//   Future<_TokenCredentials> _acquireCredentials() async {
//     var credentials = _credentials;

//     // if the access token is valid, return it
//     if (credentials != null &&
//         credentials.expiryDate.isAfter(DateTime.timestamp())) {
//       loggy.debug('Using valid access token');

//       return credentials;
//     }

//     // if we have a refresh token, refresh
//     final refreshToken =
//         credentials?.refreshToken ?? await _storage.read(key: _refreshTokenKey);
//     if (refreshToken != null) {
//       loggy.debug('Refreshing token');

//       credentials = await _refreshCredentials(refreshToken);
//     }

//     // if we still do not have a token, login
//     credentials ??= await _login();

//     await _storeCredentials(credentials);

//     return credentials;
//   }

//   Future<_TokenCredentials?> _refreshCredentials(String refreshToken) async {
//     try {
//       final response = await http
//           .get(Uri.parse('$_baseUrl/refresh?refresh_token=$refreshToken'));
//       if (response.statusCode == 200) {
//         final tokens = jsonDecode(response.body) as JsonObj;
//         return _TokenCredentials.fromResponse(tokens);
//       } else {
//         loggy.error('Failed to refresh token: ${response.statusCode}');
//       }
//     } on TimeoutException {
//       throw GoogleSignInNetworkException();
//     } on SocketException {
//       throw GoogleSignInNetworkException();
//     } catch (e) {
//       loggy.error('Failed to refresh token', e);
//     }

//     return null;
//   }

//   Future<void> _storeCredentials(_TokenCredentials credentials) {
//     _credentials = credentials;

//     return _storage.write(
//       key: _refreshTokenKey,
//       value: credentials.refreshToken,
//     );
//   }

//   Future<_TokenCredentials> _login() async {
//     loggy.debug('Logging in');

//     // start the local server
//     const port = 8099;
//     await _redirectServer?.close();
//     _redirectServer = await HttpServer.bind('localhost', port);

//     // start the login process in the browser
//     await _redirect(Uri.parse(
//         '$_baseUrl/login?scope=$_scope&forceConsent=true&client_redirect_uri=${Uri.encodeComponent('http://localhost:$port')}'));

//     // wait for the process to finish
//     final response = await _listen();

//     // return the tokens
//     final accessToken = _getAccessTokenFromResponse(response);
//     if (accessToken != null) {
//       return _TokenCredentials.fromResponse(response);
//     }

//     final error = response['error'];
//     if (error != null) {
//       throw GoogleSignInException(error);
//     }

//     throw GoogleSignInException(
//         'Unknown response: ${response.entries.map((e) => '${e.key}=${e.value}').join(',')}');
//   }

//   /// Launches the URL in the browser
//   Future<void> _redirect(Uri authorizationUrl) async {
//     if (await canLaunchUrl(authorizationUrl)) {
//       await launchUrl(authorizationUrl);
//     } else {
//       throw GoogleSignInException('Could not launch $authorizationUrl');
//     }
//   }

//   /// Listens to the [_redirectServer]
//   /// and returns the query parameters of the first request received by the server.
//   Future<Map<String, String>> _listen() async {
//     final request = await _redirectServer!.first;
//     final params = request.uri.queryParameters;

//     // bring the window to the front after successful login
//     await windowManager.show();

//     // show a simple message to the user
//     request.response.statusCode = 200;
//     request.response.headers.set('content-type', 'text/plain');

//     if (_getAccessTokenFromResponse(params) != null) {
//       request.response.writeln('Authenticated! You can close this tab.');
//     } else {
//       request.response
//           .writeln('Authentication failed! You can close this tab.');
//     }

//     // close the server
//     await request.response.close();
//     await _redirectServer!.close();
//     _redirectServer = null;

//     return params;
//   }

//   String? _getAccessTokenFromResponse(Map<String, String> queryParameters) =>
//       queryParameters['access_token'];
// }
