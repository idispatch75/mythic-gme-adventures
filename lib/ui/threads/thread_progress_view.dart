import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../global_settings/global_settings.dart';
import '../rules_help/rules_help_button.dart';
import '../rules_help/rules_help_view.dart';
import '../styles.dart';
import '../widgets/actions_menu.dart';
import 'thread.dart';
import 'thread_ctl.dart';

Widget threadProgressViewWrapper(Thread thread, {bool isDeleted = false}) {
  return AnimatedSize(
    duration: const Duration(milliseconds: 400),
    curve: Curves.easeOut,
    alignment: Alignment.topCenter,
    child: Obx(() {
      return (thread.isTracked() && !thread.isArchived)
          ? Card(
              margin: const EdgeInsets.fromLTRB(8, 0, 4, 8),
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: ThreadProgressView(thread.toTag(), isDeleted: isDeleted),
              ),
            )
          : const SizedBox(width: double.infinity);
    }),
  );
}

class ThreadProgressView extends GetView<ThreadController> {
  final String _tag;
  final bool isDeleted;

  const ThreadProgressView(this._tag, {this.isDeleted = false, super.key});

  @override
  String get tag => _tag;

  @override
  Widget build(BuildContext context) {
    final thread = controller.thread;

    Widget buttonWrapper({required Widget child}) {
      return Padding(
        padding: const EdgeInsets.only(right: 8.0),
        child: child,
      );
    }

    final buttonRow = LayoutBuilder(
      builder: (_, constraints) {
        var additionalButtons = <Widget>[];
        var additionalMenuEntries = <MenuItemButton>[];

        // buttons + menu entries for large layout
        if (constraints.maxWidth > 212) {
          additionalButtons = [
            buttonWrapper(
              child: IconButton.outlined(
                onPressed: !isDeleted ? controller.rollDiscovery : null,
                icon: AppStyles.rollIcon,
                tooltip: 'Roll Discovery',
              ),
            ),
            buttonWrapper(
              child: IconButton.outlined(
                onPressed: !isDeleted
                    ? () => controller.addFlashpoint(2)
                    : null,
                tooltip: 'Mark a Flashpoint and +2 progress',
                icon: const _MarkFlashpointIcon(add: true),
              ),
            ),
          ];
        }
        // buttons + menu entries for small layout
        else {
          additionalMenuEntries = [
            MenuItemButton(
              leadingIcon: const _MarkFlashpointIcon(add: true),
              onPressed: !isDeleted ? () => controller.addFlashpoint(2) : null,
              child: const SizedBox(
                width: 252,
                child: Text(
                  'Mark a Flashpoint and +2 progress',
                  softWrap: true,
                ),
              ),
            ),
            MenuItemButton(
              leadingIcon: AppStyles.rollIcon,
              onPressed: !isDeleted ? controller.rollDiscovery : null,
              child: const Text('Roll Discovery'),
            ),
          ];
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // help button
            Obx(() {
              final hideButton = Get.find<GlobalSettingsService>()
                  .hideHelpButtons();
              if (hideButton) {
                return const SizedBox.shrink();
              }

              return const RulesHelpButton(
                helpEntry: threadProgressTrackHelp,
              );
            }),

            // additional buttons
            ...additionalButtons,

            // add progress button
            IconButton.outlined(
              onPressed: !isDeleted ? () => controller.addProgress(2) : null,
              icon: const Icon(Icons.exposure_plus_2),
              tooltip: 'Mark +2 progress',
            ),

            // more button
            ActionsMenu([
              // additional menu entries
              ...additionalMenuEntries,

              // Mark Flashpoint with no progress
              MenuItemButton(
                leadingIcon: const Icon(Icons.flash_on),
                onPressed: !isDeleted ? controller.addFlashpoint : null,
                child: const SizedBox(
                  width: 252,
                  child: Text(
                    'Mark Flashpoint with no progress',
                    softWrap: true,
                  ),
                ),
              ),

              // Remove Flashpoint
              MenuItemButton(
                leadingIcon: const _MarkFlashpointIcon(add: false),
                onPressed: !isDeleted ? controller.removeFlashpoint : null,
                child: const Text('Remove Flashpoint'),
              ),

              // Remove 2 progress
              MenuItemButton(
                leadingIcon: const Icon(Icons.exposure_minus_2),
                onPressed: !isDeleted
                    ? () => controller.removeProgress(2)
                    : null,
                child: const Text('Remove 2 progress'),
              ),

              // Remove 1 progress
              MenuItemButton(
                leadingIcon: const Icon(Icons.exposure_minus_1),
                onPressed: !isDeleted
                    ? () => controller.removeProgress(1)
                    : null,
                child: const Text('Remove 1 progress'),
              ),
            ]),
          ],
        );
      },
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 0, 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // progress indicator
          Obx(() {
            final phaseViews = List.generate(thread.phases.length, (index) {
              final phase = thread.phases[index].value;

              final maxProgress = index * 5;
              final phaseProgress = thread.progress() - maxProgress;

              return Padding(
                padding: EdgeInsets.only(left: index.isEven ? 0 : 8),
                child: _ProgressPhaseView(phase, phaseProgress),
              );
            });

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: phaseViews.sublist(0, 2),
                ),
                if (phaseViews.length > 2)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: phaseViews.sublist(2),
                    ),
                  ),
              ],
            );
          }),

          // buttons
          Expanded(child: buttonRow),
        ],
      ),
    );
  }
}

class _ProgressPhaseView extends StatelessWidget {
  final ThreadProgressPhase _phase;
  final int _progress;

  const _ProgressPhaseView(this._phase, this._progress);

  @override
  Widget build(BuildContext context) {
    final borderColor = Theme.of(context).colorScheme.onSurface;
    const progressWidth = 14.0;

    return Row(
      children: List.generate(5, (index) {
        Color color = Colors.white;
        if (index == 4) {
          if (_progress >= 5) {
            color = _phase.hasFlashpoint
                ? Colors.green.shade600
                : Colors.red.shade600;
          } else if (_phase.hasFlashpoint) {
            color = Colors.green.shade200;
          }
        } else if (index < _progress) {
          color = Colors.grey;
        }

        return Padding(
          padding: EdgeInsets.only(left: index == 0 ? 0 : 4),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            switchInCurve: Curves.easeIn,
            switchOutCurve: Curves.easeOut,
            transitionBuilder: (child, animation) => FadeTransition(
              key: ValueKey<Key?>(child.key),
              opacity: animation,
              child: child,
            ),
            child: Container(
              key: ValueKey(color),
              width: progressWidth,
              height: progressWidth,
              foregroundDecoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: borderColor),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _MarkFlashpointIcon extends StatelessWidget {
  final bool add;

  const _MarkFlashpointIcon({required this.add});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxWidth: 24,
        maxHeight: 24,
      ),
      child: Stack(
        children: [
          const Positioned(
            top: 2,
            right: -6,
            child: Icon(Icons.flash_on, size: 20),
          ),
          Positioned(
            top: 3,
            left: -3,
            child: Icon(add ? Icons.exposure_plus_2 : Icons.remove, size: 18),
          ),
        ],
      ),
    );
  }
}
