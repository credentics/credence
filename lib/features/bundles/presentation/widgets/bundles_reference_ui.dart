import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:pass_doc_manager/app/theme/app_palette.dart';
import 'package:pass_doc_manager/domain/bundles/entities/bundle_status.dart';

const String bundleFontDisplay = 'Manrope';
const String bundleFontBody = 'Manrope';
const String bundleFontMono = 'JetBrains Mono';

class BundleReferenceColors {
  const BundleReferenceColors._();

  static const Color ink = Color(0xFF2B2824);
  static const Color muted = Color(0xFF8C857C);
  static const Color warmBackground = Color(0xFFFEFCF8);
  static const Color visaStart = Color(0xFF4C74D9);
  static const Color visaEnd = Color(0xFF5D48B4);
  static const Color rentalStart = Color(0xFFC98261);
  static const Color rentalEnd = Color(0xFFB95246);
  static const Color onboardStart = Color(0xFF4FAF92);
  static const Color onboardEnd = Color(0xFF228B78);
  static const Color travelStart = Color(0xFFC99538);
  static const Color travelEnd = Color(0xFFB06B22);
}

class BundleReferencePage extends StatelessWidget {
  const BundleReferencePage({
    super.key,
    required this.child,
    this.bottomNavigationBar,
    this.safeTop = true,
    this.maxWidth = 720,
    this.backgroundColor,
  });

  final Widget child;
  final Widget? bottomNavigationBar;
  final bool safeTop;
  final double maxWidth;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor:
          backgroundColor ??
          (isDark ? palette.background : BundleReferenceColors.warmBackground),
      bottomNavigationBar: bottomNavigationBar,
      body: SafeArea(
        top: safeTop,
        bottom: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: child,
          ),
        ),
      ),
    );
  }
}

class BundleRefHeader extends StatelessWidget {
  const BundleRefHeader({
    super.key,
    required this.title,
    this.meta,
    this.leading,
    this.trailing,
    this.centerTitle = true,
    this.padding = const EdgeInsets.fromLTRB(22, 12, 22, 10),
  });

  final String title;
  final String? meta;
  final Widget? leading;
  final Widget? trailing;
  final bool centerTitle;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final titleColumn = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: centerTitle
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: centerTitle ? TextAlign.center : TextAlign.start,
          style: TextStyle(
            fontFamily: bundleFontDisplay,
            color: palette.textPrimary,
            fontSize: 16,
            height: 1.05,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.18,
          ),
        ),
        if (meta != null && meta!.trim().isNotEmpty) ...[
          const SizedBox(height: 3),
          Text(
            meta!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: centerTitle ? TextAlign.center : TextAlign.start,
            style: TextStyle(
              fontFamily: bundleFontMono,
              color: palette.textMuted,
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.75,
            ),
          ),
        ],
      ],
    );

    return Padding(
      padding: padding,
      child: Row(
        children: [
          SizedBox(width: 54, child: leading ?? const SizedBox.shrink()),
          const SizedBox(width: 10),
          Expanded(
            child: centerTitle ? Center(child: titleColumn) : titleColumn,
          ),
          const SizedBox(width: 10),
          SizedBox(width: 54, child: trailing ?? const SizedBox.shrink()),
        ],
      ),
    );
  }
}

class BundleRefIconButton extends StatelessWidget {
  const BundleRefIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.size = 46,
    this.backgroundColor,
    this.foregroundColor,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final String? tooltip;
  final double size;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final button = Material(
      color: backgroundColor ?? palette.surfaceSoft.withValues(alpha: 0.82),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(size * 0.28),
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(
            icon,
            size: size * 0.44,
            color: foregroundColor ?? palette.textPrimary,
          ),
        ),
      ),
    );
    if (tooltip == null || tooltip!.trim().isEmpty) return button;
    return Tooltip(message: tooltip!, child: button);
  }
}

class BundleRefSearchField extends StatelessWidget {
  const BundleRefSearchField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.onChanged,
    this.padding = const EdgeInsets.symmetric(horizontal: 22),
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Padding(
      padding: padding,
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: palette.stroke),
        ),
        child: Row(
          children: [
            Icon(Icons.search_rounded, size: 17, color: palette.textMuted),
            const SizedBox(width: 9),
            Expanded(
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                style: TextStyle(
                  fontFamily: bundleFontBody,
                  color: palette.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  hintText: hintText,
                  hintStyle: TextStyle(
                    fontFamily: bundleFontBody,
                    color: palette.textMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            if (controller.text.isNotEmpty)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  controller.clear();
                  onChanged('');
                },
                child: Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: palette.textMuted,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class BundleSectionLabel extends StatelessWidget {
  const BundleSectionLabel({
    super.key,
    required this.label,
    this.trailing,
    this.padding = const EdgeInsets.symmetric(horizontal: 22),
  });

  final String label;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(
            child: Text(
              label.toUpperCase(),
              style: TextStyle(
                fontFamily: bundleFontMono,
                color: palette.textMuted,
                fontSize: 10,
                height: 1.1,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.4,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class BundleCardShell extends StatelessWidget {
  const BundleCardShell({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(14),
    this.radius = 16,
    this.backgroundColor,
    this.borderColor,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? backgroundColor;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Material(
      color: backgroundColor ?? palette.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
        side: BorderSide(color: borderColor ?? palette.stroke),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

class BundleMonoBadge extends StatelessWidget {
  const BundleMonoBadge({
    super.key,
    required this.text,
    this.templateKey,
    this.size = 44,
  });

  final String text;
  final String? templateKey;
  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final colors = bundleTemplateGradient(templateKey, palette);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        borderRadius: BorderRadius.circular(size * 0.28),
        border: templateKey == null
            ? Border.all(color: palette.stroke, width: 1.4)
            : null,
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.fade,
        softWrap: false,
        style: TextStyle(
          fontFamily: bundleFontDisplay,
          color: templateKey == null ? palette.textMuted : Colors.white,
          fontSize: math.max(11, size * 0.31),
          fontWeight: FontWeight.w800,
          letterSpacing: -0.2,
        ),
      ),
    );
  }
}

class BundleStatusPill extends StatelessWidget {
  const BundleStatusPill({super.key, required this.status, this.label});

  final BundleStatus status;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final color = bundleStatusColor(status, palette);
    final background = status == BundleStatus.draft
        ? palette.surfaceSoft
        : color.withValues(alpha: 0.11);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Text(
        (label ?? status.name).toUpperCase(),
        style: TextStyle(
          fontFamily: bundleFontMono,
          color: color,
          fontSize: 9.2,
          height: 1,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.55,
        ),
      ),
    );
  }
}

class BundleMiniStrip extends StatelessWidget {
  const BundleMiniStrip({super.key, required this.metrics, this.padding});

  final List<BundleMiniMetric> metrics;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Container(
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: palette.surfaceSoft.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          for (var i = 0; i < metrics.length; i++) ...[
            Expanded(child: _BundleMiniMetricView(metric: metrics[i])),
            if (i < metrics.length - 1) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class BundleMiniMetric {
  const BundleMiniMetric({
    required this.value,
    required this.label,
    this.color,
  });

  final String value;
  final String label;
  final Color? color;
}

class _BundleMiniMetricView extends StatelessWidget {
  const _BundleMiniMetricView({required this.metric});

  final BundleMiniMetric metric;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          metric.value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: bundleFontMono,
            color: metric.color ?? palette.textPrimary,
            fontSize: 14,
            height: 1,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          metric.label.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: bundleFontMono,
            color: palette.textMuted,
            fontSize: 8.7,
            height: 1,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.65,
          ),
        ),
      ],
    );
  }
}

class BundlePrimaryButton extends StatelessWidget {
  const BundlePrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.height = 44,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double height;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final fg = foregroundColor ?? palette.surface;
    return SizedBox(
      width: double.infinity,
      height: height,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: icon == null ? const SizedBox.shrink() : Icon(icon, size: 17),
        label: Text(label),
        style: FilledButton.styleFrom(
          backgroundColor: backgroundColor ?? palette.textPrimary,
          foregroundColor: fg,
          disabledBackgroundColor: palette.stroke,
          disabledForegroundColor: palette.textMuted,
          textStyle: const TextStyle(
            fontFamily: bundleFontBody,
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

class BundleDashedButton extends StatelessWidget {
  const BundleDashedButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon = Icons.add_rounded,
  });

  final String label;
  final VoidCallback? onTap;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Material(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: palette.strokeStrong.withValues(alpha: 0.75),
          width: 1.3,
          strokeAlign: BorderSide.strokeAlignInside,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 44,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: palette.textMuted),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontFamily: bundleFontBody,
                  color: palette.textMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BundleProgressBar extends StatelessWidget {
  const BundleProgressBar({
    super.key,
    required this.progress,
    this.color,
    this.height = 5,
  });

  final double progress;
  final Color? color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: height,
        color: palette.textMuted.withValues(alpha: 0.18),
        child: Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: progress.clamp(0, 1),
            child: Container(color: color ?? palette.textPrimary),
          ),
        ),
      ),
    );
  }
}

Color bundleStatusColor(BundleStatus status, AppPalette palette) {
  switch (status) {
    case BundleStatus.draft:
      return palette.textMuted;
    case BundleStatus.ready:
      return palette.success;
    case BundleStatus.exported:
      return palette.primary;
    case BundleStatus.archived:
      return palette.textSecondary;
  }
}

List<Color> bundleTemplateGradient(String? templateKey, AppPalette palette) {
  switch (templateKey) {
    case 'france_visa':
      return const [
        BundleReferenceColors.visaStart,
        BundleReferenceColors.visaEnd,
      ];
    case 'apartment_rental':
      return const [
        BundleReferenceColors.rentalStart,
        BundleReferenceColors.rentalEnd,
      ];
    case 'job_onboarding':
      return const [
        BundleReferenceColors.onboardStart,
        BundleReferenceColors.onboardEnd,
      ];
    case 'travel_claim':
      return const [
        BundleReferenceColors.travelStart,
        BundleReferenceColors.travelEnd,
      ];
    default:
      return [palette.surface, palette.surfaceSoft];
  }
}

String bundleTemplateInitials(String? key, String title) {
  switch (key) {
    case 'france_visa':
      return 'FR';
    case 'apartment_rental':
      return 'RL';
    case 'job_onboarding':
      return 'NJ';
    case 'travel_claim':
      return 'TC';
  }
  final words = title
      .trim()
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .toList(growable: false);
  if (words.isEmpty) return '+';
  if (words.length == 1) {
    return words.first.characters.take(2).toString().toUpperCase();
  }
  return '${words.first.characters.first}${words[1].characters.first}'
      .toUpperCase();
}
