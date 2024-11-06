import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis_auth/googleapis_auth.dart';

import 'google_auth.dart';

class MobileGoogleAuthManager
    with GoogleAuthLoggy
    implements GoogleAuthManager {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [googleDriveScope],
    forceCodeForRefreshToken: true,
  );

  @override
  Future<AuthClient> getAuthClient() async {
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
