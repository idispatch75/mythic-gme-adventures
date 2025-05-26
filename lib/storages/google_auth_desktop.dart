import 'dart:io';

import 'package:url_launcher/url_launcher.dart';
import 'package:window_manager/window_manager.dart';

import 'google_auth.dart';
import 'google_auth_oauth2.dart';

class DesktopGoogleAuthManager extends OAuth2GoogleAuthManager {
  HttpServer? _redirectServer;

  DesktopGoogleAuthManager(super.storage);

  @override
  Future<Map<String, String>> startLogin() async {
    // start the local server
    const port = 8099;
    await _redirectServer?.close();
    _redirectServer = await HttpServer.bind('localhost', port);

    // start the login process in the browser
    await _redirect(
      Uri.parse(
        '${OAuth2GoogleAuthManager.baseUrl}/login?scope=$googleDriveScope&forceConsent=true'
        '&client_redirect_uri=${Uri.encodeComponent('http://localhost:$port')}',
      ),
    );

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
      request.response.writeln(
        'Authentication failed! You can close this tab.',
      );
    }

    // close the server
    await request.response.close();
    await _redirectServer!.close();
    _redirectServer = null;

    return params;
  }
}
