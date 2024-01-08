// ignore_for_file: avoid_print

import 'package:loggy/loggy.dart';

class LogPrinter extends LoggyPrinter {
  const LogPrinter();

  @override
  void onLog(LogRecord record) {
    final time = record.time.toIso8601String().split('T')[1];
    final callerFrame =
        record.callerFrame == null ? '-' : '(${record.callerFrame?.location})';
    final logLevel = record.level
        .toString()
        .toUpperCase()
        .padRight(LogLevel.warning.toString().length);

    print(
        '$time $logLevel ${record.loggerName} $callerFrame ${record.message}');

    if (record.error != null) {
      print(record.error);
    }

    if (record.stackTrace != null) {
      print(record.stackTrace);
    }
  }
}
