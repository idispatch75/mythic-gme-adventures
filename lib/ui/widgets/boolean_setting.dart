import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'sub_label.dart';

class BooleanSetting extends StatelessWidget {
  final RxBool setting;
  final String text;
  final String? subtext;
  final bool withTopPadding;

  const BooleanSetting({
    required this.setting,
    required this.text,
    this.subtext,
    this.withTopPadding = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    Widget widget = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(text, softWrap: true),
        ),
        Obx(
          () => Switch.adaptive(
            value: setting(),
            onChanged: setting.call,
          ),
        ),
      ],
    );

    if (subtext != null) {
      widget = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          widget,
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: SubLabel(
              subtext!,
              topPadding: 0,
            ),
          ),
        ],
      );
    }

    if (withTopPadding) {
      widget = Padding(
        padding: const EdgeInsets.only(top: 16.0),
        child: widget,
      );
    }

    return widget;
  }
}
