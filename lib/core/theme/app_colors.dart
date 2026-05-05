import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Brand teal palette ─────────────────────────────────────────
  static const Color primary      = Color(0xFF0099AE); // Aqua primary
  static const Color primaryLight = Color(0xFF00C2D6); // Sky Blue
  static const Color primaryDeep  = Color(0xFF006064); // Deep Teal
  static const Color primaryT     = Color(0xFFB2EBF2); // Ice Blue tonal container
  static const Color primaryTC    = Color(0xFF003E45); // On tonal container
  static const Color secondary    = Color(0xFF006064); // Deep Teal secondary
  static const Color secondaryT   = Color(0xFFCFEFF2); // Secondary tonal
  static const Color accent       = Color(0xFF4DD0E1); // Sky Blue accent

  // ── Backgrounds ───────────────────────────────────────────────
  static const Color background   = Color(0xFFF2F8FA);
  static const Color surface      = Color(0xFFFFFFFF);
  static const Color surfaceHi    = Color(0xFFE4F2F5);
  static const Color surfaceLo    = Color(0xFFCDE6EB);

  // ── Ink / text ────────────────────────────────────────────────
  static const Color ink          = Color(0xFF062A2E);
  static const Color inkSoft      = Color(0xFF2E5358);
  static const Color inkMute      = Color(0xFF5E7E83);
  static const Color line         = Color(0xFFC5DEE3);

  // ── Semantic ──────────────────────────────────────────────────
  static const Color success      = Color(0xFF0E8A75);
  static const Color warning      = Color(0xFFD08A2E);
  static const Color danger       = Color(0xFFC0524F);
  static const Color pending      = Color(0xFF5E7E83);

  // ── Legacy aliases (keep so all existing widgets compile) ─────
  static const Color tealVibrant      = primary;
  static const Color tealMedium       = primaryLight;
  static const Color tealDeep         = primaryDeep;
  static const Color tealOcean        = Color(0xFF0A7898);
  static const Color tealGreen        = success;
  static const Color steelBlue        = Color(0xFF5A80AA);
  static const Color pearlBlue        = Color(0xFF78AECE);
  static const Color seafoam          = Color(0xFF9AEADF);
  static const Color mintPale         = primaryT;
  static const Color dustyRose        = primary;
  static const Color dustyRoseLight   = primaryLight;
  static const Color sage             = success;
  static const Color champagne        = primaryT;
  static const Color ivory            = background;
  static const Color deepTaupe        = ink;
  static const Color warmGrey         = inkSoft;
  static const Color surfaceVariant   = surfaceHi;
  static const Color textPrimary      = ink;
  static const Color textSecondary    = inkSoft;
  static const Color textOnDark       = Color(0xFFF2FAFA);
  static const Color divider          = line;

  // ── Progress bar colours per section ─────────────────────────
  static const Color progressBudget  = primary;
  static const Color progressGuests  = secondary;
  static const Color progressVendors = accent;
  static const Color progressTasks   = warning;

  // ── Gradient helpers (used by multiple widgets) ───────────────
  static const LinearGradient primaryGrad = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF00C2D6), Color(0xFF0099AE), Color(0xFF006064)],
    stops: [0.0, 0.55, 1.0],
  );

  static const LinearGradient heroGrad = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFB2EBF2), Color(0xFF7CDCE5), Color(0xFF4DD0E1)],
    stops: [0.0, 0.55, 1.0],
  );

  static const LinearGradient dialGrad = LinearGradient(
    colors: [Color(0xFF00C2D6), Color(0xFF006064)],
  );

  static const BoxShadow cardGlow = BoxShadow(
    color: Color(0x59004D54),
    blurRadius: 38,
    spreadRadius: -14,
    offset: Offset(0, 18),
  );
}
