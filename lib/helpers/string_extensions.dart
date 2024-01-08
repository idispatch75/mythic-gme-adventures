int compareIgnoreCase(String string1, String string2) {
  return string1.toLowerCase().compareTo(string2.toLowerCase());
}

extension StringExtensions on String {
  /// Returns this string
  /// or null if it is empty or blank.
  String? nullIfEmpty() => trim().isEmpty ? null : this;

  /// Compares this string to [other] while managing accents.
  int compareUsingLocale(String other) {
    return _toAscii(this).compareTo(_toAscii(other));
  }

  /// Indicates whether this string contains an [other] string,
  /// ignoring case and accents.
  bool containsUsingLocale(String other) {
    return _toAscii(this).contains(_toAscii(other));
  }

  String _toAscii(String s) {
    return s.toLowerCase().replaceAll(_toAsciiE, 'e');
  }

  static final _toAsciiE = RegExp(r'[éèêë]');
}

extension NullableStringExtensions on String? {
  /// Returns true if the string is null, empty or blank.
  bool isNullOrEmpty() {
    final s = this;
    return s == null || s.trim().isEmpty;
  }

  /// Returns true if the string is not null, empty or blank.
  bool isNotNullOrEmpty() => !isNullOrEmpty();

  bool equalsIgnoreCase(String? other) {
    return this?.toLowerCase() == other?.toLowerCase();
  }
}
