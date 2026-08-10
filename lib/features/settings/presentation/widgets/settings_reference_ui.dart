import 'package:flutter/material.dart';
import 'package:pass_doc_manager/app/theme/app_palette.dart';

const settingsFontDisplay = 'Manrope';
const settingsFontMono = 'JetBrains Mono';

class SettingsReferenceTopBar extends StatelessWidget {
  const SettingsReferenceTopBar({
    super.key,
    required this.title,
    this.leftLabel,
    this.rightLabel,
    this.onLeftTap,
    this.onRightTap,
  });

  final String title;
  final String? leftLabel;
  final String? rightLabel;
  final VoidCallback? onLeftTap;
  final VoidCallback? onRightTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 4),
      child: SizedBox(
        height: 34,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: _TopBarAction(
                label: leftLabel,
                onTap: onLeftTap,
                alignment: Alignment.centerLeft,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontFamily: settingsFontDisplay,
                color: palette.textPrimary,
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.1,
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: _TopBarAction(
                label: rightLabel,
                onTap: onRightTap,
                alignment: Alignment.centerRight,
                strong: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsReferenceGroupHeader extends StatelessWidget {
  const SettingsReferenceGroupHeader(
    this.title, {
    super.key,
    this.danger = false,
  });

  final String title;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 6),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontFamily: settingsFontMono,
          color: danger ? palette.danger : palette.textMuted,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.45,
        ),
      ),
    );
  }
}

class SettingsReferenceCard extends StatelessWidget {
  const SettingsReferenceCard({
    super.key,
    required this.children,
    this.danger = false,
    this.margin = const EdgeInsets.symmetric(horizontal: 14),
  });

  final List<Widget> children;
  final bool danger;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border.all(
          color: danger ? palette.dangerStroke : palette.stroke,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var index = 0; index < children.length; index++) ...[
            if (index > 0) Divider(height: 1, color: palette.stroke),
            children[index],
          ],
        ],
      ),
    );
  }
}

class SettingsReferenceProfileChip extends StatelessWidget {
  const SettingsReferenceProfileChip({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.initial = 'V',
  });

  final String title;
  final String subtitle;
  final String initial;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
      child: Material(
        color: palette.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: palette.stroke),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF51465B), Color(0xFF201D29)],
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initial,
                    style: const TextStyle(
                      fontFamily: settingsFontDisplay,
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: settingsFontDisplay,
                          color: palette.textPrimary,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.17,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: settingsFontMono,
                          color: palette.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.65,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: palette.textMuted,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SettingsReferenceNavRow extends StatelessWidget {
  const SettingsReferenceNavRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.value,
    this.valueTone = SettingsValueTone.neutral,
    this.trailing,
    this.showChevron = true,
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final String? value;
  final SettingsValueTone valueTone;
  final Widget? trailing;
  final bool showChevron;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final valueColor = switch (valueTone) {
      SettingsValueTone.ok => palette.success,
      SettingsValueTone.warn => palette.warning,
      SettingsValueTone.danger => palette.danger,
      SettingsValueTone.neutral => palette.textMuted,
    };

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: danger ? palette.dangerSoft : palette.surfaceSoft,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  icon,
                  color: danger ? palette.danger : palette.textPrimary,
                  size: 15,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: settingsFontDisplay,
                        color: danger ? palette.danger : palette.textPrimary,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.05,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: settingsFontDisplay,
                        color: palette.textMuted,
                        fontSize: 11,
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              if (trailing != null)
                trailing!
              else if (value != null)
                Text(
                  value!.toUpperCase(),
                  style: TextStyle(
                    fontFamily: settingsFontMono,
                    color: valueColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.65,
                  ),
                ),
              if (showChevron) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right_rounded,
                  color: danger ? palette.danger : palette.textMuted,
                  size: 18,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class SettingsReferenceToggle extends StatelessWidget {
  const SettingsReferenceToggle({super.key, required this.isOn});

  final bool isOn;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Container(
      width: 42,
      height: 24,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: isOn ? palette.primary : palette.surfaceSoft,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: palette.stroke),
      ),
      child: Align(
        alignment: isOn ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: palette.surface,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SettingsReferenceLockCta extends StatelessWidget {
  const SettingsReferenceLockCta({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
      child: Material(
        color: palette.textPrimary,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(
                    Icons.lock_rounded,
                    color: Colors.white,
                    size: 17,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Lock vault now',
                        style: TextStyle(
                          fontFamily: settingsFontDisplay,
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 1),
                      Text(
                        'UNLOCK AGAIN WITH PIN OR FACE ID',
                        style: TextStyle(
                          fontFamily: settingsFontMono,
                          color: Color(0xB3FFFFFF),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: palette.surface,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: palette.textPrimary,
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SettingsReferencePermissionCard extends StatelessWidget {
  const SettingsReferencePermissionCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Color.alphaBlend(
                palette.success.withValues(alpha: 0.05),
                palette.surface,
              ),
              border: Border.all(
                color: palette.success.withValues(alpha: 0.25),
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: palette.success,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontFamily: settingsFontDisplay,
                          color: palette.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.05,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle.toUpperCase(),
                        style: TextStyle(
                          fontFamily: settingsFontMono,
                          color: palette.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SettingsReferenceChips extends StatelessWidget {
  const SettingsReferenceChips({
    super.key,
    required this.labels,
    this.selected = const <String>{},
    this.onTap,
  });

  final List<String> labels;
  final Set<String> selected;
  final ValueChanged<String>? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: labels
            .map((label) {
              final isOn = selected.contains(label);
              final chip = Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isOn ? palette.textPrimary : palette.surface,
                  border: Border.all(
                    color: isOn ? palette.textPrimary : palette.stroke,
                  ),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    fontFamily: settingsFontMono,
                    color: isOn ? Colors.white : palette.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
              );
              if (onTap == null) return chip;
              return Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(999),
                child: InkWell(
                  onTap: () => onTap!(label),
                  borderRadius: BorderRadius.circular(999),
                  child: chip,
                ),
              );
            })
            .toList(growable: false),
      ),
    );
  }
}

class SettingsReferenceFooterText extends StatelessWidget {
  const SettingsReferenceFooterText(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 8, 22, 0),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: settingsFontMono,
          color: palette.textMuted,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

enum SettingsValueTone { neutral, ok, warn, danger }

class _TopBarAction extends StatelessWidget {
  const _TopBarAction({
    required this.label,
    required this.onTap,
    required this.alignment,
    this.strong = false,
  });

  final String? label;
  final VoidCallback? onTap;
  final Alignment alignment;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return SizedBox(
      width: 76,
      child: Align(
        alignment: alignment,
        child: label == null
            ? const SizedBox.shrink()
            : TextButton(
                onPressed: onTap,
                style: TextButton.styleFrom(
                  foregroundColor: strong
                      ? palette.textPrimary
                      : palette.textMuted,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: EdgeInsets.zero,
                  textStyle: TextStyle(
                    fontFamily: settingsFontDisplay,
                    fontSize: 14,
                    fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
                child: Text(label!),
              ),
      ),
    );
  }
}
