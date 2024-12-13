import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

abstract class AppStyles {
  static final ThemeData lightTheme = _buildTheme(
    ColorScheme.fromSeed(
      seedColor: _primaryColor,
      primary: _primaryColor,
      secondary: _secondaryColor,
      brightness: Brightness.light,
    ),
  );

  static final ThemeData darkTheme = _buildTheme(
    ColorScheme.fromSeed(
      seedColor: _primaryColor,
      brightness: Brightness.dark,
    ),
  );

  static Color get headerColor => _headerColor;
  static Color _headerColor = _theme.colorScheme.primary;

  static Color get onHeaderColor => _onHeaderColor;
  static Color _onHeaderColor = _theme.colorScheme.onPrimary;

  static RollColors get fateChartColors => _fateChartColors;
  static RollColors _fateChartColors = _fateChartColorsLight;

  static RollColors get meaningTableColors => _meaningTableColors;
  static RollColors _meaningTableColors = _meaningTableColorsLight;

  static RollColors get randomEventColors => _randomEventColors;
  static RollColors _randomEventColors = _randomEventColorsLight;

  static RollColors get genericColors => _genericColors;
  static RollColors _genericColors = _genericColorsLight;

  static Color get sceneBadgeBackground => _sceneBadgeBackground;
  static Color _sceneBadgeBackground = Colors.grey.shade300;

  static Color get sceneBadgeOnBackground => _sceneBadgeOnBackground;
  static Color _sceneBadgeOnBackground = Colors.black;

  static const Color archivedColor = Colors.grey;

  static const EdgeInsets listTileTitlePadding = EdgeInsets.only(left: 12);

  static const rollIcon = Icon(Icons.casino_outlined);

  static TextStyle? oraclesButtonTextStyle =
      GetPlatform.isWeb || GetPlatform.isDesktop
          ? const TextStyle(fontSize: 12)
          : null;

  static const oraclesButtonMaxHeight = 36.0;

  static void setBrightness(Brightness brightness) {
    final isDarkMode = brightness == Brightness.dark;
    _theme = isDarkMode ? darkTheme : lightTheme;

    _headerColor = _theme.colorScheme.primary;
    _onHeaderColor = _theme.colorScheme.onPrimary;

    _fateChartColors = isDarkMode
        ? _fateChartColorsDark.copyWith(isDarkMode)
        : _fateChartColorsLight.copyWith(isDarkMode);
    _meaningTableColors = isDarkMode
        ? _meaningTableColorsDark.copyWith(isDarkMode)
        : _meaningTableColorsLight.copyWith(isDarkMode);
    _randomEventColors = isDarkMode
        ? _randomEventColorsDark.copyWith(isDarkMode)
        : _randomEventColorsLight.copyWith(isDarkMode);
    _genericColors = isDarkMode
        ? _genericColorsDark.copyWith(isDarkMode)
        : _genericColorsLight.copyWith(isDarkMode);

    _sceneBadgeBackground =
        isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300;
    _sceneBadgeOnBackground = isDarkMode ? Colors.white : Colors.black;
  }

  static ThemeData _theme = lightTheme;
}

class RollColors {
  final Color background;
  final Color onBackground;
  final Color header;
  final Color onHeader;

  RollColors({
    required this.background,
    this.onBackground = Colors.black,
    required this.header,
    this.onHeader = Colors.white,
  });

  RollColors copyWith(bool isDarkMode) {
    return RollColors(
      background: background,
      header: header,
      onBackground: isDarkMode ? Colors.white : Colors.black,
      onHeader: isDarkMode ? Colors.black : Colors.white,
    );
  }
}

extension TextStyleExtensions on TextStyle {
  TextStyle withSmallCaps() {
    return copyWith(fontFeatures: [const FontFeature.enable('smcp')]);
  }
}

const Color _primaryColor = Color.fromARGB(255, 47, 48, 102);
const Color _secondaryColor = Color.fromARGB(255, 86, 62, 89);

final _fateChartColorsLight = RollColors(
  background: Colors.blue.shade100,
  header: Colors.blue.shade900,
);
final _fateChartColorsDark = RollColors(
  background: _fateChartColorsLight.header,
  header: _fateChartColorsLight.background,
);

final _meaningTableColorsLight = RollColors(
  background: Colors.green.shade100,
  header: Colors.green.shade900,
);
final _meaningTableColorsDark = RollColors(
  background: _meaningTableColorsLight.header,
  header: _meaningTableColorsLight.background,
);

final _randomEventColorsLight = RollColors(
  background: Colors.indigo.shade100,
  header: Colors.indigo.shade900,
);
final _randomEventColorsDark = RollColors(
  background: _randomEventColorsLight.header,
  header: _randomEventColorsLight.background,
);

final _genericColorsLight = RollColors(
  background: Colors.grey.shade300,
  header: Colors.grey.shade600,
);
final _genericColorsDark = RollColors(
  background: _genericColorsLight.header,
  header: _genericColorsLight.background,
);

ThemeData _buildTheme(ColorScheme colorScheme) {
  final theme = ThemeData(
    colorScheme: colorScheme,
    navigationBarTheme: const NavigationBarThemeData(elevation: 6),
  );

  final textTheme = GoogleFonts.rubikTextTheme(theme.textTheme).copyWith(
    headlineMedium:
        GoogleFonts.staatliches(textStyle: theme.textTheme.headlineMedium),
    titleLarge: GoogleFonts.staatliches(textStyle: theme.textTheme.titleLarge),
    titleMedium:
        GoogleFonts.staatliches(textStyle: theme.textTheme.titleMedium),
    titleSmall: GoogleFonts.staatliches(textStyle: theme.textTheme.titleSmall),
  );

  return theme.copyWith(textTheme: textTheme);
}
