import 'package:get/get.dart';

import '../helpers/secure_storage.dart';
import 'google_auth.dart';
import 'google_auth_web.dart';

class GoogleAuthService extends GetxService {
  final GoogleAuthManager authManager = WebGoogleAuthManager(
    Get.find<SecureStorage>(),
  );
}
