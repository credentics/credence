import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pass_doc_manager/app/theme/app_palette.dart';
import 'package:pass_doc_manager/domain/bundles/entities/bundle_entity.dart';
import 'package:pass_doc_manager/domain/bundles/support/bundle_template_catalog.dart';
import 'package:pass_doc_manager/features/bundles/presentation/cubit/bundles_list_cubit.dart';
import 'package:pass_doc_manager/features/bundles/presentation/support/bundle_template_presentation.dart';
import 'package:pass_doc_manager/features/bundles/presentation/widgets/bundles_reference_ui.dart';
import 'package:pass_doc_manager/l10n/l10n.dart';

class BundleCreatePage extends StatefulWidget {
  const BundleCreatePage({super.key, this.listCubit, this.initialTemplateKey});

  final BundlesListCubit? listCubit;
  final String? initialTemplateKey;

  @override
  State<BundleCreatePage> createState() => _BundleCreatePageState();
}

class _BundleCreatePageState extends State<BundleCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _purposeController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedTemplateKey;
  bool _submitting = false;
  bool _appliedInitialTemplate = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_appliedInitialTemplate) return;
    _appliedInitialTemplate = true;
    final key = widget.initialTemplateKey;
    if (key != null && key.trim().isNotEmpty) {
      _selectTemplate(key, force: true);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _purposeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit(BundlesListCubit cubit) async {
    FocusManager.instance.primaryFocus?.unfocus();
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;
    setState(() => _submitting = true);

    final bundle = await cubit.create(
      title: _titleController.text.trim(),
      purpose: _purposeController.text.trim().isEmpty
          ? null
          : _purposeController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      templateKey: _selectedTemplateKey,
    );

    if (!mounted) return;
    setState(() => _submitting = false);
    if (bundle != null) {
      Navigator.of(context).pop<BundleEntity>(bundle);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.bundleCreateError)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final listCubit = widget.listCubit;
    if (listCubit != null) {
      return _buildScaffold(context, listCubit);
    }
    return BlocProvider(
      create: (_) => BundlesListCubit(),
      child: Builder(
        builder: (context) =>
            _buildScaffold(context, context.read<BundlesListCubit>()),
      ),
    );
  }

  Widget _buildScaffold(BuildContext context, BundlesListCubit cubit) {
    return BundleReferencePage(
      child: Form(
        key: _formKey,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  BundleRefHeader(
                    title: context.l10n.bundleCreateAction,
                    meta: 'CHOOSE A START',
                    leading: _HeaderTextButton(
                      label: MaterialLocalizations.of(
                        context,
                      ).cancelButtonLabel,
                      onTap: () => Navigator.of(context).maybePop(),
                    ),
                    trailing: const SizedBox.shrink(),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 4, 22, 16),
                    child: Text(
                      context.l10n.bundleTemplateSectionSubtitle,
                      style: TextStyle(
                        fontFamily: bundleFontBody,
                        color: context.appPalette.textSecondary,
                        fontSize: 13,
                        height: 1.42,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  BundleSectionLabel(
                    label: context.l10n.bundleTemplateSectionTitle,
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    child: _TemplateGrid(
                      selectedTemplateKey: _selectedTemplateKey,
                      onTemplateTap: _previewAndSelectTemplate,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    child: _BlankBundleTile(
                      selected: _selectedTemplateKey == null,
                      onTap: () => _selectTemplate(null, force: true),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_selectedTemplateKey != null) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      child: _SelectedTemplatePanel(
                        templateKey: _selectedTemplateKey!,
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],
                  BundleSectionLabel(label: 'Details'),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 120),
              sliver: SliverList.list(
                children: [
                  _BundleTextField(
                    controller: _titleController,
                    label: context.l10n.bundleFieldTitle,
                    hint: context.l10n.bundleFieldTitleHint,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return context.l10n.bundleFieldTitleRequired;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  _BundleTextField(
                    controller: _purposeController,
                    label: context.l10n.bundleFieldPurpose,
                    hint: context.l10n.bundleFieldPurposeHint,
                  ),
                  const SizedBox(height: 12),
                  _BundleTextField(
                    controller: _descriptionController,
                    label: context.l10n.bundleFieldDescription,
                    hint: context.l10n.bundleFieldDescriptionHint,
                    minLines: 3,
                    maxLines: 4,
                  ),
                  const SizedBox(height: 18),
                  BundlePrimaryButton(
                    label: context.l10n.bundleCreateAction,
                    icon: _submitting ? null : Icons.check_rounded,
                    onPressed: _submitting ? null : () => _submit(cubit),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _previewAndSelectTemplate(String templateKey) async {
    final selected = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => _BundleTemplatePreviewPage(templateKey: templateKey),
      ),
    );
    if (selected == null || !mounted) return;
    _selectTemplate(selected, force: true);
  }

  void _selectTemplate(String? templateKey, {bool force = false}) {
    final previousTemplate = BundleTemplateCatalog.byKey(_selectedTemplateKey);
    final nextTemplate = BundleTemplateCatalog.byKey(templateKey);
    final l10n = context.l10n;

    String previousTitle = '';
    String previousPurpose = '';
    String previousDescription = '';
    if (previousTemplate != null) {
      final previousCopy = bundleTemplatePresentationCopy(
        l10n: l10n,
        template: previousTemplate,
      );
      previousTitle = previousCopy.recommendedTitle;
      previousPurpose = previousCopy.recommendedPurpose;
      previousDescription = previousCopy.recommendedDescription;
    }

    setState(() {
      _selectedTemplateKey = templateKey;
      if (nextTemplate == null) {
        if (force) {
          _titleController.clear();
          _purposeController.clear();
          _descriptionController.clear();
        }
        return;
      }
      final nextCopy = bundleTemplatePresentationCopy(
        l10n: l10n,
        template: nextTemplate,
      );
      final currentTitle = _titleController.text.trim();
      if (force || currentTitle.isEmpty || currentTitle == previousTitle) {
        _titleController.text = nextCopy.recommendedTitle;
      }
      final currentPurpose = _purposeController.text.trim();
      if (force ||
          currentPurpose.isEmpty ||
          currentPurpose == previousPurpose) {
        _purposeController.text = nextCopy.recommendedPurpose;
      }
      final currentDescription = _descriptionController.text.trim();
      if (force ||
          currentDescription.isEmpty ||
          currentDescription == previousDescription) {
        _descriptionController.text = nextCopy.recommendedDescription;
      }
    });
  }
}

class _TemplateGrid extends StatelessWidget {
  const _TemplateGrid({
    required this.selectedTemplateKey,
    required this.onTemplateTap,
  });

  final String? selectedTemplateKey;
  final ValueChanged<String> onTemplateTap;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.34,
      ),
      itemCount: BundleTemplateCatalog.templates.length,
      itemBuilder: (context, index) {
        final template = BundleTemplateCatalog.templates[index];
        final copy = bundleTemplatePresentationCopy(
          l10n: context.l10n,
          template: template,
        );
        return _TemplateTile(
          templateKey: template.key,
          title: copy.title,
          subtitle: '${template.requiredCount} REQ',
          selected: selectedTemplateKey == template.key,
          onTap: () => onTemplateTap(template.key),
        );
      },
    );
  }
}

class _TemplateTile extends StatelessWidget {
  const _TemplateTile({
    required this.templateKey,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String templateKey;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return BundleCardShell(
      onTap: onTap,
      radius: 14,
      borderColor: selected ? palette.primary : palette.stroke,
      backgroundColor: selected
          ? Color.lerp(palette.surface, palette.primary, 0.08)
          : palette.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              BundleMonoBadge(
                text: bundleTemplateInitials(templateKey, title),
                templateKey: templateKey,
                size: 36,
              ),
              const Spacer(),
              if (selected)
                Icon(
                  Icons.check_circle_rounded,
                  color: palette.primary,
                  size: 20,
                ),
            ],
          ),
          const Spacer(),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: bundleFontDisplay,
              color: palette.textPrimary,
              fontSize: 13,
              height: 1.15,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.15,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: TextStyle(
              fontFamily: bundleFontMono,
              color: palette.textMuted,
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _BlankBundleTile extends StatelessWidget {
  const _BlankBundleTile({required this.selected, required this.onTap});

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return BundleCardShell(
      onTap: onTap,
      radius: 14,
      borderColor: selected ? palette.primary : palette.stroke,
      child: Row(
        children: [
          BundleMonoBadge(text: '+', size: 38),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.bundleTemplateBlankTitle,
                  style: TextStyle(
                    fontFamily: bundleFontDisplay,
                    color: palette.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  context.l10n.bundleTemplateBlankSubtitle.toUpperCase(),
                  style: TextStyle(
                    fontFamily: bundleFontMono,
                    color: palette.textMuted,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: palette.textMuted),
        ],
      ),
    );
  }
}

class _SelectedTemplatePanel extends StatelessWidget {
  const _SelectedTemplatePanel({required this.templateKey});

  final String templateKey;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final template = BundleTemplateCatalog.byKey(templateKey)!;
    final copy = bundleTemplatePresentationCopy(
      l10n: context.l10n,
      template: template,
    );
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color.lerp(palette.surface, palette.primary, 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.primary.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          BundleMonoBadge(
            text: bundleTemplateInitials(templateKey, copy.title),
            templateKey: templateKey,
            size: 44,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: palette.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    context.l10n.bundleTemplateSelectedBadge.toUpperCase(),
                    style: TextStyle(
                      fontFamily: bundleFontMono,
                      color: palette.primary,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  copy.title,
                  style: TextStyle(
                    fontFamily: bundleFontDisplay,
                    color: palette.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  copy.summary,
                  style: TextStyle(
                    fontFamily: bundleFontBody,
                    color: palette.textSecondary,
                    fontSize: 12.5,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
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

class _BundleTextField extends StatelessWidget {
  const _BundleTextField({
    required this.controller,
    required this.label,
    required this.hint,
    this.validator,
    this.minLines = 1,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final String? Function(String?)? validator;
  final int minLines;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return TextFormField(
      controller: controller,
      validator: validator,
      minLines: minLines,
      maxLines: maxLines,
      cursorColor: palette.textPrimary,
      textInputAction: maxLines > 1
          ? TextInputAction.newline
          : TextInputAction.next,
      style: TextStyle(
        fontFamily: bundleFontBody,
        color: palette.textPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
      decoration: InputDecoration(
        labelText: label.toUpperCase(),
        hintText: hint,
        filled: true,
        fillColor: palette.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        hintStyle: TextStyle(
          fontFamily: bundleFontBody,
          color: palette.textMuted,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        labelStyle: TextStyle(
          fontFamily: bundleFontMono,
          color: palette.textMuted,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.15,
        ),
        floatingLabelStyle: TextStyle(
          fontFamily: bundleFontMono,
          color: palette.textPrimary,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.15,
        ),
        border: _outline(palette.stroke),
        enabledBorder: _outline(palette.stroke),
        focusedBorder: _outline(palette.textPrimary, width: 1.4),
        errorBorder: _outline(palette.danger),
        focusedErrorBorder: _outline(palette.danger, width: 1.4),
      ),
    );
  }

  OutlineInputBorder _outline(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}

class _HeaderTextButton extends StatelessWidget {
  const _HeaderTextButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Text(
        label,
        style: TextStyle(
          fontFamily: bundleFontBody,
          color: context.appPalette.textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _BundleTemplatePreviewPage extends StatelessWidget {
  const _BundleTemplatePreviewPage({required this.templateKey});

  final String templateKey;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final template = BundleTemplateCatalog.byKey(templateKey)!;
    final copy = bundleTemplatePresentationCopy(
      l10n: context.l10n,
      template: template,
    );
    final required = template.requirements
        .where((requirement) => !requirement.optional)
        .toList(growable: false);
    final optional = template.requirements.length - required.length;

    return BundleReferencePage(
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(22, 10, 22, 14),
          decoration: BoxDecoration(
            color: palette.background.withValues(alpha: 0.96),
            border: Border(top: BorderSide(color: palette.stroke)),
          ),
          child: BundlePrimaryButton(
            label: 'Use this template',
            onPressed: () => Navigator.of(context).pop(template.key),
          ),
        ),
      ),
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              children: [
                BundleRefHeader(
                  title: copy.title,
                  meta:
                      '${template.requiredCount} REQUIRED · $optional OPTIONAL',
                  leading: BundleRefIconButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () => Navigator.of(context).maybePop(),
                    size: 42,
                  ),
                  trailing: const SizedBox.shrink(),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: _PreviewHero(template: template, copy: copy),
                ),
                const SizedBox(height: 16),
                BundleSectionLabel(
                  label:
                      '${context.l10n.bundleTemplateRequiredLabel} · ${required.length}',
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(22, 0, 22, 120),
            sliver: SliverList.separated(
              itemCount: required.length,
              separatorBuilder: (_, __) => const SizedBox(height: 0),
              itemBuilder: (context, index) {
                final requirement = required[index];
                return _PreviewRequirementRow(requirement: requirement);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewHero extends StatelessWidget {
  const _PreviewHero({required this.template, required this.copy});

  final BundleTemplateDefinition template;
  final dynamic copy;

  @override
  Widget build(BuildContext context) {
    final colors = bundleTemplateGradient(template.key, context.appPalette);
    final optional = template.requirements.length - template.requiredCount;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'TEMPLATE PREVIEW',
                  style: TextStyle(
                    fontFamily: bundleFontMono,
                    color: Colors.white.withValues(alpha: 0.74),
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${template.requiredCount} REQ · $optional OPT',
                  style: const TextStyle(
                    fontFamily: bundleFontMono,
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.75,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${template.requirements.length} checklist items',
            style: const TextStyle(
              fontFamily: bundleFontDisplay,
              color: Colors.white,
              fontSize: 17,
              height: 1.18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            copy.summary,
            style: TextStyle(
              fontFamily: bundleFontBody,
              color: Colors.white.withValues(alpha: 0.86),
              fontSize: 12,
              height: 1.42,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewRequirementRow extends StatelessWidget {
  const _PreviewRequirementRow({required this.requirement});

  final BundleTemplateRequirement requirement;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: palette.stroke.withValues(alpha: 0.7)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: palette.strokeStrong, width: 1.4),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  requirement.title,
                  style: TextStyle(
                    fontFamily: bundleFontBody,
                    color: palette.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  requirement.description,
                  style: TextStyle(
                    fontFamily: bundleFontMono,
                    color: palette.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.15,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            requirement.optional ? 'OPT' : 'REQ',
            style: TextStyle(
              fontFamily: bundleFontMono,
              color: palette.textMuted,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.65,
            ),
          ),
        ],
      ),
    );
  }
}
