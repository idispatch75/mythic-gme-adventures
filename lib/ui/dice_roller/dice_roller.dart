import 'package:get/get.dart';
import 'package:mythic_gme_adventures/helpers/rx_list_extensions.dart';

import '../../helpers/utils.dart';
import '../../persisters/persister.dart';

class DiceRollerSettings {
  final int diceCount;
  final int faces;
  final int modifier;

  const DiceRollerSettings({
    required this.diceCount,
    required this.faces,
    required this.modifier,
  });

  Map<String, dynamic> toJson() => {
        'diceCount': diceCount,
        'faces': faces,
        'modifier': modifier,
      };

  DiceRollerSettings.fromJson(Map<String, dynamic> json)
      : this(
          diceCount: json['diceCount'],
          faces: json['faces'],
          modifier: json['modifier'],
        );
}

class DiceRoll {
  final int faces;
  final int modifier;
  final List<int> dieRolls;

  const DiceRoll({
    required this.faces,
    required this.modifier,
    required this.dieRolls,
  });

  Map<String, dynamic> toJson() => {
        'faces': faces,
        'modifier': modifier,
        'dieRolls': dieRolls,
      };

  DiceRoll.fromJson(Map<String, dynamic> json)
      : this(
          faces: json['faces'],
          modifier: json['modifier'],
          dieRolls: fromJsonValueList(json['dieRolls']),
        );
}

class DiceRollerService extends GetxService with SavableMixin {
  static const maxRolls = 4;

  final Rx<DiceRollerSettings> settings = const DiceRollerSettings(
    diceCount: 1,
    faces: 6,
    modifier: 0,
  ).obs;
  final RxList<DiceRoll> rollLog = <DiceRoll>[].obs;

  DiceRollerService();

  void incrementDiceCount() {
    setDiceCount(settings().diceCount + 1);
  }

  void decrementDiceCount() {
    setDiceCount(settings().diceCount - 1);
  }

  void setDiceCount(int count) {
    if (count > 0) {
      settings(DiceRollerSettings(
        diceCount: count,
        faces: settings().faces,
        modifier: settings().modifier,
      ));

      requestSave();
    }
  }

  void setFaces(int faces) {
    if (faces > 0) {
      settings(DiceRollerSettings(
        diceCount: settings().diceCount,
        faces: faces,
        modifier: settings().modifier,
      ));

      requestSave();
    }
  }

  void incrementModifier() {
    setModifier(settings().modifier + 1);
  }

  void decrementModifier() {
    setModifier(settings().modifier - 1);
  }

  void setModifier(int modifier) {
    settings(DiceRollerSettings(
      diceCount: settings().diceCount,
      faces: settings().faces,
      modifier: modifier,
    ));

    requestSave();
  }

  DiceRoll? roll() {
    final dieRolls =
        List.generate(settings().diceCount, (_) => rollDie(settings().faces));

    return _addRoll(DiceRoll(
      faces: settings().faces,
      modifier: settings().modifier,
      dieRolls: dieRolls,
    ));
  }

  DiceRoll? _addRoll(DiceRoll roll) {
    DiceRoll? removedRoll;

    if (rollLog.length >= maxRolls) {
      // make the update in one go to avoid unnecessary refreshes
      // and race conditions on the number of items when displaying the list
      rollLog.update((log) {
        log.add(roll);
        removedRoll = log.removeAt(0);
      });
    } else {
      rollLog.add(roll);
    }

    requestSave();

    return removedRoll;
  }

  Map<String, dynamic> toJson() => {
        'diceRoller': {
          'settings': settings.toJson(),
          'rollLog': rollLog.toJson(),
        },
      };

  DiceRollerService.fromJson(Map<String, dynamic> json) {
    final diceRoller = json['diceRoller'];

    if (diceRoller != null) {
      for (var item in fromJsonList(diceRoller['rollLog'], DiceRoll.fromJson)) {
        _addRoll(item);
      }

      settings.value = DiceRollerSettings.fromJson(diceRoller['settings']);
    }
  }
}
