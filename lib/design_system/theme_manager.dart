import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Theme manager for handling theme switching and persistence
class ThemeManager extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';

  ThemeMode _themeMode = ThemeMode.system;
  bool _isHighContrast = false;
  double _textScaleFactor = 1.0;

  ThemeMode get themeMode => _themeMode;
  bool get isHighContrast => _isHighContrast;
  double get textScaleFactor => _textScaleFactor;

  bool get isDarkMode {
    if (_themeMode == ThemeMode.system) {
      return WidgetsBinding.instance.platformDispatcher.platformBrightness ==
          Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }

  /// Initialize theme manager and load saved preferences
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();

    // Load theme mode
    final themeModeIndex = prefs.getInt(_themeKey) ?? ThemeMode.system.index;
    _themeMode = ThemeMode.values[themeModeIndex];

    // Load accessibility settings
    _isHighContrast = prefs.getBool('high_contrast') ?? false;
    _textScaleFactor = prefs.getDouble('text_scale_factor') ?? 1.0;

    notifyListeners();
  }

  /// Set theme mode and persist to storage
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;

    _themeMode = mode;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, mode.index);
  }

  /// Toggle between light and dark theme
  Future<void> toggleTheme() async {
    final newMode = _themeMode == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;
    await setThemeMode(newMode);
  }

  /// Set high contrast mode for accessibility
  Future<void> setHighContrast(bool enabled) async {
    if (_isHighContrast == enabled) return;

    _isHighContrast = enabled;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('high_contrast', enabled);
  }

  /// Set text scale factor for accessibility
  Future<void> setTextScaleFactor(double factor) async {
    if (_textScaleFactor == factor) return;

    _textScaleFactor = factor.clamp(0.8, 2.0);
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('text_scale_factor', _textScaleFactor);
  }

  /// Get theme data with accessibility modifications
  ThemeData getThemeData(ThemeData baseTheme) {
    if (!_isHighContrast) return baseTheme;

    // Apply high contrast modifications
    final colorScheme = baseTheme.colorScheme;
    final highContrastColorScheme = colorScheme.copyWith(
      primary: colorScheme.brightness == Brightness.light
          ? Colors.black
          : Colors.white,
      onPrimary: colorScheme.brightness == Brightness.light
          ? Colors.white
          : Colors.black,
      surface: colorScheme.brightness == Brightness.light
          ? Colors.white
          : Colors.black,
      onSurface: colorScheme.brightness == Brightness.light
          ? Colors.black
          : Colors.white,
    );

    return baseTheme.copyWith(
      colorScheme: highContrastColorScheme,
      // Increase contrast for better accessibility
      cardTheme: baseTheme.cardTheme.copyWith(elevation: 8),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 4,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

/// Widget that provides theme management to the widget tree
class ThemeProvider extends InheritedNotifier<ThemeManager> {
  const ThemeProvider({
    super.key,
    required ThemeManager themeManager,
    required super.child,
  }) : super(notifier: themeManager);

  static ThemeManager? of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<ThemeProvider>()
        ?.notifier;
  }
}

/// Theme toggle button widget
class ThemeToggleButton extends StatelessWidget {
  final bool showLabel;

  const ThemeToggleButton({super.key, this.showLabel = false});

  @override
  Widget build(BuildContext context) {
    final themeManager = ThemeProvider.of(context);
    if (themeManager == null) return const SizedBox.shrink();

    return ListenableBuilder(
      listenable: themeManager,
      builder: (context, child) {
        final isDark = themeManager.isDarkMode;

        if (showLabel) {
          return ListTile(
            leading: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
            title: Text(isDark ? 'Dark Mode' : 'Light Mode'),
            trailing: Switch(
              value: isDark,
              onChanged: (_) => themeManager.toggleTheme(),
            ),
            onTap: () => themeManager.toggleTheme(),
          );
        }

        return IconButton(
          icon: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
          onPressed: () => themeManager.toggleTheme(),
          tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
        );
      },
    );
  }
}

/// Accessibility settings widget
class AccessibilitySettings extends StatelessWidget {
  const AccessibilitySettings({super.key});

  @override
  Widget build(BuildContext context) {
    final themeManager = ThemeProvider.of(context);
    if (themeManager == null) return const SizedBox.shrink();

    return ListenableBuilder(
      listenable: themeManager,
      builder: (context, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Accessibility',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            // High Contrast Toggle
            SwitchListTile(
              title: const Text('High Contrast'),
              subtitle: const Text('Increase contrast for better visibility'),
              value: themeManager.isHighContrast,
              onChanged: themeManager.setHighContrast,
            ),

            const SizedBox(height: 16),

            // Text Scale Factor
            Text('Text Size', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),

            Slider(
              value: themeManager.textScaleFactor,
              min: 0.8,
              max: 2.0,
              divisions: 12,
              label: '${(themeManager.textScaleFactor * 100).round()}%',
              onChanged: themeManager.setTextScaleFactor,
            ),

            Text(
              'Sample text at ${(themeManager.textScaleFactor * 100).round()}% size',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 16 * themeManager.textScaleFactor,
              ),
            ),
          ],
        );
      },
    );
  }
}

