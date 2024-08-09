import 'package:get/get.dart';
import 'package:rxdart/rxdart.dart' as rx;

import '../../helpers/rx_list_extensions.dart';
import '../../helpers/utils.dart';
import '../../persisters/persister.dart';
import '../fate_chart/fate_chart.dart';
import '../random_events/random_event.dart';

sealed class RollEntry {
  final int timestamp;

  const RollEntry({
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'runtimeType': runtimeType.toString(),
        'timestamp': timestamp,
      };

  factory RollEntry.fromJson(Map<String, dynamic> json) =>
      switch (json['runtimeType']) {
        'FateChartRoll' => FateChartRoll.fromJson(json),
        'RandomEventRoll' => RandomEventRoll.fromJson(json),
        'MeaningTableRoll' => MeaningTableRoll.fromJson(json),
        'GenericRoll' => GenericRoll.fromJson(json),
        _ => GenericRoll(
            title: 'unknown',
            value: 'unknown',
            dieRoll: 0,
            timestamp: json['timestamp'],
          ),
      };
}

class FateChartRoll extends RollEntry {
  final Probability probability;
  final int chaosFactor;
  final int dieRoll;
  final FateChartRollOutcome outcome;
  final bool hasEvent;

  const FateChartRoll({
    required this.probability,
    required this.chaosFactor,
    required this.dieRoll,
    required this.outcome,
    required this.hasEvent,
    required super.timestamp,
  });

  @override
  Map<String, dynamic> toJson() => super.toJson()
    ..addAll({
      'probability': probability,
      'chaosFactor': chaosFactor,
      'dieRoll': dieRoll,
      'outcome': outcome.name,
      'hasEvent': hasEvent,
    });

  FateChartRoll.fromJson(Map<String, dynamic> json)
      : this(
          probability: Probability.fromJson(json['probability']),
          chaosFactor: json['chaosFactor'],
          dieRoll: json['dieRoll'],
          outcome: switch (json['outcome']) {
            'yes' => FateChartRollOutcome.yes,
            'extremeYes' => FateChartRollOutcome.extremeYes,
            'no' => FateChartRollOutcome.no,
            'extremeNo' => FateChartRollOutcome.extremeNo,
            _ => FateChartRollOutcome.yes,
          },
          hasEvent: json['hasEvent'],
          timestamp: json['timestamp'],
        );
}

class RandomEventRoll extends RollEntry {
  final RandomEventFocus focus;
  final int dieRoll;

  const RandomEventRoll({
    required this.focus,
    required this.dieRoll,
    required super.timestamp,
  });

  @override
  Map<String, dynamic> toJson() => super.toJson()
    ..addAll({
      'focus': focus,
      'dieRoll': dieRoll,
    });

  RandomEventRoll.fromJson(Map<String, dynamic> json)
      : this(
          focus: RandomEventFocus.fromJson(json['focus']),
          dieRoll: json['dieRoll'],
          timestamp: json['timestamp'],
        );
}

class MeaningTableRoll extends RollEntry {
  final String tableId;
  final List<MeaningTableSubRoll> results;

  const MeaningTableRoll({
    required this.tableId,
    required this.results,
    required super.timestamp,
  });

  @override
  Map<String, dynamic> toJson() => super.toJson()
    ..addAll({
      'tableId': tableId,
      'results': results,
    });

  MeaningTableRoll.fromJson(Map<String, dynamic> json)
      : this(
          tableId: json['tableId'],
          results: fromJsonList(json['results'], MeaningTableSubRoll.fromJson),
          timestamp: json['timestamp'],
        );
}

class MeaningTableSubRoll {
  final String entryId;
  final int dieRoll;

  const MeaningTableSubRoll({
    required this.entryId,
    required this.dieRoll,
  });

  Map<String, dynamic> toJson() => {
        'entryId': entryId,
        'dieRoll': dieRoll,
      };

  MeaningTableSubRoll.fromJson(Map<String, dynamic> json)
      : this(
          entryId: json['entryId'],
          dieRoll: json['dieRoll'],
        );
}

class GenericRoll extends RollEntry {
  final String title;
  final String value;
  final int dieRoll;

  const GenericRoll({
    required this.title,
    required this.value,
    required this.dieRoll,
    required super.timestamp,
  });

  @override
  Map<String, dynamic> toJson() => super.toJson()
    ..addAll({
      'title': title,
      'value': value,
      'dieRoll': dieRoll,
    });

  GenericRoll.fromJson(Map<String, dynamic> json)
      : this(
          title: json['title'],
          value: json['value'],
          dieRoll: json['dieRoll'],
          timestamp: json['timestamp'],
        );
}

class RollLogService extends GetxService with SavableMixin {
  final rollLog = <RollEntry>[].obs;

  late Stream<List<RollLogUpdate>> rollUpdates;
  final _rollUpdates = rx.PublishSubject<RollLogUpdate>();

  RollLogService() {
    _init();
  }

  void _init() {
    const dummyRoll = GenericRoll(
      title: '',
      value: '',
      dieRoll: 0,
      timestamp: 0,
    );

    rollUpdates = _rollUpdates.buffer(_rollUpdates
        .startWith(RollLogUpdate(newRoll: dummyRoll, removedRoll: null))
        .debounceTime(const Duration(milliseconds: 200)));
  }

  FateChartRoll addFateChartRoll({
    required Probability probability,
    required int chaosFactor,
    required int dieRoll,
    required FateChartRollOutcome outcome,
    bool skipEvent = false,
  }) {
    var hasEvent = false;
    if (dieRoll > 10 && !skipEvent) {
      final tens = dieRoll ~/ 10;
      final units = dieRoll % 10;

      hasEvent = tens == units && units <= chaosFactor;
    }

    final roll = FateChartRoll(
      probability: probability,
      chaosFactor: chaosFactor,
      dieRoll: dieRoll,
      outcome: outcome,
      hasEvent: hasEvent,
      timestamp: DateTime.timestamp().millisecondsSinceEpoch,
    );
    _addRollLogEntry(roll);

    return roll;
  }

  void addRandomEventRoll({
    required RandomEventFocus focus,
    required int dieRoll,
  }) {
    _addRollLogEntry(RandomEventRoll(
      focus: focus,
      dieRoll: dieRoll,
      timestamp: DateTime.timestamp().millisecondsSinceEpoch,
    ));
  }

  void addMeaningTableRoll({
    required String tableId,
    required List<MeaningTableSubRoll> results,
  }) {
    _addRollLogEntry(MeaningTableRoll(
      tableId: tableId,
      results: results,
      timestamp: DateTime.timestamp().millisecondsSinceEpoch,
    ));
  }

  void addGenericRoll({
    required String title,
    required String value,
    required int dieRoll,
  }) {
    _addRollLogEntry(GenericRoll(
      title: title,
      value: value,
      dieRoll: dieRoll,
      timestamp: DateTime.timestamp().millisecondsSinceEpoch,
    ));
  }

  void _addRollLogEntry(RollEntry entry) {
    RollEntry? removedEntry;
    if (rollLog.length >= 50) {
      // make the update in one go to avoid unnecessary refreshes
      // and race conditions on the number of items when displaying the list
      rollLog.update((log) {
        log.add(entry);
        removedEntry = log.removeAt(0);
      });
    } else {
      rollLog.add(entry);
    }

    _rollUpdates.add(RollLogUpdate(
      newRoll: entry,
      removedRoll: removedEntry,
    ));

    requestSave();
  }

  Map<String, dynamic> toJson() => {
        'rollLog': rollLog,
      };

  RollLogService.fromJson(Map<String, dynamic> json) {
    for (var item in fromJsonList(json['rollLog'], RollEntry.fromJson)) {
      _addRollLogEntry(item);
    }

    _init();
  }
}

class RollLogUpdate {
  final RollEntry newRoll;
  final RollEntry? removedRoll;

  RollLogUpdate({
    required this.newRoll,
    required this.removedRoll,
  });
}
