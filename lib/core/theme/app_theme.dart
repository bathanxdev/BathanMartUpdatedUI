import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Design Tokens ──────────────────────────────────────────────
class AppColors {
  AppColors._();
  // Primary — Deep Indigo Blue
  static const Color primary      = Color(0xFF1B3A6B);
  static const Color primaryLight = Color(0xFF2D5AA0);
  static const Color primaryDark  = Color(0xFF0D1F3C);
  static const Color primarySoft  = Color(0xFFEBF0FF);
  // Accent — Warm Saffron Orange  
  static const Color accent       = Color(0xFFE8712A);
  static const Color accentLight  = Color(0xFFF09050);
  static const Color accentSoft   = Color(0xFFFFF0E8);
  // Gold
  static const Color gold         = Color(0xFFD4A017);
  static const Color goldSoft     = Color(0xFFFFF8E6);
  // Teal
  static const Color teal    = Color(0xFF0F7B6C);
  static const Color tealSoft     = Color(0xFFE0F5F2);
  // Semantic
  static const Color success      = Color(0xFF16A34A);
  static const Color successSoft  = Color(0xFFDCFCE7);
  static const Color warning      = Color(0xFFD97706);
  static const Color warningSoft  = Color(0xFFFEF3C7);
  static const Color error        = Color(0xFFDC2626);
  static const Color errorSoft    = Color(0xFFFEE2E2);
  static const Color info         = Color(0xFF2563EB);
  static const Color infoSoft     = Color(0xFFEFF6FF);
  // Secondary
  static const Color secondary    = Color(0xFF0F6E56);
  static const Color secondarySoft= Color(0xFFE0F5EE);
  // Surfaces
  static const Color background   = Color(0xFFF8F7F5);
  static const Color surface      = Color(0xFFFFFFFF);
  static const Color surfaceWarm  = Color(0xFFF5F3EF);
  static const Color card         = Color(0xFFFFFFFF);
  // Text
  static const Color textPrimary  = Color(0xFF111827);
  static const Color textSecondary= Color(0xFF6B7280);
  static const Color textHint     = Color(0xFFADB5BD);
  // Border
  static const Color border       = Color(0xFFE5E7EB);
  static const Color divider      = Color(0xFFF3F4F6);
}

class AppRadius {
  AppRadius._();
  static const double xs   = 4.0;
  static const double sm   = 8.0;
  static const double md   = 12.0;
  static const double lg   = 16.0;
  static const double xl   = 20.0;
  static const double xxl  = 28.0;
  static const double full = 999.0;
}

class AppSpacing {
  AppSpacing._();
  static const double xs  = 4.0;
  static const double sm  = 8.0;
  static const double md  = 16.0;
  static const double lg  = 24.0;
  static const double xl  = 32.0;
  static const double xxl = 48.0;
}

class AppText {
  AppText._();
  static TextStyle display({Color? color, double size = 36}) =>
    GoogleFonts.dmSerifDisplay(fontSize: size, color: color ?? AppColors.textPrimary, height: 1.15);
  static TextStyle h1({Color? color}) =>
    GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w700, color: color ?? AppColors.textPrimary, height: 1.3);
  static TextStyle h2({Color? color}) =>
    GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700, color: color ?? AppColors.textPrimary, height: 1.35);
  static TextStyle h3({Color? color}) =>
    GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w600, color: color ?? AppColors.textPrimary, height: 1.4);
  static TextStyle body({Color? color, FontWeight? weight}) =>
    GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: weight ?? FontWeight.w400, color: color ?? AppColors.textSecondary, height: 1.6);
  static TextStyle bodyMd({Color? color, FontWeight? weight}) =>
    GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: weight ?? FontWeight.w500, color: color ?? AppColors.textPrimary, height: 1.5);
  static TextStyle bodyLg({Color? color}) =>
    GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w400, color: color ?? AppColors.textSecondary, height: 1.6);
  static TextStyle caption({Color? color}) =>
    GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w400, color: color ?? AppColors.textHint, height: 1.4);
  static TextStyle label({Color? color, FontWeight? weight}) =>
    GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: weight ?? FontWeight.w600, color: color ?? AppColors.textPrimary, letterSpacing: 0.3);
  static TextStyle btnText({Color? color}) =>
    GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: color ?? Colors.white, letterSpacing: 0.2);
  static TextStyle price({Color? color, double size = 22}) =>
    GoogleFonts.plusJakartaSans(fontSize: size, fontWeight: FontWeight.w800, color: color ?? AppColors.primary);
  static TextStyle mono({Color? color}) =>
    GoogleFonts.jetBrainsMono(fontSize: 13, color: color ?? AppColors.textSecondary);
}

class AppTheme {
  AppTheme._();
  static ThemeData get lightTheme {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent, statusBarIconBrightness: Brightness.dark));
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary, primary: AppColors.primary,
        secondary: AppColors.accent, error: AppColors.error,
        surface: AppColors.surface, brightness: Brightness.light),
      scaffoldBackgroundColor: AppColors.background,
      textTheme: GoogleFonts.plusJakartaSansTextTheme()
          .apply(bodyColor: AppColors.textPrimary, displayColor: AppColors.textPrimary),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface, foregroundColor: AppColors.textPrimary,
        elevation: 0, scrolledUnderElevation: 1, shadowColor: AppColors.border.withAlpha(80),
        centerTitle: false, surfaceTintColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        iconTheme: const IconThemeData(color: AppColors.textPrimary, size: 22)),
      elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary, foregroundColor: Colors.white, elevation: 0,
        minimumSize: const Size(double.infinity, 52),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        textStyle: AppText.btnText())),
      outlinedButtonTheme: OutlinedButtonThemeData(style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary, side: const BorderSide(color: AppColors.primary, width: 1.5),
        minimumSize: const Size(double.infinity, 52),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        textStyle: AppText.btnText(color: AppColors.primary))),
      textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(
        foregroundColor: AppColors.primary, textStyle: AppText.body(color: AppColors.primary))),
      inputDecorationTheme: InputDecorationTheme(
        filled: true, fillColor: AppColors.surfaceWarm,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: const BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: const BorderSide(color: AppColors.primary, width: 2)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: const BorderSide(color: AppColors.error)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: const BorderSide(color: AppColors.error, width: 2)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: AppText.body(color: AppColors.textHint),
        labelStyle: AppText.body(color: AppColors.textSecondary),
        errorStyle: AppText.caption(color: AppColors.error),
        prefixIconColor: AppColors.textHint, suffixIconColor: AppColors.textHint),
      cardTheme: CardThemeData(
        color: AppColors.card, elevation: 0,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            side: const BorderSide(color: AppColors.border)),
        margin: EdgeInsets.zero, clipBehavior: Clip.antiAlias),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceWarm, selectedColor: AppColors.primarySoft,
        labelStyle: AppText.label(),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.full),
            side: const BorderSide(color: AppColors.border)),
        elevation: 0, shadowColor: Colors.transparent, selectedShadowColor: Colors.transparent),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
        titleTextStyle: AppText.h1(), contentTextStyle: AppText.body(), elevation: 24),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating, backgroundColor: AppColors.textPrimary,
        contentTextStyle: AppText.body(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        actionTextColor: AppColors.accentLight),
      dividerTheme: const DividerThemeData(color: AppColors.divider, thickness: 1, space: 1),
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.primary, unselectedLabelColor: AppColors.textHint,
        indicatorColor: AppColors.primary, indicatorSize: TabBarIndicatorSize.label,
        dividerColor: AppColors.divider,
        labelStyle: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700),
        unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 13)),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? Colors.white : AppColors.textHint),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? AppColors.primary : AppColors.border),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent)),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface, selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textHint, type: BottomNavigationBarType.fixed, elevation: 0,
        selectedLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700),
        unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 11)),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary, linearTrackColor: AppColors.border),
    );
  }
}

// ── UI Utilities ───────────────────────────────────────────────
class AppUI {
  AppUI._();

  static BoxDecoration cardDecoration({Color? color, bool elevated = false, Color? borderColor}) => BoxDecoration(
    color: color ?? AppColors.card,
    borderRadius: BorderRadius.circular(AppRadius.lg),
    border: Border.all(color: borderColor ?? AppColors.border),
    boxShadow: elevated ? [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 20, offset: const Offset(0, 4))] : null);

  static BoxDecoration gradientDecoration({List<Color>? colors, double radius = AppRadius.lg}) => BoxDecoration(
    gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
        colors: colors ?? [AppColors.primaryDark, AppColors.primary]),
    borderRadius: BorderRadius.circular(radius));

  static Widget badge(String text, Color color, {IconData? icon, bool filled = false}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: filled ? color : color.withAlpha(20),
      borderRadius: BorderRadius.circular(AppRadius.full),
      border: filled ? null : Border.all(color: color.withAlpha(60))),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      if (icon != null) ...[Icon(icon, size: 12, color: filled ? Colors.white : color), const SizedBox(width: 4)],
      Text(text, style: AppText.label(color: filled ? Colors.white : color)),
    ]));

  static Widget statusBadge(String status) {
    final cfg = {
      'confirmed':        (AppColors.info,     Icons.check_circle_outline),
      'picking':          (AppColors.warning,  Icons.inventory_outlined),
      'packed':           (AppColors.warning,  Icons.inventory_2_outlined),
      'dispatched':       (AppColors.primary,  Icons.local_shipping_outlined),
      'out_for_delivery': (AppColors.accent,   Icons.delivery_dining_outlined),
      'delivered':        (AppColors.success,  Icons.check_circle),
      'cancelled':        (AppColors.error,    Icons.cancel_outlined),
      'active':           (AppColors.success,  Icons.check_circle_outline),
      'paused':           (AppColors.warning,  Icons.pause_circle_outline),
      'pending':          (AppColors.warning,  Icons.schedule_outlined),
      'paid':             (AppColors.success,  Icons.paid_outlined),
      'Healthy':          (AppColors.success,  Icons.check_circle_outline),
      'Alert':            (AppColors.warning,  Icons.warning_outlined),
      'Critical':         (AppColors.error,    Icons.error_outline),
      'Overstock':        (AppColors.info,     Icons.trending_up),
    };
    final (col, ico) = cfg[status] ?? (AppColors.textHint, Icons.circle_outlined);
    return badge(status, col, icon: ico);
  }

  static Widget tierBadge(String tier) {
    final cfg = {
      'MFDC': ('Express',  AppColors.success, Icons.bolt_outlined),
      'LWH':  ('Same-Day', AppColors.info,    Icons.local_shipping_outlined),
      'MCW':  ('Standard', AppColors.textHint, Icons.inventory_2_outlined),
    };
    final (lbl, col, ico) = cfg[tier] ?? ('Standard', AppColors.textHint, Icons.inventory_2_outlined);
    return badge(lbl, col, icon: ico);
  }

  static Widget sectionHeader(String title, {String? action, VoidCallback? onAction}) =>
    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(title, style: AppText.h2()),
      if (action != null && onAction != null)
        GestureDetector(onTap: onAction, child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(action, style: AppText.label(color: AppColors.accent)),
          const SizedBox(width: 4),
          const Icon(Icons.arrow_forward, size: 14, color: AppColors.accent),
        ])),
    ]);

  static Widget emptyState({required String title, String? message, IconData? icon,
      String? btnLabel, VoidCallback? onBtn}) => Center(
    child: Padding(padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 88, height: 88,
          decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(AppRadius.xl)),
          child: Icon(icon ?? Icons.inbox_outlined, size: 40, color: AppColors.primary.withAlpha(150))),
        const SizedBox(height: AppSpacing.lg),
        Text(title, style: AppText.h2(), textAlign: TextAlign.center),
        if (message != null) ...[const SizedBox(height: AppSpacing.sm),
          Text(message, style: AppText.body(), textAlign: TextAlign.center)],
        if (btnLabel != null && onBtn != null) ...[const SizedBox(height: AppSpacing.lg),
          SizedBox(width: 200, child: ElevatedButton(onPressed: onBtn, child: Text(btnLabel)))],
      ])));

  static Widget loadingOverlay() => Container(
    color: Colors.white.withAlpha(200),
    child: const Center(child: CircularProgressIndicator()));

  static Widget divider({String? label}) => label == null
    ? const Divider(color: AppColors.border)
    : Row(children: [
        const Expanded(child: Divider(color: AppColors.border)),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(label, style: AppText.caption())),
        const Expanded(child: Divider(color: AppColors.border)),
      ]);
}

// ── Gradient colors ────────────────────────────────────────────
class AppGradients {
  static const primary = LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [AppColors.primaryDark, AppColors.primary]);
  static const accent  = LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [AppColors.accent, AppColors.accentLight]);
  static const dark    = LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [Color(0xFF0A1628), AppColors.primaryDark]);
  static const teal    = LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [Color(0xFF0A3D2E), AppColors.teal]);
}
