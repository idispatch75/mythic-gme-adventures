import 'package:collection/collection.dart';
import 'package:get/get.dart';

import '../../helpers/json_utils.dart';
import '../../helpers/rx_list_extensions.dart';
import '../../persisters/persister.dart';

class Feature {
  final int id;
  String name;
  String? notes;
  bool isArchived;
  int displayOrder;

  Feature(
    this.id,
    this.name, {
    this.notes,
    this.isArchived = false,
    this.displayOrder = 0,
  });

  JsonObj toJson() => {
    'id': id,
    'name': name,
    if (notes != null) 'notes': notes,
    'isArchived': isArchived,
    'displayOrder': displayOrder,
  };

  Feature.fromJson(JsonObj json)
    : this(
        json['id'],
        json['name'],
        notes: json['notes'],
        isArchived: json['isArchived'],
        displayOrder: json['displayOrder'] ?? 0,
      );
}

class FeaturesService extends GetxService with SavableMixin {
  final features = <Rx<Feature>>[].obs;

  FeaturesService();

  void add(Feature feature) {
    feature.displayOrder = features.length;
    features.add(feature.obs);
    _sort();

    requestSave();
  }

  void archive(Feature feature, bool isArchived) {
    if (feature.isArchived != isArchived) {
      feature.isArchived = isArchived;

      _sort();

      requestSave();
    }
  }

  void delete(Feature feature) {
    features.removeWhere((e) => e.value == feature);

    requestSave();
  }

  void replaceAll(List<Rx<Feature>> newFeatures) {
    for (var i = 0; i < newFeatures.length; i++) {
      newFeatures[i].value.displayOrder = i;
    }
    features.replaceAll(newFeatures);
    _sort();

    requestSave();
  }

  void _sort() {
    // sort the list of items based on archived status
    features.value = features.sorted((a, b) {
      if (a.value.isArchived == b.value.isArchived) {
        return a.value.displayOrder - b.value.displayOrder;
      } else {
        return a.value.isArchived ? 1 : -1;
      }
    });
  }

  JsonObj toJson() => {
    'features': features,
  };

  FeaturesService.fromJson(JsonObj json) {
    for (var item in fromJsonList(json['features'], Feature.fromJson)) {
      features.add(item.obs);
    }

    _sort();
  }
}
