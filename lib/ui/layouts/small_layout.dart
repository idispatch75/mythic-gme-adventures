// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:get/get.dart';

import '../adventure/adventure.dart';
import '../chaos_factor/chaos_factor_view.dart';
import '../characters/characters_list.dart';
import '../characters/characters_view.dart';
import '../dice_roller/dice_roller_view.dart';
import '../fate_chart/fate_chart.dart';
import '../fate_chart/fate_chart_view.dart';
import '../features/features_view.dart';
import '../keyed_scenes/keyed_scene.dart';
import '../keyed_scenes/keyed_scenes_view.dart';
import '../meaning_tables/meaning_tables_ctl.dart';
import '../meaning_tables/meaning_tables_view.dart';
import '../notes/note_edit_page_view.dart';
import '../notes/notes_view.dart';
import '../player_characters/player_characters_view.dart';
import '../preferences/preferences.dart';
import '../roll_log/roll_log_view.dart';
import '../rules_help/rules_help_button.dart';
import '../rules_help/rules_help_view.dart';
import '../scenes/scene_edit_page_view.dart';
import '../scenes/scenes_view.dart';
import '../threads/threads_list.dart';
import '../threads/threads_view.dart';
import '../widgets/header.dart';
import 'layout.dart';
import 'roll_log_or_lookup_view.dart';

class SmallLayout extends GetView<LayoutController> {
  const SmallLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Scaffold(
        appBar: const AdventureAppBar(),
        bottomNavigationBar: NavigationBar(
          height: 64,
          onDestinationSelected: (int index) {
            controller.navigationTabIndex.value = index;
          },
          selectedIndex: controller.navigationTabIndex(),
          destinations: bottomNavigationDestinations,
        ),
        body: [
          const _SmallLayoutOracles(),
          const SmallLayoutScenes(),
          const SmallLayoutOther(),
        ][controller.navigationTabIndex()],
      ),
    );
  }
}

class _SmallLayoutOracles extends HookWidget {
  const _SmallLayoutOracles();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<LayoutController>();

    return LayoutTabBar(
      tabIndex: controller.oraclesTabIndex,
      tabs: [
        Tab(text: 'TABLES'),
        Obx(() {
          return Tab(text: getPhysicalDiceModeEnabled ? 'LOOKUP' : 'ROLL LOG');
        }),
        Tab(text: 'DICE ROLLER'),
      ],
      children: [
        // tables
        const _SmallLayoutTables(),

        // log
        RollLogOrLookupView(),

        // dice roller
        DiceRollerView(),
      ],
    );
  }
}

class _SmallLayoutTables extends HookWidget {
  const _SmallLayoutTables();

  @override
  Widget build(BuildContext context) {
    setupRollIndicator(context);

    return LayoutBuilder(
      builder: (_, constraints) {
        if (constraints.maxHeight > 600) {
          return const Column(
            children: [
              FateChartView(),
              Expanded(
                child: MeaningTablesView(isSmallLayout: true),
              ),
            ],
          );
        } else {
          // for smaller screens we need to have the whole view scrolling
          // and for faster drawing we need ListView.builder
          final fateCharts = Get.find<FateChartService>();
          final meaningTables = Get.find<MeaningTablesController>();

          return Obx(() {
            final fateChartRows = fateCharts.getRows(context);
            final meaningTableButtons = meaningTables.getButtons(
              isSmallLayout: true,
            );

            return ListView.builder(
              itemCount:
                  1 + fateChartRows.length + 1 + meaningTableButtons.length,
              itemBuilder: (_, index) {
                if (index == 0) {
                  return RulesHelpWrapper.header(
                    helpEntry: fateChartHelp,
                    child: fateCharts.getHeader(),
                  );
                } else if (index < 1 + fateChartRows.length) {
                  return fateChartRows[index - 1];
                } else if (index == 1 + fateChartRows.length) {
                  return meaningTables.getHeader();
                } else {
                  return meaningTableButtons[index - 2 - fateChartRows.length];
                }
              },
            );
          });
        }
      },
    );
  }
}

class SmallLayoutScenes extends HookWidget {
  const SmallLayoutScenes({super.key});

  @override
  Widget build(BuildContext context) {
    final layoutController = Get.find<LayoutController>();

    setupRollIndicator(context);

    return Obx(() {
      if (layoutController.hasEditScenePage()) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: SceneEditPageView(),
        );
      }

      Widget keyedSceneTab = const Text(
        'KEYED SCENES',
        softWrap: false,
        overflow: TextOverflow.fade,
      );

      final keyedScenesController = Get.find<KeyedScenesService>();
      if (keyedScenesController.scenes.isNotEmpty) {
        keyedSceneTab = Stack(
          clipBehavior: Clip.none,
          children: [
            keyedSceneTab,
            const Positioned(
              top: -6,
              left: -8,
              child: Badge(smallSize: 8),
            ),
          ],
        );
      }

      return LayoutTabBar(
        tabIndex: layoutController.sceneTabIndex,
        tabs: [
          const Tab(text: 'THREADS'),
          const Tab(text: 'CHARACTERS'),
          const Tab(text: 'SCENES'),
          Tab(child: keyedSceneTab),
        ],
        children: const [
          ThreadsListView(),
          CharactersListView(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ChaosFactorView(dense: true),
              Expanded(
                child: _HeaderView(
                  title: 'SCENES',
                  helpEntry: scenesHelp,
                  child: ScenesView(dense: true),
                ),
              ),
            ],
          ),
          _HeaderView(
            title: 'KEYED SCENES',
            child: KeyedScenesView(),
          ),
        ],
      );
    });
  }
}

class SmallLayoutOther extends HookWidget {
  const SmallLayoutOther({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<LayoutController>();

    setupRollIndicator(context);

    return Obx(() {
      if (controller.hasEditNotePage()) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: NoteEditPageView(),
        );
      }

      final hasFeatures = Get.find<AdventureService>().isPreparedAdventure();

      return LayoutTabBar(
        tabIndex: controller.otherTabIndex,
        tabs: [
          const Tab(text: 'THREADS'),
          const Tab(text: 'CHARACTERS'),
          if (hasFeatures) const Tab(text: 'FEATURES'),
          const Tab(text: 'PLAYERS'),
          const Tab(text: 'NOTES'),
        ],
        children: [
          _HeaderView(
            title: 'THREADS',
            child: ThreadsView(showAddToListNotification: true),
          ),
          _HeaderView(
            title: 'CHARACTERS',
            child: CharactersView(showAddToListNotification: true),
          ),
          if (hasFeatures)
            _HeaderView(
              title: 'FEATURES',
              child: const FeaturesView(),
            ),
          _HeaderView(
            title: 'PLAYERS',
            child: const PlayerCharactersView(),
          ),
          _HeaderView(
            title: 'NOTES',
            child: const NotesView(),
          ),
        ],
      );
    });
  }
}

class _HeaderView extends StatelessWidget {
  final String title;
  final RulesHelpEntry? helpEntry;
  final Widget child;

  const _HeaderView({
    required this.title,
    this.helpEntry,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    Widget header = Header(title);
    if (helpEntry != null) {
      header = RulesHelpWrapper.header(
        helpEntry: helpEntry!,
        child: header,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        header,
        Expanded(child: child),
      ],
    );
  }
}
