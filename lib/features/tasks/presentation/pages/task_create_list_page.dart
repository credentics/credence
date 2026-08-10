import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pass_doc_manager/app/theme/app_palette.dart';
import 'package:pass_doc_manager/domain/tasks/entities/task_list_entity.dart';
import 'package:pass_doc_manager/features/tasks/presentation/cubit/task_lists_cubit.dart';
import 'package:pass_doc_manager/features/tasks/presentation/support/task_visuals.dart';
import 'package:pass_doc_manager/features/tasks/presentation/widgets/tasks_reference_ui.dart';
import 'package:pass_doc_manager/l10n/l10n.dart';

class TaskCreateListPage extends StatefulWidget {
  const TaskCreateListPage({
    super.key,
    this.listCubit,
    this.embeddedDesktop = false,
  });

  final TaskListsCubit? listCubit;
  final bool embeddedDesktop;

  @override
  State<TaskCreateListPage> createState() => _TaskCreateListPageState();
}

class _TaskCreateListPageState extends State<TaskCreateListPage> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _accent = TaskVisualOptions.accentColors[1];
  String _iconKey = TaskVisualOptions.iconKeys.first;
  bool _submitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit(TaskListsCubit cubit) async {
    final title = _titleController.text.trim();
    if (title.isEmpty || _submitting) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _submitting = true);
    final created = await cubit.create(
      title: title,
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      accentColorHex: _accent,
      iconKey: _iconKey,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (created != null) {
      Navigator.of(context).pop<TaskListEntity>(created);
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.tasksListCreateError)));
  }

  @override
  Widget build(BuildContext context) {
    final provided = widget.listCubit;
    if (provided != null) {
      return _body(context, provided);
    }
    return BlocProvider(
      create: (_) => TaskListsCubit(),
      child: Builder(
        builder: (context) => _body(context, context.read<TaskListsCubit>()),
      ),
    );
  }

  Widget _body(BuildContext context, TaskListsCubit cubit) {
    final l10n = context.l10n;
    return TaskReferencePage(
      maxWidth: widget.embeddedDesktop ? 980 : 720,
      bottom: TaskBottomButton(
        label: l10n.tasksListCreateAction,
        icon: Icons.add_rounded,
        enabled: !_submitting && _titleController.text.trim().isNotEmpty,
        onTap: () => _submit(cubit),
      ),
      child: Column(
        children: [
          _CreateListTopBar(
            title: l10n.tasksListCreateTitle,
            onCancel: () => Navigator.of(context).maybePop(),
            onSave: () => _submit(cubit),
          ),
          Expanded(
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.only(bottom: 28),
              children: [
                const SizedBox(height: 8),
                _ListTextBox(
                  height: 76,
                  child: TextField(
                    controller: _titleController,
                    autofocus: true,
                    textInputAction: TextInputAction.next,
                    onChanged: (_) => setState(() {}),
                    style: TextStyle(
                      fontFamily: taskFontDisplay,
                      color: context.appPalette.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                    decoration: InputDecoration(
                      hintText: l10n.tasksListFieldTitleHint,
                      border: InputBorder.none,
                      hintStyle: TextStyle(
                        fontFamily: taskFontDisplay,
                        color: context.appPalette.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _ListTextBox(
                  height: 158,
                  child: TextField(
                    controller: _descriptionController,
                    maxLines: null,
                    minLines: 5,
                    style: TextStyle(
                      fontFamily: taskFontBody,
                      color: context.appPalette.textPrimary,
                      fontSize: 14,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      hintText: l10n.tasksListFieldDescriptionHint,
                      border: InputBorder.none,
                      hintStyle: TextStyle(
                        fontFamily: taskFontBody,
                        color: context.appPalette.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                TaskRefSectionLabel(label: l10n.tasksListPickIcon),
                const SizedBox(height: 8),
                _IconSelectorRow(
                  selected: _iconKey,
                  accentHex: _accent,
                  onChanged: (value) => setState(() => _iconKey = value),
                ),
                const SizedBox(height: 18),
                TaskRefSectionLabel(label: l10n.tasksListPickColor),
                const SizedBox(height: 8),
                _ColorSelectorRow(
                  selected: _accent,
                  onChanged: (value) => setState(() => _accent = value),
                ),
                if (_submitting) ...[
                  const SizedBox(height: 18),
                  Center(
                    child: CircularProgressIndicator(
                      color: context.appPalette.textPrimary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CreateListTopBar extends StatelessWidget {
  const _CreateListTopBar({
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

class _ListTextBox extends StatelessWidget {
  const _ListTextBox({required this.child, required this.height});

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

class _IconSelectorRow extends StatelessWidget {
  const _IconSelectorRow({
    required this.selected,
    required this.accentHex,
    required this.onChanged,
  });

  final String selected;
  final String accentHex;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final accent = TaskVisualOptions.parseAccent(accentHex);
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final key in TaskVisualOptions.iconKeys) ...[
            InkWell(
              onTap: () => onChanged(key),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: selected == key
                      ? accent.withValues(alpha: 0.16)
                      : palette.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected == key
                        ? palette.textPrimary
                        : palette.stroke,
                  ),
                ),
                child: Icon(
                  TaskVisualOptions.iconFor(key),
                  size: 22,
                  color: selected == key ? accent : palette.textMuted,
                ),
              ),
            ),
            const SizedBox(width: 10),
          ],
        ],
      ),
    );
  }
}

class _ColorSelectorRow extends StatelessWidget {
  const _ColorSelectorRow({required this.selected, required this.onChanged});

  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final hex in TaskVisualOptions.accentColors) ...[
            GestureDetector(
              onTap: () => onChanged(hex),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: TaskVisualOptions.parseAccent(hex),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected == hex
                        ? palette.textPrimary
                        : palette.strokeStrong,
                    width: selected == hex ? 2.4 : 1.2,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
        ],
      ),
    );
  }
}
