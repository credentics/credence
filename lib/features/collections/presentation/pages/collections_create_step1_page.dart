import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pass_doc_manager/app/di/injection.dart';
import 'package:pass_doc_manager/app/theme/app_palette.dart';
import 'package:pass_doc_manager/core/utils/local_asset_file_store.dart';
import 'package:pass_doc_manager/domain/branding/usecases/download_company_logo_to_local.dart';
import 'package:pass_doc_manager/domain/branding/usecases/search_company_brands.dart';
import 'package:pass_doc_manager/features/collections/presentation/pages/collection_create_flow_models.dart';
import 'package:pass_doc_manager/features/collections/presentation/widgets/collection_block_icon_picker.dart';
import 'package:pass_doc_manager/features/collections/presentation/widgets/collections_ui.dart';
import 'package:pass_doc_manager/l10n/l10n.dart';

const _collectionCreateBg = Color(0xFFFEFCF8);
const _collectionCreateInk = Color(0xFF1D1A16);
const _collectionCreateMuted = Color(0xFF9E978E);
const _collectionCreateSoft = Color(0xFFF5F2EE);
const _collectionCreateBorder = Color(0xFFE8E2DA);
const _collectionCreateRisk = Color(0xFFC44B3E);
const _collectionCreateFont = 'Manrope';
const _collectionCreateMono = 'JetBrains Mono';

class CollectionsCreateStep1Page extends StatefulWidget {
  const CollectionsCreateStep1Page({
    super.key,
    this.initialDraft,
    this.isEditing = false,
  });

  final CollectionCreateDraft? initialDraft;
  final bool isEditing;

  @override
  State<CollectionsCreateStep1Page> createState() =>
      _CollectionsCreateStep1PageState();
}

class _CollectionsCreateStep1PageState
    extends State<CollectionsCreateStep1Page> {
  static const _colorOptions = <String>[
    '#1152D4',
    '#E11D48',
    '#059669',
    '#F59E0B',
    '#7C3AED',
    '#0EA5E9',
    '#0F172A',
    '#DC2626',
    '#0891B2',
    '#D946EF',
    '#EA580C',
    '#65A30D',
    '#0284C7',
    '#BE185D',
    '#4F46E5',
    '#115E59',
  ];

  static const _extendedColors = [
    '#1152D4',
    '#F43F5E',
    '#10B981',
    '#F59E0B',
    '#A855F7',
    '#0EA5E9',
    '#0F172A',
    '#EC4899',
    '#14B8A6',
    '#8B5CF6',
    '#EF4444',
    '#22C55E',
    '#3B82F6',
    '#F97316',
    '#06B6D4',
    '#84CC16',
    '#D946EF',
    '#6366F1',
    '#78716C',
    '#64748B',
  ];

  final ImagePicker _imagePicker = ImagePicker();
  late final TextEditingController _nameController;
  late String _selectedIcon;
  String? _selectedIconEmoji;
  String? _selectedIconImagePath;
  late String _selectedColor;

  SearchCompanyBrands get _searchCompanyBrandsUseCase => getIt();
  DownloadCompanyLogoToLocal get _downloadCompanyLogoToLocalUseCase => getIt();

  @override
  void initState() {
    super.initState();
    final initial =
        widget.initialDraft ??
        const CollectionCreateDraft(
          name: '',
          iconKey: 'folder',
          accentColorHex: '#1152D4',
        );
    _nameController = TextEditingController(text: initial.name);
    _selectedIcon = initial.iconKey;
    _selectedIconEmoji = initial.iconEmoji;
    _selectedIconImagePath = initial.iconImagePath;
    _selectedColor = initial.accentColorHex;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.isEditing;
    final palette = context.appPalette;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark ? palette.background : _collectionCreateBg;

    return Scaffold(
      backgroundColor: background,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        top: true,
        child: Column(
          children: [
            _sheetHeader(context),
            Expanded(
              child: ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
                children: [
                  _ReferenceSectionTitle(
                    label: context.l10n.collectionEntryDetails,
                  ),
                  const SizedBox(height: 8),
                  _ReferenceTextField(
                    label: 'Collection name',
                    controller: _nameController,
                    onChanged: (_) => setState(() {}),
                    hintText: context.l10n.collectionsNameHint,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submit(),
                  ),
                  const SizedBox(height: 18),
                  _ReferenceSectionTitle(
                    label: context.l10n.collectionEntryIconSection,
                  ),
                  const SizedBox(height: 12),
                  _iconPickerCard(context),
                  const SizedBox(height: 18),
                  _ReferenceSectionTitle(
                    label: context.l10n.collectionsAccentColor,
                  ),
                  const SizedBox(height: 12),
                  _AccentSwatchWrap(
                    colors: _colorOptions,
                    selected: _selectedColor,
                    onSelected: (hex) => setState(() => _selectedColor = hex),
                    onCustomTap: () async {
                      final hex = await _showColorPickerDialog(context);
                      if (hex != null) {
                        setState(() => _selectedColor = hex);
                      }
                    },
                  ),
                  const SizedBox(height: 22),
                  _ReferenceSubmitButton(
                    label: isEditing
                        ? context.l10n.commonSave
                        : context.l10n.collectionsCreateTitle,
                    onPressed: _submit,
                  ),
                  const SizedBox(height: 6),
                  Center(
                    child: Text(
                      isEditing
                          ? 'Changes update this collection only'
                          : 'Cancelling rolls back · no partial collection created',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: _collectionCreateMono,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.7,
                        color: isDark
                            ? palette.textMuted
                            : _collectionCreateMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sheetHeader(BuildContext context) {
    final isEditing = widget.isEditing;
    final palette = context.appPalette;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 12),
      decoration: BoxDecoration(
        color: isDark ? palette.background : _collectionCreateBg,
        border: Border(
          bottom: BorderSide(
            color: isDark ? palette.stroke : _collectionCreateBorder,
          ),
        ),
      ),
      child: Row(
        children: [
          _HeaderTextAction(
            label: context.l10n.commonCancel,
            color: isDark ? palette.textSecondary : _collectionCreateMuted,
            alignment: Alignment.centerLeft,
            onTap: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Text(
              isEditing ? context.l10n.editCollection : 'New collection',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: _collectionCreateFont,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
                color: isDark ? palette.textPrimary : _collectionCreateInk,
              ),
            ),
          ),
          _HeaderTextAction(
            label: isEditing
                ? context.l10n.commonSave
                : _shortCreateActionLabel(context),
            color: isDark ? palette.textPrimary : _collectionCreateInk,
            alignment: Alignment.centerRight,
            fontWeight: FontWeight.w800,
            onTap: _submit,
          ),
        ],
      ),
    );
  }

  String _shortCreateActionLabel(BuildContext context) {
    final label = context.l10n.collectionsCreateTitle.trim();
    if (label.isEmpty) {
      return 'Create';
    }
    return label.split(RegExp(r'\s+')).first;
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.collectionsNameRequired)),
      );
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context).pop(
      CollectionCreateDraft(
        name: name,
        iconKey: _selectedIcon,
        iconEmoji: _selectedIconEmoji,
        iconImagePath: _selectedIconImagePath,
        accentColorHex: _selectedColor,
      ),
    );
  }

  Widget _iconPickerCard(BuildContext context) {
    final palette = context.appPalette;
    final accent = _colorFromHex(_selectedColor);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final previewTitle = _nameController.text.trim().isEmpty
        ? (widget.isEditing ? 'Collection' : 'New Collection')
        : _nameController.text.trim();
    final subtitle = _selectedIconImagePath?.trim().isNotEmpty == true
        ? context.l10n.collectionEntryLocalImageSelected
        : (_selectedIconEmoji?.trim().isNotEmpty == true
              ? context.l10n.collectionEntryEmojiSelected
              : collectionIconLabel(_selectedIcon));
    final hasCustomIcon =
        (_selectedIconEmoji ?? '').trim().isNotEmpty ||
        (_selectedIconImagePath ?? '').trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            buildCollectionLeadingIcon(
              context,
              iconKey: _selectedIcon,
              iconEmoji: _selectedIconEmoji,
              iconImagePath: _selectedIconImagePath,
              accent: accent,
              shellSize: 64,
              shellRadius: 18,
              iconSize: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                children: [
                  _IconModeStrip(
                    activeMode:
                        _selectedIconImagePath?.trim().isNotEmpty == true
                        ? _CollectionIconMode.photo
                        : _selectedIconEmoji?.trim().isNotEmpty == true
                        ? _CollectionIconMode.emoji
                        : _CollectionIconMode.search,
                    onSearch: _selectCollectionIcon,
                    onEmoji: _selectCollectionEmoji,
                    onPhoto: _pickCollectionIconImage,
                  ),
                  const SizedBox(height: 7),
                  Text(
                    context.l10n.collectionEntryBlockIconHint,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: _collectionCreateFont,
                      fontSize: 11.5,
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? palette.textMuted
                          : _collectionCreateMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(
            color: isDark ? palette.surfaceSoft : _collectionCreateSoft,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? palette.stroke : _collectionCreateBorder,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      text: TextSpan(
                        style: TextStyle(
                          fontFamily: _collectionCreateFont,
                          fontSize: 12.5,
                          height: 1.25,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? palette.textSecondary
                              : const Color(0xFF716A62),
                        ),
                        children: [
                          TextSpan(
                            text: previewTitle,
                            style: TextStyle(
                              color: isDark
                                  ? palette.textPrimary
                                  : _collectionCreateInk,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          TextSpan(text: ' · $subtitle'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (hasCustomIcon) ...[
                const SizedBox(width: 10),
                _InlineRemoveButton(
                  onTap: () {
                    setState(() {
                      _selectedIconEmoji = null;
                      _selectedIconImagePath = null;
                    });
                  },
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _selectCollectionIcon() async {
    final selected = await showCollectionIconSearchSheet(
      context,
      searchCompanyBrands: _searchCompanyBrandsUseCase,
      downloadCompanyLogoToLocal: _downloadCompanyLogoToLocalUseCase,
      initialQuery: _nameController.text.trim(),
    );
    if (selected == null || !selected.hasSelection || !mounted) {
      return;
    }
    setState(() {
      final iconKey = selected.iconKey?.trim();
      final iconImagePath = selected.imagePath?.trim();
      if ((iconKey ?? '').isNotEmpty) {
        _selectedIcon = iconKey!;
        _selectedIconEmoji = null;
        _selectedIconImagePath = null;
      } else if ((iconImagePath ?? '').isNotEmpty) {
        _selectedIconEmoji = null;
        _selectedIconImagePath = iconImagePath;
      }
    });
  }

  Future<void> _selectCollectionEmoji() async {
    final selected = await showCollectionEmojiPickerSheet(
      context,
      initialEmoji: _selectedIconEmoji ?? '',
    );
    if (!mounted) {
      return;
    }
    final trimmed = (selected ?? '').trim();
    if (trimmed.isEmpty) {
      return;
    }
    setState(() {
      _selectedIconEmoji = trimmed;
      _selectedIconImagePath = null;
    });
  }

  Future<void> _pickCollectionIconImage() async {
    final sourcePath = await _pickCollectionIconSourcePath();
    if ((sourcePath ?? '').trim().isEmpty || !mounted) {
      return;
    }

    final sourceFile = File(sourcePath!.trim());
    if (!await sourceFile.exists()) {
      return;
    }

    final persisted = await LocalAssetFileStore.copyIntoAppSupport(
      sourcePath: sourcePath,
      directoryName: 'collection_icons',
      fileNamePrefix:
          'collection_icon_${_fileNameStem(sourcePath.split(RegExp(r'[\\/]')).last)}',
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _selectedIconEmoji = null;
      _selectedIconImagePath = persisted ?? sourcePath;
    });
  }

  Future<String?> _pickCollectionIconSourcePath() async {
    if (Platform.isIOS || Platform.isAndroid) {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 95,
        maxWidth: 3200,
        maxHeight: 3200,
      );
      return image?.path;
    }

    final file = await openFile(
      acceptedTypeGroups: const [
        XTypeGroup(
          label: 'Images',
          extensions: ['jpg', 'jpeg', 'png', 'heic', 'webp'],
          uniformTypeIdentifiers: [
            'public.jpeg',
            'public.png',
            'public.heic',
            'org.webmproject.webp',
            'public.image',
          ],
        ),
      ],
    );
    return file?.path;
  }

  String _fileNameStem(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'image';
    final dot = trimmed.lastIndexOf('.');
    if (dot <= 0) return trimmed;
    return trimmed.substring(0, dot);
  }

  Future<String?> _showColorPickerDialog(BuildContext context) {
    return showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return _ColorPickerDialog(
          initialColor: _selectedColor,
          extendedColors: _extendedColors,
        );
      },
    );
  }
}

class _ColorPickerDialog extends StatefulWidget {
  const _ColorPickerDialog({
    required this.initialColor,
    required this.extendedColors,
  });

  final String initialColor;
  final List<String> extendedColors;

  @override
  State<_ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<_ColorPickerDialog> {
  late String _pickedHex;
  late TextEditingController _hexController;

  @override
  void initState() {
    super.initState();
    _pickedHex = widget.initialColor;
    _hexController = TextEditingController(text: _pickedHex);
  }

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }

  void _onHexFieldChanged(String value) {
    var hex = value.trim();
    if (!hex.startsWith('#')) {
      hex = '#$hex';
    }
    final normalized = hex.replaceAll('#', '');
    if (normalized.length == 6 && int.tryParse(normalized, radix: 16) != null) {
      setState(() {
        _pickedHex = '#${normalized.toUpperCase()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.l10n.collectionsPickColor,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: context.appPalette.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            // Color grid
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final hex in widget.extendedColors)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _pickedHex = hex;
                        _hexController.text = hex;
                      });
                    },
                    child: Container(
                      width: 38,
                      height: 38,
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _pickedHex == hex
                              ? collectionsPrimary
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: _colorFromHex(hex),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            // Hex input field
            Row(
              children: [
                // Preview circle
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _colorFromHex(_pickedHex),
                    shape: BoxShape.circle,
                    border: Border.all(color: context.appPalette.stroke),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _hexController,
                    onChanged: _onHexFieldChanged,
                    decoration: InputDecoration(
                      hintText: context.l10n.collectionsColorHint,
                      hintStyle: TextStyle(color: Color(0xFF9AAAAF)),
                      filled: true,
                      fillColor: context.appPalette.surface,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: collectionsCardBorder,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: collectionsCardBorder,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF9DB8F6),
                          width: 1.2,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Select button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(_pickedHex),
                style: ElevatedButton.styleFrom(
                  backgroundColor: collectionsPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Select',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderTextAction extends StatelessWidget {
  const _HeaderTextAction({
    required this.label,
    required this.color,
    required this.alignment,
    required this.onTap,
    this.fontWeight = FontWeight.w600,
  });

  final String label;
  final Color color;
  final Alignment alignment;
  final VoidCallback onTap;
  final FontWeight fontWeight;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: 88,
        height: 38,
        child: Align(
          alignment: alignment,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: _collectionCreateFont,
              fontSize: 15,
              fontWeight: fontWeight,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}

class _ReferenceSectionTitle extends StatelessWidget {
  const _ReferenceSectionTitle({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontFamily: _collectionCreateMono,
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 2.2,
        color: isDark ? context.appPalette.textMuted : _collectionCreateMuted,
      ),
    );
  }
}

class _ReferenceTextField extends StatelessWidget {
  const _ReferenceTextField({
    required this.label,
    required this.controller,
    required this.hintText,
    required this.onChanged,
    required this.textInputAction,
    required this.onSubmitted,
  });

  final String label;
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;
  final TextInputAction textInputAction;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: isDark ? palette.surface : Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: isDark ? palette.stroke : _collectionCreateBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontFamily: _collectionCreateMono,
              fontSize: 10,
              fontWeight: FontWeight.w500,
              letterSpacing: 1.8,
              color: isDark ? palette.textMuted : _collectionCreateMuted,
            ),
          ),
          const SizedBox(height: 5),
          TextField(
            controller: controller,
            onChanged: onChanged,
            textInputAction: textInputAction,
            onSubmitted: onSubmitted,
            style: TextStyle(
              fontFamily: _collectionCreateFont,
              fontSize: 20,
              height: 1.2,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.28,
              color: isDark ? palette.textPrimary : _collectionCreateInk,
            ),
            decoration: InputDecoration(
              isDense: true,
              border: InputBorder.none,
              hintText: hintText,
              hintStyle: TextStyle(
                fontFamily: _collectionCreateFont,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? palette.textMuted
                    : _collectionCreateMuted.withValues(alpha: 0.72),
              ),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReferenceSubmitButton extends StatelessWidget {
  const _ReferenceSubmitButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: isDark
              ? context.appPalette.primary
              : _collectionCreateInk,
          foregroundColor: isDark ? Colors.white : _collectionCreateBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: _collectionCreateFont,
            fontSize: 15.5,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.1,
          ),
        ),
      ),
    );
  }
}

enum _CollectionIconMode { search, emoji, photo }

class _IconModeStrip extends StatelessWidget {
  const _IconModeStrip({
    required this.activeMode,
    required this.onSearch,
    required this.onEmoji,
    required this.onPhoto,
  });

  final _CollectionIconMode activeMode;
  final VoidCallback onSearch;
  final VoidCallback onEmoji;
  final VoidCallback onPhoto;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? palette.surfaceSoft : _collectionCreateSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _IconModeTab(
            label: context.l10n.collectionEntrySearchIcon,
            active: activeMode == _CollectionIconMode.search,
            onTap: onSearch,
          ),
          _IconModeTab(
            label: context.l10n.collectionEntryUseEmoji,
            active: activeMode == _CollectionIconMode.emoji,
            onTap: onEmoji,
          ),
          _IconModeTab(
            label: context.l10n.collectionEntrySourcePhotos,
            active: activeMode == _CollectionIconMode.photo,
            onTap: onPhoto,
          ),
        ],
      ),
    );
  }
}

class _IconModeTab extends StatelessWidget {
  const _IconModeTab({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Material(
        color: active
            ? (isDark ? palette.surface : Colors.white)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(9),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(9),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 5),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: _collectionCreateFont,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: active
                    ? (isDark ? palette.textPrimary : _collectionCreateInk)
                    : (isDark ? palette.textMuted : _collectionCreateMuted),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InlineRemoveButton extends StatelessWidget {
  const _InlineRemoveButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Text(
          context.l10n.commonRemove,
          style: const TextStyle(
            fontFamily: _collectionCreateFont,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: _collectionCreateRisk,
          ),
        ),
      ),
    );
  }
}

class _AccentSwatchWrap extends StatelessWidget {
  const _AccentSwatchWrap({
    required this.colors,
    required this.selected,
    required this.onSelected,
    required this.onCustomTap,
  });

  final List<String> colors;
  final String selected;
  final ValueChanged<String> onSelected;
  final VoidCallback onCustomTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 11,
      children: [
        for (final hex in colors)
          _AccentSwatch(
            color: _colorFromHex(hex),
            active: selected == hex,
            onTap: () => onSelected(hex),
          ),
        _CustomAccentSwatch(onTap: onCustomTap),
      ],
    );
  }
}

class _AccentSwatch extends StatelessWidget {
  const _AccentSwatch({
    required this.color,
    required this.active,
    required this.onTap,
  });

  final Color color;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ringColor = isDark
        ? context.appPalette.textPrimary
        : _collectionCreateInk;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        width: 32,
        height: 32,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: active ? ringColor : Colors.transparent,
            width: 1.6,
          ),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: ringColor.withValues(alpha: 0.08),
                    blurRadius: 0,
                    spreadRadius: 3,
                  ),
                ]
              : const [],
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 0,
                spreadRadius: 0.5,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomAccentSwatch extends StatelessWidget {
  const _CustomAccentSwatch({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDark ? palette.surface : Colors.white,
          border: Border.all(
            color: isDark ? palette.stroke : _collectionCreateBorder,
            width: 1.3,
          ),
        ),
        child: Icon(
          Icons.add_rounded,
          size: 18,
          color: isDark ? palette.textMuted : _collectionCreateMuted,
        ),
      ),
    );
  }
}

Color _colorFromHex(String hex) {
  final normalized = hex.replaceAll('#', '').trim();
  final value = int.tryParse(normalized, radix: 16);
  if (value == null) {
    return collectionsPrimary;
  }
  return Color(0xFF000000 | value);
}
