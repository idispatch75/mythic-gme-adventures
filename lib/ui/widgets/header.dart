import 'package:flutter/material.dart';

import '../styles.dart';

class Header extends StatelessWidget {
  final String _text;

  /// A header using [headerColor] as background.
  const Header(this._text, {super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: AppStyles.headerColor,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 3, 4, 2),
          child: Text(
            _text.toUpperCase(),
            style: theme.textTheme.titleMedium!
                .copyWith(color: AppStyles.onHeaderColor),
          ),
        ),
      ),
    );
  }
}
