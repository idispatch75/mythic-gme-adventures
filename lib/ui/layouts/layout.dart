import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:get/get.dart';

import '../adventure/adventure_info_view.dart';
import '../meaning_tables/meaning_table.dart';
import '../styles.dart';

/// Right to left on Windows (OK then Cancel),
/// left to right for the other platforms
TextDirection dialogButtonDirection =
    !GetPlatform.isWeb && GetPlatform.isWindows
        ? TextDirection.rtl
        : TextDirection.ltr;

enum DeviceType { phone, tablet, desktop }

const kPhoneBreakPoint = 590.0;

class LayoutController extends GetxController {
  final navigationTabIndex = 0.obs;
  final oraclesTabIndex = 0.obs;
  final sceneTabIndex = 0.obs;
  final otherTabIndex = 0.obs;

  final hasEditScenePage = false.obs;

  final Rx<MeaningTable?> meaningTableDetails = Rx(null);
}

Widget getZoneDecoration(
  Widget child, {
  bool withLeft = true,
  bool withRight = true,
}) {
  return DecoratedBox(
    position: DecorationPosition.foreground,
    decoration: BoxDecoration(
      border: Border(
        top: Layout.borderSide,
        left: withLeft ? Layout.borderSide : BorderSide.none,
        bottom: Layout.borderSide,
        right: withRight ? Layout.borderSide : BorderSide.none,
      ),
    ),
    child: child,
  );
}

class LayoutTabBar extends HookWidget {
  final Rx<int> tabIndex;
  final List<Widget> tabs;
  final List<Widget> children;

  const LayoutTabBar({
    super.key,
    required this.tabs,
    required this.children,
    required this.tabIndex,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final navigationBarTheme = NavigationBarTheme.of(context);
    final tabBarElevation = navigationBarTheme.elevation != null
        ? max(0.0, navigationBarTheme.elevation! - 3)
        : 3.0;

    final tabController = useTabController(
      initialLength: tabs.length,
      initialIndex: min(tabIndex(), children.length - 1),
      keys: [tabs.length],
    );

    useEffect(() {
      final subscription = tabIndex.listen((index) {
        tabController.index = index;
      });

      return subscription.cancel;
    }, [tabs.length]);

    return Column(
      children: [
        // tabs contents
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: TabBarView(
              controller: tabController,
              children: children,
            ),
          ),
        ),

        // tabs
        Material(
          type: MaterialType.canvas,
          color: colorScheme.surface,
          surfaceTintColor: colorScheme.surfaceTint,
          elevation: tabBarElevation,
          child: TabBar(
            controller: tabController,
            onTap: (index) => tabIndex.value = index,
            labelPadding: EdgeInsets.zero,
            tabs: tabs,
          ),
        ),
      ],
    );
  }
}

class AdventureAppBar extends StatelessWidget implements PreferredSizeWidget {
  const AdventureAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(16, 4, 4, 0),
      child: AdventureInfoView(dense: true),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

abstract class Layout {
  static const verticalSpacer = SizedBox(width: 4);
  static const horizontalSpacer = SizedBox(height: 4);
  static BorderSide get borderSide =>
      BorderSide(color: AppStyles.headerColor, width: 2);
}

const bottomNavigationDestinations = [
  NavigationDestination(
    icon: Icon(Icons.remove_red_eye_outlined),
    selectedIcon: Icon(Icons.remove_red_eye_rounded),
    label: 'Oracles',
    tooltip: '',
  ),
  NavigationDestination(
    icon: Icon(Icons.video_camera_back_outlined),
    selectedIcon: Icon(Icons.video_camera_back_rounded),
    label: 'Scenes',
    tooltip: '',
  ),
  NavigationDestination(
    icon: Icon(Icons.more_horiz_outlined),
    label: 'More',
    tooltip: '',
  )
];
