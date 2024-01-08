import 'package:flutter/material.dart';

class SubLabel extends StatelessWidget {
  final String text;

  const SubLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        text,
        softWrap: true,
        style: getTextStyle(theme),
      ),
    );
  }

  static TextStyle getTextStyle(ThemeData theme) => theme.textTheme.labelSmall!;
}
