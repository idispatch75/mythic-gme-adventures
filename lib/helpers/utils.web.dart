import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart';

import 'json_utils.dart';

Future<JsonObj?> pickFileAsJson({required String dialogTitle}) {
  return _pickFile(
    dialogTitle: dialogTitle,
    extension: 'json',
    fileReader: (file, completer) {
      file.text().toDart.then((text) {
        completer.complete(jsonDecode(text.toDart));
      });
    },
  );
}

Future<Uint8List?> pickFileAsBytes({
  required String dialogTitle,
  required String extension,
}) {
  return _pickFile(
    dialogTitle: dialogTitle,
    extension: extension,
    fileReader: (file, completer) {
      file.arrayBuffer().toDart.then((bytes) {
        completer.complete(bytes.toDart.asUint8List());
      });
    },
  );
}

Future<T?> _pickFile<T>({
  required String dialogTitle,
  required String extension,
  required void Function(File, Completer<T?>) fileReader,
}) async {
  final loadEnded = Completer<T?>();

  final uploadInput = HTMLInputElement()..type = 'file';
  uploadInput.draggable = true;
  uploadInput.accept = '.$extension';
  _addToDom(uploadInput);
  uploadInput.showPicker();

  uploadInput.onChange.listen((e) {
    final files = uploadInput.files;
    final file = files?.item(0);
    if (file == null) {
      loadEnded.complete(null);
    } else {
      fileReader(file, loadEnded);
    }
  });

  return loadEnded.future;
}

Future<void> saveTextFile(
  String text, {
  required String fileName,
  required String dialogTitle,
}) async {
  final blob = Blob(
    <JSUint8Array>[utf8.encoder.convert(text).toJS].toJS,
    BlobPropertyBag(type: 'text/plain'),
  );

  return _saveBlobFile(blob, fileName: fileName);
}

Future<void> saveBinaryFile(
  Uint8List bytes, {
  required String fileName,
  required String dialogTitle,
}) async {
  final blob = Blob(
    <JSUint8Array>[bytes.toJS].toJS,
    BlobPropertyBag(type: 'application/octet-stream'),
  );

  return _saveBlobFile(blob, fileName: fileName);
}

Future<void> _saveBlobFile(
  Blob blob, {
  required String fileName,
}) async {
  final url = URL.createObjectURL(blob);

  final element = HTMLAnchorElement()
    ..href = url
    ..download = fileName;
  _addToDom(element);
  element.click();
}

void _addToDom(Element element) {
  const containerId = '__file-container';

  Element? target = document.getElementById(containerId);
  if (target == null) {
    target = document.createElement(containerId)..id = containerId;

    document.body!.appendChild(target);
  } else {
    while (target.children.length > 0) {
      target.removeChild(target.children.item(0)!);
    }
  }

  target.appendChild(element);
}
