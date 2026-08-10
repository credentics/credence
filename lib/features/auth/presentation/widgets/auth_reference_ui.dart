import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:pass_doc_manager/app/theme/app_palette.dart';

const String authDisplayFont = 'Manrope';
const String authMonoFont = 'JetBrains Mono';

class AuthReferenceShell extends StatelessWidget {
  const AuthReferenceShell({super.key, required this.child, this.bottom});

  final Widget child;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: Stack(
          children: [
            const Positioned.fill(child: AuthLockBackdrop()),
            LayoutBuilder(
              builder: (context, constraints) {
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 430),
                    child: Column(
                      children: [
                        Expanded(child: child),
                        if (bottom != null) bottom!,
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class AuthLockBackdrop extends StatelessWidget {
  const AuthLockBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0, -0.45),
          radius: 0.9,
          colors: [
            (isDark ? palette.primary : const Color(0xFFEDE8F8)).withValues(
              alpha: isDark ? 0.18 : 0.56,
            ),
            palette.background.withValues(alpha: 0),
          ],
          stops: const [0, 1],
        ),
      ),
    );
  }
}

class AuthVaultMedallion extends StatelessWidget {
  const AuthVaultMedallion({
    super.key,
    this.large = false,
    this.warn = false,
    this.ok = false,
  });

  final bool large;
  final bool warn;
  final bool ok;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final size = large ? 112.0 : 96.0;
    final coreSize = large ? 56.0 : 48.0;
    final coreColor = warn
        ? palette.danger
        : ok
        ? palette.success
        : palette.primary;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  center: const Alignment(0, -0.25),
                  colors: [
                    palette.primarySoft.withValues(alpha: 0.8),
                    palette.primarySoft.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          CustomPaint(
            size: Size.square(size),
            painter: _AuthRingPainter(
              ringColor: palette.textMuted.withValues(alpha: 0.48),
              tickColor: palette.textMuted.withValues(alpha: 0.55),
            ),
          ),
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.all(large ? 12 : 11),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: palette.surface,
                  border: Border.all(color: palette.stroke),
                  boxShadow: [
                    BoxShadow(
                      color: palette.shadow.withValues(alpha: 0.45),
                      blurRadius: 22,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            width: coreSize,
            height: coreSize,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(large ? 16 : 14),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  coreColor,
                  Color.lerp(coreColor, Colors.black, 0.28) ?? coreColor,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: coreColor.withValues(alpha: 0.22),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              warn ? Icons.delete_outline_rounded : Icons.lock_outline_rounded,
              color: Colors.white,
              size: large ? 28 : 24,
            ),
          ),
        ],
      ),
    );
  }
}

class AuthLockShield extends StatelessWidget {
  const AuthLockShield({
    super.key,
    this.icon = Icons.shield_outlined,
    this.warn = false,
    this.ok = false,
    this.size = 60,
  });

  final IconData icon;
  final bool warn;
  final bool ok;
  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final color = warn
        ? palette.danger
        : ok
        ? palette.success
        : palette.primary;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, Color.lerp(color, Colors.black, 0.26) ?? color],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: size * 0.47),
    );
  }
}

class AuthPinBars extends StatelessWidget {
  const AuthPinBars({
    super.key,
    required this.filled,
    this.error = false,
    this.ok = false,
  });

  final int filled;
  final bool error;
  final bool ok;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (index) {
        final isFilled = index < filled;
        final isActive = index == filled && filled < 6 && !error && !ok;
        final color = error
            ? palette.danger
            : ok
            ? palette.success
            : isFilled
            ? palette.textPrimary
            : isActive
            ? palette.textSecondary
            : palette.strokeStrong;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 36,
          height: isActive ? 8 : 7,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}

class AuthPinDots extends StatelessWidget {
  const AuthPinDots({
    super.key,
    required this.filled,
    this.error = false,
    this.ok = false,
  });

  final int filled;
  final bool error;
  final bool ok;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (index) {
        final isFilled = index < filled;
        final color = error
            ? palette.danger
            : ok
            ? palette.success
            : isFilled
            ? palette.textPrimary
            : palette.strokeStrong;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 8),
          width: isFilled ? 15 : 14,
          height: isFilled ? 15 : 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            border: Border.all(color: color),
          ),
        );
      }),
    );
  }
}

class AuthRulePill extends StatelessWidget {
  const AuthRulePill({super.key, required this.label, required this.met});

  final String label;
  final bool met;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final color = met ? palette.success : palette.textMuted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: met
            ? palette.success.withValues(alpha: 0.12)
            : palette.surfaceSoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (met) ...[
            Icon(Icons.check_rounded, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontFamily: authMonoFont,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class AuthNumpad extends StatelessWidget {
  const AuthNumpad({
    super.key,
    required this.onDigit,
    required this.onDelete,
    this.leading,
    this.enabled = true,
  });

  final ValueChanged<String> onDigit;
  final VoidCallback onDelete;
  final Widget? leading;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final keys = <Widget>[
      for (final digit in ['1', '2', '3', '4', '5', '6', '7', '8', '9'])
        AuthNumpadKey(
          label: digit,
          enabled: enabled,
          onTap: () => onDigit(digit),
        ),
      leading ?? const SizedBox(width: 64, height: 64),
      AuthNumpadKey(label: '0', enabled: enabled, onTap: () => onDigit('0')),
      AuthNumpadKey(
        icon: Icons.backspace_outlined,
        enabled: enabled,
        onTap: onDelete,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(26, 12, 26, 6),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 3,
        mainAxisSpacing: 14,
        crossAxisSpacing: 22,
        childAspectRatio: 1,
        children: keys,
      ),
    );
  }
}

class AuthNumpadKey extends StatelessWidget {
  const AuthNumpadKey({
    super.key,
    this.label,
    this.icon,
    required this.onTap,
    this.enabled = true,
  });

  final String? label;
  final IconData? icon;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;

    return InkResponse(
      onTap: enabled ? onTap : null,
      radius: 46,
      borderRadius: BorderRadius.circular(999),
      containedInkWell: false,
      child: SizedBox.expand(
        child: Center(
          child: icon == null
              ? Text(
                  label ?? '',
                  style: TextStyle(
                    fontFamily: authDisplayFont,
                    fontSize: 30,
                    fontWeight: FontWeight.w400,
                    letterSpacing: -0.6,
                    color: enabled
                        ? palette.textPrimary
                        : palette.textMuted.withValues(alpha: 0.45),
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                )
              : Icon(
                  icon,
                  size: 27,
                  color: enabled
                      ? palette.textPrimary
                      : palette.textMuted.withValues(alpha: 0.45),
                ),
        ),
      ),
    );
  }
}

class AuthOnboardingCard extends StatelessWidget {
  const AuthOnboardingCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
    this.primary = false,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final fg = primary ? palette.surface : palette.textPrimary;

    return Material(
      color: primary ? palette.textPrimary : palette.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: primary ? palette.textPrimary : palette.stroke,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: primary
                          ? Colors.white.withValues(alpha: 0.12)
                          : palette.surfaceSoft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, size: 17, color: fg),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontFamily: authDisplayFont,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.17,
                        color: fg,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: fg.withValues(alpha: 0.72),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: TextStyle(
                  fontFamily: authDisplayFont,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  height: 1.45,
                  color: primary
                      ? palette.surface.withValues(alpha: 0.68)
                      : palette.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AuthBiometricPrompt extends StatelessWidget {
  const AuthBiometricPrompt({
    super.key,
    required this.title,
    required this.subtitle,
    required this.primaryLabel,
    required this.secondaryLabel,
    required this.onPrimary,
    required this.onSecondary,
  });

  final String title;
  final String subtitle;
  final String primaryLabel;
  final String secondaryLabel;
  final VoidCallback onPrimary;
  final VoidCallback onSecondary;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 5,
              decoration: BoxDecoration(
                color: palette.strokeStrong,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 18),
            const AuthFaceIcon(size: 58),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: authDisplayFont,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
                color: palette.textPrimary,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: authDisplayFont,
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                height: 1.45,
                color: palette.textSecondary,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: AuthActionButton(
                    label: secondaryLabel,
                    onTap: onSecondary,
                    primary: false,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AuthActionButton(
                    label: primaryLabel,
                    onTap: onPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Face data stays on device',
              style: TextStyle(
                fontFamily: authMonoFont,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: palette.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AuthFaceIcon extends StatelessWidget {
  const AuthFaceIcon({super.key, this.size = 38});

  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;

    return CustomPaint(
      size: Size.square(size),
      painter: _FacePainter(color: palette.textPrimary),
    );
  }
}

class AuthActionButton extends StatelessWidget {
  const AuthActionButton({
    super.key,
    required this.label,
    required this.onTap,
    this.primary = true,
    this.danger = false,
  });

  final String label;
  final VoidCallback? onTap;
  final bool primary;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final bg = danger
        ? palette.danger
        : primary
        ? palette.textPrimary
        : palette.surfaceSoft;
    final fg = primary || danger ? palette.surface : palette.textPrimary;

    return Material(
      color: bg.withValues(alpha: onTap == null ? 0.5 : 1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 40,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: authDisplayFont,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: fg.withValues(alpha: onTap == null ? 0.6 : 1),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AuthSectionHeader extends StatelessWidget {
  const AuthSectionHeader(this.label, {super.key, this.color});

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 6),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
            fontFamily: authMonoFont,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.4,
            color: color ?? palette.textMuted,
          ),
        ),
      ),
    );
  }
}

class AuthStatusHero extends StatelessWidget {
  const AuthStatusHero({
    super.key,
    required this.title,
    required this.subtitle,
    this.ok = true,
  });

  final String title;
  final String subtitle;
  final bool ok;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 14, 14, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.stroke),
      ),
      child: Row(
        children: [
          AuthLockShield(icon: Icons.lock_outline_rounded, ok: ok, size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: authDisplayFont,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.08,
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle.toUpperCase(),
                  style: TextStyle(
                    fontFamily: authMonoFont,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.45,
                    color: palette.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AuthSettingsRow extends StatelessWidget {
  const AuthSettingsRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.value,
    this.trailing,
    this.onTap,
    this.danger = false,
    this.showChevron = true,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool danger;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final tone = danger ? palette.danger : palette.textPrimary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      child: Material(
        color: palette.surface,
        borderRadius: BorderRadius.circular(13),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(13),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: danger
                        ? palette.danger.withValues(alpha: 0.12)
                        : palette.surfaceSoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 17, color: tone),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontFamily: authDisplayFont,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.05,
                          color: tone,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontFamily: authDisplayFont,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          height: 1.35,
                          color: palette.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 10),
                  trailing!,
                ] else if (value != null) ...[
                  const SizedBox(width: 10),
                  Text(
                    value!.toUpperCase(),
                    style: TextStyle(
                      fontFamily: authMonoFont,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                      color: danger ? palette.danger : palette.textPrimary,
                    ),
                  ),
                ],
                if (showChevron) ...[
                  const SizedBox(width: 6),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: danger ? palette.danger : palette.textMuted,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AuthReferenceToggle extends StatelessWidget {
  const AuthReferenceToggle({super.key, required this.isOn});

  final bool isOn;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: 36,
      height: 20,
      decoration: BoxDecoration(
        color: isOn ? palette.success : palette.strokeStrong,
        borderRadius: BorderRadius.circular(999),
      ),
      alignment: isOn ? Alignment.centerRight : Alignment.centerLeft,
      padding: const EdgeInsets.all(2),
      child: Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          color: palette.surface,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.16),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthRingPainter extends CustomPainter {
  const _AuthRingPainter({required this.ringColor, required this.tickColor});

  final Color ringColor;
  final Color tickColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 1;
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = ringColor;

    const dashCount = 36;
    const gapRadians = 0.035;
    final segment = (math.pi * 2) / dashCount;
    for (var i = 0; i < dashCount; i++) {
      final start = i * segment;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        segment - gapRadians,
        false,
        ringPaint,
      );
    }

    final tickPaint = Paint()..color = tickColor;
    for (final angle in [
      0.0,
      math.pi / 2,
      math.pi,
      math.pi * 1.5,
      math.pi / 4,
      math.pi * 0.75,
      math.pi * 1.25,
      math.pi * 1.75,
    ]) {
      final point = Offset(
        center.dx + math.cos(angle) * (radius - 5),
        center.dy + math.sin(angle) * (radius - 5),
      );
      canvas.drawCircle(
        point,
        angle % (math.pi / 2) == 0 ? 1.4 : 1.0,
        tickPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _AuthRingPainter oldDelegate) {
    return oldDelegate.ringColor != ringColor ||
        oldDelegate.tickColor != tickColor;
  }
}

class _FacePainter extends CustomPainter {
  const _FacePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final rect = Rect.fromLTWH(1, 1, size.width - 2, size.height - 2);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(size.width * 0.25)),
      paint,
    );
    final eyePaint = Paint()..color = color;
    canvas.drawCircle(
      Offset(size.width * 0.36, size.height * 0.38),
      2.2,
      eyePaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.64, size.height * 0.38),
      2.2,
      eyePaint,
    );
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(size.width * 0.5, size.height * 0.57),
        width: size.width * 0.34,
        height: size.height * 0.26,
      ),
      0,
      math.pi,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _FacePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
