import 'package:get/get.dart';

import '../helpers/secure_storage.dart';
import 'google_auth.dart';
import 'google_auth_desktop.dart';
import 'google_auth_mobile.dart';

class GoogleAuthService extends GetxService {
  final GoogleAuthManager authManager = GetPlatform.isDesktop
      ? DesktopGoogleAuthManager(Get.find<SecureStorage>())
      : MobileGoogleAuthManager() as GoogleAuthManager;
}
