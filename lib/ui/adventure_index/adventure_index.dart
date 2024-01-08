import 'package:get/get.dart';

import '../../helpers/utils.dart';

class AdventureIndexService extends GetxService {
  final List<IndexAdventure> adventures;

  AdventureIndexService(this.adventures);

  void addAdventure(IndexAdventure adventure) {
    adventures.add(adventure);
  }

  Map<String, dynamic> toJson(bool isLocal) => {
        'adventures': adventures
            .where((e) =>
                isLocal ? e.localSaveTimestamp > 0 : e.remoteSaveTimestamp > 0)
            .toList(),
      };

  AdventureIndexService.fromJson(Map<String, dynamic> json)
      : this(
          fromJsonList(json['adventures'], IndexAdventure.fromJson),
        );
}

class IndexAdventure {
  final int id;
  String name;
  bool isDeleted;
  int? saveTimestamp;

  /// The save timestamp of the adventure if exist locally.
  ///
  /// `0` if it does not exist locally.
  int localSaveTimestamp;

  /// The save timestamp of the adventure if exist remotely.
  ///
  /// `0` if it does not exist remotely.
  int remoteSaveTimestamp;

  IndexAdventure({
    required this.id,
    required this.name,
    this.isDeleted = false,
    this.saveTimestamp,
    this.localSaveTimestamp = 0,
    this.remoteSaveTimestamp = 0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (isDeleted) 'deleted': true,
        if (saveTimestamp != null) 'saveTimestamp': saveTimestamp,
      };

  IndexAdventure.fromJson(Map<String, dynamic> json)
      : this(
          id: json['id'],
          name: json['name'],
          isDeleted: json['deleted'] ?? false,
          saveTimestamp: json['saveTimestamp'],
        );

  @override
  int get hashCode => id;

  @override
  bool operator ==(Object other) {
    return other is IndexAdventure && other.id == id;
  }
}
