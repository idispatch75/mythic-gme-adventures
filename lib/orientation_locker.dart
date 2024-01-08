import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'ui/layouts/layout.dart';

class OrientationLocker extends StatefulWidget {
  final Widget child;

  /// A widget that locks the screen to portrait
  /// if it is less than [kPhoneBreakPoint] logical pixels wide.
  const OrientationLocker({required this.child, super.key});

  @override
  State<OrientationLocker> createState() => _OrientationLockerState();
}

class _OrientationLockerState extends State<OrientationLocker>
    with WidgetsBindingObserver {
  FlutterView? _view;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _view = View.maybeOf(context);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _view = null;

    super.dispose();
  }

  @override
  void didChangeMetrics() {
    final Display? display = _view?.display;
    if (display == null) {
      return;
    }
    if (display.size.width / display.devicePixelRatio < kPhoneBreakPoint) {
      SystemChrome.setPreferredOrientations(<DeviceOrientation>[
        DeviceOrientation.portraitUp,
      ]);
    } else {
      SystemChrome.setPreferredOrientations(<DeviceOrientation>[]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
