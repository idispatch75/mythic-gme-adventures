import 'package:get/get.dart';

import '../../helpers/json_utils.dart';
import '../../persisters/persister.dart';

class ChaosFactorService extends GetxService with SavableMixin {
  final RxInt chaosFactor;
  final RxBool isCombatClash;
  final RxInt fateChartFactor;

  ChaosFactorService([int chaosFactor = 5])
    : chaosFactor = chaosFactor.obs,
      isCombatClash = false.obs,
      fateChartFactor = chaosFactor.obs {
    this.chaosFactor.listen(_setFateChartFactor);
    isCombatClash.listen((_) => _setFateChartFactor(this.chaosFactor()));
  }

  void _setFateChartFactor(int value) {
    if (isCombatClash()) {
      fateChartFactor(5);
    } else {
      fateChartFactor(value);
    }
  }

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
