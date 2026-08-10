import 'dart:io';

import 'package:flutter/material.dart';
import 'package:pass_doc_manager/app/theme/app_palette.dart';
import 'package:pass_doc_manager/core/extensions/local_file_type_extensions.dart';

enum WorkTint { lavender, blush, blue, mint, peach, sand, neutral }

const String workFontDisplay = 'Manrope';
const String workFontBody = 'Manrope';
const String workFontMono = 'JetBrains Mono';

class WorkDesignTopBar extends StatelessWidget {
  const WorkDesignTopBar({
    super.key,
    required this.onBackTap,
    this.onSearchTap,
    this.onAddTap,
    this.onMoreTap,
    this.onFilterTap,
    this.showBack = true,
  });

  final VoidCallback? onBackTap;
  final VoidCallback? onSearchTap;
  final VoidCallback? onAddTap;
  final VoidCallback? onMoreTap;
  final VoidCallback? onFilterTap;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (showBack)
          WorkCircleButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: onBackTap,
          )
        else
          const SizedBox(width: 44, height: 44),
        const Spacer(),
        if (onSearchTap != null) ...[
          WorkCircleButton(icon: Icons.search_rounded, onTap: onSearchTap),
          const SizedBox(width: 8),
        ],
        if (onFilterTap != null) ...[
          WorkCircleButton(icon: Icons.tune_rounded, onTap: onFilterTap),
          const SizedBox(width: 8),
        ],
        if (onMoreTap != null) ...[
          WorkCircleButton(icon: Icons.more_horiz_rounded, onTap: onMoreTap),
          const SizedBox(width: 8),
        ],
        if (onAddTap != null)
          WorkCircleButton(icon: Icons.add_rounded, onTap: onAddTap),
      ],
    );
  }
}

class WorkCircleButton extends StatelessWidget {
  const WorkCircleButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.size = 44,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: palette.surfaceSoft,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: palette.stroke),
          ),
          child: Icon(icon, color: palette.textPrimary, size: size * 0.46),
        ),
      ),
    );
  }
}

class WorkIntroHeader extends StatelessWidget {
  const WorkIntroHeader({
    super.key,
    required this.kicker,
    required this.title,
    required this.subtitle,
    this.icon,
    this.iconPath,
    this.iconTint = WorkTint.lavender,
  });

  final String kicker;
  final String title;
  final String subtitle;
  final String? icon;
  final String? iconPath;
  final WorkTint iconTint;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if ((icon ?? iconPath ?? '').trim().isNotEmpty) ...[
          WorkCompanyLogo(
            name: icon ?? title,
            logoPath: iconPath,
            size: 52,
            tint: iconTint,
          ),
          const SizedBox(height: 14),
        ],
        Text(
          kicker.toUpperCase(),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: workFontMono,
            fontSize: 11,
            height: 1.2,
            fontWeight: FontWeight.w800,
            letterSpacing: 2.1,
            color: palette.textMuted,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: workFontDisplay,
            fontSize: 30,
            height: 0.96,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.9,
            color: palette.textPrimary,
          ),
        ),
        if (subtitle.trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontFamily: workFontBody,
              fontSize: 13.5,
              height: 1.38,
              fontWeight: FontWeight.w500,
              color: palette.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}

class WorkSectionLabel extends StatelessWidget {
  const WorkSectionLabel({super.key, required this.value, this.trailing});

  final String value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            value.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: workFontMono,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.7,
              color: context.appPalette.textMuted,
            ),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class WorkSheetHeader extends StatelessWidget {
  const WorkSheetHeader({
    super.key,
    required this.title,
    required this.onCancel,
    required this.onSave,
    this.saveLabel = 'Save',
    this.saveEnabled = true,
    this.isSaving = false,
  });

  final String title;
  final VoidCallback onCancel;
  final VoidCallback? onSave;
  final String saveLabel;
  final bool saveEnabled;
  final bool isSaving;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final effectiveSaveEnabled = saveEnabled && onSave != null && !isSaving;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 10),
      child: Row(
        children: [
          SizedBox(
            width: 82,
            child: TextButton(
              onPressed: isSaving ? null : onCancel,
              style: TextButton.styleFrom(
                foregroundColor: palette.textSecondary,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                alignment: Alignment.centerLeft,
              ),
              child: const Text(
                'Cancel',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: workFontBody,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: workFontDisplay,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
                color: palette.textPrimary,
              ),
            ),
          ),
          SizedBox(
            width: 82,
            child: Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: effectiveSaveEnabled ? onSave : null,
                style: TextButton.styleFrom(
                  foregroundColor: palette.textPrimary,
                  disabledForegroundColor: palette.textMuted,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: isSaving
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: palette.textPrimary,
                        ),
                      )
                    : Text(
                        saveLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: workFontBody,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
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

class WorkEditorSectionLabel extends StatelessWidget {
  const WorkEditorSectionLabel({super.key, required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 8),
      child: Text(
        value.toUpperCase(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontFamily: workFontMono,
          fontSize: 10,
          height: 1.1,
          fontWeight: FontWeight.w700,
          letterSpacing: 2.7,
          color: context.appPalette.textMuted,
        ),
      ),
    );
  }
}

class WorkFieldGroup extends StatelessWidget {
  const WorkFieldGroup({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.stroke),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1)
              Divider(height: 1, color: palette.stroke.withValues(alpha: 0.72)),
          ],
        ],
      ),
    );
  }
}

class WorkPickerField extends StatelessWidget {
  const WorkPickerField({
    super.key,
    required this.label,
    required this.value,
    this.onTap,
    this.leading,
    this.monospaceValue = false,
    this.trailing,
  });

  final String label;
  final String value;
  final VoidCallback? onTap;
  final Widget? leading;
  final bool monospaceValue;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final content = Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Row(
        children: [
          SizedBox(
            width: 104,
            child: Text(
              label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: workFontMono,
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.35,
                color: palette.textMuted,
              ),
            ),
          ),
          if (leading != null) ...[leading!, const SizedBox(width: 8)],
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontFamily: monospaceValue ? workFontMono : workFontBody,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                letterSpacing: monospaceValue ? 0.15 : -0.05,
                color: value.trim().isEmpty
                    ? palette.textMuted
                    : palette.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          trailing ??
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: palette.textMuted,
              ),
        ],
      ),
    );
    if (onTap == null) {
      return content;
    }
    return Material(
      color: Colors.transparent,
      child: InkWell(onTap: onTap, child: content),
    );
  }
}

class WorkSourceSegmented extends StatelessWidget {
  const WorkSourceSegmented({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: palette.surfaceSoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: InkWell(
                onTap: () => onSelected(i),
                borderRadius: BorderRadius.circular(11),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: i == selectedIndex
                        ? palette.surface
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(11),
                    boxShadow: i == selectedIndex
                        ? [
                            BoxShadow(
                              color: palette.shadow.withValues(alpha: 0.18),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : const [],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    labels[i],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: workFontBody,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: i == selectedIndex
                          ? palette.textPrimary
                          : palette.textSecondary,
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

class WorkHelpText extends StatelessWidget {
  const WorkHelpText({super.key, required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      style: TextStyle(
        fontFamily: workFontBody,
        fontSize: 12.5,
        height: 1.45,
        fontWeight: FontWeight.w500,
        color: context.appPalette.textSecondary,
      ),
    );
  }
}

class WorkCompanyLogo extends StatelessWidget {
  const WorkCompanyLogo({
    super.key,
    required this.name,
    this.logoPath,
    this.size = 44,
    this.tint = WorkTint.lavender,
  });

  final String name;
  final String? logoPath;
  final double size;
  final WorkTint tint;

  @override
  Widget build(BuildContext context) {
    final normalizedPath = (logoPath ?? '').trim();
    final logoFile = normalizedPath.isEmpty ? null : File(normalizedPath);
    final hasLogo = logoFile?.existsSync() == true;
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: workTintBackground(context, tint),
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      alignment: Alignment.center,
      child: hasLogo
          ? Image.file(
              logoFile!,
              width: size,
              height: size,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.medium,
              cacheWidth: (size * 3).round(),
              cacheHeight: (size * 3).round(),
            )
          : Text(
              workInitials(name),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: workFontDisplay,
                fontSize: size * 0.31,
                height: 1,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
                color: workTintForeground(context, tint),
              ),
            ),
    );
  }
}

class WorkCompanyCard extends StatelessWidget {
  const WorkCompanyCard({
    super.key,
    required this.name,
    required this.role,
    required this.stats,
    required this.onTap,
    this.logoPath,
    this.tint = WorkTint.lavender,
  });

  final String name;
  final String role;
  final List<String> stats;
  final VoidCallback onTap;
  final String? logoPath;
  final WorkTint tint;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: palette.stroke),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              WorkCompanyLogo(name: name, logoPath: logoPath, tint: tint),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: workFontDisplay,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.1,
                        color: palette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      role,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: workFontBody,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: palette.textSecondary,
                      ),
                    ),
                    if (stats.isNotEmpty) ...[
                      const SizedBox(height: 9),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          for (var i = 0; i < stats.length; i++) ...[
                            Text(
                              stats[i].toUpperCase(),
                              style: TextStyle(
                                fontFamily: workFontMono,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                                color: palette.textMuted,
                              ),
                            ),
                            if (i != stats.length - 1)
                              Container(
                                width: 3,
                                height: 3,
                                decoration: BoxDecoration(
                                  color: palette.textMuted,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: palette.textMuted,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class WorkFolderTile extends StatelessWidget {
  const WorkFolderTile({
    super.key,
    required this.title,
    required this.count,
    required this.icon,
    required this.onTap,
    this.tint = WorkTint.lavender,
  });

  final String title;
  final String count;
  final IconData icon;
  final VoidCallback onTap;
  final WorkTint tint;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          // minHeight: 104,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: workTintBackground(context, tint),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? palette.stroke
                  : Colors.transparent,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: palette.surface.withValues(alpha: 0.64),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Icon(
                  icon,
                  color: workTintForeground(context, tint),
                  size: 18,
                ),
              ),
              const Spacer(),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: workFontBody,
                  fontSize: 13.2,
                  height: 1.18,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.1,
                  color: palette.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                count.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: workFontMono,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.9,
                  color: palette.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class WorkFileThumb extends StatelessWidget {
  const WorkFileThumb({
    super.key,
    this.path = '',
    this.mime = '',
    this.size = const Size(46, 56),
    this.tint = WorkTint.blush,
    this.extensionColor,
  });

  final String path;
  final String mime;
  final Size size;
  final WorkTint tint;
  final Color? extensionColor;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final ext = _extensionLabel(path, mime);
    return Container(
      width: size.width,
      height: size.height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: palette.surfaceSoft,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: palette.stroke),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 7,
            right: 7,
            top: 10,
            child: Column(
              children: List.generate(
                4,
                (index) => Container(
                  height: 3,
                  margin: const EdgeInsets.only(bottom: 5),
                  decoration: BoxDecoration(
                    color: palette.strokeStrong.withValues(alpha: 0.88),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 18,
              color: extensionColor ?? workTintForeground(context, tint),
              alignment: Alignment.center,
              child: Text(
                ext,
                style: const TextStyle(
                  fontFamily: workFontMono,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _extensionLabel(String path, String mime) {
    final normalized = path.trim();
    if (normalized.isNotEmpty) {
      final dotIndex = normalized.lastIndexOf('.');
      if (dotIndex != -1 && dotIndex < normalized.length - 1) {
        final ext = normalized.substring(dotIndex + 1).toUpperCase();
        if (ext.length <= 4) return ext;
      }
    }
    final type = resolveFileTypeLabel(path: path, mime: mime).trim();
    if (type.isEmpty) return 'FILE';
    final firstWord = type.split(RegExp(r'\s+')).first.toUpperCase();
    return firstWord.substring(0, firstWord.length.clamp(1, 4).toInt());
  }
}

class WorkFileCard extends StatelessWidget {
  const WorkFileCard({
    super.key,
    required this.title,
    required this.meta,
    required this.onTap,
    this.path = '',
    this.mime = '',
    this.trailing,
  });

  final String title;
  final String meta;
  final String path;
  final String mime;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: palette.stroke),
          ),
          child: Row(
            children: [
              WorkFileThumb(path: path, mime: mime),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: workFontBody,
                        fontSize: 14.5,
                        height: 1.18,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.1,
                        color: palette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      meta.toUpperCase(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: workFontMono,
                        fontSize: 10.8,
                        height: 1.25,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.7,
                        color: palette.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              trailing ??
                  Icon(
                    Icons.chevron_right_rounded,
                    color: palette.textMuted,
                    size: 24,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class WorkFolderDocumentCard extends StatelessWidget {
  const WorkFolderDocumentCard({
    super.key,
    required this.title,
    required this.metaParts,
    required this.onTap,
    this.path = '',
    this.mime = '',
    this.onLongPress,
  });

  final String title;
  final List<String> metaParts;
  final String path;
  final String mime;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final filteredMeta = metaParts
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList(growable: false);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: palette.stroke),
          ),
          child: Row(
            children: [
              WorkFileThumb(
                path: path,
                mime: mime,
                size: const Size(46, 56),
                extensionColor: _workFileExtensionColor(context, path, mime),
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
                        fontFamily: workFontBody,
                        fontSize: 14,
                        height: 1.18,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.1,
                        color: palette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      filteredMeta.join(' · ').toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: workFontMono,
                        fontSize: 10.5,
                        height: 1.2,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.55,
                        color: palette.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: palette.surfaceSoft,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: palette.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class WorkRecentTile extends StatelessWidget {
  const WorkRecentTile({
    super.key,
    required this.title,
    required this.meta,
    required this.onTap,
    this.path = '',
    this.mime = '',
  });

  final String title;
  final String meta;
  final String path;
  final String mime;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          width: 132,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: palette.stroke),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              WorkFileThumb(path: path, mime: mime),
              const SizedBox(height: 10),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: workFontBody,
                  fontSize: 12.8,
                  height: 1.18,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.1,
                  color: palette.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                meta.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: workFontMono,
                  fontSize: 11.2,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: palette.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class WorkBatchUploadRow extends StatelessWidget {
  const WorkBatchUploadRow({
    super.key,
    required this.fileName,
    required this.fileMeta,
    required this.controller,
    required this.hintText,
    this.path = '',
    this.mime = '',
    this.onRemove,
  });

  final String fileName;
  final String fileMeta;
  final TextEditingController controller;
  final String hintText;
  final String path;
  final String mime;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final normalizedMeta = fileMeta.trim();
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: palette.stroke),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          WorkFileThumb(path: path, mime: mime, size: const Size(46, 56)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: workFontBody,
                    fontSize: 13.2,
                    height: 1.15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.05,
                    color: palette.textPrimary,
                  ),
                ),
                if (normalizedMeta.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    normalizedMeta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: workFontMono,
                      fontSize: 10.3,
                      height: 1.18,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.45,
                      color: palette.textMuted,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                TextField(
                  controller: controller,
                  minLines: 1,
                  maxLines: 2,
                  style: TextStyle(
                    fontFamily: workFontBody,
                    fontSize: 14,
                    height: 1.2,
                    fontWeight: FontWeight.w700,
                    color: palette.textPrimary,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: hintText,
                    hintStyle: TextStyle(
                      fontFamily: workFontBody,
                      fontWeight: FontWeight.w600,
                      color: palette.textMuted,
                    ),
                    filled: true,
                    fillColor: palette.surfaceSoft,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(11),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (onRemove != null) ...[
            const SizedBox(width: 8),
            IconButton(
              onPressed: onRemove,
              visualDensity: VisualDensity.compact,
              icon: Icon(
                Icons.close_rounded,
                size: 18,
                color: palette.textMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class WorkDashedAdd extends StatelessWidget {
  const WorkDashedAdd({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: palette.strokeStrong,
              style: BorderStyle.solid,
              width: 1.2,
            ),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_rounded, color: palette.textMuted, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontFamily: workFontBody,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: palette.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Color _workFileExtensionColor(BuildContext context, String path, String mime) {
  final label = _workExtensionLabel(path, mime);
  final dark = Theme.of(context).brightness == Brightness.dark;
  return switch (label) {
    'PDF' => dark ? const Color(0xFFC9838A) : const Color(0xFF7C3B43),
    'IMG' ||
    'PNG' ||
    'JPG' ||
    'JPEG' ||
    'HEIC' ||
    'WEBP' => dark ? const Color(0xFF70CDB5) : const Color(0xFF2E665B),
    'DOC' || 'DOCX' => dark ? const Color(0xFF7EA8EF) : const Color(0xFF365A91),
    _ => dark ? context.appPalette.textSecondary : context.appPalette.primary,
  };
}

String _workExtensionLabel(String path, String mime) {
  final normalized = path.trim();
  if (normalized.isNotEmpty) {
    final dotIndex = normalized.lastIndexOf('.');
    if (dotIndex != -1 && dotIndex < normalized.length - 1) {
      final ext = normalized.substring(dotIndex + 1).toUpperCase();
      if (ext.length <= 4) return ext;
    }
  }
  final type = resolveFileTypeLabel(path: path, mime: mime).trim();
  if (type.isEmpty) return 'FILE';
  final firstWord = type.split(RegExp(r'\s+')).first.toUpperCase();
  return firstWord.substring(0, firstWord.length.clamp(1, 4).toInt());
}

Color workTintBackground(BuildContext context, WorkTint tint) {
  final dark = Theme.of(context).brightness == Brightness.dark;
  if (dark) {
    return switch (tint) {
      WorkTint.lavender => const Color(0xFF221A34),
      WorkTint.blush => const Color(0xFF321C25),
      WorkTint.blue => const Color(0xFF17253C),
      WorkTint.mint => const Color(0xFF132F29),
      WorkTint.peach => const Color(0xFF342619),
      WorkTint.sand => const Color(0xFF312B1B),
      WorkTint.neutral => context.appPalette.surfaceSoft,
    };
  }
  return switch (tint) {
    WorkTint.lavender => const Color(0xFFEDE7FF),
    WorkTint.blush => const Color(0xFFFFE8EF),
    WorkTint.blue => const Color(0xFFE5EEFF),
    WorkTint.mint => const Color(0xFFE2F7F0),
    WorkTint.peach => const Color(0xFFFFEBCF),
    WorkTint.sand => const Color(0xFFF7EFCB),
    WorkTint.neutral => context.appPalette.surfaceSoft,
  };
}

Color workTintForeground(BuildContext context, WorkTint tint) {
  final dark = Theme.of(context).brightness == Brightness.dark;
  if (dark) {
    return switch (tint) {
      WorkTint.lavender => const Color(0xFFB49AFF),
      WorkTint.blush => const Color(0xFFFF9AB4),
      WorkTint.blue => const Color(0xFF8DB5FF),
      WorkTint.mint => const Color(0xFF69D7BB),
      WorkTint.peach => const Color(0xFFFFB463),
      WorkTint.sand => const Color(0xFFE5C95D),
      WorkTint.neutral => context.appPalette.textSecondary,
    };
  }
  return switch (tint) {
    WorkTint.lavender => const Color(0xFF4F3B7A),
    WorkTint.blush => const Color(0xFF8E314C),
    WorkTint.blue => const Color(0xFF245AAE),
    WorkTint.mint => const Color(0xFF1B7A67),
    WorkTint.peach => const Color(0xFF9A5A14),
    WorkTint.sand => const Color(0xFF756215),
    WorkTint.neutral => context.appPalette.textSecondary,
  };
}

String workInitials(String value) {
  final parts = value
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList(growable: false);
  if (parts.isEmpty) return 'W';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}
