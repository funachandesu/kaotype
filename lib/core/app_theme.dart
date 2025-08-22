// lib/core/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class KaotypeColors {
  static const Color greenMain = Color(0xFF127158);
  static const Color greenLight = Color(0xFF46C5A1);
  static const Color greenPale = Color(0xFF92D8C5);
  static const Color purpleMain = Color(0xFF7D4F9F);
  static const Color purpleLight = Color(0xFFA572AF);
  static const Color grayBg = Color(0xFFD9D9D9);
}

ThemeData buildKaotypeTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;

  final scheme = ColorScheme(
    brightness: brightness,
    primary: KaotypeColors.greenMain,
    onPrimary: Colors.white,
    primaryContainer: KaotypeColors.greenLight,
    onPrimaryContainer: Colors.black,
    secondary: KaotypeColors.purpleMain,
    onSecondary: Colors.white,
    secondaryContainer: KaotypeColors.purpleLight,
    onSecondaryContainer: Colors.white,
    tertiary: KaotypeColors.greenPale,
    onTertiary: Colors.black,
    tertiaryContainer: KaotypeColors.greenPale, // OK
    onTertiaryContainer: Colors.black,
    error: const Color(0xFFB00020),
    onError: Colors.white,
    surface: isDark ? const Color(0xFF121212) : Colors.white,
    onSurface: isDark ? Colors.white : const Color(0xFF212121),
    surfaceContainerHighest: KaotypeColors.grayBg,
    outline: Colors.black12,
  );

  // ① Material3 の標準 TextTheme を“ベース”にする
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    brightness: brightness,
  );

  // ② そのベースに Noto Sans JP を合成
  final notoTheme = GoogleFonts.notoSansJpTextTheme(
    base.textTheme,
  ).apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface);
  // final fontFamily = GoogleFonts.notoSansJp().fontFamily;

  return base.copyWith(
    textTheme: notoTheme,
    // M2系の後方互換（AppBar などで参照されることがあるので念のため）
    primaryTextTheme: notoTheme,
    scaffoldBackgroundColor: isDark
        ? const Color(0xFF101314)
        : const Color(0xFFF7FAF8),
    appBarTheme: base.appBarTheme.copyWith(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      // ③ AppBarのタイトルへも明示適用（w800→w700/900に寄せる）
      titleTextStyle: notoTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
      ),
      toolbarTextStyle: notoTheme.bodyMedium,
      elevation: 0,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(vertical: 14),
        textStyle: notoTheme.labelLarge, // ④ ボタンにも明示
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: scheme.primary,
        side: BorderSide(color: scheme.primary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(vertical: 14),
        textStyle: notoTheme.labelLarge,
      ),
    ),
    dividerColor: KaotypeColors.grayBg,
    cardTheme: base.cardTheme.copyWith(
      color: scheme.primary.withOpacity(0.10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
    ),
  );
}
