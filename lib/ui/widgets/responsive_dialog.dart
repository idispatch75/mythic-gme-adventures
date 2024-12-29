import 'package:flutter/material.dart';

import '../layouts/layout.dart';

class ResponsiveDialog extends StatelessWidget {
  static const boxConstraints = BoxConstraints(maxHeight: 600, maxWidth: 500);

  final Widget Function(bool isFullscreen) childBuilder;
  final String? title;

  /// A dialog that displays in full screen on phones,
  /// and with a reasonable size otherwise.
  const ResponsiveDialog({required this.childBuilder, super.key})
      : title = null;

  const ResponsiveDialog.withAppBar({
    required this.childBuilder,
    required String this.title,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    Widget dialogContent(bool isFullscreen) {
      Widget widget = Padding(
        padding: EdgeInsets.fromLTRB(8, title != null ? 0 : 8, 8, 0),
        child: childBuilder(isFullscreen),
      );

      if (title != null) {
        widget = Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: Text(title!),
            backgroundColor: Colors.transparent,
            automaticallyImplyLeading: false,
            leading: const CloseButton(),
            scrolledUnderElevation: 0,
            centerTitle: true,
          ),
          body: widget,
        );
      }

      return ConstrainedBox(
        constraints: boxConstraints,
        child: widget,
      );
    }

    return LayoutBuilder(
      builder: (_, constraints) => constraints.maxWidth <= kPhoneBreakPoint
          ? Dialog.fullscreen(child: dialogContent(true))
          : Dialog(child: dialogContent(false)),
    );
  }
}
