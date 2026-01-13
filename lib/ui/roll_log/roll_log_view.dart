import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../helpers/dialogs.dart';
import '../../helpers/utils.dart';
import '../fate_chart/fate_chart.dart';
import '../meaning_tables/meaning_table.dart';
import '../preferences/preferences.dart';
import '../random_events/random_event.dart';
import '../styles.dart';
import '../widgets/long_press_detector.dart';
import 'clear_log_button.dart';
import 'roll_log.dart';

class RollLogView extends HookWidget {
  static final DateFormat _dateFormat = DateFormat.yMMMEd().add_jms();
  static final DateFormat _timeFormat = DateFormat.jms();

  final _animatedListKey = GlobalKey<AnimatedListState>();

  RollLogView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<RollLogService>();
    final log = controller.rollLog;
    final rollUpdates = controller.rollUpdates;

    final scrollController = useScrollController();

    useEffect(() {
      final subscription = rollUpdates.listen((updates) async {
        // scroll to top
        if (scrollController.hasClients) {
          final position = scrollController.position.minScrollExtent;
          await scrollController.animateTo(
            position,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOut,
          );
        }

        // handles additions
        final additions = updates.whereType<RollLogAdd>().toList();

        if (additions.isNotEmpty) {
          // animate new rolls
          _animatedListKey.currentState?.insertAllItems(0, additions.length);

          // animate removed rolls
          final removedRolls = additions
              .where((e) => e.removedRoll != null)
              .map((e) => e.removedRoll)
              .toList();
          for (var i = 0; i < removedRolls.length; i++) {
            _animatedListKey.currentState?.removeItem(
              log.length - i,
              (_, _) => const SizedBox(),
            );
          }
        }

        // handle clear
        if (updates.any((e) => e is RollLogClear)) {
          _animatedListKey.currentState?.removeAllItems(
            (_, _) => const SizedBox.shrink(),
          );
        }
      });

      return subscription.cancel;
    }, [rollUpdates]);

    final rollDateTextStyle = Theme.of(context).textTheme.labelSmall;

    final isDarkMode = Get.find<LocalPreferencesService>().enableDarkMode();

    return Column(
      children: [
        Expanded(
          child: AnimatedList(
            key: _animatedListKey,
            initialItemCount: log.length,
            itemBuilder: (_, index, animation) {
              final entry = log[log.length - index - 1];

              String rollDateText;
              final rollDate = DateTime.fromMillisecondsSinceEpoch(
                entry.timestamp,
              );
              final now = DateTime.now();
              if (now.day == rollDate.day &&
                  now.month == rollDate.month &&
                  now.year == rollDate.year) {
                rollDateText = _timeFormat.format(rollDate);
              } else {
                rollDateText = _dateFormat.format(rollDate);
              }

              final itemView = Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isDarkMode ? 12 : 0.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    getEntryView(entry),
                    Padding(
                      padding: EdgeInsets.fromLTRB(0, 0, isDarkMode ? 0 : 4, 8),
                      child: Text(
                        rollDateText,
                        style: rollDateTextStyle,
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              );

              return SizeTransition(
                key: ValueKey(entry.timestamp),
                sizeFactor: CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeIn,
                ),
                child: itemView,
              );
            },
            controller: scrollController,
          ),
        ),

        // clear
        Obx(
          () => ClearLogButton(
            onPressed: log.isNotEmpty
                ? () async {
                    if (await Dialogs.showConfirmation(
                      title: 'Clear the log?',
                      message: 'The log entries will be permanently deleted.',
                    )) {
                      controller.clear();
                    }
                  }
                : null,
          ),
        ),
      ],
    );
  }
}

Widget getEntryView(RollEntry entry) {
  return switch (entry) {
    final FateChartRoll entry => _FateChartView(entry),
    final RandomEventRoll entry => _RandomEventView(entry),
    final MeaningTableRoll entry => _MeaningTableView(entry),
    final GenericRoll entry => _GenericView(entry),
  };
}

class _FateChartView extends StatelessWidget {
  final FateChartRoll _roll;

  const _FateChartView(this._roll);

  @override
  Widget build(BuildContext context) {
    final outcomeText = switch (_roll.outcome) {
      FateChartRollOutcome.extremeNo => 'Exceptional No',
      FateChartRollOutcome.no => 'No',
      FateChartRollOutcome.yes => 'Yes',
      FateChartRollOutcome.extremeYes => 'Exceptional Yes',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RollHeader(_roll.probability.text, AppStyles.fateChartColors),
        _Result(outcomeText, _roll.dieRoll, AppStyles.fateChartColors),
        if (_roll.hasEvent)
          const TextButton(
            onPressed: rollRandomEvent,
            child: Text('ROLL RANDOM EVENT'),
          ),
      ],
    );
  }
}

class _RandomEventView extends StatelessWidget {
  final RandomEventRoll _roll;

  const _RandomEventView(this._roll);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RollHeader('Random Event', AppStyles.randomEventColors),
        _Result(_roll.focus.name, _roll.dieRoll, AppStyles.randomEventColors),

        // event target
        if (_roll.focus.target != null)
          Container(
            color: AppStyles.randomEventColors.background,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 4, 4),
              child: Text(
                _roll.focus.target!,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppStyles.randomEventColors.onBackground,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _MeaningTableView extends GetView<MeaningTablesService> {
  final MeaningTableRoll _roll;

  const _MeaningTableView(this._roll);

  @override
  Widget build(BuildContext context) {
    return LongPressDetector(
      duration: const Duration(milliseconds: 1000),
      onLongPress: () => _copyResult(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RollHeader(
            controller.getMeaningTableName(_roll.tableId),
            AppStyles.meaningTableColors,
          ),
          for (var result in _roll.results)
            Obx(
              () {
                Get.find<MeaningTablesService>()
                    .language(); // just to update on change
                return _Result(
                  controller.getMeaningTableEntry(
                    result.entryId,
                    result.dieRoll,
                  ),
                  result.dieRoll,
                  AppStyles.meaningTableColors,
                );
              },
            ),
        ],
      ),
    );
  }

  Future<void> _copyResult(BuildContext context) async {
    await Clipboard.setData(
      ClipboardData(
        text: _roll.results
            .map((e) => controller.getMeaningTableEntry(e.entryId, e.dieRoll))
            .join(', '),
      ),
    );

    if (context.mounted) {
      showSnackBar(context, 'Result copied to the clipboard');
    }
  }
}

class _GenericView extends StatelessWidget {
  final GenericRoll _roll;

  const _GenericView(this._roll);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RollHeader(_roll.title, AppStyles.genericColors),
        _Result(_roll.value, _roll.dieRoll, AppStyles.genericColors),
      ],
    );
  }
}

class RollHeader extends StatelessWidget {
  final String _text;
  final RollColors _colors;

  const RollHeader(this._text, this._colors, {super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: _colors.header,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 2, 4, 2),
        child: Text(
          _text.toUpperCase(),
          style: theme.textTheme.titleSmall!.copyWith(color: _colors.onHeader),
          overflow: TextOverflow.fade,
        ),
      ),
    );
  }
}

class _Result extends StatelessWidget {
  final String _text;
  final int _dieRoll;
  final RollColors _colors;

  const _Result(this._text, this._dieRoll, this._colors);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: _colors.background,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 6, 4, 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // result
            Expanded(
              child: Text(
                _text,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _colors.onBackground,
                ),
              ),
            ),

            // die roll
            Padding(
              padding: const EdgeInsets.only(left: 4.0),
              child: Text(
                _dieRoll.toString(),
                style: theme.textTheme.bodySmall!.copyWith(
                  color: _colors.onBackground,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sets up the roll indicator as a bottom sheet.
/// Must be called inside a HookWidget.
void setupRollIndicator(BuildContext context) {
  useEffect(() {
    final rollLog = Get.find<RollLogService>();

    final subscription = rollLog.rollUpdates.listen((updates) {
      if (!context.mounted) return;

      showAppModalBottomSheet<void>(
        context,
        ListView(
          children: updates
              .whereType<RollLogAdd>()
              .map((e) => getEntryView(e.newRoll))
              .toList(),
        ),
      );
    });

    return subscription.cancel;
  }, const []);
}
