import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../helpers/rx_list_extensions.dart';
import '../../helpers/string_extensions.dart';
import '../adventure/adventure.dart';
import '../global_settings/global_settings.dart';
import '../layouts/layout.dart';
import '../roll_log/roll_log.dart';
import '../widgets/header.dart';
import 'meaning_table.dart';
import 'meaning_tables_view.dart';

class MeaningTablesController extends GetxController {
  final tables = <MeaningTable>[].obs;
  final favorites = <String>{}.obs;

  StreamSubscription<String>? _languageSubscription;

  @override
  void onInit() {
    super.onInit();

    _languageSubscription =
        Get.find<MeaningTablesService>().language.listen((_) {
      _init();
    });

    _init();
  }

  @override
  void onClose() {
    _languageSubscription?.cancel();

    super.onClose();
  }

  void _init() {
    favorites.replaceAll(
        Get.find<GlobalSettingsService>().favoriteMeaningTables.toSet()
          ..addAll(Get.find<AdventureService>().favoriteMeaningTables));

    final sortedTables =
        Get.find<MeaningTablesService>().meaningTables.toList(growable: false);
    sortedTables.sort((a, b) {
      final isFavoriteA = favorites.contains(a.id);
      final isFavoriteB = favorites.contains(b.id);

      if (isFavoriteA == isFavoriteB) {
        final orderA = a.order ?? 1000;
        final orderB = b.order ?? 1000;

        if (orderA == orderB) {
          return a.name.compareUsingLocale(b.name);
        } else {
          return orderA - orderB;
        }
      } else {
        return isFavoriteA ? -1 : 1;
      }
    });

    tables.replaceAll(sortedTables);
  }

  Future<void> chooseFavorite(MeaningTable table) async {
    final choice = await Get.dialog<String>(
      SimpleDialog(
        title: const Text('Set favorite for'),
        children: [
          ('global', 'All Adventures'),
          ('adventure', 'The current Adventure only'),
          ('none', 'Not favorite'),
        ]
            .map(
              (e) => SimpleDialogOption(
                onPressed: () {
                  Get.back(result: e.$1);
                },
                child: Text(e.$2),
              ),
            )
            .toList(),
      ),
      barrierDismissible: true,
    );

    if (choice != null) {
      final globalSettings = Get.find<GlobalSettingsService>();
      final adventure = Get.find<AdventureService>();

      bool hasChanged = false;
      switch (choice) {
        case 'global':
          hasChanged = globalSettings.addMeaningTableFavorite(table.id);
          hasChanged |= adventure.removeMeaningTableFavorite(table.id);
          break;
        case 'adventure':
          hasChanged = globalSettings.removeMeaningTableFavorite(table.id);
          hasChanged |= adventure.addMeaningTableFavorite(table.id);
          break;
        case 'none':
          hasChanged = globalSettings.removeMeaningTableFavorite(table.id);
          hasChanged |= adventure.removeMeaningTableFavorite(table.id);
          break;
      }

      if (hasChanged) {
        _init();
      }
    }
  }

  List<MeaningTableSubRoll> roll(String tableId, {bool addToLog = true}) {
    // a roll includes 2 rolls, usually on the same table
    // except for actions and descriptions which have 2 separate tables.
    final table = Get.find<MeaningTablesService>()
        .meaningTables
        .firstWhere((e) => e.id == tableId);

    MeaningTableSubRoll createSubRoll(int index, int entryCount) {
      return MeaningTableSubRoll(
          entryId: '${tableId}_$index',
          dieRoll: Random().nextInt(entryCount) + 1);
    }

    final results = [
      createSubRoll(1, table.entryCount1),
      createSubRoll(
        table.entryCount2 != null ? 2 : 1,
        table.entryCount2 ?? table.entryCount1,
      )
    ];

    if (addToLog) {
      Get.find<RollLogService>().addMeaningTableRoll(
        tableId: tableId,
        results: results,
      );
    }

    return results;
  }

  void showDetails(MeaningTable table) {
    Get.find<LayoutController>().meaningTableDetails(table);
  }

  Widget getHeader() => const Header('Meaning Tables');

  /// The buttons for each table.
  ///
  /// This function must be called inside an [Obx]
  /// to benefit from favorite re-ordering.
  List<Widget> getButtons({required bool isSmallLayout}) => tables
      .map((e) => MeaningTableButton(
            e,
            isFavorite: favorites.contains(e.id),
            isSmallLayout: isSmallLayout,
            key: ValueKey(e.id),
          ))
      .toList();
}
