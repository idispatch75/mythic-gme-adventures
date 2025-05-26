import 'package:get/get.dart';

import '../../helpers/json_utils.dart';
import '../../persisters/persister.dart';

class ChaosFactorService extends GetxService with SavableMixin {
  final RxInt chaosFactor;

  ChaosFactorService([int chaosFactor = 5]) : chaosFactor = chaosFactor.obs;

  void increment() {
    if (chaosFactor() < 9) {
      chaosFactor(chaosFactor() + 1);

      requestSave();
    }
  }

  void decrement() {
    if (chaosFactor() > 1) {
      chaosFactor(chaosFactor() - 1);

      requestSave();
    }
  }

  JsonObj toJson() => {
    'chaosFactor': chaosFactor(),
  };

  ChaosFactorService.fromJson(JsonObj json) : this(json['chaosFactor']);
}
