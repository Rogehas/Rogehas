import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Koyu tema: koyu gri zemin, kırmızı vurgu.
  static const bg = Color(0xFF1A1A1A);
  static const surface = Color(0xFF262626);
  static const ink = Color(0xFFF2F2F2); // metin rengi (koyu zeminde açık)
  static const muted = Color(0xFFA3A3A3);
  static const primary = Color(
    0xFFA8141F,
  ); // düğme ve üst çubuk kırmızısı (üstünde beyaz yazı)
  static const accentText = Color(
    0xFFFF4B55,
  ); // koyu zeminde kırmızı yazı/simge
  static const lime = Color(
    0xFFC8102E,
  ); // canlı vurgu (seçili öğe, kendi mesajım)
  static const limeSoft = Color(0xFF3A1F24);
  static const sand = Color(0xFF3A3020);
  static const sky = Color(0xFF1F2F3D);
  static const lavender = Color(0xFF2F2742);
  static const mint = Color(0xFF1F3A2B);
  static const clay = Color(0xFFFF6B4A);
  static const claySoft = Color(0xFF3E231C);
  static const line = Color(0xFF383838);

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
    BoxShadow(color: Color(0x40000000), blurRadius: 24, offset: Offset(0, 8)),
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

  static ThemeData get dark {
    final base = ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.dark,
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
