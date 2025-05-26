import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rxdart/rxdart.dart' as rx;

import '../../helpers/rx_list_extensions.dart';
import '../../helpers/utils.dart';
import '../fate_chart/fate_chart.dart';
import '../preferences/preferences.dart';
import '../roll_log/roll_log.dart';
import 'thread.dart';

class ThreadController extends GetxController {
  final Thread thread;

  var needsFlashpoint = false.obs;

  final _availablePhases = List.generate(4, (_) => ThreadProgressPhase().obs);

  ThreadController(this.thread) {
    needsFlashpoint.bindStream(
      rx.CombineLatestStream(
        [
          thread.progress.stream.startWith(thread.progress()),
          ..._availablePhases.map((e) => e.stream.startWith(e.value)),
        ],
        (values) {
          final progress = values[0] as int;
          final phases = values.sublist(1).cast<ThreadProgressPhase>().toList();

          final activePhase = _getActivePhaseIndex();
          final activePhaseProgress = max(progress - 1, 0) % 5 + 1;
          final phaseToCheck = activePhaseProgress >= 4
              ? phases[activePhase]
              : activePhase > 0
              ? phases[activePhase - 1]
              : null;

          return phaseToCheck != null && !phaseToCheck.hasFlashpoint;
        },
      ),
    );
  }

  void track(int nbPhases) {
    // update the number of phases in the thread
    thread.phases.replaceAll(_availablePhases.sublist(0, nbPhases));

    // update its progress
    thread.progress.value = min(thread.progress(), nbPhases * 5);

    // reset the phases that are no more used
    for (int i = thread.phases.length; i < _availablePhases.length; i++) {
      final phase = _availablePhases[i];
      if (phase().hasFlashpoint) {
        phase.update((phase) {
          phase!.hasFlashpoint = false;
        });
        break;
      }
    }

    // mark as tracked
    thread.isTracked(true);

    _service.requestSave();
  }

  void untrack() {
    thread.isTracked(false);

    _service.requestSave();
  }

  void addProgress(int progress) {
    final maxProgress = thread.phases.length * 5;
    thread.progress.value = min(thread.progress() + progress, maxProgress);

    _service.requestSave();
  }

  void removeProgress(int progress) {
    final previousPhase = _getActivePhaseIndex();

    thread.progress.value = max(thread.progress() - progress, 0);

    final newPhase = _getActivePhaseIndex();
    if (previousPhase != newPhase) {
      thread.phases[previousPhase].update((phase) {
        phase!.hasFlashpoint = false;
      });
    }

    _service.requestSave();
  }

  void addFlashpoint([int progress = 0]) {
    if (progress > 0) {
      addProgress(progress);
    }

    for (int i = 0; i <= _getActivePhaseIndex(); i++) {
      final phase = thread.phases[i];
      if (!phase().hasFlashpoint) {
        phase.update((phase) {
          phase!.hasFlashpoint = true;
        });
        break;
      }
    }

    _service.requestSave();
  }

  void removeFlashpoint() {
    for (int i = _getActivePhaseIndex(); i >= 0; i--) {
      final phase = thread.phases[i];
      if (phase().hasFlashpoint) {
        phase.update((phase) {
          phase!.hasFlashpoint = false;
        });
        break;
      }
    }

    _service.requestSave();
  }

  Future<void> rollDiscovery() async {
    final probability = await Get.dialog<Probability>(
      SimpleDialog(
        title: const Text('Probability'),
        children:
            [
                  FiftyFifty.instance,
                  Likely.instance,
                  VeryLikely.instance,
                  NearlyCertain.instance,
                  Certain.instance,
                ]
                .map(
                  (e) => SimpleDialogOption(
                    onPressed: () {
                      Get.back(result: e);
                    },
                    child: Text(e.text),
                  ),
                )
                .toList(),
      ),
      barrierDismissible: true,
    );

    if (probability != null) {
      if (getPhysicalDiceModeEnabled) {
        _showDiscoveryLookup(Get.overlayContext!, probability);
      } else {
        final fateRoll = Get.find<FateChartService>().roll(
          probability,
          skipEvents: true,
        );
        if (fateRoll.outcome == FateChartRollOutcome.yes) {
          _rollDiscoveryCheck();
        } else if (fateRoll.outcome == FateChartRollOutcome.extremeYes) {
          _rollDiscoveryCheck();
          _rollDiscoveryCheck();
        }
      }
    }
  }

  void _rollDiscoveryCheck() {
    final dieRoll = rollDie(10 + thread.progress());

    String message;
    if (dieRoll < 10) {
      message = 'Progress +2';
      addProgress(2);
    } else if (dieRoll == 10) {
      message = 'Flashpoint +2';
      addFlashpoint(2);
    } else if (dieRoll < 15) {
      message = 'Track +1';
      addProgress(1);
    } else if (dieRoll < 18) {
      message = 'Progress +3';
      addProgress(3);
    } else if (dieRoll == 18) {
      message = 'Flashpoint +3';
      addFlashpoint(3);
    } else if (dieRoll == 19) {
      message = 'Track +2';
      addProgress(2);
    } else if (dieRoll < 25) {
      message = 'Strengthen Progress +1';
      addProgress(1);
    } else {
      message = 'Strengthen Progress +2';
      addProgress(2);
    }

    Get.find<RollLogService>().addGenericRoll(
      title: 'Thread Discovery Check',
      value: message,
      dieRoll: dieRoll,
    );
  }

  void _showDiscoveryLookup(BuildContext context, Probability probability) {
    Get.find<FateChartService>().showFateChartLookup(
      context,
      probability,
      thread: thread,
    );
  }

  int _getActivePhaseIndex() {
    return max(thread.progress() - 1, 0) ~/ 5;
  }

  ThreadsService get _service => Get.find<ThreadsService>();
}
