import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pass_doc_manager/app/theme/app_palette.dart';
import 'package:pass_doc_manager/domain/tasks/entities/task_list_entity.dart';
import 'package:pass_doc_manager/domain/tasks/entities/task_priority.dart';
import 'package:pass_doc_manager/features/tasks/presentation/support/task_visuals.dart';
import 'package:pass_doc_manager/l10n/l10n.dart';

const String taskFontDisplay = 'Manrope';
const String taskFontBody = 'Manrope';
const String taskFontMono = 'JetBrains Mono';

class TaskReferenceColors {
  const TaskReferenceColors._();

  static const Color ink = Color(0xFF2B2824);
  static const Color muted = Color(0xFF8C857C);
  static const Color surface = Color(0xFFFFFEFB);
  static const Color surfaceSoft = Color(0xFFF7F4EF);
  static const Color border = Color(0xFFEDE8E1);
  static const Color peach = Color(0xFFF8E8DE);
  static const Color lavender = Color(0xFFF0EAF8);
  static const Color mint = Color(0xFFE8F4EF);
  static const Color blush = Color(0xFFF7E9E8);
  static const Color blue = Color(0xFFE9F0FA);
  static const Color danger = Color(0xFFB84B3E);
  static const Color warn = Color(0xFFC48729);
  static const Color ok = Color(0xFF2E8C62);
}

class TaskReferencePage extends StatelessWidget {
  const TaskReferencePage({
    super.key,
    required this.child,
    this.bottom,
    this.safeTop = true,
    this.maxWidth = 720,
  });

  final Widget child;
  final Widget? bottom;
  final bool safeTop;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark ? palette.background : const Color(0xFFFEFCF8);

    return Scaffold(
      backgroundColor: background,
      bottomNavigationBar: bottom,
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

class TaskRefIconButton extends StatelessWidget {
  const TaskRefIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.size = 54,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final button = Material(
      color: palette.surfaceSoft.withValues(alpha: 0.82),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(size * 0.3),
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, size: size * 0.42, color: palette.textPrimary),
        ),
      ),
    );
    if (tooltip == null) return button;
    return Tooltip(message: tooltip!, child: button);
  }
}

class TaskRefHeader extends StatelessWidget {
  const TaskRefHeader({
    super.key,
    required this.title,
    this.meta,
    this.leading,
    this.trailing,
    this.centerTitle = false,
  });

  final String title;
  final String? meta;
  final Widget? leading;
  final Widget? trailing;
  final bool centerTitle;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final titleWidget = Column(
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
            fontFamily: taskFontDisplay,
            color: palette.textPrimary,
            fontSize: 28,
            height: 1.02,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.7,
          ),
        ),
        if (meta != null && meta!.trim().isNotEmpty) ...[
          const SizedBox(height: 5),
          Text(
            meta!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: centerTitle ? TextAlign.center : TextAlign.start,
            style: TextStyle(
              fontFamily: taskFontMono,
              color: palette.textMuted,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ],
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 10),
      child: Row(
        children: [
          SizedBox(width: 54, child: leading ?? const SizedBox.shrink()),
          const SizedBox(width: 12),
          Expanded(
            child: centerTitle ? Center(child: titleWidget) : titleWidget,
          ),
          const SizedBox(width: 12),
          SizedBox(width: 54, child: trailing ?? const SizedBox.shrink()),
        ],
      ),
    );
  }
}

class TaskRefSectionLabel extends StatelessWidget {
  const TaskRefSectionLabel({
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
                fontFamily: taskFontMono,
                color: palette.textMuted,
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.7,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class TaskRefSearch extends StatelessWidget {
  const TaskRefSearch({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.hintText,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: palette.stroke),
        ),
        child: Row(
          children: [
            Icon(Icons.search_rounded, color: palette.textMuted, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                style: TextStyle(
                  fontFamily: taskFontBody,
                  color: palette.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText: hintText,
                  border: InputBorder.none,
                  isDense: true,
                  hintStyle: TextStyle(
                    fontFamily: taskFontBody,
                    color: palette.textMuted,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TaskQuickAddField extends StatefulWidget {
  const TaskQuickAddField({
    super.key,
    required this.hintText,
    required this.onSubmit,
    this.onOpenDetails,
    this.autofocus = false,
  });

  final String hintText;
  final Future<bool> Function(String title) onSubmit;
  final Future<bool> Function(String title)? onOpenDetails;
  final bool autofocus;

  @override
  State<TaskQuickAddField> createState() => _TaskQuickAddFieldState();
}

class _TaskQuickAddFieldState extends State<TaskQuickAddField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode()..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _controller.text.trim();
    if (title.isEmpty || _submitting) return;
    setState(() => _submitting = true);
    try {
      final created = await widget.onSubmit(title);
      if (!mounted) return;
      if (created) {
        _controller.clear();
        FocusManager.instance.primaryFocus?.unfocus();
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _openDetails() async {
    if (widget.onOpenDetails == null) return;
    final created = await widget.onOpenDetails!(_controller.text.trim());
    if (!mounted) return;
    if (created) {
      _controller.clear();
      FocusManager.instance.primaryFocus?.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final focused = _focusNode.hasFocus;
    final hasDraft = _controller.text.trim().isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 62,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: focused ? palette.textPrimary : palette.stroke,
            width: focused ? 1.4 : 1,
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
            Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: focused ? palette.textPrimary : palette.textMuted,
                  width: 1.5,
                  strokeAlign: BorderSide.strokeAlignInside,
                ),
              ),
              child: Text(
                '+',
                style: TextStyle(
                  fontFamily: taskFontDisplay,
                  color: focused ? palette.textPrimary : palette.textMuted,
                  height: 1,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                autofocus: widget.autofocus,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                onChanged: (_) => setState(() {}),
                style: TextStyle(
                  fontFamily: taskFontDisplay,
                  color: palette.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  border: InputBorder.none,
                  hintStyle: TextStyle(
                    fontFamily: taskFontDisplay,
                    color: palette.textMuted,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            if (focused || hasDraft)
              Text(
                'ENTER',
                style: TextStyle(
                  fontFamily: taskFontMono,
                  color: palette.textMuted,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            if (widget.onOpenDetails != null) ...[
              const SizedBox(width: 8),
              InkWell(
                onTap: _openDetails,
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 32,
                  height: 32,
                  child: Icon(
                    Icons.edit_outlined,
                    size: 18,
                    color: palette.textSecondary,
                  ),
                ),
              ),
            ],
            if (_submitting) ...[
              const SizedBox(width: 8),
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: palette.textPrimary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class TaskQStatCard extends StatelessWidget {
  const TaskQStatCard({
    super.key,
    required this.label,
    required this.count,
    required this.meta,
    required this.kind,
    required this.onTap,
  });

  final String label;
  final int count;
  final String meta;
  final TaskQStatKind kind;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final isToday = kind == TaskQStatKind.today;
    final bg = Theme.of(context).brightness == Brightness.dark
        ? palette.surfaceSoft
        : (isToday ? TaskReferenceColors.peach : TaskReferenceColors.lavender);
    final border = isToday ? const Color(0xFFEBCFC3) : const Color(0xFFDCD0EB);
    final fg = isToday ? const Color(0xFF57322A) : const Color(0xFF40345F);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? palette.stroke
                  : border,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontFamily: taskFontMono,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? palette.textSecondary
                      : fg,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '$count',
                style: TextStyle(
                  fontFamily: taskFontDisplay,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? palette.textPrimary
                      : fg,
                  fontSize: 28,
                  height: 1,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                meta,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: taskFontMono,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? palette.textMuted
                      : fg.withValues(alpha: 0.7),
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum TaskQStatKind { today, upcoming }

class TaskPriorityFilterChip extends StatelessWidget {
  const TaskPriorityFilterChip({
    super.key,
    required this.label,
    required this.priority,
    required this.count,
    required this.active,
    required this.onTap,
  });

  final String label;
  final TaskPriority? priority;
  final int count;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: active ? palette.textPrimary : palette.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: active ? palette.textPrimary : palette.stroke,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TaskPriorityDot(priority: priority),
            const SizedBox(width: 6),
            Text(
              '$label $count',
              style: TextStyle(
                fontFamily: taskFontMono,
                color: active ? palette.surface : palette.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TaskListRefCard extends StatelessWidget {
  const TaskListRefCard({
    super.key,
    required this.list,
    required this.onTap,
    this.trailing,
    this.onArchive,
    this.onDelete,
    this.archived = false,
  });

  final TaskListEntity list;
  final VoidCallback onTap;
  final Widget? trailing;
  final VoidCallback? onArchive;
  final VoidCallback? onDelete;
  final bool archived;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final accent = TaskVisualOptions.parseAccent(list.accentColorHex);
    final icon = TaskVisualOptions.iconFor(list.iconKey);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            padding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
            decoration: BoxDecoration(
              color: archived
                  ? palette.surfaceSoft.withValues(alpha: 0.72)
                  : palette.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: archived
                    ? palette.strokeStrong.withValues(alpha: 0.7)
                    : palette.stroke,
                style: archived ? BorderStyle.solid : BorderStyle.solid,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, color: accent, size: 21),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        list.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: taskFontDisplay,
                          color: archived
                              ? palette.textSecondary
                              : palette.textPrimary,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                          letterSpacing: -0.1,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _listMeta(context, list),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: taskFontMono,
                          color: list.overdueCount > 0
                              ? palette.danger
                              : palette.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.45,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                trailing ??
                    _TaskListOverflowMenu(
                      list: list,
                      onArchive: onArchive,
                      onDelete: onDelete,
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _listMeta(BuildContext context, TaskListEntity list) {
    final updated = DateFormat.MMMd(
      Localizations.localeOf(context).toLanguageTag(),
    ).format(list.updatedAt.toLocal());
    final overdue = list.overdueCount > 0
        ? ' · ${list.overdueCount} overdue'
        : '';
    final pin = list.pinnedOpenCount > 0
        ? ' · PIN ${list.pinnedOpenCount}'
        : '';
    return '${list.openCount} open · ${list.doneCount} done · Updated $updated$overdue$pin';
  }
}

class _TaskListOverflowMenu extends StatelessWidget {
  const _TaskListOverflowMenu({
    required this.list,
    required this.onArchive,
    required this.onDelete,
  });

  final TaskListEntity list;
  final VoidCallback? onArchive;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final l10n = context.l10n;
    if (onArchive == null && onDelete == null) {
      return Icon(
        Icons.chevron_right_rounded,
        color: palette.textMuted.withValues(alpha: 0.7),
        size: 20,
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 34,
          height: 36,
          child: PopupMenuButton<String>(
            tooltip: MaterialLocalizations.of(context).showMenuTooltip,
            padding: EdgeInsets.zero,
            icon: Icon(
              Icons.more_horiz_rounded,
              color: palette.textMuted.withValues(alpha: 0.78),
              size: 22,
            ),
            onSelected: (value) {
              switch (value) {
                case 'archive':
                  onArchive?.call();
                  return;
                case 'delete':
                  onDelete?.call();
                  return;
              }
            },
            itemBuilder: (context) => [
              if (onArchive != null)
                PopupMenuItem<String>(
                  value: 'archive',
                  child: Row(
                    children: [
                      Icon(
                        list.isArchived
                            ? Icons.unarchive_rounded
                            : Icons.archive_rounded,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        list.isArchived
                            ? l10n.tasksActionUnarchive
                            : l10n.tasksActionArchive,
                      ),
                    ],
                  ),
                ),
              if (onDelete != null)
                PopupMenuItem<String>(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete_outline_rounded,
                        size: 18,
                        color: palette.danger,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        l10n.tasksActionDelete,
                        style: TextStyle(color: palette.danger),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        Icon(
          Icons.chevron_right_rounded,
          color: palette.textMuted.withValues(alpha: 0.7),
          size: 20,
        ),
      ],
    );
  }
}

class TaskCheckbox extends StatelessWidget {
  const TaskCheckbox({
    super.key,
    required this.checked,
    required this.onTap,
    this.overdue = false,
  });

  final bool checked;
  final bool overdue;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final color = checked
        ? palette.textPrimary
        : overdue
        ? palette.danger
        : palette.strokeStrong;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: checked ? palette.textPrimary : Colors.transparent,
          border: Border.all(color: color, width: 1.75),
          boxShadow: overdue && !checked
              ? [
                  BoxShadow(
                    color: palette.danger.withValues(alpha: 0.14),
                    blurRadius: 0,
                    spreadRadius: 3,
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: checked
            ? Icon(Icons.check_rounded, size: 14, color: palette.surface)
            : null,
      ),
    );
  }
}

class TaskPriorityDot extends StatelessWidget {
  const TaskPriorityDot({super.key, required this.priority});

  final TaskPriority? priority;

  @override
  Widget build(BuildContext context) {
    final color = switch (priority) {
      TaskPriority.high => TaskReferenceColors.danger,
      TaskPriority.medium => TaskReferenceColors.warn,
      TaskPriority.low => const Color(0xFF4274BF),
      null => context.appPalette.textMuted.withValues(alpha: 0.45),
    };
    return Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

class TaskMetaText extends StatelessWidget {
  const TaskMetaText({super.key, required this.children, this.color});

  final List<InlineSpan> children;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return RichText(
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: TextStyle(
          fontFamily: taskFontMono,
          color: color ?? palette.textMuted,
          fontSize: 10,
          height: 1.35,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.45,
        ),
        children: children,
      ),
    );
  }
}

class TaskChevron extends StatelessWidget {
  const TaskChevron({super.key});

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.chevron_right_rounded,
      size: 22,
      color: context.appPalette.textMuted.withValues(alpha: 0.62),
    );
  }
}

class TaskCompletedHeader extends StatelessWidget {
  const TaskCompletedHeader({
    super.key,
    required this.count,
    required this.expanded,
    required this.onTap,
  });

  final int count;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: palette.surfaceSoft.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Text(
                context.l10n.tasksSectionDone.toUpperCase(),
                style: TextStyle(
                  fontFamily: taskFontMono,
                  color: palette.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                constraints: const BoxConstraints(minWidth: 22),
                height: 18,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: palette.textPrimary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontFamily: taskFontMono,
                    color: palette.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Spacer(),
              Icon(
                expanded
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                size: 20,
                color: palette.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TaskSegmentedSwitch extends StatelessWidget {
  const TaskSegmentedSwitch({
    super.key,
    required this.items,
    required this.activeIndex,
    required this.onChanged,
  });

  final List<String> items;
  final int activeIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: palette.textPrimary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            for (var i = 0; i < items.length; i++)
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onChanged(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 140),
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      color: activeIndex == i
                          ? palette.surface
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(9),
                      boxShadow: activeIndex == i
                          ? [
                              BoxShadow(
                                color: palette.shadow.withValues(alpha: 0.08),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      items[i],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: taskFontBody,
                        color: activeIndex == i
                            ? palette.textPrimary
                            : palette.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class TaskDayRail extends StatelessWidget {
  const TaskDayRail({
    super.key,
    required this.label,
    required this.count,
    this.kind = TaskDayRailKind.normal,
  });

  final String label;
  final int count;
  final TaskDayRailKind kind;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = switch (kind) {
      TaskDayRailKind.today =>
        isDark
            ? palette.surfaceSoft
            : TaskReferenceColors.peach.withValues(alpha: 0.72),
      TaskDayRailKind.overdue =>
        isDark ? palette.dangerSoft : TaskReferenceColors.blush,
      TaskDayRailKind.normal => palette.surfaceSoft.withValues(alpha: 0.7),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontFamily: taskFontMono,
                color: palette.textPrimary,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.7,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                height: 2,
                decoration: BoxDecoration(
                  color: palette.textPrimary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '$count',
              style: TextStyle(
                fontFamily: taskFontMono,
                color: palette.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum TaskDayRailKind { normal, today, overdue }

class TaskOverdueStrip extends StatelessWidget {
  const TaskOverdueStrip({
    super.key,
    required this.count,
    required this.onReview,
  });

  final int count;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? palette.dangerSoft
              : TaskReferenceColors.blush,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: palette.danger.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '$count overdue task${count == 1 ? '' : 's'} need a new date.',
                style: TextStyle(
                  fontFamily: taskFontBody,
                  color: palette.danger,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            TextButton(
              onPressed: onReview,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'REVIEW',
                style: TextStyle(
                  fontFamily: taskFontMono,
                  color: palette.danger,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.7,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TaskEmptyStack extends StatelessWidget {
  const TaskEmptyStack({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return SizedBox(
      height: 170,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _StackCard(
            color: Theme.of(context).brightness == Brightness.dark
                ? palette.surfaceSoft
                : TaskReferenceColors.lavender,
            angle: -0.12,
            offset: const Offset(-24, 0),
          ),
          _StackCard(
            color: Theme.of(context).brightness == Brightness.dark
                ? palette.surface
                : TaskReferenceColors.peach,
            angle: 0.04,
            offset: const Offset(0, -8),
          ),
          _StackCard(
            color: Theme.of(context).brightness == Brightness.dark
                ? palette.surfaceSoft
                : TaskReferenceColors.mint,
            angle: -0.05,
            offset: const Offset(24, 6),
          ),
        ],
      ),
    );
  }
}

class _StackCard extends StatelessWidget {
  const _StackCard({
    required this.color,
    required this.angle,
    required this.offset,
  });

  final Color color;
  final double angle;
  final Offset offset;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Transform.translate(
      offset: offset,
      child: Transform.rotate(
        angle: angle,
        child: Container(
          width: 200,
          height: 130,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: palette.stroke),
            boxShadow: [
              BoxShadow(
                color: palette.shadow.withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              _StackLine(width: double.infinity),
              const SizedBox(height: 8),
              const _StackLine(width: 120),
              const Spacer(),
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: palette.textPrimary.withValues(alpha: 0.28),
                        width: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(child: _StackLine(width: double.infinity)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StackLine extends StatelessWidget {
  const _StackLine({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 6,
      decoration: BoxDecoration(
        color: context.appPalette.textPrimary.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

class TaskStarterChip extends StatelessWidget {
  const TaskStarterChip({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: palette.stroke),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: taskFontBody,
            color: palette.textPrimary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class TaskBottomButton extends StatelessWidget {
  const TaskBottomButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.enabled = true,
  });

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 8, 22, 18),
        child: FilledButton.icon(
          onPressed: enabled ? onTap : null,
          icon: icon == null ? const SizedBox.shrink() : Icon(icon, size: 19),
          label: Text(label),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(58),
            backgroundColor: palette.textPrimary,
            foregroundColor: palette.surface,
            disabledBackgroundColor: palette.textMuted.withValues(alpha: 0.25),
            disabledForegroundColor: palette.textMuted,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            textStyle: const TextStyle(
              fontFamily: taskFontDisplay,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class TaskDangerRow extends StatelessWidget {
  const TaskDangerRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: palette.dangerSoft,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: palette.dangerStroke),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: taskFontBody,
                        color: palette.danger,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontFamily: taskFontMono,
                        color: palette.danger.withValues(alpha: 0.82),
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: palette.danger),
            ],
          ),
        ),
      ),
    );
  }
}
