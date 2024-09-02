import 'package:flutter/material.dart';

class SubLabel extends StatelessWidget {
  final String text;
  final double topPadding;

  const SubLabel(this.text, {this.topPadding = 4, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(top: topPadding),
      child: Text(
        text,
        softWrap: true,
        style: getTextStyle(theme),
      ),
    );
  }

  static TextStyle getTextStyle(ThemeData theme) => theme.textTheme.labelSmall!;
}
