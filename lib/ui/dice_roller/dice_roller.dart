import 'package:get/get.dart';
import 'package:rxdart/rxdart.dart' as rx;

import '../../helpers/json_utils.dart';
import '../../helpers/rx_list_extensions.dart';
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

  JsonObj toJson() => {
        'diceCount': diceCount,
        'faces': faces,
        'modifier': modifier,
      };

  DiceRollerSettings.fromJson(JsonObj json)
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

  JsonObj toJson() => {
        'faces': faces,
        'modifier': modifier,
        'dieRolls': dieRolls,
      };

  DiceRoll.fromJson(JsonObj json)
      : this(
          faces: json['faces'],
          modifier: json['modifier'],
          dieRolls: fromJsonValueList(json['dieRolls']),
        );
}

class DiceRollerService extends GetxService with SavableMixin {
  static const _listedFaces = [2, 3, 4, 6, 8, 10, 12, 20, 100];

  final Rx<DiceRollerSettings> settings = const DiceRollerSettings(
    diceCount: 1,
    faces: 6,
    modifier: 0,
  ).obs;

  final RxList<DiceRoll> rollLog = <DiceRoll>[].obs;

  late Stream<List<DiceRollerLogUpdate>> rollUpdates;
  final _rollUpdates = rx.PublishSubject<DiceRollerLogUpdate>();

  DiceRollerService() {
    _init();
  }

  void _init() {
    const dummyRoll = DiceRoll(faces: 1, modifier: 0, dieRolls: []);

    rollUpdates = _rollUpdates.buffer(_rollUpdates
        .startWith(
            const DiceRollerLogAdd(newRoll: dummyRoll, removedRoll: null))
        .debounceTime(const Duration(milliseconds: 200)));
  }

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

  void incrementFaces() {
    for (var i = 0; i < _listedFaces.length; i++) {
      final faces = _listedFaces[i];

      if (faces > settings().faces) {
        setFaces(faces);
        return;
      }
    }
  }

  void decrementFaces() {
    for (var i = _listedFaces.length - 1; i >= 0; i--) {
      final faces = _listedFaces[i];

      if (faces < settings().faces) {
        setFaces(faces);
        return;
      }
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

  void roll() {
    _roll(settings());
  }

  void clear() {
    rollLog.clear();

    _rollUpdates.add(const DiceRollerLogClear());

    requestSave();
  }

  void rollExisting(DiceRoll roll) {
    _roll(DiceRollerSettings(
      diceCount: roll.dieRolls.length,
      faces: roll.faces,
      modifier: roll.modifier,
    ));
  }

  void _roll(DiceRollerSettings settings) {
    final dieRolls =
        List.generate(settings.diceCount, (_) => rollDie(settings.faces));

    _addRoll(DiceRoll(
      faces: settings.faces,
      modifier: settings.modifier,
      dieRolls: dieRolls,
    ));
  }

  void _addRoll(DiceRoll roll) {
    DiceRoll? removedRoll;

    if (rollLog.length >= 20) {
      // make the update in one go to avoid unnecessary refreshes
      // and race conditions on the number of items when displaying the list
      rollLog.update((log) {
        log.add(roll);
        removedRoll = log.removeAt(0);
      });
    } else {
      rollLog.add(roll);
    }

    _rollUpdates.add(DiceRollerLogAdd(
      newRoll: roll,
      removedRoll: removedRoll,
    ));

    requestSave();
  }

  JsonObj toJson() => {
        'diceRoller': {
          'settings': settings.toJson(),
          'rollLog': rollLog.toJson(),
        },
      };

  DiceRollerService.fromJson(JsonObj json) {
    final JsonObj? diceRoller = json['diceRoller'];

    if (diceRoller != null) {
      for (var item in fromJsonList(diceRoller['rollLog'], DiceRoll.fromJson)) {
        _addRoll(item);
      }

      settings.value = DiceRollerSettings.fromJson(diceRoller['settings']);
    }

    _init();
  }
}

sealed class DiceRollerLogUpdate {
  const DiceRollerLogUpdate();
}

class DiceRollerLogAdd extends DiceRollerLogUpdate {
  final DiceRoll newRoll;
  final DiceRoll? removedRoll;

  const DiceRollerLogAdd({
    required this.newRoll,
    required this.removedRoll,
  });
}

class DiceRollerLogClear extends DiceRollerLogUpdate {
  const DiceRollerLogClear();
}
