import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// AIVONITY Design System Theme Configuration
/// Implements Material 3 design principles with modern adventure branding
class AivonityTheme {
  // Modern Adventure Color Palette
  static const Color primaryAlpineBlue = Color(
    0xFF1E3A8A,
  ); // Deep mountain blue
  static const Color primaryBlueLight = Color(0xFF3B82F6); // Alpine sky blue
  static const Color primaryBlueDark = Color(0xFF1E40AF); // Deep lake blue

  static const Color accentSunsetCoral = Color(
    0xFFFB7185,
  ); // Modern sunset coral
  static const Color accentSummitOrange = Color(0xFFEA580C); // Peak orange
  static const Color accentPineGreen = Color(0xFF059669); // Adventure green
  static const Color accentMountainGray = Color(0xFF6B7280); // Stone gray
  static const Color accentSkyBlue = Color(0xFF0EA5E9); // Sky blue
  static const Color accentPurple = Color(0xFF8B5CF6); // Adventure purple
  static const Color accentRed = Color(0xFFEF4444); // Alert red
  static const Color accentYellow = Color(0xFFF59E0B); // Warning yellow
  static const Color accentPink = Color(0xFFEC4899); // Social pink

  static const Color neutralMistGray = Color(0xFFF8FAFC); // Cloud mist
  static const Color neutralStoneGray = Color(0xFF64748B); // Mountain stone
  static const Color darkNightBlue = Color(0xFF0F172A); // Night sky

  // Gradient Colors for Modern Adventure UI
  static const LinearGradient adventureGradient = LinearGradient(
    colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6), Color(0xFFFB7185)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient summitGradient = LinearGradient(
    colors: [Color(0xFFEA580C), Color(0xFFFB7185), Color(0xFF3B82F6)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient mountainGradient = LinearGradient(
    colors: [Color(0xFF1E40AF), Color(0xFF64748B), Color(0xFF1E3A8A)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Light Theme - Modern Adventure Style
  static ThemeData get lightTheme {
    final ColorScheme colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: primaryAlpineBlue,
      onPrimary: Colors.white,
      primaryContainer: primaryBlueLight,
      onPrimaryContainer: Colors.white,
      secondary: accentSummitOrange,
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFFFCC80),
      onSecondaryContainer: Color(0xFF4D2700),
      tertiary: accentPineGreen,
      onTertiary: Colors.white,
      tertiaryContainer: Color(0xFFD3E4FD),
      onTertiaryContainer: Color(0xFF001B3E),
      error: Color(0xFFDC2626),
      onError: Colors.white,
      errorContainer: Color(0xFFFFDAD6),
      onErrorContainer: Color(0xFF410002),
      surface: neutralMistGray,
      onSurface: darkNightBlue,
      surfaceContainerHighest: Color(0xFFE7E0D9),
      onSurfaceVariant: neutralStoneGray,
      outline: Color(0xFF7D7767),
      outlineVariant: Color(0xFFD0C5B4),
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
      inverseSurface: darkNightBlue,
      onInverseSurface: neutralMistGray,
      inversePrimary: Color(0xFF8DD99F),
      surfaceTint: primaryAlpineBlue,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,

      // Typography - Modern Adventure Font Stack
      textTheme: _buildTextTheme(colorScheme),

      // App Bar Theme - Mountain Peak Style
      appBarTheme: AppBarTheme(
        elevation: 4,
        centerTitle: true,
        backgroundColor: primaryAlpineBlue,
        foregroundColor: Colors.white,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
        shadowColor: darkNightBlue.withValues(alpha:0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
        ),
      ),

      // Card Theme - Adventure Equipment Style
      cardTheme: CardThemeData(
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
        clipBehavior: Clip.antiAlias,
        color: Colors.white,
        shadowColor: darkNightBlue.withValues(alpha:0.1),
        margin: EdgeInsets.all(8),
      ),

      // Elevated Button Theme - Summit Style
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 4,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
          shadowColor: darkNightBlue.withValues(alpha:0.2),
          backgroundColor: primaryAlpineBlue,
          foregroundColor: Colors.white,
        ),
      ),

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: primaryAlpineBlue, width: 2),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
          foregroundColor: primaryAlpineBlue,
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
          foregroundColor: primaryAlpineBlue,
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: neutralMistGray,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: neutralStoneGray.withValues(alpha:0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: neutralStoneGray.withValues(alpha:0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: primaryAlpineBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Color(0xFFDC2626)),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        hintStyle: TextStyle(color: neutralStoneGray),
      ),

      // Scaffold background
      scaffoldBackgroundColor: neutralMistGray,

      // Floating Action Button Theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accentSummitOrange,
        foregroundColor: Colors.white,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: primaryAlpineBlue,
        unselectedItemColor: neutralStoneGray,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500),
      ),

      // Divider Theme
      dividerTheme: DividerThemeData(
        color: neutralStoneGray.withValues(alpha:0.2),
        thickness: 1,
        space: 1,
      ),
    );
  }

  // Dark Theme - Adventure Night Style
  static ThemeData get darkTheme {
    final ColorScheme colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: primaryBlueLight,
      onPrimary: Color(0xFF003912),
      primaryContainer: primaryBlueDark,
      onPrimaryContainer: Color(0xFF8DD99F),
      secondary: accentSummitOrange,
      onSecondary: Color(0xFF4D2700),
      secondaryContainer: Color(0xFF6B3A00),
      onSecondaryContainer: Color(0xFFFFCC80),
      tertiary: accentPineGreen,
      onTertiary: Color(0xFF003258),
      tertiaryContainer: Color(0xFF00497D),
      onTertiaryContainer: Color(0xFFD3E4FD),
      error: Color(0xFFDC2626),
      onError: Color(0xFF690005),
      errorContainer: Color(0xFF93000A),
      onErrorContainer: Color(0xFFFFDAD6),
      surface: darkNightBlue,
      onSurface: neutralMistGray,
      surfaceContainerHighest: Color(0xFF4C4639),
      onSurfaceVariant: Color(0xFFD0C5B4),
      outline: Color(0xFF998F7E),
      outlineVariant: Color(0xFF4C4639),
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
      inverseSurface: neutralMistGray,
      onInverseSurface: darkNightBlue,
      inversePrimary: Color(0xFF006E25),
      surfaceTint: primaryBlueLight,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: _buildTextTheme(colorScheme),

      // App Bar Theme - Night Adventure Style
      appBarTheme: AppBarTheme(
        elevation: 4,
        centerTitle: true,
        backgroundColor: primaryBlueDark,
        foregroundColor: Colors.white,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
        shadowColor: Colors.black.withValues(alpha:0.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
        ),
      ),

      // Card Theme - Night Adventure Style
      cardTheme: CardThemeData(
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
        clipBehavior: Clip.antiAlias,
        color: Color(0xFF1E293B),
        shadowColor: Colors.black.withValues(alpha:0.3),
        margin: EdgeInsets.all(8),
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 4,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
          shadowColor: Colors.black.withValues(alpha:0.3),
          backgroundColor: primaryBlueLight,
          foregroundColor: Color(0xFF003912),
        ),
      ),

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: primaryBlueLight, width: 2),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
          foregroundColor: primaryBlueLight,
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
          foregroundColor: primaryBlueLight,
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Color(0xFF334155),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: neutralStoneGray.withValues(alpha:0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: neutralStoneGray.withValues(alpha:0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: primaryBlueLight, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Color(0xFFDC2626)),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        hintStyle: TextStyle(color: neutralStoneGray.withValues(alpha:0.7)),
      ),

      // Scaffold background
      scaffoldBackgroundColor: darkNightBlue,

      // Floating Action Button Theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accentSummitOrange,
        foregroundColor: Colors.white,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF1E293B),
        selectedItemColor: primaryBlueLight,
        unselectedItemColor: neutralStoneGray.withValues(alpha:0.7),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500),
      ),

      // Divider Theme
      dividerTheme: DividerThemeData(
        color: neutralStoneGray.withValues(alpha:0.3),
        thickness: 1,
        space: 1,
      ),
    );
  }

  // Modern Adventure Text Theme
  static TextTheme _buildTextTheme(ColorScheme colorScheme) {
    return TextTheme(
      // Headlines - Bold Adventure Headings
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        color: colorScheme.onSurface,
        letterSpacing: -0.5,
        height: 1.2,
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: colorScheme.onSurface,
        letterSpacing: -0.25,
        height: 1.3,
      ),
      headlineSmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: colorScheme.onSurface,
        letterSpacing: 0,
        height: 1.3,
      ),

      // Titles - Section Headers
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
        letterSpacing: 0,
        height: 1.4,
      ),
      titleMedium: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
        letterSpacing: 0.15,
        height: 1.4,
      ),
      titleSmall: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
        letterSpacing: 0.1,
        height: 1.4,
      ),

      // Body Text - Adventure Content
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: colorScheme.onSurface,
        letterSpacing: 0.5,
        height: 1.6,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: colorScheme.onSurface,
        letterSpacing: 0.25,
        height: 1.5,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: colorScheme.onSurfaceVariant,
        letterSpacing: 0.4,
        height: 1.4,
      ),

      // Labels - Compact Text
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
        letterSpacing: 0.1,
        height: 1.4,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
        letterSpacing: 0.5,
        height: 1.4,
      ),
      labelSmall: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
        letterSpacing: 1.5,
        height: 1.4,
      ),
    );
  }

  // Adventure-themed gradient helpers
  static BoxDecoration adventureGradientDecoration({
    BorderRadius borderRadius = const BorderRadius.all(Radius.circular(16)),
    double elevation = 4,
  }) {
    return BoxDecoration(
      gradient: adventureGradient,
      borderRadius: borderRadius,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha:0.1),
          blurRadius: elevation * 2,
          offset: Offset(0, elevation),
        ),
      ],
    );
  }

  static BoxDecoration summitGradientDecoration({
    BorderRadius borderRadius = const BorderRadius.all(Radius.circular(16)),
    double elevation = 4,
  }) {
    return BoxDecoration(
      gradient: summitGradient,
      borderRadius: borderRadius,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha:0.1),
          blurRadius: elevation * 2,
          offset: Offset(0, elevation),
        ),
      ],
    );
  }
}

