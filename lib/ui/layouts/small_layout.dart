import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:get/get.dart';

import '../chaos_factor/chaos_factor_view.dart';
import '../characters/characters_list.dart';
import '../characters/characters_view.dart';
import '../dice_roller/dice_roller_view.dart';
import '../fate_chart/fate_chart.dart';
import '../fate_chart/fate_chart_view.dart';
import '../meaning_tables/meaning_tables_ctl.dart';
import '../meaning_tables/meaning_tables_view.dart';
import '../notes/notes_view.dart';
import '../player_characters/player_characters_view.dart';
import '../roll_log/roll_log_view.dart';
import '../scenes/scene_edit_page_view.dart';
import '../scenes/scenes_view.dart';
import '../threads/threads_list.dart';
import '../threads/threads_view.dart';
import '../widgets/header.dart';
import 'layout.dart';

class SmallLayout extends HookWidget {
  const SmallLayout({super.key});

  @override
  Widget build(BuildContext context) {
    final layout = Get.find<LayoutController>();

    return Obx(
      () => Scaffold(
        appBar: const AdventureAppBar(),
        bottomNavigationBar: NavigationBar(
          height: 64,
          onDestinationSelected: (int index) {
            layout.navigationTabIndex.value = index;
          },
          selectedIndex: layout.navigationTabIndex(),
          destinations: bottomNavigationDestinations,
        ),
        body: [
          const _SmallLayoutOracles(),
          const SmallLayoutScenes(),
          const SmallLayoutOther(),
        ][layout.navigationTabIndex()],
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
      tabs: const [
        Tab(text: 'Tables'),
        Tab(text: 'Roll Log'),
        Tab(text: 'Dice Roller'),
      ],
      children: [
        // tables
        const _SmallLayoutTables(),

        // log
        RollLogView(),

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

    return LayoutBuilder(builder: (_, constraints) {
      if (constraints.maxHeight > 600) {
        return const Column(
          children: [
            FateChartView(),
            Expanded(child: MeaningTablesView()),
          ],
        );
      } else {
        // for smaller screens we need to have the whole view scrolling
        // and for faster drawing we need ListView.builder
        final fateCharts = Get.find<FateChartService>();
        final meaningTables = Get.find<MeaningTablesController>();

        return Obx(() {
          final fateChartRows = fateCharts.getRows();
          final meaningTableButtons = meaningTables.getButtons();

          return ListView.builder(
            itemCount:
                1 + fateChartRows.length + 1 + meaningTableButtons.length,
            itemBuilder: (_, index) {
              if (index == 0) {
                return fateCharts.getHeader();
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
    });
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
      } else {
        return LayoutTabBar(
          tabIndex: layoutController.sceneTabIndex,
          tabs: const [
            Tab(text: 'Threads'),
            Tab(text: 'Characters'),
            Tab(text: 'Scenes'),
          ],
          children: [
            // threads
            const ThreadsListView(),

            // characters
            const CharactersListView(),

            // scenes
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                getZoneDecoration(const ChaosFactorView(dense: true)),
                const Header('Scenes'),
                const Expanded(child: ScenesView(dense: true)),
              ],
            ),
          ],
        );
      }
    });
  }
}

class SmallLayoutOther extends HookWidget {
  const SmallLayoutOther({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<LayoutController>();

    setupRollIndicator(context);

    return LayoutTabBar(
      tabIndex: controller.otherTabIndex,
      tabs: const [
        Tab(text: 'Threads'),
        Tab(text: 'Characters'),
        Tab(text: 'Players'),
        Tab(text: 'Notes'),
      ],
      children: [
        ThreadsView(showAddToListNotification: true),
        CharactersView(showAddToListNotification: true),
        const PlayerCharactersView(),
        const NotesView(),
      ],
    );
  }
}
