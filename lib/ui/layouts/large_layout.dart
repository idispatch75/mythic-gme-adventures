import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:get/get.dart';

import '../adventure/adventure_info_view.dart';
import '../chaos_factor/chaos_factor_view.dart';
import '../characters/characters_list.dart';
import '../characters/characters_view.dart';
import '../dice_roller/dice_roller_view.dart';
import '../fate_chart/fate_chart_view.dart';
import '../meaning_tables/meaning_tables_view.dart';
import '../notes/notes_view.dart';
import '../player_characters/player_characters_view.dart';
import '../roll_log/roll_log_view.dart';
import '../scenes/scene_edit_page_view.dart';
import '../scenes/scenes_view.dart';
import '../threads/threads_list.dart';
import '../threads/threads_view.dart';
import 'layout.dart';

class LargeLayout extends HookWidget {
  const LargeLayout({super.key});

  @override
  Widget build(context) {
    final layoutController = Get.find<LayoutController>();

    final tabController = useTabController(initialLength: 5, initialIndex: 0);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Row(
          children: [
            // oracles
            SizedBox(
              width: _LargeLayoutTables.width,
              child: const _LargeLayoutOracles(),
            ),
            Layout.verticalSpacer,

            // third column
            Obx(() {
              return Expanded(
                child: layoutController.hasEditScenePage()
                    ? SceneEditPageView()
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: [
                              // chaos factor
                              getZoneDecoration(const ChaosFactorView()),

                              // adventure info
                              const Expanded(
                                child: Padding(
                                  padding: EdgeInsets.fromLTRB(16, 16, 0, 0),
                                  child: AdventureInfoView(),
                                ),
                              ),
                            ],
                          ),
                          Layout.horizontalSpacer,

                          // lists
                          Expanded(
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 5,
                                  child: getZoneDecoration(
                                      const ThreadsListView()),
                                ),
                                Layout.verticalSpacer,
                                Expanded(
                                  flex: 4,
                                  child: getZoneDecoration(
                                      const CharactersListView()),
                                ),
                              ],
                            ),
                          ),
                          Layout.horizontalSpacer,

                          // tabs
                          Expanded(
                            child: getZoneDecoration(
                              Column(
                                children: [
                                  TabBar(
                                    controller: tabController,
                                    tabs: const [
                                      Tab(text: 'Scenes'),
                                      Tab(text: 'Characters'),
                                      Tab(text: 'Threads'),
                                      Tab(text: 'Players'),
                                      Tab(text: 'Notes'),
                                    ],
                                  ),
                                  Expanded(
                                    child: TabBarView(
                                      controller: tabController,
                                      children: [
                                        const ScenesView(),
                                        CharactersView(),
                                        ThreadsView(),
                                        const PlayerCharactersView(),
                                        const NotesView(),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _LargeLayoutOracles extends GetView<LayoutController> {
  const _LargeLayoutOracles();

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
        const _LargeLayoutTables(),

        // dice roller
        getZoneDecoration(DiceRollerView()),
      ],
    );
  }
}

class _LargeLayoutTables extends StatelessWidget {
  static const _columnWidth = 260.0;
  static final width = _columnWidth * 2 + Layout.verticalSpacer.width!;

  const _LargeLayoutTables();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Column(
          children: [
            // fate chart
            SizedBox(
              width: _columnWidth,
              child: getZoneDecoration(const FateChartView()),
            ),

            // meaning tables
            Expanded(
              child: SizedBox(
                width: _columnWidth,
                child: getZoneDecoration(const MeaningTablesView()),
              ),
            ),
          ],
        ),
        Layout.verticalSpacer,

        // roll log
        Expanded(
          child: getZoneDecoration(
            RollLogView(),
          ),
        ),
      ],
    );
  }
}
