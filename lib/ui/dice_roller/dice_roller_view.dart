import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:get/get.dart';

import '../../helpers/dialogs.dart';
import '../roll_log/clear_log_button.dart';
import '../roll_log/roll_log_view.dart';
import '../styles.dart';
import 'dice_roller.dart';

class DiceRollerView extends HookWidget {
  final _animatedListKey = GlobalKey<AnimatedListState>();

  DiceRollerView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DiceRollerService>();
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
        final additions = updates.whereType<DiceRollerLogAdd>().toList();
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
              (_, animation) => FadeTransition(
                opacity: CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeIn,
                ),
                child: _DiceRollView(removedRolls[i]!),
              ),
            );
          }
        }

        // handle clear
        if (updates.any((e) => e is DiceRollerLogClear)) {
          _animatedListKey.currentState?.removeAllItems(
            (_, _) => const SizedBox.shrink(),
          );
        }
      });

      return subscription.cancel;
    }, [rollUpdates]);

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // rolls
        Expanded(
          child: AnimatedList(
            key: _animatedListKey,
            initialItemCount: log.length,
            itemBuilder: (_, index, animation) {
              final roll = log[log.length - index - 1];

              return SizeTransition(
                sizeFactor: CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeIn,
                ),
                child: _DiceRollView(roll),
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

        // roller
        Obx(
          () => ColoredBox(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            child: _RollerView(controller.settings()),
          ),
        ),
      ],
    );
  }
}

class _RollerView extends GetView<DiceRollerService> {
  final DiceRollerSettings _settings;

  const _RollerView(this._settings);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle = theme.textTheme.bodyLarge!;
    final colorScheme = theme.colorScheme;

    final modifierButtonStyle = _settings.modifier < 0
        ? OutlinedButton.styleFrom(
            foregroundColor: colorScheme.onErrorContainer,
            backgroundColor: colorScheme.errorContainer,
          )
        : null;
    final modifierPrefixText = _settings.modifier < 0 ? '-' : '+';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: DefaultTextStyle.merge(
        style: textStyle,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                // dice count
                Column(
                  children: [
                    _incrementButton(controller.incrementDiceCount),
                    OutlinedButton(
                      onPressed: () async {
                        final newValue = await Dialogs.showNumberPicker(
                          title: 'Number of dice',
                        );
                        if (newValue != null) {
                          controller.setDiceCount(newValue);
                        }
                      },
                      child: Text(_settings.diceCount.toString()),
                    ),
                    _decrementButton(controller.decrementDiceCount),
                  ],
                ),

                // faces
                _getPrefixText('d'),
                Column(
                  children: [
                    _incrementButton(controller.incrementFaces),
                    OutlinedButton(
                      onPressed: () async {
                        final newValue = await Dialogs.showNumberPicker(
                          title: 'Number of faces',
                        );
                        if (newValue != null) {
                          controller.setFaces(newValue);
                        }
                      },
                      child: Text(_settings.faces.toString()),
                    ),
                    _decrementButton(controller.decrementFaces),
                  ],
                ),

                // modifier
                _getPrefixText(modifierPrefixText),
                Column(
                  children: [
                    _incrementButton(controller.incrementModifier),
                    OutlinedButton(
                      style: modifierButtonStyle,
                      onPressed: () async {
                        final newValue = await Dialogs.showNumberPicker(
                          title: 'Modifier',
                        );
                        if (newValue != null) {
                          controller.setModifier(newValue);
                        }
                      },
                      child: Text(_settings.modifier.abs().toString()),
                    ),
                    _decrementButton(controller.decrementModifier),
                  ],
                ),
              ],
            ),

            // roll
            IconButton.filled(
              onPressed: controller.roll,
              icon: AppStyles.rollIcon,
              tooltip: 'Roll',
            ),
          ],
        ),
      ),
    );
  }

  Widget _getPrefixText(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Text(text),
    );
  }

  Widget _incrementButton(VoidCallback onPressed) {
    return IconButton(
      onPressed: onPressed,
      icon: const Icon(Icons.expand_less),
    );
  }

  Widget _decrementButton(VoidCallback onPressed) {
    return IconButton(
      onPressed: onPressed,
      icon: const Icon(Icons.expand_more),
    );
  }
}

class _DiceRollView extends StatelessWidget {
  final DiceRoll _diceRoll;

  const _DiceRollView(this._diceRoll);

  @override
  Widget build(BuildContext context) {
    var rollLabel = '${_diceRoll.dieRolls.length}d${_diceRoll.faces}';
    if (_diceRoll.modifier > 0) {
      rollLabel += '+${_diceRoll.modifier}';
    } else if (_diceRoll.modifier < 0) {
      rollLabel += _diceRoll.modifier.toString();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RollHeader(rollLabel, AppStyles.genericColors),
        _DiceRollResult(_diceRoll),
      ],
    );
  }
}

class _DiceRollResult extends GetView<DiceRollerService> {
  final DiceRoll _diceRoll;

  const _DiceRollResult(this._diceRoll);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppStyles.genericColors;

    return Container(
      color: colors.background,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 6, 4, 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // sum
            Expanded(
              child: Text(
                (_diceRoll.dieRolls.sum + _diceRoll.modifier).toString(),
                style: theme.textTheme.bodyLarge!.copyWith(
                  color: colors.onBackground,
                ),
              ),
            ),

            // detail
            //if (_diceRoll.dieRolls.length > 1 || _diceRoll.modifier != 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                _diceRoll.dieRolls.sorted((a, b) => b - a).join(', '),
                style: theme.textTheme.bodySmall!.copyWith(
                  color: colors.onBackground,
                ),
              ),
            ),

            // reroll
            IconButton.outlined(
              onPressed: () => controller.rollExisting(_diceRoll),
              icon: AppStyles.rollIcon,
              tooltip: 'Reroll',
            ),
          ],
        ),
      ),
    );
  }
}
