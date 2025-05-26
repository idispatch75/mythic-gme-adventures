import 'package:get/get.dart';

import '../../helpers/json_utils.dart';
import '../../helpers/utils.dart';
import '../../persisters/persister.dart';
import '../fate_chart/fate_chart.dart';

class AdventureService extends GetxService with SavableMixin {
  static const supportedSchemaVersion = 3;

  final int schemaVersion;
  final int id;
  final Rx<String> name;
  FateChartType fateChartType;
  Set<String> favoriteMeaningTables;
  final RxBool isPreparedAdventure;
  final Rx<int?> saveTimestamp;

  AdventureService({
    this.schemaVersion = supportedSchemaVersion,
    int? id,
    required String name,
    this.fateChartType = FateChartType.standard,
    Set<String>? favoriteMeaningTables,
    bool isPreparedAdventure = false,
    int? saveTimestamp,
  }) : id = id ?? newId,
       name = name.obs,
       favoriteMeaningTables = favoriteMeaningTables ?? {},
       isPreparedAdventure = isPreparedAdventure.obs,
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
    'schemaVersion': supportedSchemaVersion,
    'id': id,
    'name': name(),
    'fateChartType': fateChartTypeToJson(fateChartType),
    'favoriteMeaningTables': favoriteMeaningTables.toList(),
    'isPreparedAdventure': isPreparedAdventure(),
    if (saveTimestamp() != null) 'saveTimestamp': saveTimestamp(),
  };

  AdventureService.fromJson(JsonObj json)
    : this(
        schemaVersion: json['schemaVersion'] ?? 1,
        id: json['id'],
        name: json['name'],
        fateChartType: fateChartTypeFromJson(json['fateChartType']),
        favoriteMeaningTables: fromJsonValueList<String>(
          json['favoriteMeaningTables'],
        ).toSet(),
        isPreparedAdventure: json['isPreparedAdventure'] ?? false,
        saveTimestamp: json['saveTimestamp'],
      );
}
