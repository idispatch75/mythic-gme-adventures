import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:get/get.dart';

import '../chaos_factor/chaos_factor_view.dart';
import '../characters/characters_list.dart';
import '../dice_roller/dice_roller_view.dart';
import '../fate_chart/fate_chart_view.dart';
import '../meaning_tables/meaning_tables_view.dart';
import '../roll_log/roll_log_view.dart';
import '../scenes/scene_edit_page_view.dart';
import '../scenes/scenes_view.dart';
import '../threads/threads_list.dart';
import '../widgets/header.dart';
import 'layout.dart';
import 'roll_log_or_lookup_view.dart';
import 'small_layout.dart';

class MediumLayout extends GetView<LayoutController> {
  const MediumLayout({super.key});

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
          const _MediumLayoutOracles(),
          LayoutBuilder(builder: (_, constraints) {
            if (constraints.maxHeight > 600) {
              return const _MediumLayoutScenes();
            } else {
              return const SmallLayoutScenes();
            }
          }),
          const SmallLayoutOther(),
        ][controller.navigationTabIndex()],
      ),
    );
  }
}

class _MediumLayoutOracles extends GetView<LayoutController> {
  const _MediumLayoutOracles();

  @override
  Widget build(BuildContext context) {
    return LayoutTabBar(
      tabIndex: controller.oraclesTabIndex,
      tabs: const [
        Tab(text: 'Tables'),
        Tab(text: 'Dice Roller'),
      ],
      children: [
        // tables
        const _MediumLayoutTables(),

        // dice roller
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 350),
            child: getZoneDecoration(DiceRollerView()),
          ),
        ),
      ],
    );
  }
}

class _MediumLayoutTables extends StatelessWidget {
  const _MediumLayoutTables();

  @override
  Widget build(BuildContext context) {
    const tablesWidth = 290.0;

    return Row(
      children: [
        Column(
          children: [
            // fate chart
            SizedBox(
              width: tablesWidth,
              child: getZoneDecoration(const FateChartView(), withLeft: false),
            ),

            // meaning tables
            Expanded(
              child: SizedBox(
                width: tablesWidth,
                child: getZoneDecoration(
                  const MeaningTablesView(
                    isSmallLayout: false,
                  ),
                  withLeft: false,
                ),
              ),
            ),
          ],
        ),
        Layout.verticalSpacer,

        // roll log
        Expanded(
          child:
              getZoneDecoration(const RollLogOrLookupView(), withRight: false),
        ),
      ],
    );
  }
}

class _MediumLayoutScenes extends HookWidget {
  const _MediumLayoutScenes();

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
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // chaos factor
            getZoneDecoration(const ChaosFactorView(), withLeft: false),

            Layout.horizontalSpacer,

            // lists
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: getZoneDecoration(
                      const ThreadsListView(),
                      withLeft: false,
                    ),
                  ),
                  Layout.verticalSpacer,
                  Expanded(
                    flex: 4,
                    child: getZoneDecoration(
                      const CharactersListView(),
                      withRight: false,
                    ),
                  ),
                ],
              ),
            ),
            Layout.horizontalSpacer,

            // scenes
            const Header('Scenes'),
            const Expanded(child: ScenesView()),
          ],
        );
      }
    });
  }
}
