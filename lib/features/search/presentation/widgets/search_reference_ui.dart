import 'package:flutter/material.dart';
import 'package:pass_doc_manager/app/theme/app_palette.dart';

const searchFontDisplay = 'Manrope';
const searchFontBody = 'Manrope';
const searchFontMono = 'JetBrains Mono';

class SearchRefHeader extends StatelessWidget {
  const SearchRefHeader({
    super.key,
    required this.title,
    this.onCancel,
    this.trailing,
    this.showCancel = true,
  });

  final String title;
  final VoidCallback? onCancel;
  final Widget? trailing;
  final bool showCancel;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return SizedBox(
      height: 36,
      child: Row(
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: showCancel
                  ? TextButton(
                      onPressed: onCancel,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(52, 36),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        foregroundColor: palette.textSecondary,
                        textStyle: const TextStyle(
                          fontFamily: searchFontBody,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.1,
                        ),
                      ),
                      child: const Text('Cancel'),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: searchFontDisplay,
              color: palette.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.08,
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: trailing ?? const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }
}

class SearchRefInput extends StatelessWidget {
  const SearchRefInput({
    super.key,
    required this.controller,
    required this.hintText,
    required this.onChanged,
    required this.onClear,
    this.focusNode,
    this.showCommandHint = true,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final String hintText;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final bool showCommandHint;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return AnimatedBuilder(
      animation: Listenable.merge([
        controller,
        if (focusNode != null) focusNode!,
      ]),
      builder: (context, _) {
        final focused = focusNode?.hasFocus ?? false;
        final localHasText = controller.text.trim().isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: focused ? palette.textPrimary : palette.stroke,
              width: focused ? 1.2 : 1,
            ),
            boxShadow: focused
                ? [
                    BoxShadow(
                      color: palette.textPrimary.withValues(alpha: 0.08),
                      blurRadius: 0,
                      spreadRadius: 3,
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Icon(Icons.search_rounded, size: 18, color: palette.textMuted),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  onChanged: onChanged,
                  cursorColor: palette.textPrimary,
                  style: TextStyle(
                    fontFamily: searchFontBody,
                    color: palette.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.08,
                  ),
                  decoration: InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                    hintText: hintText,
                    hintStyle: TextStyle(
                      fontFamily: searchFontBody,
                      color: palette.textMuted,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              if (localHasText)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onClear,
                  child: Container(
                    width: 19,
                    height: 19,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: palette.textMuted,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      size: 13,
                      color: palette.surface,
                    ),
                  ),
                )
              else if (showCommandHint)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: palette.textPrimary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Text(
                    'CMD K',
                    style: TextStyle(
                      fontFamily: searchFontMono,
                      color: palette.textMuted,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class SearchScopeOption {
  const SearchScopeOption({
    required this.key,
    required this.label,
    required this.count,
  });

  final String key;
  final String label;
  final int count;
}

class SearchRefScopeChips extends StatelessWidget {
  const SearchRefScopeChips({
    super.key,
    required this.options,
    required this.activeKey,
    required this.onChanged,
  });

  final List<SearchScopeOption> options;
  final String activeKey;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          for (var i = 0; i < options.length; i++) ...[
            _SearchScopeChip(
              option: options[i],
              active: options[i].key == activeKey,
              onTap: () => onChanged(options[i].key),
            ),
            if (i < options.length - 1) const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }
}

class _SearchScopeChip extends StatelessWidget {
  const _SearchScopeChip({
    required this.option,
    required this.active,
    required this.onTap,
  });

  final SearchScopeOption option;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Material(
      color: active ? palette.textPrimary : palette.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
        side: BorderSide(color: active ? palette.textPrimary : palette.stroke),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Text(
            '${option.label} ${option.count}',
            style: TextStyle(
              fontFamily: searchFontMono,
              color: active ? palette.surface : palette.textMuted,
              fontSize: 10.2,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.45,
            ),
          ),
        ),
      ),
    );
  }
}

class SearchRefGroupHeader extends StatelessWidget {
  const SearchRefGroupHeader({
    super.key,
    required this.label,
    required this.count,
    this.trailing,
  });

  final String label;
  final int count;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 12, 2, 4),
      child: Row(
        children: [
          Expanded(
            child: Text.rich(
              TextSpan(
                text: label.toUpperCase(),
                children: [
                  TextSpan(
                    text: '  $count',
                    style: TextStyle(color: palette.textPrimary),
                  ),
                ],
              ),
              style: TextStyle(
                fontFamily: searchFontMono,
                color: palette.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
          ),
          if (trailing != null)
            Text(
              trailing!.toUpperCase(),
              style: TextStyle(
                fontFamily: searchFontMono,
                color: palette.textMuted,
                fontSize: 9.4,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.55,
              ),
            ),
        ],
      ),
    );
  }
}

class SearchRefResultRow extends StatelessWidget {
  const SearchRefResultRow({
    super.key,
    required this.title,
    required this.query,
    required this.pathSegments,
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    this.snippet,
    this.onTap,
    this.trailing,
    this.disabled = false,
  });

  final String title;
  final String query;
  final List<String> pathSegments;
  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final String? snippet;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Opacity(
      opacity: disabled ? 0.55 : 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: disabled ? null : onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 11),
            child: Row(
              crossAxisAlignment: snippet == null
                  ? CrossAxisAlignment.center
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: iconBackground,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 17, color: iconColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _HighlightedText(
                        text: title,
                        query: query,
                        baseStyle: TextStyle(
                          fontFamily: searchFontBody,
                          color: palette.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.08,
                          height: 1.16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _PathSegments(segments: pathSegments),
                      if (snippet != null && snippet!.trim().isNotEmpty) ...[
                        const SizedBox(height: 7),
                        Container(
                          padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
                          decoration: BoxDecoration(
                            color: palette.textPrimary.withValues(alpha: 0.04),
                            borderRadius: const BorderRadius.horizontal(
                              right: Radius.circular(7),
                            ),
                            border: Border(
                              left: BorderSide(
                                color: palette.primary,
                                width: 2,
                              ),
                            ),
                          ),
                          child: _HighlightedText(
                            text: snippet!,
                            query: query,
                            maxLines: 3,
                            baseStyle: TextStyle(
                              fontFamily: searchFontMono,
                              color: palette.textMuted,
                              fontSize: 10.8,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.08,
                              height: 1.38,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                trailing ??
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: palette.textMuted,
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SearchRefRecentRow extends StatelessWidget {
  const SearchRefRecentRow({
    super.key,
    required this.query,
    required this.onTap,
    required this.onRemove,
  });

  final String query;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 11),
        child: Row(
          children: [
            Icon(Icons.history_rounded, size: 16, color: palette.textMuted),
            const SizedBox(width: 11),
            Expanded(
              child: Text(
                query,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: searchFontBody,
                  color: palette.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.08,
                ),
              ),
            ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onRemove,
              child: Icon(
                Icons.close_rounded,
                size: 15,
                color: palette.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SearchRefSuggestedChip extends StatelessWidget {
  const SearchRefSuggestedChip({
    super.key,
    required this.label,
    required this.onTap,
    this.dotColor,
  });

  final String label;
  final Color? dotColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Material(
      color: palette.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
        side: BorderSide(color: palette.stroke),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (dotColor != null) ...[
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontFamily: searchFontMono,
                  color: palette.textPrimary,
                  fontSize: 10.3,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SearchRefStatusBanner extends StatelessWidget {
  const SearchRefStatusBanner({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.tone = SearchRefBannerTone.warning,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final SearchRefBannerTone tone;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final color = switch (tone) {
      SearchRefBannerTone.warning => palette.warning,
      SearchRefBannerTone.info => palette.primary,
      SearchRefBannerTone.success => palette.success,
    };
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: searchFontBody,
                    color: palette.textPrimary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.05,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: searchFontMono,
                    color: palette.textMuted,
                    fontSize: 9.8,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
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

enum SearchRefBannerTone { warning, info, success }

class SearchRefMessage extends StatelessWidget {
  const SearchRefMessage({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: palette.surfaceSoft,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: palette.stroke),
              ),
              child: Icon(icon, size: 27, color: palette.textMuted),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: searchFontDisplay,
                color: palette.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.14,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: searchFontBody,
                color: palette.textMuted,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SearchRefFooter extends StatelessWidget {
  const SearchRefFooter({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 18),
      child: Text(
        text.toUpperCase(),
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: searchFontMono,
          color: palette.textMuted,
          fontSize: 9.4,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.75,
        ),
      ),
    );
  }
}

class _PathSegments extends StatelessWidget {
  const _PathSegments({required this.segments});

  final List<String> segments;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final visible = segments
        .map((segment) => segment.trim())
        .where((segment) => segment.isNotEmpty)
        .toList(growable: false);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < visible.length; i++) ...[
            Text(
              visible[i].toUpperCase(),
              style: TextStyle(
                fontFamily: searchFontMono,
                color: palette.textMuted,
                fontSize: 9.4,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.55,
              ),
            ),
            if (i < visible.length - 1)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  '›',
                  style: TextStyle(
                    fontFamily: searchFontMono,
                    color: palette.textMuted.withValues(alpha: 0.45),
                    fontSize: 9.4,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _HighlightedText extends StatelessWidget {
  const _HighlightedText({
    required this.text,
    required this.query,
    required this.baseStyle,
    this.maxLines = 1,
  });

  final String text;
  final String query;
  final TextStyle baseStyle;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) {
      return Text(
        text,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        style: baseStyle,
      );
    }

    final lower = text.toLowerCase();
    final index = lower.indexOf(normalizedQuery);
    if (index < 0) {
      return Text(
        text,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        style: baseStyle,
      );
    }

    return RichText(
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: baseStyle,
        children: [
          if (index > 0) TextSpan(text: text.substring(0, index)),
          TextSpan(
            text: text.substring(index, index + normalizedQuery.length),
            style: baseStyle.copyWith(
              backgroundColor: palette.warning.withValues(alpha: 0.30),
              color: palette.textPrimary,
            ),
          ),
          if (index + normalizedQuery.length < text.length)
            TextSpan(text: text.substring(index + normalizedQuery.length)),
        ],
      ),
    );
  }
}
