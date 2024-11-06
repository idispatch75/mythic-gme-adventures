import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:get/get.dart';

import 'json_utils.dart';

Future<JsonObj?> pickFileAsJson({required String dialogTitle}) async {
  final filePath =
      await _pickFilePath(dialogTitle: dialogTitle, extension: 'json');
  if (filePath == null) {
    return null;
  }

  final text = await File(filePath).readAsString();

  return jsonDecode(text);
}

Future<Uint8List?> pickFileAsBytes({
  required String dialogTitle,
  required String extension,
}) async {
  final filePath =
      await _pickFilePath(dialogTitle: dialogTitle, extension: extension);
  if (filePath == null) {
    return null;
  }

  final bytes = await File(filePath).readAsBytes();

  return bytes;
}

Future<String?> _pickFilePath({
  required String dialogTitle,
  required String extension,
}) async {
  final result = await FilePicker.platform.pickFiles(
    dialogTitle: dialogTitle,
    // extensions are moderately supported on Android:
    // the mime type must be known somehow
    // (and it is not for json for instance, at least on Android 8)
    type: GetPlatform.isAndroid ? FileType.any : FileType.custom,
    allowedExtensions: GetPlatform.isAndroid ? null : [extension],
  );
  if (result == null || result.count != 1) {
    return null;
  }

  return result.files[0].path!;
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

Future<void> saveBinaryFile(
  Uint8List bytes, {
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
      await file.writeAsBytes(bytes, flush: true);
    }
  } else {
    await FlutterFileDialog.saveFile(
      params: SaveFileDialogParams(
        data: bytes,
        fileName: fileName,
      ),
    );
  }
}
