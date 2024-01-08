import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'sub_label.dart';

class BooleanSetting extends StatelessWidget {
  final RxBool setting;
  final String text;
  final String? subtext;
  final bool hasTopPadding;

  const BooleanSetting({
    required this.setting,
    required this.text,
    this.subtext,
    this.hasTopPadding = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    Widget widget = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(text, softWrap: true),
              if (subtext != null) SubLabel(subtext!),
            ],
          ),
        ),
        Obx(
          () => Switch.adaptive(
            value: setting(),
            onChanged: setting.call,
          ),
        ),
      ],
    );

    if (hasTopPadding) {
      widget = Padding(
        padding: const EdgeInsets.only(top: 16.0),
        child: widget,
      );
    }

    return widget;
  }
}
