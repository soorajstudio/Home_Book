import 'package:flutter/material.dart';

/// ---------------------------------------------------------------------------
/// Design system for "Family Finance".
///
/// Direction: a warm, human take on money — not another cold corporate-blue
/// fintech screen. Deep ink-navy surfaces anchor the hero/header moments,
/// a warm cream page background keeps daily use easy on the eyes, and a
/// single confident coral accent stands in for every primary action.
/// Money numerals get their own weight and tabular spacing so amounts are
/// always the most legible thing on any given screen.
/// ---------------------------------------------------------------------------
class AppTheme {
  AppTheme._();

  // ---- Core palette --------------------------------------------------------
  static const Color ink = Color(0xFF12172B); // deepest navy — hero surfaces
  static const Color inkElevated = Color(0xFF1B2140); // cards on ink
  static const Color inkLine = Color(0xFF2B3358); // hairlines on ink

  static const Color coral = Color(0xFFFF6B4A); // primary accent
  static const Color coralDeep = Color(0xFFE8543A);
  static const Color coralSoft = Color(0xFFFFE4DA);

  static const Color gold = Color(0xFFF2B84B); // secondary accent / highlight

  static const Color cream = Color(0xFFFBF7F0); // page background
  static const Color card = Color(0xFFFFFFFF);
  static const Color sand = Color(0xFFF3ECE0); // subtle recessed fill

  static const Color teal = Color(0xFF0F766E); // income
  static const Color tealSoft = Color(0xFFDCF3EF);
  static const Color rose = Color(0xFFE8544A); // expense
  static const Color roseSoft = Color(0xFFFCE4E1);

  static const Color textPrimary = Color(0xFF1B1B23);
  static const Color textSecondary = Color(0xFF6F6B7A);
  static const Color textMuted = Color(0xFFA8A3B3);
  static const Color divider = Color(0xFFEAE3D6);

  // Back-compat aliases used across older screen code.
  static const Color primary = coral;
  static const Color primaryDark = coralDeep;
  static const Color primaryLight = gold;
  static const Color secondary = teal;
  static const Color accent = gold;
  static const Color incomeColor = teal;
  static const Color expenseColor = rose;
  static const Color background = cream;
  static const Color cardBg = card;

  // ---- Type scale ------------------------------------------------------
  static const String _display = 'Roboto';

  static const TextStyle moneyLarge = TextStyle(
    fontFamily: _display,
    fontSize: 40,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.8,
    height: 1.05,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const TextStyle moneyMedium = TextStyle(
    fontFamily: _display,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.4,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const TextStyle moneySmall = TextStyle(
    fontFamily: _display,
    fontSize: 15,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const TextStyle eyebrow = TextStyle(
    fontSize: 11.5,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.1,
    color: textMuted,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.2,
    color: textPrimary,
  );

  // ---- Radii & shadows -------------------------------------------------
  static const double radiusSm = 12;
  static const double radiusMd = 18;
  static const double radiusLg = 26;
  static const double radiusPill = 100;

  static List<BoxShadow> softShadow({double opacity = 0.06}) => [
        BoxShadow(
          color: Colors.black.withValues(alpha: opacity),
          blurRadius: 24,
          offset: const Offset(0, 10),
          spreadRadius: -6,
        ),
      ];

  static List<BoxShadow> coralGlow = [
    BoxShadow(
      color: coral.withValues(alpha: 0.28),
      blurRadius: 20,
      offset: const Offset(0, 8),
      spreadRadius: -6,
    ),
  ];

  // ---- Gradients ---------------------------------------------------------
  static const LinearGradient inkGradient = LinearGradient(
    colors: [Color(0xFF12172B), Color(0xFF232A4D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [coral, Color(0xFFFF8B63)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient incomeGradient = LinearGradient(
    colors: [Color(0xFF0F766E), Color(0xFF14958A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient expenseGradient = LinearGradient(
    colors: [Color(0xFFE8544A), Color(0xFFF0776E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFF2B84B), Color(0xFFF7CE7C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ---- ThemeData -----------------------------------------------------------
  static ThemeData get theme {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: coral,
        brightness: Brightness.light,
      ).copyWith(
        primary: coral,
        secondary: teal,
        surface: card,
        error: rose,
      ),
      scaffoldBackgroundColor: cream,
      fontFamily: _display,
      splashFactory: InkRipple.splashFactory,
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: cream,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 19,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black.withValues(alpha: 0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          side: BorderSide(color: divider.withValues(alpha: 0.7), width: 1),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: coral,
          foregroundColor: Colors.white,
          disabledBackgroundColor: coral.withValues(alpha: 0.4),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSm),
          ),
          padding: const EdgeInsets.symmetric(vertical: 17, horizontal: 24),
          textStyle: const TextStyle(
            fontSize: 15.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
          ),
        ).copyWith(
          overlayColor: WidgetStateProperty.all(Colors.white.withValues(alpha: 0.1)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: coral,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: const BorderSide(color: divider, width: 1.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSm),
          ),
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: textPrimary,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: sand.withValues(alpha: 0.6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: coral, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: rose, width: 1.4),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: rose, width: 1.8),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        labelStyle: const TextStyle(color: textSecondary, fontSize: 14.5),
        hintStyle: TextStyle(color: textMuted.withValues(alpha: 0.9)),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: coral,
        unselectedItemColor: Color(0xFFB7B2C2),
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle:
            TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        unselectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: coralSoft,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? coralDeep : textMuted,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? coralDeep : textMuted,
            size: 24,
          );
        }),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: sand,
        selectedColor: coralSoft,
        labelStyle: const TextStyle(
            fontSize: 12.5, fontWeight: FontWeight.w600, color: textPrimary),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusPill),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      dividerTheme: const DividerThemeData(
        color: divider,
        thickness: 1,
        space: 1,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: coral,
        foregroundColor: Colors.white,
        elevation: 3,
        highlightElevation: 6,
        extendedTextStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
        ),
        titleTextStyle: const TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: ink,
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 13.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSm),
        ),
        behavior: SnackBarBehavior.floating,
        actionTextColor: gold,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: coral,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? Colors.white : Colors.white),
        trackColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? coral : const Color(0xFFE0DCD3)),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? coral : Colors.transparent),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        side: const BorderSide(color: Color(0xFFC9C3B4), width: 1.6),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? coral : textMuted),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: textPrimary,
        unselectedLabelColor: textMuted,
        indicatorColor: coral,
        labelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 13.5),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
        elevation: 8,
      ),
    );
  }

  // ---- Helpers ---------------------------------------------------------
  static Color hexToColor(String hex) {
    final h = hex.replaceAll('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }

  static const Map<String, IconData> categoryIcons = {
    'salary': Icons.work_outline_rounded,
    'freelance': Icons.laptop_mac_rounded,
    'business': Icons.business_center_outlined,
    'investment': Icons.trending_up_rounded,
    'food': Icons.restaurant_outlined,
    'transport': Icons.directions_car_filled_outlined,
    'shopping': Icons.shopping_bag_outlined,
    'utilities': Icons.bolt_outlined,
    'health': Icons.favorite_border_rounded,
    'education': Icons.school_outlined,
    'rent': Icons.home_outlined,
    'entertainment': Icons.movie_outlined,
    'savings': Icons.savings_outlined,
    'category': Icons.category_outlined,
    'other': Icons.more_horiz_rounded,
  };

  static IconData getIcon(String? name) =>
      categoryIcons[name?.toLowerCase()] ?? Icons.category_outlined;

  /// Deterministic accent palette used for charts / avatars — warmer, more
  /// distinctive than default Material hues, ordered for good adjacency
  /// contrast in pie/bar charts.
  static const List<Color> chartPalette = [
    Color(0xFFFF6B4A), // coral
    Color(0xFF0F766E), // teal
    Color(0xFFF2B84B), // gold
    Color(0xFF6D5DD3), // violet
    Color(0xFFE8544A), // rose
    Color(0xFF2E9DA6), // seafoam
    Color(0xFFD98A3D), // amber
    Color(0xFF9C6ADE), // lilac
    Color(0xFF4C7A5A), // moss
  ];
}
