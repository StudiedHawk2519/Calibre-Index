import 'package:material_ui/material_ui.dart';

class ColorTheme extends ChangeNotifier {
  ColorTheme(
    this._darkMode, {
    this.seedColor = const Color(0xFF52638A),
    this.lightDynamicScheme,
    this.darkDynamicScheme,
  });

  final Color seedColor;
  final ColorScheme? lightDynamicScheme;
  final ColorScheme? darkDynamicScheme;
  bool _darkMode;

  ColorScheme get lightColorScheme =>
      lightDynamicScheme ?? _createFallbackScheme(Brightness.light);
  ColorScheme get darkColorScheme =>
      darkDynamicScheme ?? _createFallbackScheme(Brightness.dark);
  ColorScheme get colorScheme => _darkMode ? darkColorScheme : lightColorScheme;

  ColorScheme _createFallbackScheme(Brightness brightness) =>
      ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: brightness,
        dynamicSchemeVariant: DynamicSchemeVariant.tonalSpot,
      );

  ThemeData get themeData => themeDataFor(colorScheme);

  ThemeData themeDataFor(ColorScheme scheme) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLow,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: 0.45),
        thickness: 1,
        space: 1,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primaryContainer,
        foregroundColor: scheme.onPrimaryContainer,
        shape: const StadiumBorder(),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHigh,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: TextStyle(color: scheme.onInverseSurface),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      searchBarTheme: SearchBarThemeData(
        backgroundColor: WidgetStatePropertyAll(scheme.surfaceContainerHigh),
        elevation: const WidgetStatePropertyAll(0),
        side: const WidgetStatePropertyAll(BorderSide.none),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
      ),
      expansionTileTheme: ExpansionTileThemeData(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        childrenPadding: const EdgeInsets.only(bottom: 8),
        iconColor: scheme.primary,
        collapsedIconColor: scheme.onSurfaceVariant,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        indicatorColor: scheme.secondaryContainer,
        elevation: 0,
        height: 72,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
        indicatorShape: const StadiumBorder(),
      ),
    );
  }

  Color get settingsIcon => colorScheme.primary;
  Color get descriptionArrowBackground => colorScheme.secondaryContainer;
  Color get descriptionArrow => colorScheme.onSecondaryContainer;
  Color get alertBoxColor => colorScheme.surfaceContainerHigh;
  Color get descriptionIconColor => colorScheme.primaryContainer;
  Color get descriptionIconAltColor => colorScheme.tertiaryContainer;
  Color get descriptionIconEnabledColor => colorScheme.onPrimaryContainer;
  Color get tileUnderlineColor => colorScheme.outlineVariant;
  Color get directoryPickerText => colorScheme.onSurface;
  Color get directoryPickerBg => colorScheme.surfaceContainer;
  Color get progressBar => colorScheme.primary;
  Color get settingsTile => colorScheme.surfaceContainerLow;
  Color get tileColor1 => colorScheme.surfaceContainerLow;
  Color get tileColor2 => colorScheme.surfaceContainerLow;
  Color get descriptionBackground => colorScheme.surface;
  Color get settingsBackground => colorScheme.surface;
  Color get headerText => colorScheme.onSurface;
  Color get subHeaderText => colorScheme.onSurfaceVariant;
  Color get di => colorScheme.primary;
  Color get appBarColor => colorScheme.surface;
  Color get appBarTitleColor => colorScheme.onSurface;
  Color get iconColor => colorScheme.primary;
  Color get modalSheetColor => colorScheme.surfaceContainerLow;
  bool get darkMode => _darkMode;

  void darkModeOn() => _setDarkMode(true);

  void darkModeOff() => _setDarkMode(false);

  void _setDarkMode(bool value) {
    if (_darkMode == value) return;
    _darkMode = value;
    notifyListeners();
  }
}
