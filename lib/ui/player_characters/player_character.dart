import 'package:get/get.dart';

import '../../helpers/json_utils.dart';
import '../../persisters/persister.dart';

class PlayerCharacter {
  String name;
  String? notes;

  PlayerCharacter(this.name, {this.notes});

  JsonObj toJson() => {
    'name': name,
    if (notes != null) 'notes': notes,
  };

  PlayerCharacter.fromJson(JsonObj json)
    : this(json['name'], notes: json['notes']);
}

class PlayerCharactersService extends GetxService with SavableMixin {
  var playerCharacters = <Rx<PlayerCharacter>>[].obs;

  PlayerCharactersService();

  void add(PlayerCharacter player) {
    playerCharacters.add(player.obs);

    requestSave();
  }

  void delete(PlayerCharacter player) {
    playerCharacters.removeWhere((e) => e.value == player);

    requestSave();
  }

  JsonObj toJson() => {
    'playerCharacters': playerCharacters,
  };

  PlayerCharactersService.fromJson(JsonObj json) {
    for (var item in fromJsonList(
      json['playerCharacters'],
      PlayerCharacter.fromJson,
    )) {
      add(item);
    }
  }
}
