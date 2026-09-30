import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const bg = Color(0xFFF4F1EA);
  static const surface = Colors.white;
  static const ink = Color(0xFF10201B);
  static const muted = Color(0xFF5E6B66);
  static const primary = Color(0xFF0B4D3E);
  static const lime = Color(0xFFD4F26A);
  static const limeSoft = Color(0xFFE6F5B0);
  static const sand = Color(0xFFEFE4CB);
  static const sky = Color(0xFFDCEAF2);
  static const lavender = Color(0xFFE6E0F3);
  static const mint = Color(0xFFD9EBDD);
  static const clay = Color(0xFFD9532B);
  static const claySoft = Color(0xFFFBE0D6);
  static const line = Color(0xFFE6E1D6);

  // Vefat (koyu) ekranı
  static const darkBg = Color(0xFF131A21);
  static const darkSurface = Color(0xFF1D2731);
  static const darkSurface2 = Color(0xFF26323E);
  static const darkLine = Color(0xFF2C3947);
  static const darkText = Color(0xFFEAEFF3);
  static const darkMuted = Color(0xFFA0AEBB);
  static const darkAccent = Color(0xFFC9D6E2);
}

class AppTheme {
  static const cardShadow = [
    BoxShadow(color: Color(0x1410201B), blurRadius: 24, offset: Offset(0, 8)),
  ];

  /// Başlıklar için Bricolage Grotesque.
  static TextStyle display(
    double size, {
    Color color = AppColors.ink,
    FontWeight weight = FontWeight.w800,
  }) => GoogleFonts.bricolageGrotesque(
    fontSize: size,
    fontWeight: weight,
    color: color,
    letterSpacing: -size * 0.02,
    height: 1.1,
  );

  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        surface: AppColors.surface,
      ),
    );
    return base.copyWith(
      // Mesajlar yüzen alt menünün üstünde kalsın, menüyü kapatmasın.
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        insetPadding: EdgeInsets.fromLTRB(16, 0, 16, 120),
      ),
      textTheme: GoogleFonts.manropeTextTheme(base.textTheme)
          .apply(bodyColor: AppColors.ink, displayColor: AppColors.ink),
    );
  }
}
