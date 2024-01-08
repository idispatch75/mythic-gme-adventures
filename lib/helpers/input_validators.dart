import 'string_extensions.dart';

String? validateNotEmpty(String? value) {
  if (value.isNullOrEmpty()) {
    return 'The field is mandatory';
  }
  return null;
}
