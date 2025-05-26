import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../helpers/json_utils.dart';

class MeaningTable {
  final String id;
  int? order;
  String? get characterTrait =>
      Get.find<MeaningTablesService>().getMeaningTableCharacterTrait(id);
  final int entryCount1;
  final int? entryCount2;
  String get name => Get.find<MeaningTablesService>().getMeaningTableName(id);

  MeaningTable({
    required this.id,
    required this.entryCount1,
    this.order,
    this.entryCount2,
  });

  @override
  int get hashCode => id.hashCode;

  @override
  bool operator ==(Object other) {
    return other is MeaningTable && id == other.id;
  }
}

class MeaningTablesService extends GetxService {
  final meaningTables = <MeaningTable>{};
  final language = _defaultLanguage.obs;

  static const String _defaultLanguage = 'en';
  final Map<String, Map<String, String>> _translations = {};

  List<String> get languageCodes => _translations.keys.toList();

  Future<void> loadFromAssets() async {
    final assetManifest = await AssetManifest.loadFromAssetBundle(rootBundle);

    for (var asset in assetManifest.listAssets().where(
      (string) => string.startsWith('assets/meaning_tables/'),
    )) {
      // parse the asset
      final json = await rootBundle.loadString(asset);

      // add the table to the meaning tables
      final locale = asset.split('/')[2];
      addTableFromJson(locale: locale, json: json);
    }
  }

  /// Adds a table to [meaningTables] and updates the translations.
  void addTableFromJson({required String locale, required String json}) {
    // parse the JSON
    final JsonObj table = jsonDecode(json);
    final String id = table['id'];
    final String name = table['name'];
    final String? characterTrait = table['characterTrait'];
    final int? order = table['order'];
    final List<dynamic> entries1 = table['entries'];
    final List<dynamic>? entries2 = table['entries2'];

    // add the table to the known tables,
    // or update the order if it already exists
    final newTable = MeaningTable(
      id: id,
      order: order,
      entryCount1: entries1.length,
      entryCount2: entries2?.length,
    );
    final currentTable = meaningTables.lookup(newTable);
    if (currentTable == null) {
      meaningTables.add(newTable);
    } else {
      if (newTable.order != null) {
        currentTable.order = newTable.order;
      }
    }

    // update the locale
    final localeEntries = <String, String>{};
    localeEntries['meaning_tables.$id.name'] = name;
    if (characterTrait != null) {
      localeEntries['meaning_tables.$id.characterTrait'] = characterTrait;
    }

    void addEntryTranslations(List<dynamic> entries, int index) {
      for (var i = 0; i < entries.length; i++) {
        localeEntries['meaning_tables.${id}_$index.${i + 1}'] = entries[i];
      }
    }

    addEntryTranslations(entries1, 1);
    if (entries2 != null) {
      addEntryTranslations(entries2, 2);
    }

    _appendTranslations({locale: localeEntries});
  }

  String getMeaningTableName(String tableId) {
    return _getTranslation('meaning_tables.$tableId.name');
  }

  String? getMeaningTableCharacterTrait(String tableId) {
    final key = 'meaning_tables.$tableId.characterTrait';
    return _translations[language()]?[key];
  }

  String getMeaningTableEntry(String entryId, int dieRoll) {
    return _getTranslation('meaning_tables.$entryId.$dieRoll');
  }

  void _appendTranslations(Map<String, Map<String, String>> newTranslations) {
    newTranslations.forEach((language, map) {
      if (_translations.containsKey(language)) {
        _translations[language]!.addAll(map);
      } else {
        _translations[language] = map;
      }
    });
  }

  String _getTranslation(String key) {
    return _translations[language()]?[key] ??
        _translations[_defaultLanguage]?[key] ??
        key;
  }
}
