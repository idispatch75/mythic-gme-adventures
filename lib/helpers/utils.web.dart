import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';

import 'package:web/web.dart';

import 'json_utils.dart';

Future<JsonObj?> pickFileAsJson({required String dialogTitle}) async {
  final loadEnded = Completer<JsonObj?>();

  final uploadInput = HTMLInputElement()..type = 'file';
  uploadInput.draggable = true;
  uploadInput.accept = '.json';
  _addToDom(uploadInput);
  uploadInput.showPicker();

  uploadInput.onChange.listen((e) {
    final files = uploadInput.files;
    final file = files?.item(0);
    if (file == null) {
      loadEnded.complete(null);
    } else {
      file.text().toDart.then((text) {
        loadEnded.complete(jsonDecode(text.toDart));
      });
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
