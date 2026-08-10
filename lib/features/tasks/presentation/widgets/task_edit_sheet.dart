import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pass_doc_manager/app/theme/app_palette.dart';
import 'package:pass_doc_manager/domain/bundles/entities/bundle_item_type.dart';
import 'package:pass_doc_manager/domain/tasks/entities/task_entity.dart';
import 'package:pass_doc_manager/domain/tasks/entities/task_linked_ref.dart';
import 'package:pass_doc_manager/domain/tasks/entities/task_priority.dart';
import 'package:pass_doc_manager/features/bundles/presentation/widgets/add_to_bundle_sheet.dart';
import 'package:pass_doc_manager/features/search/presentation/pages/vault_search_page.dart';
import 'package:pass_doc_manager/features/tasks/presentation/widgets/tasks_reference_ui.dart';
import 'package:pass_doc_manager/l10n/app_localizations.dart';
import 'package:pass_doc_manager/l10n/l10n.dart';

class TaskEditResult {
  const TaskEditResult({
    required this.title,
    this.notes,
    this.dueDate,
    required this.priority,
    this.linkedRef,
    required this.isPinned,
    this.deleteRequested = false,
  });

  const TaskEditResult.delete()
    : title = '',
      notes = null,
      dueDate = null,
      priority = TaskPriority.medium,
      linkedRef = null,
      isPinned = false,
      deleteRequested = true;

  final String title;
  final String? notes;
  final DateTime? dueDate;
  final TaskPriority priority;
  final TaskLinkedRef? linkedRef;
  final bool isPinned;
  final bool deleteRequested;
}

Future<TaskEditResult?> showTaskEditSheet(
  BuildContext context, {
  TaskEntity? initial,
  required String listTitle,
  String initialTitle = '',
}) {
  return Navigator.of(context).push<TaskEditResult>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => _TaskEditPage(
        initial: initial,
        listTitle: listTitle,
        initialTitle: initialTitle,
      ),
    ),
  );
}

class _TaskEditPage extends StatefulWidget {
  const _TaskEditPage({
    required this.initial,
    required this.listTitle,
    required this.initialTitle,
  });

  final TaskEntity? initial;
  final String listTitle;
  final String initialTitle;

  @override
  State<_TaskEditPage> createState() => _TaskEditPageState();
}

class _TaskEditPageState extends State<_TaskEditPage> {
  late final TextEditingController _titleController;
  late final TextEditingController _notesController;
  late DateTime? _dueDate;
  late TaskPriority _priority;
  late bool _isPinned;
  TaskLinkedRef? _linkedRef;

  bool get _isEdit => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _titleController = TextEditingController(
      text: initial?.title ?? widget.initialTitle,
    );
    _notesController = TextEditingController(text: initial?.notes ?? '');
    _dueDate = initial?.dueDate;
    _priority = initial?.priority ?? TaskPriority.low;
    _isPinned = initial?.isPinned ?? false;
    _linkedRef = initial?.linkedRef;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 8),
    );
    if (picked == null || !mounted) return;
    setState(() => _dueDate = picked);
  }

  Future<void> _pickLinkedRef() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final picks = await Navigator.of(context).push<List<BundleItemCandidate>>(
      MaterialPageRoute(builder: (_) => const VaultSearchPage(pickMode: true)),
    );
    if (picks == null || picks.isEmpty || !mounted) return;
    final first = picks.first;
    setState(() {
      _linkedRef = TaskLinkedRef(
        type: _linkedRefType(first.type),
        refId: first.refId,
        displayNameSnapshot: first.displayName,
      );
    });
  }

  String _linkedRefType(BundleItemType type) {
    switch (type) {
      case BundleItemType.credential:
        return 'credential';
      case BundleItemType.document:
        return 'document';
      case BundleItemType.collection:
        return 'collection';
      case BundleItemType.note:
        return 'note';
      case BundleItemType.identityCard:
        return 'document';
    }
  }

  void _submit() {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context).pop(
      TaskEditResult(
        title: title,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        dueDate: _dueDate,
        priority: _priority,
        linkedRef: _linkedRef,
        isPinned: _isPinned,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final l10n = context.l10n;

    return TaskReferencePage(
      child: Column(
        children: [
          _EditorTopBar(
            title: _isEdit ? l10n.taskEditTitle : l10n.taskCreateTitle,
            onCancel: () => Navigator.of(context).maybePop(),
            onSave: _submit,
          ),
          Expanded(
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.only(bottom: 28),
              children: [
                const SizedBox(height: 8),
                TaskRefSectionLabel(label: l10n.taskFieldTitle),
                const SizedBox(height: 8),
                _EditorTextBox(
                  height: 84,
                  child: TextField(
                    controller: _titleController,
                    autofocus: !_isEdit,
                    maxLines: 2,
                    onChanged: (_) => setState(() {}),
                    textInputAction: TextInputAction.next,
                    style: TextStyle(
                      fontFamily: taskFontDisplay,
                      color: palette.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                    decoration: InputDecoration(
                      hintText: l10n.taskFieldTitleHint,
                      border: InputBorder.none,
                      hintStyle: TextStyle(
                        fontFamily: taskFontDisplay,
                        color: palette.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                TaskRefSectionLabel(label: l10n.taskFieldNotes),
                const SizedBox(height: 8),
                _EditorTextBox(
                  height: 168,
                  child: TextField(
                    controller: _notesController,
                    maxLines: null,
                    minLines: 6,
                    textInputAction: TextInputAction.newline,
                    style: TextStyle(
                      fontFamily: taskFontBody,
                      color: palette.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                    decoration: InputDecoration(
                      hintText: l10n.taskFieldNotesHint,
                      border: InputBorder.none,
                      hintStyle: TextStyle(
                        fontFamily: taskFontBody,
                        color: palette.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                TaskRefSectionLabel(label: l10n.taskFieldPriority),
                const SizedBox(height: 8),
                _PrioritySelector(
                  selected: _priority,
                  onChanged: (value) => setState(() => _priority = value),
                ),
                const SizedBox(height: 18),
                TaskRefSectionLabel(label: 'Details'),
                const SizedBox(height: 8),
                _TogglePanel(
                  children: [
                    _DateRow(
                      label: l10n.taskFieldDue,
                      value: _dueDate == null
                          ? l10n.taskFieldDueNone
                          : _formatDate(context, _dueDate!),
                      onTap: _pickDueDate,
                      onClear: _dueDate == null
                          ? null
                          : () => setState(() => _dueDate = null),
                    ),
                    _SwitchRow(
                      title: l10n.taskFieldPin,
                      subtitle: l10n.taskFieldPinHint,
                      value: _isPinned,
                      onChanged: (value) => setState(() => _isPinned = value),
                    ),
                    _LinkedRow(
                      title: l10n.taskFieldLink,
                      value:
                          _linkedRef?.displayNameSnapshot ??
                          l10n.taskFieldLinkNone,
                      isEmpty: _linkedRef == null,
                      onTap: _pickLinkedRef,
                      onClear: _linkedRef == null
                          ? null
                          : () => setState(() => _linkedRef = null),
                    ),
                    _ReadOnlyRow(
                      title: context.l10n.collectionDetailTaskList,
                      value: widget.listTitle,
                    ),
                  ],
                ),
                if (_isEdit) ...[
                  const SizedBox(height: 18),
                  TaskDangerRow(
                    title: l10n.tasksActionDelete,
                    subtitle: 'Shows a 5 second undo after delete',
                    onTap: () {
                      FocusManager.instance.primaryFocus?.unfocus();
                      Navigator.of(context).pop(const TaskEditResult.delete());
                    },
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(BuildContext context, DateTime date) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    return DateFormat.yMMMd(locale).format(date.toLocal());
  }
}

class _EditorTopBar extends StatelessWidget {
  const _EditorTopBar({
    required this.title,
    required this.onCancel,
    required this.onSave,
  });

  final String title;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 12),
      child: Row(
        children: [
          SizedBox(
            width: 82,
            child: TextButton(
              onPressed: onCancel,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                alignment: Alignment.centerLeft,
              ),
              child: Text(
                context.l10n.commonCancel,
                style: TextStyle(
                  fontFamily: taskFontDisplay,
                  color: palette.textSecondary,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: taskFontDisplay,
                color: palette.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.35,
              ),
            ),
          ),
          SizedBox(
            width: 82,
            child: TextButton(
              onPressed: onSave,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                alignment: Alignment.centerRight,
              ),
              child: Text(
                context.l10n.commonSave,
                style: const TextStyle(
                  fontFamily: taskFontDisplay,
                  color: Color(0xFF2458D3),
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditorTextBox extends StatelessWidget {
  const _EditorTextBox({required this.child, required this.height});

  final Widget child;
  final double height;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Container(
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 13),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: palette.stroke),
        ),
        child: child,
      ),
    );
  }
}

class _PrioritySelector extends StatelessWidget {
  const _PrioritySelector({required this.selected, required this.onChanged});

  final TaskPriority selected;
  final ValueChanged<TaskPriority> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Row(
        children: [
          for (final priority in TaskPriority.values) ...[
            Expanded(
              child: _PriorityChip(
                label: _priorityLabel(priority, l10n),
                priority: priority,
                selected: priority == selected,
                onTap: () => onChanged(priority),
              ),
            ),
            if (priority != TaskPriority.values.last) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  String _priorityLabel(TaskPriority priority, AppLocalizations l10n) {
    switch (priority) {
      case TaskPriority.low:
        return l10n.taskPriorityLow;
      case TaskPriority.medium:
        return l10n.taskPriorityMedium;
      case TaskPriority.high:
        return l10n.taskPriorityHigh;
    }
  }
}

class _PriorityChip extends StatelessWidget {
  const _PriorityChip({
    required this.label,
    required this.priority,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final TaskPriority priority;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? palette.textPrimary.withValues(alpha: 0.05)
              : palette.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? palette.textPrimary : palette.stroke,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TaskPriorityDot(priority: priority),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: taskFontBody,
                  color: selected ? palette.textPrimary : palette.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TogglePanel extends StatelessWidget {
  const _TogglePanel({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Container(
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
                Divider(height: 1, color: palette.stroke),
            ],
          ],
        ),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                    color: palette.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: taskFontMono,
                    color: palette.textMuted,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.45,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _DateRow extends StatelessWidget {
  const _DateRow({
    required this.label,
    required this.value,
    required this.onTap,
    this.onClear,
  });

  final String label;
  final String value;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return _TapRow(
      title: label,
      value: value,
      onTap: onTap,
      onClear: onClear,
      icon: Icons.event_rounded,
    );
  }
}

class _LinkedRow extends StatelessWidget {
  const _LinkedRow({
    required this.title,
    required this.value,
    required this.isEmpty,
    required this.onTap,
    this.onClear,
  });

  final String title;
  final String value;
  final bool isEmpty;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return _TapRow(
      title: title,
      value: value,
      muted: isEmpty,
      onTap: onTap,
      onClear: onClear,
      icon: Icons.link_rounded,
    );
  }
}

class _ReadOnlyRow extends StatelessWidget {
  const _ReadOnlyRow({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontFamily: taskFontBody,
                color: palette.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: taskFontMono,
                color: palette.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TapRow extends StatelessWidget {
  const _TapRow({
    required this.title,
    required this.value,
    required this.onTap,
    required this.icon,
    this.onClear,
    this.muted = false,
  });

  final String title;
  final String value;
  final VoidCallback onTap;
  final VoidCallback? onClear;
  final IconData icon;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                      color: palette.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: taskFontMono,
                      color: muted ? palette.textMuted : palette.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.45,
                    ),
                  ),
                ],
              ),
            ),
            if (onClear != null)
              IconButton(
                onPressed: onClear,
                icon: Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: palette.textMuted,
                ),
              )
            else
              Icon(icon, color: palette.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}
