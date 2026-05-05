import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  // ── Display — Cormorant Garamond ─────────────────────────────────────────

  static TextStyle get displayLarge => const TextStyle(
        fontFamily: 'CormorantGaramond',
        fontSize: 40,
        fontWeight: FontWeight.w500,
        color: AppColors.ink,
        height: 1.2,
      );

  static TextStyle get countdownNumber => const TextStyle(
        fontFamily: 'CormorantGaramond',
        fontSize: 88,
        fontStyle: FontStyle.italic,
        fontWeight: FontWeight.w500,
        color: Colors.white,
        height: 0.95,
        letterSpacing: -1.8,
      );

  static TextStyle get displayMedium => const TextStyle(
        fontFamily: 'CormorantGaramond',
        fontSize: 30,
        fontWeight: FontWeight.w500,
        color: AppColors.ink,
        height: 1.3,
      );

  static TextStyle get displaySmall => const TextStyle(
        fontFamily: 'CormorantGaramond',
        fontSize: 24,
        fontWeight: FontWeight.w500,
        color: AppColors.ink,
        height: 1.3,
      );

  static TextStyle get cardTitle => const TextStyle(
        fontFamily: 'CormorantGaramond',
        fontSize: 20,
        fontWeight: FontWeight.w500,
        color: AppColors.ink,
      );

  static TextStyle get appBarTitle => const TextStyle(
        fontFamily: 'CormorantGaramond',
        fontSize: 24,
        fontWeight: FontWeight.w500,
        color: AppColors.ink,
      );

  static TextStyle get italicNumeral => const TextStyle(
        fontFamily: 'CormorantGaramond',
        fontStyle: FontStyle.italic,
        fontWeight: FontWeight.w600,
        fontSize: 44,
        color: AppColors.ink,
        letterSpacing: -0.9,
      );

  // ── Section eyebrow ──────────────────────────────────────────────────────

  static const TextStyle sectionEyebrow = TextStyle(
    fontFamily: 'GoogleSans',
    fontSize: 10,
    fontWeight: FontWeight.w700,
    letterSpacing: 2.2,
    color: AppColors.inkSoft,
  );

  // ── Card subtitle — Google Sans ───────────────────────────────────────────

  static const TextStyle cardSubtitle = TextStyle(
    fontFamily: 'GoogleSans',
    fontSize: 13,
    color: AppColors.inkMute,
    height: 1.4,
  );

  // ── Body / Labels — Google Sans ────────────────────────────────────────────

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: 'GoogleSans',
    fontSize: 16,
    color: AppColors.ink,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: 'GoogleSans',
    fontSize: 14,
    color: AppColors.ink,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: 'GoogleSans',
    fontSize: 12,
    color: AppColors.inkMute,
    height: 1.4,
  );

  static const TextStyle labelLarge = TextStyle(
    fontFamily: 'GoogleSans',
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.ink,
    letterSpacing: 0.1,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: 'GoogleSans',
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.inkMute,
    letterSpacing: 0.3,
  );

  static const TextStyle percentLabel = TextStyle(
    fontFamily: 'GoogleSans',
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.inkMute,
  );

  static const TextStyle countdownLabel = TextStyle(
    fontFamily: 'GoogleSans',
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: AppColors.primaryTC,
    letterSpacing: 0.4,
  );

  static const TextStyle urgencyBadge = TextStyle(
    fontFamily: 'GoogleSans',
    fontSize: 10,
    fontWeight: FontWeight.w700,
    color: AppColors.danger,
  );

  static const TextStyle buttonText = TextStyle(
    fontFamily: 'GoogleSans',
    fontSize: 15,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );
}
