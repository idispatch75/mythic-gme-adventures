// ignore_for_file: invalid_use_of_protected_member

import 'package:get/get.dart';

extension RxListExtension<E> on RxList<E> {
  /// Replaces all existing items of this list with [items].
  // Replaces assignAll() to avoid the useless call to refresh() when clearing
  void replaceAll(Iterable<E> items) {
    value.length = 0;
    addAll(items);
  }

  /// Updates the raw list in the updater and then refreshes.
  void update(void Function(List<E>) updater) {
    updater(value);
    refresh();
  }
}

extension RxSetExtension<E> on RxSet<E> {
  /// Replaces all existing items of this set with [items].
  // Replaces assignAll() to avoid the useless call to refresh() when clearing
  void replaceAll(Iterable<E> items) {
    value.clear();
    addAll(items);
  }
}
