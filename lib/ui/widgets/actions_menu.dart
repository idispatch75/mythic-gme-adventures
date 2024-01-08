import 'package:flutter/material.dart';

class ActionsMenu extends StatelessWidget {
  final List<Widget> _menuChildren;

  const ActionsMenu(this._menuChildren, {super.key});

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      builder: (
        BuildContext context,
        MenuController controller,
        Widget? child,
      ) =>
          IconButton(
        onPressed: () {
          if (controller.isOpen) {
            controller.close();
          } else {
            controller.open();
          }
        },
        icon: Icon(Icons.adaptive.more),
      ),
      menuChildren: _menuChildren,
    );
  }
}
