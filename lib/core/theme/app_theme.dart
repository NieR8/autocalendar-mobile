import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Холодная тема — льдисто-белый фон, стальной синий primary.
/// Без serif, Inter во всём. Pill-кнопки. Светлый, читаемый на солнце.
///
/// Статусы:
///   planned  → голубой #3B82F6
///   in_progress → янтарный #F59E0B (тёплый акцент на холодном фоне)
///   ready    → изумрудный #10B981

class AppTheme {
  // === Цвета ===
  static const Color bg = Color(0xFFF0F4F8);
  static const Color surface = Color(0xFFF0F4F8);
  static const Color surface2 = Color(0xFFE2E8F0);
  static const Color border = Color(0xFFCBD5E1);
  static const Color text = Color(0xFF1E293B);
  static const Color textDim = Color(0xFF64748B);
  static const Color textMute = Color(0xFF94A3B8);

  static const Color primary = Color(0xFF2563EB);
  static const Color primaryLight = Color(0xFF3B82F6);
  static const Color accent = Color(0xFF06B6D4);

  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);

  // Статусы записей
  static const Color statusPlanned = Color(0xFF3B82F6);
  static const Color statusProgress = Color(0xFFF59E0B);
  static const Color statusReady = Color(0xFF10B981);

  // Красная линия текущего времени
  static const Color nowLine = Color(0xFFEF4444);

  // === Радиусы ===
  static const double radius = 8.0;
  static const double radiusSm = 6.0;
  static const double radiusCard = 12.0;

  /// ThemeData — холодный, светлый, Inter во всём.
  static ThemeData get light {
    final colorScheme = ColorScheme.light(
      primary: primary,
      onPrimary: Colors.white,
      primaryContainer: primaryLight,
      secondary: accent,
      onSecondary: Colors.white,
      surface: surface,
      onSurface: text,
      error: danger,
      onError: Colors.white,
      outline: border,
      surfaceContainerHighest: surface2,
    );

    final base = ThemeData.light();

    return base.copyWith(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: bg,
      textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.inter(
            fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: -0.02, color: text),
        displayMedium: GoogleFonts.inter(
            fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.02, color: text),
        headlineLarge: GoogleFonts.inter(
            fontSize: 24, fontWeight: FontWeight.w600, letterSpacing: -0.01, color: text),
        headlineMedium: GoogleFonts.inter(
            fontSize: 20, fontWeight: FontWeight.w600, letterSpacing: -0.01, color: text),
        titleLarge: GoogleFonts.inter(
            fontSize: 18, fontWeight: FontWeight.w600, color: text),
        bodyLarge: GoogleFonts.inter(fontSize: 16, color: text),
        bodyMedium: GoogleFonts.inter(fontSize: 14, color: text),
        bodySmall: GoogleFonts.inter(fontSize: 12, color: textDim),
        labelLarge: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: text),
        labelMedium: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: textDim),
        labelSmall: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: textMute),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: text,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: const Border(bottom: BorderSide(color: border, width: 1)),
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
            fontSize: 20, fontWeight: FontWeight.w600, color: text),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusCard),
          side: const BorderSide(color: border, width: 0.5),
        ),
        surfaceTintColor: Colors.transparent,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(99)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          textStyle: GoogleFonts.inter(
              fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: text,
          side: const BorderSide(color: border),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(99)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: GoogleFonts.inter(
              fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        alignLabelWithHint: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        labelStyle: GoogleFonts.inter(color: textDim, fontSize: 14),
        hintStyle: GoogleFonts.inter(color: textDim, fontSize: 14),
        floatingLabelStyle: GoogleFonts.inter(color: textDim, fontSize: 14),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: primary.withOpacity(0.12),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return GoogleFonts.inter(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? primary : textMute,
          );
        }),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(99)),
        elevation: 2,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: primary,
        unselectedLabelColor: textMute,
        indicatorColor: primary,
        labelStyle: GoogleFonts.inter(
            fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 13),
      ),
      dividerTheme: const DividerThemeData(
        color: border,
        thickness: 0.5,
        space: 1,
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        menuStyle: MenuStyle(
          backgroundColor: WidgetStateProperty.all(surface),
          surfaceTintColor: WidgetStateProperty.all(Colors.transparent),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: text,
        contentTextStyle: GoogleFonts.inter(color: surface, fontSize: 14),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSm)),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius)),
        titleTextStyle: GoogleFonts.inter(
            fontSize: 20, fontWeight: FontWeight.w600, color: text),
        contentTextStyle: GoogleFonts.inter(fontSize: 14, color: text),
      ),
    );
  }

  static Color statusColor(String status) {
    switch (status) {
      case 'in_progress':
        return statusProgress;
      case 'ready':
        return statusReady;
      default:
        return statusPlanned;
    }
  }

  /// Тёмная тема — мягкий нейтрально-серый (как iOS dark mode).
  static ThemeData get dark {
    const dBg = Color(0xFF000000);
    const dSurface = Color(0xFF000000);
    const dSurface2 = Color(0xFF1A1A1A);
    const dBorder = Color(0xFF2A2A2A);
    const dText = Color(0xFFF2F2F7);
    const dTextDim = Color(0xFFAEAEB2);
    const dTextMute = Color(0xFF636366);

    final colorScheme = ColorScheme.dark(
      primary: primary,
      onPrimary: Colors.white,
      primaryContainer: primaryLight,
      secondary: accent,
      onSecondary: Colors.white,
      surface: dSurface,
      onSurface: dText,
      error: danger,
      onError: Colors.white,
      outline: dBorder,
      surfaceContainerHighest: dSurface2,
    );

    final base = ThemeData.dark();

    return base.copyWith(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: dBg,
      textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.inter(
            fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: -0.02, color: dText),
        displayMedium: GoogleFonts.inter(
            fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.02, color: dText),
        headlineLarge: GoogleFonts.inter(
            fontSize: 24, fontWeight: FontWeight.w600, letterSpacing: -0.01, color: dText),
        headlineMedium: GoogleFonts.inter(
            fontSize: 20, fontWeight: FontWeight.w600, letterSpacing: -0.01, color: dText),
        titleLarge: GoogleFonts.inter(
            fontSize: 18, fontWeight: FontWeight.w600, color: dText),
        bodyLarge: GoogleFonts.inter(fontSize: 16, color: dText),
        bodyMedium: GoogleFonts.inter(fontSize: 14, color: dText),
        bodySmall: GoogleFonts.inter(fontSize: 12, color: dTextDim),
        labelLarge: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: dText),
        labelMedium: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: dTextDim),
        labelSmall: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: dTextMute),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: dSurface,
        foregroundColor: dText,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: const Border(bottom: BorderSide(color: dBorder, width: 1)),
        titleTextStyle: GoogleFonts.inter(
            fontSize: 20, fontWeight: FontWeight.w600, color: dText),
      ),
      cardTheme: CardThemeData(
        color: dSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusCard),
          side: const BorderSide(color: dBorder, width: 0.5),
        ),
        surfaceTintColor: Colors.transparent,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: dText,
          side: const BorderSide(color: dBorder),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dSurface2,
        alignLabelWithHint: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: dBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: dBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        labelStyle: GoogleFonts.inter(color: dTextDim, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: dSurface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: primary.withOpacity(0.15),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return GoogleFonts.inter(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? primary : dTextMute,
          );
        }),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
      ),
      dividerTheme: const DividerThemeData(color: dBorder, thickness: 0.5, space: 1),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: dText,
        contentTextStyle: GoogleFonts.inter(color: dBg, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusSm)),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: dSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
        titleTextStyle: GoogleFonts.inter(
            fontSize: 20, fontWeight: FontWeight.w600, color: dText),
        contentTextStyle: GoogleFonts.inter(fontSize: 14, color: dText),
      ),
    );
  }

  // Тёмные цвета (для inline использования в виджетах, которые не
  // могут использовать Theme.of(context) — например в статических методах).
  static const Color darkBg = Color(0xFF000000);
  static const Color darkSurface = Color(0xFF000000);
  static const Color darkSurface2 = Color(0xFF1A1A1A);
  static const Color darkBorder = Color(0xFF2A2A2A);
  static const Color darkText = Color(0xFFF2F2F7);
  static const Color darkTextDim = Color(0xFFAEAEB2);
  static const Color darkTextMute = Color(0xFF636366);

  /// Возвращает правильные цвета в зависимости от темы.
  /// Используй в виджетах вместо хардкоженных AppTheme.surface и т.д.
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color bgOf(BuildContext context) =>
      isDark(context) ? darkBg : bg;
  static Color surfaceOf(BuildContext context) =>
      isDark(context) ? darkSurface : surface;
  static Color surface2Of(BuildContext context) =>
      isDark(context) ? darkSurface2 : surface2;
  static Color borderOf(BuildContext context) =>
      isDark(context) ? darkBorder : border;
  static Color textOf(BuildContext context) =>
      isDark(context) ? darkText : text;
  static Color textDimOf(BuildContext context) =>
      isDark(context) ? darkTextDim : textDim;
  static Color textMuteOf(BuildContext context) =>
      isDark(context) ? darkTextMute : textMute;
}
