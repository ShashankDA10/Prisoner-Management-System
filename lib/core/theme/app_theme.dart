import 'package:flutter/material.dart';

/// Government-grade Material 3 theme.
/// Inspired by Karnataka Govt portal color language:
/// deep navy authority blue + amber accent + clean whites.
class AppTheme {
  AppTheme._();

  // ── Brand colors ────────────────────────────────────────────────────────────
  static const Color primaryNavy = Color(0xFF1A3A5C);     // deep authority blue
  static const Color primaryDark  = Color(0xFF0F2540);    // sidebar / header bg
  static const Color accent       = Color(0xFFC8960C);    // Karnataka gold/amber
  static const Color accentLight  = Color(0xFFF5D87E);
  static const Color success      = Color(0xFF2E7D32);
  static const Color warning      = Color(0xFFE65100);
  static const Color error        = Color(0xFFC62828);
  static const Color info         = Color(0xFF01579B);

  // ── Surface / background ────────────────────────────────────────────────────
  static const Color surfaceWhite  = Color(0xFFFFFFFF);
  static const Color surfaceGrey   = Color(0xFFF4F6F8);  // page background
  static const Color surfaceCard   = Color(0xFFFFFFFF);
  static const Color borderLight   = Color(0xFFDDE3ED);
  static const Color borderMedium  = Color(0xFFB0BEC5);

  // ── Text ────────────────────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFF0D1B2A);
  static const Color textSecondary = Color(0xFF546E7A);
  static const Color textDisabled  = Color(0xFF90A4AE);
  static const Color textOnDark    = Color(0xFFFFFFFF);
  static const Color textOnAccent  = Color(0xFF1A1A1A);

  // ── Sidebar ─────────────────────────────────────────────────────────────────
  static const Color sidebarBg         = Color(0xFF0F2540);
  static const Color sidebarSelected   = Color(0xFF1A3A5C);
  static const Color sidebarHover      = Color(0xFF162D4A);
  static const Color sidebarIconActive = Color(0xFFC8960C);
  static const Color sidebarText       = Color(0xFFB0C4DE);
  static const Color sidebarTextActive = Color(0xFFFFFFFF);

  // ── Dashboard card accents ───────────────────────────────────────────────────
  static const Color cardTotal      = Color(0xFF1A3A5C);
  static const Color cardUndertrial = Color(0xFF5C3D1A);
  static const Color cardConvicted  = Color(0xFF2E4057);
  static const Color cardAdmitted   = Color(0xFF1A5C3A);
  static const Color cardReleased   = Color(0xFF5C1A2E);
  static const Color cardBail       = Color(0xFF1A4A5C);
  static const Color cardTransfer   = Color(0xFF3A1A5C);

  // ── Typography ──────────────────────────────────────────────────────────────
  static const String _fontFamily = 'Roboto';

  static TextTheme get _textTheme => const TextTheme(
    displayLarge  : TextStyle(fontFamily: _fontFamily, fontSize: 32, fontWeight: FontWeight.w700, color: textPrimary, letterSpacing: -0.5),
    displayMedium : TextStyle(fontFamily: _fontFamily, fontSize: 28, fontWeight: FontWeight.w600, color: textPrimary),
    displaySmall  : TextStyle(fontFamily: _fontFamily, fontSize: 24, fontWeight: FontWeight.w600, color: textPrimary),
    headlineLarge : TextStyle(fontFamily: _fontFamily, fontSize: 20, fontWeight: FontWeight.w600, color: textPrimary),
    headlineMedium: TextStyle(fontFamily: _fontFamily, fontSize: 18, fontWeight: FontWeight.w600, color: textPrimary),
    headlineSmall : TextStyle(fontFamily: _fontFamily, fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary),
    titleLarge    : TextStyle(fontFamily: _fontFamily, fontSize: 15, fontWeight: FontWeight.w600, color: textPrimary),
    titleMedium   : TextStyle(fontFamily: _fontFamily, fontSize: 14, fontWeight: FontWeight.w500, color: textPrimary),
    titleSmall    : TextStyle(fontFamily: _fontFamily, fontSize: 13, fontWeight: FontWeight.w500, color: textSecondary),
    bodyLarge     : TextStyle(fontFamily: _fontFamily, fontSize: 14, fontWeight: FontWeight.w400, color: textPrimary, height: 1.5),
    bodyMedium    : TextStyle(fontFamily: _fontFamily, fontSize: 13, fontWeight: FontWeight.w400, color: textPrimary, height: 1.5),
    bodySmall     : TextStyle(fontFamily: _fontFamily, fontSize: 12, fontWeight: FontWeight.w400, color: textSecondary, height: 1.4),
    labelLarge    : TextStyle(fontFamily: _fontFamily, fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary, letterSpacing: 0.3),
    labelMedium   : TextStyle(fontFamily: _fontFamily, fontSize: 12, fontWeight: FontWeight.w500, color: textSecondary),
    labelSmall    : TextStyle(fontFamily: _fontFamily, fontSize: 11, fontWeight: FontWeight.w500, color: textDisabled, letterSpacing: 0.4),
  );

  static ThemeData get light {
    final cs = ColorScheme.fromSeed(
      seedColor: primaryNavy,
      primary:   primaryNavy,
      secondary: accent,
      surface:   surfaceGrey,
      error:     error,
      brightness: Brightness.light,
    ).copyWith(
      primaryContainer:   const Color(0xFFD6E4F7),
      secondaryContainer: accentLight,
      surfaceContainerHighest: borderLight,
      outline:            borderMedium,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme:  cs,
      fontFamily:   _fontFamily,
      textTheme:    _textTheme,
      scaffoldBackgroundColor: surfaceGrey,

      // ── AppBar ──────────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: primaryDark,
        foregroundColor: textOnDark,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: _textTheme.headlineSmall?.copyWith(color: textOnDark, fontWeight: FontWeight.w600),
        iconTheme: const IconThemeData(color: textOnDark),
      ),

      // ── Card ────────────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color:     surfaceCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: borderLight, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      // ── Divider ─────────────────────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color:  borderLight,
        space:  1,
        thickness: 1,
      ),

      // ── Input ────────────────────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled:      true,
        fillColor:   surfaceWhite,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: borderMedium),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: primaryNavy, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: error),
        ),
        labelStyle: _textTheme.bodyMedium?.copyWith(color: textSecondary),
        hintStyle:  _textTheme.bodyMedium?.copyWith(color: textDisabled),
        isDense: true,
      ),

      // ── ElevatedButton ───────────────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryNavy,
          foregroundColor: textOnDark,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          textStyle: _textTheme.labelLarge?.copyWith(color: textOnDark),
        ),
      ),

      // ── OutlinedButton ───────────────────────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryNavy,
          side: const BorderSide(color: primaryNavy),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          textStyle: _textTheme.labelLarge,
        ),
      ),

      // ── TextButton ───────────────────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryNavy,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          textStyle: _textTheme.labelLarge,
        ),
      ),

      // ── DataTable ────────────────────────────────────────────────────────────
      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStateProperty.all(const Color(0xFFF0F4F8)),
        headingTextStyle: _textTheme.labelLarge?.copyWith(color: primaryNavy),
        dataTextStyle: _textTheme.bodyMedium,
        dividerThickness: 1,
        columnSpacing: 24,
        horizontalMargin: 16,
        dataRowMinHeight: 44,
        dataRowMaxHeight: 56,
      ),

      // ── Chip ─────────────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFEEF2F7),
        labelStyle: _textTheme.labelMedium,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),

      // ── Drawer ───────────────────────────────────────────────────────────────
      drawerTheme: const DrawerThemeData(
        backgroundColor: sidebarBg,
        elevation: 2,
      ),

      // ── Tooltip ──────────────────────────────────────────────────────────────
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: primaryDark,
          borderRadius: BorderRadius.circular(4),
        ),
        textStyle: _textTheme.bodySmall?.copyWith(color: textOnDark),
      ),

      // ── SnackBar ─────────────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: primaryDark,
        contentTextStyle: _textTheme.bodyMedium?.copyWith(color: textOnDark),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    );
  }
}
