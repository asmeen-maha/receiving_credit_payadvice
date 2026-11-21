import 'package:flutter/material.dart';

/// "Carnival Bento" palette.
abstract final class AppColors {
  // Brand
  static const magenta = Color(0xFFDB2F7A);
  static const magentaDark = Color(0xFFB8215F);
  static const magentaDeep = Color(0xFFA21D59);
  static const magentaLight = Color(0xFFE8418A);
  static const magentaSoft = Color(0xFFFDE3EE);
  static const marigold = Color(0xFFF5A524);
  static const marigoldSoft = Color(0xFFFFF1D6);
  static const marigoldText = Color(0xFF9A5B00);
  static const lagoon = Color(0xFF13A094);
  static const lagoonSoft = Color(0xFFDBF4F0);
  static const lagoonText = Color(0xFF0B7A70);

  // Surfaces
  static const blush = Color(0xFFFFF5F8);
  // Opaque so shadows don't show through (Flutter paints shadows under translucent fills).
  static const glass = Color(0xFFFFFBFD);
  static const glassBorder = Color(0xEBFFFFFF);
  static const row = Color(0xDBFFFFFF);
  static const rowVerified = Color(0xEBE0F5EA);
  static const chipBorder = Color(0xFFF3D9E5);

  // Text
  static const ink = Color(0xFF2B1630); // plum
  static const ink2 = Color(0xFF4A3350);
  static const muted = Color(0xFF7C6479);
  static const faint = Color(0xFFA893A4);
  static const disabled = Color(0xFFBCAAB8);

  // Status
  static const verified = Color(0xFF1E9E6A);
  static const verifiedSoft = Color(0xFFE0F5EA);
  static const pending = Color(0xFFC97A00);
  static const pendingSoft = Color(0xFFFFF0D4);
  static const danger = Color(0xFFE5483E);
  static const dangerSoft = Color(0xFFFDE7E5);

  static const heroGradient = LinearGradient(
    begin: Alignment(-0.6, -1),
    end: Alignment(0.6, 1),
    colors: [magentaLight, Color(0xFFD02A72), magentaDeep],
  );

  static const logoGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFEE4E92), magenta, marigold],
  );

  static List<BoxShadow> softShadow = [
    BoxShadow(
        color: const Color(0xFF781E46).withOpacity(.18),
        blurRadius: 40,
        offset: const Offset(0, 18),
        spreadRadius: -22),
  ];

  static List<BoxShadow> glow(Color color, {double opacity = .55}) => [
        BoxShadow(color: color.withOpacity(opacity), blurRadius: 20, offset: const Offset(0, 10), spreadRadius: -10),
      ];
}
