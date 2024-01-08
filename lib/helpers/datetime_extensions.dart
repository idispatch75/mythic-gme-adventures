import 'package:intl/intl.dart';

extension DateTimeExtensions on DateTime {
  bool isSameDay(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }

  static final DateFormat _timeFormat = DateFormat.jms();
  static final DateFormat _dateFormat =
      DateFormat.yMEd().addPattern("'at'").add_jms();

  String elapsedFromNow() {
    final elapsed = DateTime.now().difference(this);

    if (elapsed.inSeconds < 10) {
      return 'now';
    } else if (elapsed.inMinutes < 1) {
      return '< 1 min. ago';
    } else if (elapsed.inMinutes < 10) {
      return '${elapsed.inMinutes} min. ago';
    } else {
      if (isSameDay(DateTime.now())) {
        return 'at ${_timeFormat.format(this)}';
      } else {
        return _dateFormat.format(this);
      }
    }
  }
}
