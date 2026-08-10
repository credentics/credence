import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF2D2936);
  static const primaryAccent = Color(0xFF403A4D);
  static const primarySoft = Color(0xFFF0ECF8);

  static const background = Color(0xFFFAF9F6);
  static const backgroundAlt = Color(0xFFF4F2EE);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceSoft = Color(0xFFF5F3EF);

  static const stroke = Color(0xFFE9E5DF);
  static const strokeStrong = Color(0xFFDDD8CF);

  static const textPrimary = Color(0xFF292620);
  static const textSecondary = Color(0xFF766F65);
  static const textMuted = Color(0xFFA49C91);

  static const success = Color(0xFF278156);
  static const warning = Color(0xFFB87818);
  static const danger = Color(0xFFB84B3E);
  static const dangerSoft = Color(0xFFFFF4F2);
  static const dangerStroke = Color(0xFFF2B8B0);

  static const shadow = Color(0x1429251F);
}

@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.primary,
    required this.primaryAccent,
    required this.primarySoft,
    required this.background,
    required this.backgroundAlt,
    required this.surface,
    required this.surfaceSoft,
    required this.stroke,
    required this.strokeStrong,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.success,
    required this.warning,
    required this.danger,
    required this.dangerSoft,
    required this.dangerStroke,
    required this.shadow,
  });

  const AppPalette.light()
    : primary = AppColors.primary,
      primaryAccent = AppColors.primaryAccent,
      primarySoft = AppColors.primarySoft,
      background = AppColors.background,
      backgroundAlt = AppColors.backgroundAlt,
      surface = AppColors.surface,
      surfaceSoft = AppColors.surfaceSoft,
      stroke = AppColors.stroke,
      strokeStrong = AppColors.strokeStrong,
      textPrimary = AppColors.textPrimary,
      textSecondary = AppColors.textSecondary,
      textMuted = AppColors.textMuted,
      success = AppColors.success,
      warning = AppColors.warning,
      danger = AppColors.danger,
      dangerSoft = AppColors.dangerSoft,
      dangerStroke = AppColors.dangerStroke,
      shadow = AppColors.shadow;

  const AppPalette.dark()
    : primary = const Color(0xFF9B7DFF),
      primaryAccent = const Color(0xFFB49AFF),
      primarySoft = const Color(0xFF1E1535),
      background = const Color(0xFF0F1117),
      backgroundAlt = const Color(0xFF151821),
      surface = const Color(0xFF1A1D27),
      surfaceSoft = const Color(0xFF21252F),
      stroke = const Color(0xFF2A2E3A),
      strokeStrong = const Color(0xFF333845),
      textPrimary = const Color(0xFFF0F1F4),
      textSecondary = const Color(0xFF9CA3B4),
      textMuted = const Color(0xFF5C6478),
      success = const Color(0xFF34D399),
      warning = const Color(0xFFFBBF24),
      danger = const Color(0xFFF87171),
      dangerSoft = const Color(0xFF2D1518),
      dangerStroke = const Color(0xFF5C2126),
      shadow = const Color(0x40000000);

  final Color primary;
  final Color primaryAccent;
  final Color primarySoft;
  final Color background;
  final Color backgroundAlt;
  final Color surface;
  final Color surfaceSoft;
  final Color stroke;
  final Color strokeStrong;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color success;
  final Color warning;
  final Color danger;
  final Color dangerSoft;
  final Color dangerStroke;
  final Color shadow;

  @override
  AppPalette copyWith({
    Color? primary,
    Color? primaryAccent,
    Color? primarySoft,
    Color? background,
    Color? backgroundAlt,
    Color? surface,
    Color? surfaceSoft,
    Color? stroke,
    Color? strokeStrong,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? success,
    Color? warning,
    Color? danger,
    Color? dangerSoft,
    Color? dangerStroke,
    Color? shadow,
  }) {
    return AppPalette(
      primary: primary ?? this.primary,
      primaryAccent: primaryAccent ?? this.primaryAccent,
      primarySoft: primarySoft ?? this.primarySoft,
      background: background ?? this.background,
      backgroundAlt: backgroundAlt ?? this.backgroundAlt,
      surface: surface ?? this.surface,
      surfaceSoft: surfaceSoft ?? this.surfaceSoft,
      stroke: stroke ?? this.stroke,
      strokeStrong: strokeStrong ?? this.strokeStrong,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      dangerSoft: dangerSoft ?? this.dangerSoft,
      dangerStroke: dangerStroke ?? this.dangerStroke,
      shadow: shadow ?? this.shadow,
    );
  }

  @override
  AppPalette lerp(covariant ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) {
      return this;
    }

    return AppPalette(
      primary: Color.lerp(primary, other.primary, t) ?? primary,
      primaryAccent:
          Color.lerp(primaryAccent, other.primaryAccent, t) ?? primaryAccent,
      primarySoft: Color.lerp(primarySoft, other.primarySoft, t) ?? primarySoft,
      background: Color.lerp(background, other.background, t) ?? background,
      backgroundAlt:
          Color.lerp(backgroundAlt, other.backgroundAlt, t) ?? backgroundAlt,
      surface: Color.lerp(surface, other.surface, t) ?? surface,
      surfaceSoft: Color.lerp(surfaceSoft, other.surfaceSoft, t) ?? surfaceSoft,
      stroke: Color.lerp(stroke, other.stroke, t) ?? stroke,
      strokeStrong:
          Color.lerp(strokeStrong, other.strokeStrong, t) ?? strokeStrong,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t) ?? textPrimary,
      textSecondary:
          Color.lerp(textSecondary, other.textSecondary, t) ?? textSecondary,
      textMuted: Color.lerp(textMuted, other.textMuted, t) ?? textMuted,
      success: Color.lerp(success, other.success, t) ?? success,
      warning: Color.lerp(warning, other.warning, t) ?? warning,
      danger: Color.lerp(danger, other.danger, t) ?? danger,
      dangerSoft: Color.lerp(dangerSoft, other.dangerSoft, t) ?? dangerSoft,
      dangerStroke:
          Color.lerp(dangerStroke, other.dangerStroke, t) ?? dangerStroke,
      shadow: Color.lerp(shadow, other.shadow, t) ?? shadow,
    );
  }
}

extension AppPaletteContext on BuildContext {
  AppPalette get appPalette =>
      Theme.of(this).extension<AppPalette>() ?? const AppPalette.light();
}
