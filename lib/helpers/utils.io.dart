import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:get/get.dart';

import 'json_utils.dart';

Future<JsonObj?> pickFileAsJson({required String dialogTitle}) async {
  final result = await FilePicker.platform.pickFiles(
    dialogTitle: dialogTitle,
    allowedExtensions: ['json'],
  );
  if (result == null || result.count != 1) {
    return null;
  }

  final filePath = result.files[0].path!;

  final text = await File(filePath).readAsString();

  return jsonDecode(text);
}

Future<void> saveTextFile(
  String text, {
  required String fileName,
  required String dialogTitle,
}) async {
  if (GetPlatform.isDesktop) {
    final exportFile = await FilePicker.platform.saveFile(
      dialogTitle: dialogTitle,
      fileName: fileName,
    );

    if (exportFile != null) {
      final file = File(exportFile);
      await file.writeAsString(text, flush: true);
    }
  } else {
    await FlutterFileDialog.saveFile(
      params: SaveFileDialogParams(
        data: utf8.encoder.convert(text),
        fileName: fileName,
      ),
    );
  }
}
