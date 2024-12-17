import 'package:animated_list_plus/animated_list_plus.dart';
import 'package:flutter/material.dart';

/// Builds an animated list view with a [Divider] as separator.
Widget defaultAnimatedListView<TItem extends Object>({
  required List<TItem> items,
  required Widget Function(BuildContext, TItem item, int index) itemBuilder,
  required Widget Function(BuildContext, TItem item) removedItemBuilder,
  bool Function(TItem a, TItem b)? comparer,
}) {
  return ImplicitlyAnimatedList<TItem>(
    items: items,
    areItemsTheSame: comparer ?? (a, b) => a == b,
    insertDuration: _insertDuration,
    removeDuration: _removeDuration,
    updateDuration: _updateDuration,
    itemBuilder: (context, animation, item, index) =>
        _buildItemBuilderTransition(
      animation: animation,
      child: itemBuilder(context, item, index),
    ),
    removeItemBuilder: (context, animation, item) =>
        _buildRemoveItemBuilderTransition(
      animation: animation,
      child: removedItemBuilder(context, item),
    ),
    separatorBuilder: (_, __) => _buildSeparator(),
  );
}

/// Builds a reorderable list view with a [Divider] as separator.
Widget defaultReorderableListView<TItem extends Object>({
  required List<TItem> items,
  required Widget Function(BuildContext, TItem item, int index) itemBuilder,
  required Widget Function(BuildContext, TItem item) removedItemBuilder,
  required void Function(List<TItem> newItems) onReorderFinished,
  bool Function(TItem a, TItem b)? comparer,
  Key Function(TItem)? keyProvider,
}) {
  assert((keyProvider == null) == (comparer == null));

  return ImplicitlyAnimatedReorderableList<TItem>.separated(
    items: items,
    areItemsTheSame: comparer ?? (a, b) => a == b,
    insertDuration: _insertDuration,
    removeDuration: _removeDuration,
    updateDuration: _updateDuration,
    itemBuilder: (context, animation, item, index) => Reorderable(
      key: keyProvider != null ? keyProvider(item) : ValueKey(item),
      child: _buildItemBuilderTransition(
        animation: animation,
        child: _ReorderableView(
          child: itemBuilder(context, item, index),
        ),
      ),
    ),
    removeItemBuilder: (context, animation, item) => Reorderable(
      key: keyProvider != null ? keyProvider(item) : ValueKey(item),
      child: _buildRemoveItemBuilderTransition(
        animation: animation,
        child: _ReorderableView(
          isDeleted: true,
          child: removedItemBuilder(context, item),
        ),
      ),
    ),
    separatorBuilder: (_, __) => _buildSeparator(),
    onReorderFinished: (item, from, to, newItems) =>
        onReorderFinished(newItems),
  );
}

class _ReorderableView extends StatelessWidget {
  final Widget child;
  final bool isDeleted;

  const _ReorderableView({required this.child, this.isDeleted = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Handle(
          enabled: !isDeleted,
          delay: const Duration(milliseconds: 0),
          child: Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Icon(
              Icons.drag_handle,
              color: Theme.of(context).colorScheme.onSurface.withAlpha(100),
            ),
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}

Widget _buildItemBuilderTransition({
  required Animation<double> animation,
  required Widget child,
}) {
  return SizeTransition(
    sizeFactor: CurvedAnimation(parent: animation, curve: Curves.easeOut),
    child: child,
  );
}

Widget _buildRemoveItemBuilderTransition({
  required Animation<double> animation,
  required Widget child,
}) {
  return SizeTransition(
    sizeFactor: CurvedAnimation(parent: animation, curve: Curves.easeIn),
    child: child,
  );
}

Widget _buildSeparator() {
  return const Divider(height: 0, thickness: 1);
}

const _insertDuration = Duration(milliseconds: 500);
const _removeDuration = Duration(milliseconds: 400);
const _updateDuration = Duration(milliseconds: 300);
