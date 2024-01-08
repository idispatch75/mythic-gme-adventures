import 'package:get/get.dart';

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

  Map<String, dynamic> toJson() => {
        'chaosFactor': chaosFactor(),
      };

  ChaosFactorService.fromJson(Map<String, dynamic> json)
      : this(json['chaosFactor']);
}
