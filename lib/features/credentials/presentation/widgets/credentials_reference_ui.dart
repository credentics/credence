import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:pass_doc_manager/domain/credentials/entities/credential_security_status.dart';
import 'package:pass_doc_manager/features/credentials/presentation/widgets/company_logo_avatar.dart';

const String credentialsFontDisplay = 'Manrope';
const String credentialsFontBody = 'Manrope';
const String credentialsFontMono = 'JetBrains Mono';

class CredentialsReferenceColors {
  const CredentialsReferenceColors._();

  static const bg = Color(0xFFFEFCF8);
  static const surface = Color(0xFFFFFFFF);
  static const fg = Color(0xFF2B2824);
  static const muted = Color(0xFF8D867F);
  static const border = Color(0xFFEDE8E1);
  static const hairline = Color(0xFFF4F0EA);
  static const lavender = Color(0xFFE9E0F6);
  static const blush = Color(0xFFF5DFDD);
  static const blue = Color(0xFFDDEAF7);
  static const mint = Color(0xFFDDF2E8);
  static const peach = Color(0xFFF6E4CC);
  static const sand = Color(0xFFF4EFE4);
  static const ok = Color(0xFF3E9A6B);
  static const warn = Color(0xFF9A6A28);
  static const risk = Color(0xFFC64E3C);
}

TextStyle credentialsDisplayStyle({
  double size = 26,
  FontWeight weight = FontWeight.w700,
  Color color = CredentialsReferenceColors.fg,
  double? height,
  double letterSpacing = -0.65,
}) {
  return TextStyle(
    fontFamily: credentialsFontDisplay,
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
  );
}

TextStyle credentialsBodyStyle({
  double size = 14,
  FontWeight weight = FontWeight.w500,
  Color color = CredentialsReferenceColors.fg,
  double? height,
  double letterSpacing = -0.05,
}) {
  return TextStyle(
    fontFamily: credentialsFontBody,
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
  );
}

TextStyle credentialsMonoStyle({
  double size = 10,
  FontWeight weight = FontWeight.w500,
  Color color = CredentialsReferenceColors.muted,
  double? height,
  double letterSpacing = 1.0,
}) {
  return TextStyle(
    fontFamily: credentialsFontMono,
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
    fontFeatures: const [FontFeature.tabularFigures()],
  );
}

class CredentialsReferenceTheme extends StatelessWidget {
  const CredentialsReferenceTheme({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);
    return Theme(
      data: base.copyWith(
        scaffoldBackgroundColor: CredentialsReferenceColors.bg,
        textTheme: base.textTheme.apply(
          fontFamily: credentialsFontBody,
          bodyColor: CredentialsReferenceColors.fg,
          displayColor: CredentialsReferenceColors.fg,
        ),
        colorScheme: base.colorScheme.copyWith(
          surface: CredentialsReferenceColors.surface,
          onSurface: CredentialsReferenceColors.fg,
          primary: CredentialsReferenceColors.fg,
          secondary: CredentialsReferenceColors.muted,
          error: CredentialsReferenceColors.risk,
        ),
      ),
      child: child,
    );
  }
}

class CredentialsReferencePage extends StatelessWidget {
  const CredentialsReferencePage({
    super.key,
    required this.child,
    this.backgroundColor = CredentialsReferenceColors.bg,
  });

  final Widget child;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return CredentialsReferenceTheme(
      child: ColoredBox(color: backgroundColor, child: child),
    );
  }
}

class CredentialsHeader extends StatelessWidget {
  const CredentialsHeader({
    super.key,
    required this.title,
    this.eyebrow,
    this.leading,
    this.trailing,
    this.centerTitle = false,
    this.padding = const EdgeInsets.fromLTRB(22, 6, 22, 10),
  });

  final String title;
  final String? eyebrow;
  final Widget? leading;
  final Widget? trailing;
  final bool centerTitle;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final titleWidget = Text(
      title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: centerTitle ? TextAlign.center : TextAlign.start,
      style: credentialsDisplayStyle(size: centerTitle ? 16 : 26),
    );

    return Padding(
      padding: padding,
      child: Row(
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 12)],
          Expanded(
            child: centerTitle
                ? titleWidget
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (eyebrow != null) ...[
                        Text(
                          eyebrow!.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: credentialsMonoStyle(
                            size: 11,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: 6),
                      ],
                      titleWidget,
                    ],
                  ),
          ),
          if (trailing != null) ...[const SizedBox(width: 12), trailing!],
        ],
      ),
    );
  }
}

class CredentialsIconButton extends StatelessWidget {
  const CredentialsIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.size = 38,
    this.backgroundColor = CredentialsReferenceColors.surface,
    this.foregroundColor = CredentialsReferenceColors.fg,
    this.borderColor = CredentialsReferenceColors.border,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final String? tooltip;
  final double size;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: backgroundColor,
            border: borderColor == null
                ? null
                : Border.all(color: borderColor!),
          ),
          child: Icon(icon, size: size * 0.48, color: foregroundColor),
        ),
      ),
    );

    if (tooltip == null) {
      return button;
    }
    return Tooltip(message: tooltip!, child: button);
  }
}

class CredentialsTextButton extends StatelessWidget {
  const CredentialsTextButton({
    super.key,
    required this.label,
    required this.onTap,
    this.color = CredentialsReferenceColors.muted,
    this.weight = FontWeight.w600,
  });

  final String label;
  final VoidCallback? onTap;
  final Color color;
  final FontWeight weight;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: color,
        padding: EdgeInsets.zero,
        minimumSize: const Size(44, 38),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        textStyle: credentialsBodyStyle(size: 14, weight: weight, color: color),
      ),
      child: Text(label),
    );
  }
}

class CredentialsSearchField extends StatelessWidget {
  const CredentialsSearchField({
    super.key,
    required this.hint,
    this.controller,
    this.onChanged,
    this.trailing,
    this.enabled = true,
    this.initialText,
  });

  final String hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final Widget? trailing;
  final bool enabled;
  final String? initialText;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 46),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F4EF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.search_rounded,
            size: 19,
            color: CredentialsReferenceColors.muted,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              enabled: enabled,
              onChanged: onChanged,
              style: credentialsBodyStyle(size: 14, weight: FontWeight.w600),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: initialText ?? hint,
                hintStyle: credentialsBodyStyle(
                  size: 14,
                  color: CredentialsReferenceColors.muted,
                ),
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class CredentialsCard extends StatelessWidget {
  const CredentialsCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.color = CredentialsReferenceColors.surface,
    this.borderColor = CredentialsReferenceColors.border,
    this.radius = 22,
    this.boxShadow,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final Color? borderColor;
  final double radius;
  final List<BoxShadow>? boxShadow;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: borderColor == null ? null : Border.all(color: borderColor!),
        boxShadow: boxShadow,
      ),
      child: child,
    );
  }
}

class CredentialsBrandAvatar extends StatelessWidget {
  const CredentialsBrandAvatar({
    super.key,
    required this.serviceName,
    this.serviceUrl,
    this.logoPath,
    this.imageUrl,
    this.brandHex,
    this.size = 36,
    this.radius,
  });

  final String serviceName;
  final String? serviceUrl;
  final String? logoPath;
  final String? imageUrl;
  final int? brandHex;
  final double size;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    final bg = brandHex == null
        ? _brandFallbackColor(serviceName)
        : Color(brandHex!);
    return CompanyLogoAvatar(
      serviceName: serviceName,
      serviceUrl: serviceUrl,
      imageUrl: imageUrl,
      localImagePath: logoPath,
      size: size,
      borderRadius: BorderRadius.circular(radius ?? (size * 0.28)),
      backgroundColor: Colors.transparent,
      fallbackColor: bg,
      fallbackTextColor: _onColor(bg),
    );
  }
}

class CredentialsMetricStrip extends StatelessWidget {
  const CredentialsMetricStrip({
    super.key,
    required this.score,
    required this.strong,
    required this.reused,
    required this.weak,
  });

  final int score;
  final int strong;
  final int reused;
  final int weak;

  @override
  Widget build(BuildContext context) {
    return CredentialsCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: _MetricCell(
              value: score,
              label: 'Score',
              color: CredentialsReferenceColors.ok,
            ),
          ),
          Expanded(
            child: _MetricCell(value: strong, label: 'Strong'),
          ),
          Expanded(
            child: _MetricCell(
              value: reused,
              label: 'Reused',
              color: CredentialsReferenceColors.risk,
            ),
          ),
          Expanded(
            child: _MetricCell(
              value: weak,
              label: 'Weak',
              color: CredentialsReferenceColors.warn,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCell extends StatelessWidget {
  const _MetricCell({
    required this.value,
    required this.label,
    this.color = CredentialsReferenceColors.fg,
  });

  final int value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$value',
          style: credentialsDisplayStyle(size: 20, color: color, height: 0.95),
        ),
        const SizedBox(height: 4),
        Text(label.toUpperCase(), style: credentialsMonoStyle(size: 9.5)),
      ],
    );
  }
}

class CredentialsChipRow extends StatelessWidget {
  const CredentialsChipRow({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(children: _gap(children, const SizedBox(width: 6))),
    );
  }
}

class CredentialsChip extends StatelessWidget {
  const CredentialsChip({
    super.key,
    required this.label,
    this.active = false,
    this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
          decoration: BoxDecoration(
            color: active
                ? CredentialsReferenceColors.fg
                : const Color(0xFFF7F4EF),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            style: credentialsBodyStyle(
              size: 12,
              color: active
                  ? CredentialsReferenceColors.surface
                  : CredentialsReferenceColors.muted,
            ),
          ),
        ),
      ),
    );
  }
}

class CredentialsSectionLabel extends StatelessWidget {
  const CredentialsSectionLabel(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(label.toUpperCase(), style: credentialsMonoStyle(size: 10));
  }
}

class CredentialsListGroup extends StatelessWidget {
  const CredentialsListGroup({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return CredentialsCard(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(children: _withDividers(children)),
    );
  }
}

class CredentialsListRow extends StatelessWidget {
  const CredentialsListRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.brand,
    required this.onTap,
    this.status = CredentialSecurityStatus.secure,
    this.statusLabel,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget brand;
  final VoidCallback? onTap;
  final CredentialSecurityStatus status;
  final String? statusLabel;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final isWarning = status == CredentialSecurityStatus.warning;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              brand,
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: credentialsBodyStyle(
                        size: 15,
                        weight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: credentialsBodyStyle(
                        size: 13,
                        color: CredentialsReferenceColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              CredentialsPill(
                label: statusLabel ?? (isWarning ? 'Weak' : null),
                tone: isWarning
                    ? CredentialsPillTone.risk
                    : CredentialsPillTone.ok,
              ),
              const SizedBox(width: 8),
              if (trailing != null)
                trailing!
              else
                const Icon(
                  Icons.chevron_right_rounded,
                  color: CredentialsReferenceColors.muted,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

enum CredentialsPillTone { ok, warn, risk, ghost }

class CredentialsPill extends StatelessWidget {
  const CredentialsPill({super.key, this.label, required this.tone});

  final String? label;
  final CredentialsPillTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = switch (tone) {
      CredentialsPillTone.ok => (
        bg: const Color(0xFFE7F4EC),
        fg: CredentialsReferenceColors.ok,
        border: Colors.transparent,
      ),
      CredentialsPillTone.warn => (
        bg: const Color(0xFFF5EAD7),
        fg: CredentialsReferenceColors.warn,
        border: Colors.transparent,
      ),
      CredentialsPillTone.risk => (
        bg: const Color(0xFFF7E5E1),
        fg: CredentialsReferenceColors.risk,
        border: Colors.transparent,
      ),
      CredentialsPillTone.ghost => (
        bg: Colors.transparent,
        fg: CredentialsReferenceColors.muted,
        border: CredentialsReferenceColors.border,
      ),
    };

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: label == null ? 7 : 9,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: colors.bg,
        borderRadius: BorderRadius.circular(999),
        border: colors.border == Colors.transparent
            ? null
            : Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(shape: BoxShape.circle, color: colors.fg),
          ),
          if (label != null) ...[
            const SizedBox(width: 5),
            Text(
              label!.toUpperCase(),
              style: credentialsMonoStyle(
                size: 10,
                weight: FontWeight.w500,
                color: colors.fg,
                letterSpacing: 0.65,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class CredentialsField extends StatelessWidget {
  const CredentialsField({
    super.key,
    required this.label,
    required this.value,
    this.valueStyle,
    this.actions = const [],
    this.focused = false,
  });

  final String label;
  final String value;
  final TextStyle? valueStyle;
  final List<Widget> actions;
  final bool focused;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
      decoration: BoxDecoration(
        color: focused
            ? CredentialsReferenceColors.surface
            : const Color(0xFFF7F4EF),
        borderRadius: BorderRadius.circular(12),
        border: focused
            ? Border.all(color: CredentialsReferenceColors.fg, width: 1.5)
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: credentialsMonoStyle(size: 9.5),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style:
                      valueStyle ??
                      credentialsBodyStyle(size: 15, weight: FontWeight.w600),
                ),
              ],
            ),
          ),
          if (actions.isNotEmpty) ...[
            const SizedBox(width: 10),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: _gap(actions, const SizedBox(width: 6)),
            ),
          ],
        ],
      ),
    );
  }
}

class CredentialsInputField extends StatelessWidget {
  const CredentialsInputField({
    super.key,
    required this.label,
    required this.controller,
    this.focusNode,
    this.hint,
    this.actions = const [],
    this.keyboardType,
    this.obscureText = false,
    this.maxLines = 1,
    this.onChanged,
    this.focused = false,
  });

  final String label;
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String? hint;
  final List<Widget> actions;
  final TextInputType? keyboardType;
  final bool obscureText;
  final int maxLines;
  final ValueChanged<String>? onChanged;
  final bool focused;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        color: focused
            ? CredentialsReferenceColors.surface
            : const Color(0xFFF7F4EF),
        borderRadius: BorderRadius.circular(12),
        border: focused
            ? Border.all(color: CredentialsReferenceColors.fg, width: 1.5)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: credentialsMonoStyle(size: 9.5)),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: maxLines > 1
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  keyboardType: keyboardType,
                  obscureText: obscureText,
                  maxLines: obscureText ? 1 : maxLines,
                  minLines: maxLines > 1 ? math.min(3, maxLines) : 1,
                  onChanged: onChanged,
                  style: credentialsBodyStyle(
                    size: 15,
                    weight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    hintText: hint,
                    hintStyle: credentialsBodyStyle(
                      size: 15,
                      color: CredentialsReferenceColors.muted,
                    ),
                  ),
                ),
              ),
              if (actions.isNotEmpty) ...[
                const SizedBox(width: 10),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: _gap(actions, const SizedBox(width: 6)),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class CredentialsFieldAction extends StatelessWidget {
  const CredentialsFieldAction({
    super.key,
    required this.icon,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Ink(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: active
                ? CredentialsReferenceColors.fg
                : CredentialsReferenceColors.surface,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 15,
            color: active
                ? CredentialsReferenceColors.surface
                : CredentialsReferenceColors.fg,
          ),
        ),
      ),
    );
  }
}

enum CredentialsStrengthTone { weak, fair, good, strong }

class CredentialsStrengthMeter extends StatelessWidget {
  const CredentialsStrengthMeter({
    super.key,
    required this.score,
    required this.label,
    required this.caption,
  });

  final int score;
  final String label;
  final String caption;

  CredentialsStrengthTone get _tone {
    if (score >= 85) return CredentialsStrengthTone.strong;
    if (score >= 65) return CredentialsStrengthTone.good;
    if (score >= 40) return CredentialsStrengthTone.fair;
    return CredentialsStrengthTone.weak;
  }

  @override
  Widget build(BuildContext context) {
    final tone = _tone;
    final fill = switch (tone) {
      CredentialsStrengthTone.weak => 1,
      CredentialsStrengthTone.fair => 2,
      CredentialsStrengthTone.good => 3,
      CredentialsStrengthTone.strong => 4,
    };
    final color = switch (tone) {
      CredentialsStrengthTone.weak => CredentialsReferenceColors.risk,
      CredentialsStrengthTone.fair => CredentialsReferenceColors.warn,
      CredentialsStrengthTone.good => CredentialsReferenceColors.ok,
      CredentialsStrengthTone.strong => CredentialsReferenceColors.ok,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: List.generate(4, (index) {
            return Expanded(
              child: Container(
                height: 5,
                margin: EdgeInsets.only(right: index == 3 ? 0 : 4),
                decoration: BoxDecoration(
                  color: index < fill
                      ? color
                      : CredentialsReferenceColors.hairline,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Text(
              label,
              style: credentialsBodyStyle(
                size: 12.5,
                weight: FontWeight.w700,
                color: color,
              ),
            ),
            const Spacer(),
            Flexible(
              child: Text(
                caption.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                style: credentialsMonoStyle(size: 10),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class CredentialsGeneratorDisplay extends StatelessWidget {
  const CredentialsGeneratorDisplay({
    super.key,
    required this.password,
    required this.score,
    required this.strengthLabel,
    required this.caption,
    required this.onCopy,
    required this.onRegenerate,
  });

  final String password;
  final int score;
  final String strengthLabel;
  final String caption;
  final VoidCallback? onCopy;
  final VoidCallback? onRegenerate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      decoration: BoxDecoration(
        color: CredentialsReferenceColors.fg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            password,
            style: credentialsMonoStyle(
              size: 19,
              weight: FontWeight.w600,
              color: CredentialsReferenceColors.surface,
              letterSpacing: 0.4,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: CredentialsStrengthMeter(
                  score: score,
                  label: '$strengthLabel · $score',
                  caption: caption,
                ),
              ),
              const SizedBox(width: 14),
              _GeneratorAction(
                icon: Icons.autorenew_rounded,
                onTap: onRegenerate,
              ),
              const SizedBox(width: 8),
              _GeneratorAction(icon: Icons.copy_rounded, onTap: onCopy),
            ],
          ),
        ],
      ),
    );
  }
}

class _GeneratorAction extends StatelessWidget {
  const _GeneratorAction({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Ink(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: const Color(0xFF47413A),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 16,
            color: CredentialsReferenceColors.surface,
          ),
        ),
      ),
    );
  }
}

class CredentialsQuickAction extends StatelessWidget {
  const CredentialsQuickAction({
    super.key,
    required this.icon,
    required this.label,
    this.meta,
    this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final String? meta;
  final VoidCallback? onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger
        ? CredentialsReferenceColors.risk
        : CredentialsReferenceColors.fg;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: danger
                      ? const Color(0xFFF7E5E1)
                      : const Color(0xFFF7F4EF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 15, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: credentialsBodyStyle(
                    size: 14,
                    weight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
              if (meta != null)
                Text(
                  meta!.toUpperCase(),
                  style: credentialsMonoStyle(
                    size: 10.5,
                    color: danger
                        ? CredentialsReferenceColors.risk.withValues(
                            alpha: 0.65,
                          )
                        : CredentialsReferenceColors.muted,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class CredentialsBreachBanner extends StatelessWidget {
  const CredentialsBreachBanner({
    super.key,
    required this.count,
    this.onGenerate,
    this.onMarkRotated,
  });

  final int count;
  final VoidCallback? onGenerate;
  final VoidCallback? onMarkRotated;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF2EF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEAB7AE)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFF6D9D3),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              size: 18,
              color: CredentialsReferenceColors.risk,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Found in $count known ${count == 1 ? 'breach' : 'breaches'}',
                  style: credentialsBodyStyle(
                    size: 13.5,
                    weight: FontWeight.w700,
                    color: CredentialsReferenceColors.risk,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Rotate this password before saving. Keep the old one masked until you replace it.',
                  style: credentialsBodyStyle(
                    size: 12.5,
                    color: const Color(0xFF724338),
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _RiskButton(label: 'Generate new', onTap: onGenerate),
                    _RiskButton(
                      label: 'Mark as rotated',
                      onTap: onMarkRotated,
                      secondary: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RiskButton extends StatelessWidget {
  const _RiskButton({required this.label, this.onTap, this.secondary = false});

  final String label;
  final VoidCallback? onTap;
  final bool secondary;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          decoration: BoxDecoration(
            color: secondary
                ? CredentialsReferenceColors.surface
                : CredentialsReferenceColors.risk,
            borderRadius: BorderRadius.circular(999),
            border: secondary
                ? Border.all(color: const Color(0xFFEAB7AE))
                : null,
          ),
          child: Text(
            label,
            style: credentialsBodyStyle(
              size: 11.5,
              weight: FontWeight.w600,
              color: secondary
                  ? CredentialsReferenceColors.risk
                  : CredentialsReferenceColors.surface,
            ),
          ),
        ),
      ),
    );
  }
}

class CredentialsCopyToast extends StatelessWidget {
  const CredentialsCopyToast({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 9, 14, 9),
      decoration: BoxDecoration(
        color: CredentialsReferenceColors.fg,
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [
          BoxShadow(
            color: Color(0x44201E1B),
            blurRadius: 28,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: const BoxDecoration(
              color: CredentialsReferenceColors.ok,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              size: 15,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            message,
            style: credentialsBodyStyle(
              size: 12.5,
              weight: FontWeight.w600,
              color: CredentialsReferenceColors.surface,
            ),
          ),
        ],
      ),
    );
  }
}

class CredentialsPrimaryButton extends StatelessWidget {
  const CredentialsPrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.backgroundColor = CredentialsReferenceColors.fg,
    this.foregroundColor = CredentialsReferenceColors.surface,
  });

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: FilledButton.icon(
        onPressed: onTap,
        icon: icon == null ? const SizedBox.shrink() : Icon(icon, size: 17),
        label: Text(label),
        style: FilledButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          textStyle: credentialsBodyStyle(
            size: 15,
            weight: FontWeight.w600,
            color: foregroundColor,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          disabledBackgroundColor: const Color(0xFFD8D1C8),
          disabledForegroundColor: Colors.white.withValues(alpha: 0.74),
        ),
      ),
    );
  }
}

class CredentialsSegmented extends StatelessWidget {
  const CredentialsSegmented({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF0ECE6),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    color: i == selectedIndex
                        ? CredentialsReferenceColors.surface
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(
                    labels[i],
                    style: credentialsBodyStyle(
                      size: 13,
                      weight: i == selectedIndex
                          ? FontWeight.w700
                          : FontWeight.w600,
                      color: i == selectedIndex
                          ? CredentialsReferenceColors.fg
                          : CredentialsReferenceColors.muted,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class CredentialsToggle extends StatelessWidget {
  const CredentialsToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 38,
        height: 22,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: value
              ? CredentialsReferenceColors.fg
              : const Color(0xFFE7E2DA),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Align(
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 18,
            height: 18,
            decoration: const BoxDecoration(
              color: CredentialsReferenceColors.surface,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}

class CredentialsEmptyReferenceState extends StatelessWidget {
  const CredentialsEmptyReferenceState({
    super.key,
    this.onAddTap,
    this.onImportTap,
    this.onGeneratorTap,
    this.scrollable = true,
  });

  final VoidCallback? onAddTap;
  final VoidCallback? onImportTap;
  final VoidCallback? onGeneratorTap;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      children: [
        const _CredentialEmptyVisual(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Column(
            children: [
              Text(
                'A calm place for your passwords.',
                textAlign: TextAlign.center,
                style: credentialsDisplayStyle(size: 23),
              ),
              const SizedBox(height: 6),
              Text(
                'Add one by hand, generate something fresh, or import from another manager. Everything stays encrypted on this device.',
                textAlign: TextAlign.center,
                style: credentialsBodyStyle(
                  size: 13,
                  color: CredentialsReferenceColors.fg.withValues(alpha: 0.78),
                  height: 1.55,
                ),
              ),
              const SizedBox(height: 16),
              CredentialsPrimaryButton(
                label: 'Add first credential',
                icon: Icons.add_rounded,
                onTap: onAddTap,
              ),
              const SizedBox(height: 10),
              Wrap(
                alignment: WrapAlignment.center,
                children: [
                  _InlineLink(
                    label: 'import from a manager',
                    onTap: onImportTap,
                  ),
                  Text(
                    ' · ',
                    style: credentialsBodyStyle(
                      size: 12.5,
                      color: CredentialsReferenceColors.muted,
                    ),
                  ),
                  _InlineLink(label: 'generate one', onTap: onGeneratorTap),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.only(left: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CredentialsSectionLabel('Quick start · tap to add'),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _gap([
                    _BrandChip(label: 'Stripe', text: 'S'),
                    _BrandChip(label: 'Notion', text: 'N'),
                    _BrandChip(label: 'Crédit Agricole', text: 'CA'),
                    _BrandChip(label: 'Air France', text: 'AF'),
                    _BrandChip(label: 'GitHub', text: 'GH'),
                    _BrandChip(label: 'Other', icon: Icons.add_rounded),
                  ], const SizedBox(width: 8)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'LOCAL-FIRST · END-TO-END ENCRYPTED · NO TELEMETRY',
          textAlign: TextAlign.center,
          style: credentialsMonoStyle(size: 9.5, letterSpacing: 1.0),
        ),
      ],
    );

    if (!scrollable) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(0, 6, 0, 28),
        child: content,
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(0, 6, 0, 28),
      child: content,
    );
  }
}

class _InlineLink extends StatelessWidget {
  const _InlineLink({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        label,
        style:
            credentialsBodyStyle(
              size: 12.5,
              weight: FontWeight.w600,
              color: CredentialsReferenceColors.fg,
            ).copyWith(
              decoration: TextDecoration.underline,
              decorationColor: CredentialsReferenceColors.border,
              decorationThickness: 1.4,
            ),
      ),
    );
  }
}

class _CredentialEmptyVisual extends StatelessWidget {
  const _CredentialEmptyVisual();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 196,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            left: 16,
            right: 16,
            top: 8,
            bottom: 8,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: const LinearGradient(
                  colors: [
                    CredentialsReferenceColors.lavender,
                    CredentialsReferenceColors.blush,
                    CredentialsReferenceColors.mint,
                  ],
                ),
              ),
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -58),
            child: Transform.rotate(
              angle: -0.08,
              child: _GhostCredentialCard(opacity: 0.58),
            ),
          ),
          Transform.translate(
            offset: const Offset(0, 58),
            child: Transform.rotate(
              angle: 0.07,
              child: _GhostCredentialCard(opacity: 0.42),
            ),
          ),
          Container(
            width: 278,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: CredentialsReferenceColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: CredentialsReferenceColors.border),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x26201E1B),
                  blurRadius: 40,
                  offset: Offset(0, 22),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      'Preview · what a credential looks like'.toUpperCase(),
                      style: credentialsMonoStyle(size: 8.5),
                    ),
                    const Spacer(),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: CredentialsReferenceColors.ok,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 11),
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF5B45A0), Color(0xFF332A44)],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        children: [
                          _GhostLine(widthFactor: 0.62, height: 8),
                          const SizedBox(height: 6),
                          _GhostLine(widthFactor: 0.38, height: 6),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: CredentialsReferenceColors.bg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: CredentialsReferenceColors.border,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        '••••••••••••',
                        style: credentialsBodyStyle(
                          size: 13,
                          letterSpacing: 2.2,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE5F4EA),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'STRONG',
                          style: credentialsMonoStyle(
                            size: 8.5,
                            weight: FontWeight.w700,
                            color: CredentialsReferenceColors.ok,
                          ),
                        ),
                      ),
                    ],
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

class _GhostCredentialCard extends StatelessWidget {
  const _GhostCredentialCard({required this.opacity});

  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Container(
        width: 245,
        height: 52,
        decoration: BoxDecoration(
          color: CredentialsReferenceColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: CredentialsReferenceColors.border),
        ),
      ),
    );
  }
}

class _GhostLine extends StatelessWidget {
  const _GhostLine({required this.widthFactor, required this.height});

  final double widthFactor;
  final double height;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      alignment: Alignment.centerLeft,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: CredentialsReferenceColors.hairline,
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

class _BrandChip extends StatelessWidget {
  const _BrandChip({required this.label, this.text, this.icon});

  final String label;
  final String? text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(7, 7, 12, 7),
      decoration: BoxDecoration(
        color: CredentialsReferenceColors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: CredentialsReferenceColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: icon == null
                  ? CredentialsReferenceColors.lavender
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            alignment: Alignment.center,
            child: icon == null
                ? Text(
                    text ?? '',
                    style: credentialsMonoStyle(
                      size: 10,
                      weight: FontWeight.w700,
                      color: CredentialsReferenceColors.fg,
                      letterSpacing: 0,
                    ),
                  )
                : Icon(icon, size: 13, color: CredentialsReferenceColors.muted),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: credentialsBodyStyle(size: 12, weight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class CredentialsImportSourceRow extends StatelessWidget {
  const CredentialsImportSourceRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: CredentialsReferenceColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: CredentialsReferenceColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: CredentialsReferenceColors.surface,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: credentialsBodyStyle(
                        size: 14,
                        weight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle.toUpperCase(),
                      style: credentialsMonoStyle(size: 10, letterSpacing: 0.6),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: CredentialsReferenceColors.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CredentialsImportCredentialRow extends StatelessWidget {
  const CredentialsImportCredentialRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.tag,
    required this.tagTone,
    required this.onTap,
    this.onLongPress,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final String tag;
  final CredentialsPillTone tagTone;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final tagColor = switch (tagTone) {
      CredentialsPillTone.ok => CredentialsReferenceColors.ok,
      CredentialsPillTone.warn => CredentialsReferenceColors.warn,
      CredentialsPillTone.risk => CredentialsReferenceColors.risk,
      CredentialsPillTone.ghost => CredentialsReferenceColors.muted,
    };
    final tagBg = switch (tagTone) {
      CredentialsPillTone.ok => const Color(0xFFE7F4EC),
      CredentialsPillTone.warn => const Color(0xFFF5EAD7),
      CredentialsPillTone.risk => const Color(0xFFF7E5E1),
      CredentialsPillTone.ghost => const Color(0xFFF7F4EF),
    };

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: selected
                      ? CredentialsReferenceColors.fg
                      : CredentialsReferenceColors.surface,
                  borderRadius: BorderRadius.circular(6),
                  border: selected
                      ? null
                      : Border.all(color: CredentialsReferenceColors.border),
                ),
                child: selected
                    ? const Icon(
                        Icons.check_rounded,
                        size: 14,
                        color: Colors.white,
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              CredentialsBrandAvatar(serviceName: title, size: 32),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: credentialsBodyStyle(
                        size: 13.5,
                        weight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: credentialsMonoStyle(
                        size: 10.5,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: tagBg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  tag.toUpperCase(),
                  style: credentialsMonoStyle(
                    size: 9.5,
                    weight: FontWeight.w600,
                    color: tagColor,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

List<Widget> _gap(List<Widget> children, Widget separator) {
  return [
    for (var i = 0; i < children.length; i++) ...[
      if (i != 0) separator,
      children[i],
    ],
  ];
}

List<Widget> _withDividers(List<Widget> children) {
  return [
    for (var i = 0; i < children.length; i++) ...[
      if (i != 0)
        Container(height: 1, color: CredentialsReferenceColors.hairline),
      children[i],
    ],
  ];
}

Color _brandFallbackColor(String serviceName) {
  const palette = [
    CredentialsReferenceColors.lavender,
    CredentialsReferenceColors.blush,
    CredentialsReferenceColors.blue,
    CredentialsReferenceColors.mint,
    CredentialsReferenceColors.peach,
    CredentialsReferenceColors.sand,
    Color(0xFF302A3E),
  ];
  final hash = serviceName.codeUnits.fold<int>(0, (acc, v) => acc + (v * 31));
  return palette[hash.abs() % palette.length];
}

Color _onColor(Color color) {
  final luminance = color.computeLuminance();
  return luminance > 0.48
      ? CredentialsReferenceColors.fg
      : CredentialsReferenceColors.surface;
}
