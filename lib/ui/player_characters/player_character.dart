import 'package:get/get.dart';

import '../../helpers/utils.dart';
import '../../persisters/persister.dart';

class PlayerCharacter {
  String name;
  String? notes;

  PlayerCharacter(this.name, {this.notes});

  Map<String, dynamic> toJson() => {
        'name': name,
        if (notes != null) 'notes': notes,
      };

  PlayerCharacter.fromJson(Map<String, dynamic> json)
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

  Map<String, dynamic> toJson() => {
        'playerCharacters': playerCharacters,
      };

  PlayerCharactersService.fromJson(Map<String, dynamic> json) {
    for (var item
        in fromJsonList(json['playerCharacters'], PlayerCharacter.fromJson)) {
      add(item);
    }
  }
}
