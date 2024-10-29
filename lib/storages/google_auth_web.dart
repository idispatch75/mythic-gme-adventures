import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:web/web.dart';

import 'google_auth.dart';

class WebGoogleAuthManager extends OAuth2GoogleAuthManager {
  @override
  Future<Map<String, String>> startLogin() async {
    final location = Uri.parse(window.location.href);
    final redirectUri =
        '${location.origin}${location.path}${location.path.endsWith('/') ? '' : '/'}auth.html';

    final responseUrl = await FlutterWebAuth2.authenticate(
      url:
          '${OAuth2GoogleAuthManager.baseUrl}/login?scope=$googleDriveScope&forceConsent=true&client_redirect_uri=${Uri.encodeComponent(redirectUri)}',
      callbackUrlScheme: 'https',
      options: const FlutterWebAuth2Options(
        intentFlags: ephemeralIntentFlags,
      ),
    );

    final response = Uri.parse(responseUrl).queryParameters;

    return response;
  }
}
