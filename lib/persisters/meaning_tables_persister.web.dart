import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

import '../storages/data_storage.dart';

Future<void> saveCustomTablesFromZip(
  Uint8List zipContent,
  List<String> destinationDirectory,
  DataStorage storage,
) async {
  final archive = ZipDecoder().decodeBytes(zipContent);

  // TODO delete all
  final jsonFiles = archive.where((e) => e.isFile && e.name.endsWith('.json'));
  for (final file in jsonFiles) {
    final parts = file.name.split('/');
    if (parts.length == 2) {
      final content = utf8.decoder.convert(file.content as List<int>);
      await storage
          .save([...destinationDirectory, parts[0]], parts[1], content);
    }
  }
}
