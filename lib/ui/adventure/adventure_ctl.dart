import 'dart:async';

import 'package:get/get.dart';

import '../../helpers/get_extensions.dart';
import '../../helpers/utils.dart';
import '../../persisters/adventure_persister.dart';
import '../../persisters/meaning_tables_persister.dart';
import '../../persisters/persister.dart';
import '../fate_chart/fate_chart.dart';
import '../layouts/layout.dart';
import '../meaning_tables/meaning_tables_ctl.dart';
import 'adventure_info_controller.dart';

class AdventureController extends GetxController with StateMixin<bool> {
  final int _id;

  AdventureController(this._id);

  @override
  Future<void> onInit() async {
    super.onInit();

    try {
      await Get.find<MeaningTablesPersisterService>().loadTables();
      await Get.find<AdventurePersisterService>().loadAdventure(_id);
    } on UnsupportedSchemaVersionException catch (e) {
      handleUnsupportedSchemaVersion(e).ignore();

      return;
    }

    Get.replaceForced(AdventureInfoController());
    Get.replaceForced(MeaningTablesController());
    Get.replaceForced(FateChartService());
    Get.replaceForced(LayoutController());

    change(true, status: RxStatus.success());
  }
}
