import 'package:get/get.dart';

import '../../helpers/json_utils.dart';
import '../../helpers/utils.dart';
import '../../persisters/persister.dart';
import '../fate_chart/fate_chart.dart';

class AdventureService extends GetxService with SavableMixin {
  final int id;
  final Rx<String> name;
  FateChartType fateChartType;
  Set<String> favoriteMeaningTables;
  final Rx<int?> saveTimestamp;

  AdventureService({
    int? id,
    required String name,
    this.fateChartType = FateChartType.standard,
    Set<String>? favoriteMeaningTables,
    int? saveTimestamp,
  })  : id = id ?? newId,
        name = name.obs,
        favoriteMeaningTables = favoriteMeaningTables ?? {},
        saveTimestamp = saveTimestamp.obs;

  bool addMeaningTableFavorite(String id) {
    if (favoriteMeaningTables.add(id)) {
      requestSave();
      return true;
    }

    return false;
  }

  bool removeMeaningTableFavorite(String id) {
    if (favoriteMeaningTables.remove(id)) {
      requestSave();
      return true;
    }

    return false;
  }

  String toTag() => id.toString();

  JsonObj toJson() => {
        'id': id,
        'name': name(),
        'fateChartType': fateChartTypeToJson(fateChartType),
        'favoriteMeaningTables': favoriteMeaningTables.toList(),
        if (saveTimestamp() != null) 'saveTimestamp': saveTimestamp(),
      };

  AdventureService.fromJson(JsonObj json)
      : this(
          id: json['id'],
          name: json['name'],
          fateChartType: fateChartTypeFromJson(json['fateChartType']),
          favoriteMeaningTables:
              fromJsonValueList<String>(json['favoriteMeaningTables']).toSet(),
          saveTimestamp: json['saveTimestamp'],
        );
}
