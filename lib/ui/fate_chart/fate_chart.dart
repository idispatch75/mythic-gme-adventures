import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../helpers/utils.dart';
import '../adventure/adventure.dart';
import '../chaos_factor/chaos_factor.dart';
import '../preferences/preferences.dart';
import '../random_events/random_event.dart';
import '../roll_log/roll_log.dart';
import '../rules_help/rules_help_button.dart';
import '../rules_help/rules_help_view.dart';
import '../styles.dart';
import '../threads/thread.dart';
import '../widgets/header.dart';
import 'fate_chart_lookup_view.dart';
import 'fate_chart_view.dart';

enum FateChartType {
  standard,
  mid,
  low,
  none,
}

String fateChartTypeToJson(FateChartType fateChartType) => fateChartType.name;

FateChartType fateChartTypeFromJson(String name) => switch (name) {
  'standard' => FateChartType.standard,
  'mid' => FateChartType.mid,
  'low' => FateChartType.low,
  'none' => FateChartType.none,
  _ => FateChartType.standard,
};

sealed class Probability {
  final String text;

  static const certain = Certain.instance;
  static const nearlyCertain = NearlyCertain.instance;
  static const veryLikely = VeryLikely.instance;
  static const likely = Likely.instance;
  static const fiftyFifty = FiftyFifty.instance;
  static const unlikely = Unlikely.instance;
  static const veryUnlikely = VeryUnlikely.instance;
  static const nearlyImpossible = NearlyImpossible.instance;
  static const impossible = Impossible.instance;

  const Probability(this.text);

  String toJson() => switch (this) {
    Certain() => Certain._id,
    NearlyCertain() => NearlyCertain._id,
    VeryLikely() => VeryLikely._id,
    Likely() => Likely._id,
    FiftyFifty() => FiftyFifty._id,
    Unlikely() => Unlikely._id,
    VeryUnlikely() => VeryUnlikely._id,
    NearlyImpossible() => NearlyImpossible._id,
    Impossible() => Impossible._id,
  };

  factory Probability.fromJson(String json) => switch (json) {
    Certain._id => Certain.instance,
    NearlyCertain._id => NearlyCertain.instance,
    VeryLikely._id => VeryLikely.instance,
    Likely._id => Likely.instance,
    FiftyFifty._id => FiftyFifty.instance,
    Unlikely._id => Unlikely.instance,
    VeryUnlikely._id => VeryUnlikely.instance,
    NearlyImpossible._id => NearlyImpossible.instance,
    Impossible._id => Impossible.instance,
    _ => FiftyFifty.instance,
  };
}

class Certain extends Probability {
  static const String _id = 'Certain';

  static const instance = Certain._();

  const Certain._() : super('Certain');
}

class NearlyCertain extends Probability {
  static const String _id = 'NearlyCertain';

  static const instance = NearlyCertain._();

  const NearlyCertain._() : super('Nearly Certain');
}

class VeryLikely extends Probability {
  static const String _id = 'VeryLikely';

  static const instance = VeryLikely._();

  const VeryLikely._() : super('Very Likely');
}

class Likely extends Probability {
  static const String _id = 'Likely';

  static const instance = Likely._();

  const Likely._() : super('Likely');
}

class FiftyFifty extends Probability {
  static const String _id = 'FiftyFifty';

  static const instance = FiftyFifty._();

  const FiftyFifty._() : super('50 / 50');
}

class Unlikely extends Probability {
  static const String _id = 'Unlikely';

  static const instance = Unlikely._();

  const Unlikely._() : super('Unlikely');
}

class VeryUnlikely extends Probability {
  static const String _id = 'VeryUnlikely';

  static const instance = VeryUnlikely._();

  const VeryUnlikely._() : super('Very Unlikely');
}

class NearlyImpossible extends Probability {
  static const String _id = 'NearlyImpossible';

  static const instance = NearlyImpossible._();

  const NearlyImpossible._() : super('Nearly Impossible');
}

class Impossible extends Probability {
  static const String _id = 'Impossible';

  static const instance = Impossible._();

  const Impossible._() : super('Impossible');
}

class ProbabilityVM {
  final Probability probability;
  final bool hasRightBorder;
  final bool hasFullWidth;

  const ProbabilityVM(
    this.probability, {
    this.hasRightBorder = false,
    this.hasFullWidth = false,
  });
}

final probabilityVMs = [
  const ProbabilityVM(Probability.certain),
  const ProbabilityVM(Probability.nearlyCertain, hasRightBorder: true),
  const ProbabilityVM(Probability.veryLikely),
  const ProbabilityVM(Probability.likely, hasRightBorder: true),
  const ProbabilityVM(
    Probability.fiftyFifty,
    hasRightBorder: true,
    hasFullWidth: true,
  ),
  const ProbabilityVM(Probability.unlikely),
  const ProbabilityVM(Probability.veryUnlikely, hasRightBorder: true),
  const ProbabilityVM(Probability.nearlyImpossible),
  const ProbabilityVM(Probability.impossible, hasRightBorder: true),
];

enum FateChartRollOutcome {
  extremeNo,
  no,
  yes,
  extremeYes,
}

class FateChartOutcomeProbability {
  final int extremeYes;
  final int threshold;
  final int extremeNo;

  FateChartOutcomeProbability(this.extremeYes, this.threshold, this.extremeNo);
}

/// The probabilities for a range of chaos factors.
class _ChaosFactorOutcomeProbabilities {
  /// The low end of the range (included)
  final int min;

  /// The high end of the range (included)
  final int max;

  final List<FateChartOutcomeProbability> outcomeProbabilities;

  _ChaosFactorOutcomeProbabilities(
    this.min,
    this.max,
    this.outcomeProbabilities,
  );
}

class FateChartService extends GetxService {
  FateChartRoll roll(Probability probability, {bool skipEvents = false}) {
    final outcomeProbability = getOutcomeProbability(probability);

    // roll the die
    final dieRoll = roll100Die();

    // determine the outcome value based on the roll and outcome probability
    FateChartRollOutcome outcome;
    if (dieRoll <= outcomeProbability.extremeYes) {
      outcome = FateChartRollOutcome.extremeYes;
    } else if (dieRoll <= outcomeProbability.threshold) {
      outcome = FateChartRollOutcome.yes;
    } else if (dieRoll < outcomeProbability.extremeNo) {
      outcome = FateChartRollOutcome.no;
    } else {
      outcome = FateChartRollOutcome.extremeNo;
    }

    // add the roll to the log
    final chaosFactor = Get.find<ChaosFactorService>().chaosFactor.value;

    return Get.find<RollLogService>().addFateChartRoll(
      probability: probability,
      chaosFactor: chaosFactor,
      dieRoll: dieRoll,
      outcome: outcome,
      skipEvent: skipEvents,
    );
  }

  void showFateChartLookup(
    BuildContext context,
    Probability probability, {
    Thread? thread,
  }) {
    final outcomeProbability = getOutcomeProbability(probability);

    final content = FateChartLookupView(
      probability: probability,
      outcomeProbability: outcomeProbability,
      thread: thread,
    );

    showAppModalBottomSheet<void>(context, content);
  }

  /// Determines the outcome probability of the specified [probability]
  /// based on the current chaos factor and fate chart type.
  FateChartOutcomeProbability getOutcomeProbability(Probability probability) {
    final chaosFactor = Get.find<ChaosFactorService>().chaosFactor.value;

    final adventure = Get.find<AdventureService>();
    final chart = switch (adventure.fateChartType) {
      FateChartType.standard => _standardFateChart,
      FateChartType.mid => _midFateChart,
      FateChartType.low => _lowFateChart,
      FateChartType.none => _noneFateChart,
    };

    final probabilityIndex = probabilityVMs.indexWhere(
      (e) => e.probability == probability,
    );

    return (chart.firstWhereOrNull(
              (e) => e.min <= chaosFactor && chaosFactor <= e.max,
            ) ??
            _fallbackChaosFactorOutcomeProbabilities)
        .outcomeProbabilities[probabilityIndex];
  }

  Widget getHeader() => const Header('Fate Chart');

  /// Must be wrapped in a Obx to listen to the physical dice mode
  List<Widget> getRows(BuildContext context) {
    final isPhysicalDiceModeEnabled = getPhysicalDiceModeEnabled;

    return [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _getProbabilityButton(
            context,
            Probability.certain,
            isPhysicalDiceModeEnabled: isPhysicalDiceModeEnabled,
          ),
          _getProbabilityButton(
            context,
            Probability.nearlyCertain,
            isPhysicalDiceModeEnabled: isPhysicalDiceModeEnabled,
          ),
        ],
      ),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _getProbabilityButton(
            context,
            Probability.veryLikely,
            isPhysicalDiceModeEnabled: isPhysicalDiceModeEnabled,
          ),
          _getProbabilityButton(
            context,
            Probability.likely,
            isPhysicalDiceModeEnabled: isPhysicalDiceModeEnabled,
          ),
        ],
      ),
      _getProbabilityButton(
        context,
        Probability.fiftyFifty,
        isPhysicalDiceModeEnabled: isPhysicalDiceModeEnabled,
      ),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _getProbabilityButton(
            context,
            Probability.unlikely,
            isPhysicalDiceModeEnabled: isPhysicalDiceModeEnabled,
          ),
          _getProbabilityButton(
            context,
            Probability.veryUnlikely,
            isPhysicalDiceModeEnabled: isPhysicalDiceModeEnabled,
          ),
        ],
      ),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _getProbabilityButton(
            context,
            Probability.nearlyImpossible,
            isPhysicalDiceModeEnabled: isPhysicalDiceModeEnabled,
          ),
          _getProbabilityButton(
            context,
            Probability.impossible,
            isPhysicalDiceModeEnabled: isPhysicalDiceModeEnabled,
          ),
        ],
      ),
      RulesHelpWrapper(
        helpEntry: randomEventHelp,
        iconColor: AppStyles.randomEventColors.onBackground,
        alignment: Alignment.centerRight,
        child: ConstrainedBox(
          constraints: const BoxConstraints.tightFor(width: double.infinity),
          child: FateChartButton(
            text: 'RANDOM EVENT',
            onPressed: isPhysicalDiceModeEnabled
                ? () => showRandomEventLookup(context)
                : rollRandomEvent,
            rollColors: AppStyles.randomEventColors,
            hasRightBorder: true,
            hasFullWidth: true,
          ),
        ),
      ),
    ];
  }

  Widget _getProbabilityButton(
    BuildContext context,
    Probability probability, {
    required bool isPhysicalDiceModeEnabled,
  }) {
    final vm = probabilityVMs.firstWhere((e) => e.probability == probability);

    return FateChartButton(
      text: vm.probability.text,
      onPressed: () {
        if (isPhysicalDiceModeEnabled) {
          showFateChartLookup(context, probability);
        } else {
          roll(probability);
        }
      },
      rollColors: AppStyles.fateChartColors,
      hasRightBorder: vm.hasRightBorder,
      hasFullWidth: vm.hasFullWidth,
    );
  }
}

typedef _FateChart = List<_ChaosFactorOutcomeProbabilities>;

final _FateChart _standardFateChart = List.generate(9, (index) => index + 1)
    .map(
      (chaosFactor) => _ChaosFactorOutcomeProbabilities(
        chaosFactor,
        chaosFactor,
        _outcomeProbabilitiesByThreshold
            .getRange(9 - chaosFactor, 9 - chaosFactor + 9)
            .toList(),
      ),
    )
    .toList();

final _FateChart _midFateChart = [
  _buildChaosFactorFromChart(_standardFateChart, 2, 1, 1),
  _buildChaosFactorFromChart(_standardFateChart, 3, 2, 3),
  _buildChaosFactorFromChart(_standardFateChart, 4, 4, 6),
  _buildChaosFactorFromChart(_standardFateChart, 5, 7, 8),
  _buildChaosFactorFromChart(_standardFateChart, 6, 9, 9),
];

final _FateChart _lowFateChart = [
  _buildChaosFactorFromChart(_standardFateChart, 3, 1, 2),
  _buildChaosFactorFromChart(_standardFateChart, 4, 3, 7),
  _buildChaosFactorFromChart(_standardFateChart, 5, 8, 9),
];

final _FateChart _noneFateChart = [
  _buildChaosFactorFromChart(_standardFateChart, 4, 1, 9),
];

final _fallbackChaosFactorOutcomeProbabilities =
    _ChaosFactorOutcomeProbabilities(
      1,
      9,
      _outcomeProbabilitiesByThreshold.getRange(4, 13).toList(),
    );

final _outcomeProbabilitiesByThreshold = [
  _getOutcomeProbabilityForThreshold(99),
  _getOutcomeProbabilityForThreshold(99),
  _getOutcomeProbabilityForThreshold(99),
  _getOutcomeProbabilityForThreshold(95),
  _getOutcomeProbabilityForThreshold(90),
  _getOutcomeProbabilityForThreshold(85),
  _getOutcomeProbabilityForThreshold(75),
  _getOutcomeProbabilityForThreshold(65),
  _getOutcomeProbabilityForThreshold(50),
  _getOutcomeProbabilityForThreshold(35),
  _getOutcomeProbabilityForThreshold(25),
  _getOutcomeProbabilityForThreshold(15),
  _getOutcomeProbabilityForThreshold(10),
  _getOutcomeProbabilityForThreshold(5),
  _getOutcomeProbabilityForThreshold(1),
  _getOutcomeProbabilityForThreshold(1),
  _getOutcomeProbabilityForThreshold(1),
];

final _availableOutcomeProbabilities = {
  for (var e
      in [5, 10, 15, 25, 35, 50, 65, 75, 85, 90, 95]
          .map(
            (threshold) => (threshold, _computeOutcomeProbability(threshold)),
          )
          .toList())
    e.$1: e.$2,
  1: FateChartOutcomeProbability(0, 1, 81),
  99: FateChartOutcomeProbability(20, 99, 101),
};

final _fallbackOutcomeProbability =
    _availableOutcomeProbabilities[50] ??
    FateChartOutcomeProbability(10, 50, 91);

FateChartOutcomeProbability _computeOutcomeProbability(int threshold) {
  final extremeYes = threshold * 20 ~/ 100;
  final extremeNo = 100 - ((100 - threshold) * 20 ~/ 100) + 1;

  return FateChartOutcomeProbability(extremeYes, threshold, extremeNo);
}

FateChartOutcomeProbability _getOutcomeProbabilityForThreshold(int threshold) {
  return _availableOutcomeProbabilities[threshold] ??
      _fallbackOutcomeProbability;
}

/// Creates a [_ChaosFactorOutcomeProbabilities] using the probabilities of
/// the [fateChart] at the specified [index], and using the specified [min] and [max].
_ChaosFactorOutcomeProbabilities _buildChaosFactorFromChart(
  _FateChart fateChart,
  int index,
  int min,
  int max,
) {
  return _ChaosFactorOutcomeProbabilities(
    min,
    max,
    fateChart[index].outcomeProbabilities,
  );
}
