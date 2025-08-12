// lib/core/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// 16Pっぽい緑ベース + 補色（紫）
class KaotypeColors {
  static const Color greenMain = Color(0xFF127158); // 濃緑（主）
  static const Color greenLight = Color(0xFF46C5A1); // 明るいアクセント
  static const Color greenPale = Color(0xFF92D8C5); // ペール
  static const Color purpleMain = Color(0xFF7D4F9F); // 補色（濃紫）
  static const Color purpleLight = Color(0xFFA572AF); // 補色（淡紫）
  static const Color grayBg = Color(0xFFD9D9D9); // セクション区切り
}

ThemeData buildKaotypeTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;

  // 手動 ColorScheme
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
    tertiaryContainer: KaotypeColors.greenPale.withOpacity(0.6),
    onTertiaryContainer: Colors.black,
    error: const Color(0xFFB00020),
    onError: Colors.white,
    surface: isDark ? const Color(0xFF121212) : Colors.white,
    onSurface: isDark ? Colors.white : const Color(0xFF212121),
    surfaceContainerHighest: KaotypeColors.grayBg, // 3.22+のみ使用
    outline: Colors.black12,
  );

  // ★ Noto Sans JP を採用（色も適用）、fontFamily も明示
  final jpTextTheme = GoogleFonts.notoSansJpTextTheme().apply(
    bodyColor: scheme.onSurface,
    displayColor: scheme.onSurface,
  );
  final fontFamily = GoogleFonts.notoSansJp().fontFamily;

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    textTheme: jpTextTheme,
    fontFamily: fontFamily,
    scaffoldBackgroundColor: isDark
        ? const Color(0xFF101314)
        : const Color(0xFFF7FAF8),
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      elevation: 0,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: scheme.primary,
        side: BorderSide(color: scheme.primary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
    ),
    dividerColor: KaotypeColors.grayBg,
    cardTheme: CardThemeData(
      color: scheme.primary.withOpacity(0.10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
    ),
  );
}
