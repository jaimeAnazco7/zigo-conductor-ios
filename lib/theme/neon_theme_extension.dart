import 'package:flutter/material.dart';

/// Tokens de marca "Neon Steel Blue" (ZIGO Conductor).
/// Uso: `Theme.of(context).extension<NeonThemeExtension>()`
@immutable
class NeonThemeExtension extends ThemeExtension<NeonThemeExtension> {
  const NeonThemeExtension({
    required this.background,
    required this.surfaceCard,
    required this.accent,
    required this.highlight,
    required this.onAccent,
    required this.errorNeon,
    required this.borderSubtle,
    this.glowBlur = 8,
  });

  final Color background;
  final Color surfaceCard;
  final Color accent;
  final Color highlight;
  final Color onAccent;
  final Color errorNeon;
  final Color borderSubtle;
  final double glowBlur;

  /// Sombra neón suave (usar con moderación en listas).
  List<BoxShadow> get glowShadow => [
        BoxShadow(
          color: accent.withOpacity(0.35),
          blurRadius: glowBlur,
          spreadRadius: 0,
        ),
      ];

  static const NeonThemeExtension dark = NeonThemeExtension(
    background: Color(0xFF01203d),
    surfaceCard: Color(0xFF082f4d),
    accent: Color(0xFF18e8bc),
    highlight: Color(0xFFc6f7fd),
    onAccent: Color(0xFF01203d),
    errorNeon: Color(0xFFFF4D8C),
    borderSubtle: Color(0x6618e8bc),
    glowBlur: 8,
  );

  /// Variante para tema claro (mismos acentos, fondos claros en ThemeData).
  static const NeonThemeExtension light = NeonThemeExtension(
    background: Color(0xFF01203d),
    surfaceCard: Color(0xFFFFFFFF),
    accent: Color(0xFF18e8bc),
    highlight: Color(0xFFc6f7fd),
    onAccent: Color(0xFF01203d),
    errorNeon: Color(0xFFFF4D8C),
    borderSubtle: Color(0x6618e8bc),
    glowBlur: 6,
  );

  @override
  NeonThemeExtension copyWith({
    Color? background,
    Color? surfaceCard,
    Color? accent,
    Color? highlight,
    Color? onAccent,
    Color? errorNeon,
    Color? borderSubtle,
    double? glowBlur,
  }) {
    return NeonThemeExtension(
      background: background ?? this.background,
      surfaceCard: surfaceCard ?? this.surfaceCard,
      accent: accent ?? this.accent,
      highlight: highlight ?? this.highlight,
      onAccent: onAccent ?? this.onAccent,
      errorNeon: errorNeon ?? this.errorNeon,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      glowBlur: glowBlur ?? this.glowBlur,
    );
  }

  @override
  NeonThemeExtension lerp(ThemeExtension<NeonThemeExtension>? other, double t) {
    if (other is! NeonThemeExtension) return this;
    return NeonThemeExtension(
      background: Color.lerp(background, other.background, t)!,
      surfaceCard: Color.lerp(surfaceCard, other.surfaceCard, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      highlight: Color.lerp(highlight, other.highlight, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      errorNeon: Color.lerp(errorNeon, other.errorNeon, t)!,
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t)!,
      glowBlur: glowBlur + (other.glowBlur - glowBlur) * t,
    );
  }
}
