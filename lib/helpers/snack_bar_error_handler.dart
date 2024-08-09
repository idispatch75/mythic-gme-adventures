import 'package:catcher_2/model/platform_type.dart';
import 'package:catcher_2/model/report.dart';
import 'package:catcher_2/model/report_handler.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:loggy/loggy.dart';

/// Handler which displays error report as snack bar.
class SnackBarErrorHandler extends ReportHandler {
  SnackBarErrorHandler();

  /// Handle report. If there's scaffold messenger in provided context, then
  /// snackbar will be shown.
  @override
  Future<bool> handle(Report report, BuildContext? context) async {
    try {
      if (!_hasScaffoldMessenger(context!)) {
        _printLog('Passed context has no ScaffoldMessenger in widget ancestor');
        return false;
      }

      final message = 'An error occurred: ${report.error}';

      final colorTheme = Theme.of(context).colorScheme;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(minutes: 5),
          content: Text(
            message,
            style: TextStyle(color: colorTheme.onErrorContainer),
          ),
          backgroundColor: colorTheme.errorContainer,
          width: 500,
          behavior: SnackBarBehavior.floating,
          showCloseIcon: true,
          closeIconColor: colorTheme.onErrorContainer,
        ),
      );
      return true;
    } catch (exception, stackTrace) {
      _printLog('Failed to show snackbar: $exception, $stackTrace');
      return false;
    }
  }

  /// Checks whether context has scaffold messenger.
  bool _hasScaffoldMessenger(BuildContext context) {
    try {
      return context.findAncestorWidgetOfExactType<ScaffoldMessenger>() != null;
    } catch (exception, stackTrace) {
      _printLog('_hasScaffoldMessenger failed: $exception, $stackTrace');
      return false;
    }
  }

  void _printLog(String log) {
    if (kDebugMode) {
      logError(log);
    }
  }

  @override
  bool isContextRequired() => true;

  @override
  List<PlatformType> getSupportedPlatforms() => [
        PlatformType.android,
        PlatformType.iOS,
        PlatformType.web,
        PlatformType.linux,
        PlatformType.macOS,
        PlatformType.windows,
      ];
}
