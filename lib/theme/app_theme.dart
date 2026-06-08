// lib/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Core Palette ──────────────────────────────────────────────────────────
  static const Color bg         = Color(0xFF080D18);
  static const Color bgCard     = Color(0xFF0F1624);
  static const Color bgSurface  = Color(0xFF172035);
  static const Color primary    = Color(0xFF00C8F0);   // electric cyan
  static const Color primaryDim = Color(0xFF007A99);
  static const Color accent     = Color(0xFFFFAA00);   // gold
  static const Color success    = Color(0xFF00DFA0);
  static const Color danger     = Color(0xFFFF3D6B);
  static const Color purple     = Color(0xFFBB88FF);
  static const Color textPri    = Color(0xFFECF0FF);
  static const Color textSec    = Color(0xFF7A90BB);
  static const Color textMuted  = Color(0xFF374860);
  static const Color border     = Color(0xFF1A2A40);

  // ── Gradients ─────────────────────────────────────────────────────────────
  static const LinearGradient cyanGrad = LinearGradient(
    colors: [Color(0xFF00C8F0), Color(0xFF0055CC)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
  static const LinearGradient goldGrad = LinearGradient(
    colors: [Color(0xFFFFAA00), Color(0xFFFF5500)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
  static const LinearGradient greenGrad = LinearGradient(
    colors: [Color(0xFF00DFA0), Color(0xFF00AA77)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
  static const LinearGradient purpleGrad = LinearGradient(
    colors: [Color(0xFFBB88FF), Color(0xFF7744DD)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );

  // ── Shadows ───────────────────────────────────────────────────────────────
  static List<BoxShadow> cyanGlow = [
    BoxShadow(color: primary.withOpacity(0.30), blurRadius: 20, spreadRadius: 0),
    BoxShadow(color: primary.withOpacity(0.08), blurRadius: 50, spreadRadius: 4),
  ];
  static List<BoxShadow> goldGlow = [
    BoxShadow(color: accent.withOpacity(0.35), blurRadius: 18, spreadRadius: 0),
  ];
  static List<BoxShadow> card = [
    BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20, offset: Offset(0,6)),
  ];

  // ── ThemeData ─────────────────────────────────────────────────────────────
  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: bg,
    colorScheme: const ColorScheme.dark(
      primary: primary, secondary: accent,
      surface: bgCard, error: danger,
    ),
    textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme).apply(
      bodyColor: textSec, displayColor: textPri,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent, elevation: 0,
    ),
  );

  // ── Helper: type color ────────────────────────────────────────────────────
  static Color forType(String ext) {
    switch (ext.toLowerCase()) {
      case 'pdf':  return danger;
      case 'xlsx': case 'xls': case 'csv': return success;
      case 'docx': case 'doc': return primary;
      case 'txt':  return accent;
      default:     return textSec;
    }
  }
}
