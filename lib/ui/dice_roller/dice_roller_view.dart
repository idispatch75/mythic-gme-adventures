import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../roll_log/roll_log_view.dart';
import '../styles.dart';
import 'dice_roller.dart';

class DiceRollerView extends GetView<DiceRollerService> {
  final _animatedLisKey = GlobalKey<AnimatedListState>();

  DiceRollerView({super.key});

  @override
  Widget build(BuildContext context) {
    final rollLog = controller.rollLog;

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // rolls
        Expanded(
          child: AnimatedList(
            key: _animatedLisKey,
            initialItemCount: rollLog.length,
            itemBuilder: (_, index, animation) {
              if (index >= rollLog.length) {
                return Placeholder();
              }

              final roll = rollLog[rollLog.length - index - 1];

              return SizeTransition(
                sizeFactor: CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeIn,
                ),
                child: _DiceRollView(roll),
              );
            },
          ),
        ),

        // roller
        Obx(
          () => _RollerView(controller.settings(), _animatedLisKey),
        ),
      ],
    );
  }
}

class _RollerView extends GetView<DiceRollerService> {
  final DiceRollerSettings _settings;
  final GlobalKey<AnimatedListState> _animatedLisKey;

  const _RollerView(this._settings, this._animatedLisKey);

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyLarge!;

    return Padding(
      padding: const EdgeInsets.all(6),
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
                    IconButton(
                      onPressed: controller.incrementDiceCount,
                      icon: const Icon(Icons.expand_less),
                    ),
                    OutlinedButton(
                      onPressed: () => {},
                      child: Text(_settings.diceCount.toString()),
                    ),
                    IconButton(
                      onPressed: controller.decrementDiceCount,
                      icon: const Icon(Icons.expand_more),
                    ),
                  ],
                ),

                // faces
                _getInsideText('d'),
                OutlinedButton(
                  onPressed: () => {},
                  child: Text(_settings.faces.toString()),
                ),

                // modifier
                _getInsideText(_settings.modifier < 0 ? '-' : '+'),
                Column(
                  children: [
                    IconButton(
                      onPressed: controller.incrementModifier,
                      icon: const Icon(Icons.expand_less),
                    ),
                    OutlinedButton(
                      onPressed: () => {},
                      child: Text(_settings.modifier.abs().toString()),
                    ),
                    IconButton(
                      onPressed: controller.decrementModifier,
                      icon: const Icon(Icons.expand_more),
                    ),
                  ],
                ),
              ],
            ),

            // roll
            IconButton.filled(
              onPressed: () {
                final removedRoll = controller.roll();

                _animatedLisKey.currentState?.insertItem(0);

                if (removedRoll != null) {
                  _animatedLisKey.currentState?.removeItem(
                    controller.rollLog.length,
                    (_, animation) => FadeTransition(
                      opacity: CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeIn,
                      ),
                      child: _DiceRollView(removedRoll),
                    ),
                  );
                }
              },
              icon: AppStyles.rollIcon,
              tooltip: 'Roll',
            ),
          ],
        ),
      ),
    );
  }

  Widget _getInsideText(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Text(text),
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

class _DiceRollResult extends StatelessWidget {
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
            if (_diceRoll.dieRolls.length > 1)
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
              onPressed: () => {},
              icon: AppStyles.rollIcon,
              tooltip: 'Reroll',
            ),
          ],
        ),
      ),
    );
  }
}
