import 'package:get/get.dart';

import '../../helpers/json_utils.dart';
import '../../persisters/persister.dart';

class Feature {
  String name;
  String? notes;
  bool isArchived;

  Feature(
    this.name, {
    this.notes,
    this.isArchived = false,
  });

  JsonObj toJson() => {
        'name': name,
        if (notes != null) 'notes': notes,
        'isArchived': isArchived,
      };

  Feature.fromJson(JsonObj json)
      : this(
          json['name'],
          notes: json['notes'],
          isArchived: json['isArchived'],
        );
}

class FeaturesService extends GetxService with SavableMixin {
  final features = <Rx<Feature>>[].obs;

  FeaturesService();

  void add(Feature feature) {
    features.add(feature.obs);

    requestSave();
  }

  void delete(Feature feature) {
    features.removeWhere((e) => e.value == feature);

    requestSave();
  }

  JsonObj toJson() => {
        'features': features,
      };

  FeaturesService.fromJson(JsonObj json) {
    for (var item in fromJsonList(json['features'], Feature.fromJson)) {
      add(item);
    }
  }
}
