import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:appflowy_editor/appflowy_editor.dart' hide Path;
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:pass_doc_manager/app/di/injection.dart';
import 'package:pass_doc_manager/app/presentation/widgets/adaptive_modal.dart';
import 'package:pass_doc_manager/app/theme/app_palette.dart';
import 'package:pass_doc_manager/core/extensions/local_file_type_extensions.dart';
import 'package:pass_doc_manager/core/utils/local_asset_file_store.dart';
import 'package:pass_doc_manager/core/utils/local_asset_path_resolver.dart';
import 'package:pass_doc_manager/core/utils/local_file_image_provider.dart';
import 'package:pass_doc_manager/domain/branding/usecases/download_company_logo_to_local.dart';
import 'package:pass_doc_manager/domain/branding/usecases/search_company_brands.dart';
import 'package:pass_doc_manager/domain/collections/entities/collection_block_metadata_keys.dart';
import 'package:pass_doc_manager/domain/collections/entities/collection_block_entity.dart';
import 'package:pass_doc_manager/domain/collections/entities/collection_block_type.dart';
import 'package:pass_doc_manager/domain/collections/entities/collection_checklist_item_entity.dart';
import 'package:pass_doc_manager/features/collections/presentation/cubit/collection_detail_cubit.dart';
import 'package:pass_doc_manager/features/collections/presentation/services/link_preview_service.dart';
import 'package:pass_doc_manager/features/documents/presentation/services/address_lookup_service.dart';
import 'package:pass_doc_manager/features/collections/presentation/widgets/collections_ui.dart';
import 'package:pass_doc_manager/features/collections/presentation/widgets/collection_block_icon_picker.dart';
import 'package:pass_doc_manager/features/collections/presentation/widgets/static_map_preview.dart';
import 'package:pass_doc_manager/features/documents/presentation/pages/document_file_preview_page.dart';
import 'package:pass_doc_manager/features/notes/presentation/support/note_appflowy_document_codec.dart';
import 'package:pass_doc_manager/features/notes/presentation/widgets/note_appflowy_inline_editor.dart';
import 'package:pass_doc_manager/features/notes/presentation/widgets/note_markdown_view.dart';
import 'package:pass_doc_manager/l10n/l10n.dart';

const _collectionNoteDocumentJsonKey = 'appflowy_document_json';

class CollectionBlockEntryPage extends StatefulWidget {
  const CollectionBlockEntryPage({
    super.key,
    required this.collectionId,
    this.parentBlockId,
    required this.type,
    this.initialBlock,
  });

  final String collectionId;
  final String? parentBlockId;
  final CollectionBlockType type;
  final CollectionBlockEntity? initialBlock;

  bool get isEdit => initialBlock != null;

  @override
  State<CollectionBlockEntryPage> createState() =>
      _CollectionBlockEntryPageState();
}

class _CollectionBlockEntryPageState extends State<CollectionBlockEntryPage> {
  final ImagePicker _imagePicker = ImagePicker();
  late final TextEditingController _titleController;
  late final TextEditingController _subtitleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _urlController;
  late final TextEditingController _domainController;
  late final TextEditingController _amountController;
  late final TextEditingController _locationController;
  late final TextEditingController _unitFloorController;
  late final TextEditingController _labelController;
  late final TextEditingController _categoryController;
  late final TextEditingController _valueController;
  late final TextEditingController _targetAmountController;
  late final TextEditingController _unitController;
  final FocusNode _noteEditorFocusNode = FocusNode();
  final FocusNode _noteTitleFocusNode = FocusNode();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  DateTime? _expiryDate;
  String _currencyCode = 'USD';
  String _category = 'General';
  String _securityLevel = 'Standard';
  String _fieldType = 'Short Text';
  String? _blockCustomIconKey;
  String? _blockCustomIconEmoji;
  String? _blockCustomIconImagePath;
  String? _pickedFilePath;
  String? _pickedFileName;
  String? _pickedFileTypeLabel;
  String? _pickedFileSizeLabel;
  int? _pickedFileBytes;
  bool _clearExistingFile = false;
  String? _linkPreviewImage;
  String? _linkPreviewTitle;
  String? _linkPreviewDescription;
  bool _linkPreviewLoading = false;
  EditorState? _noteEditorState;
  StreamSubscription<dynamic>? _noteEditorSubscription;
  bool _notePreviewMode = false;
  bool _noteFullscreen = false;
  bool _sectionDefaultCollapsed = true;
  bool _documentUploadDragging = false;
  Timer? _linkDebounce;
  Timer? _locationDebounce;
  AddressSuggestion? _selectedLocation;
  List<AddressSuggestion> _locationSuggestions = const [];
  bool _locationSearching = false;
  final List<_ChecklistDraftItem> _checklistItems = <_ChecklistDraftItem>[];
  bool _checklistSeeded = false;

  SearchCompanyBrands get _searchCompanyBrandsUseCase => getIt();
  DownloadCompanyLogoToLocal get _downloadCompanyLogoToLocalUseCase => getIt();

  @override
  void initState() {
    super.initState();
    final block = widget.initialBlock;
    _titleController = TextEditingController(text: block?.title ?? '');
    _subtitleController = TextEditingController(text: block?.subtitle ?? '');
    _descriptionController = TextEditingController(
      text: block?.description ?? '',
    );
    _urlController = TextEditingController(text: block?.url ?? '');
    _domainController = TextEditingController(text: block?.domainLabel ?? '');
    _amountController = TextEditingController(
      text: block?.amount == null ? '' : block!.amount!.toStringAsFixed(2),
    );
    _locationController = TextEditingController(
      text: block?.locationLabel ?? block?.metadata['location'] ?? '',
    );
    _unitFloorController = TextEditingController(
      text: block?.metadata['unit_floor'] ?? '',
    );
    _labelController = TextEditingController(
      text: block?.metadata['label'] ?? block?.title ?? '',
    );
    _valueController = TextEditingController(
      text: block?.metadata['value'] ?? block?.subtitle ?? '',
    );
    _targetAmountController = TextEditingController(
      text: block?.metadata['target_amount'] ?? '',
    );
    _unitController = TextEditingController(
      text: block?.metadata['unit'] ?? '',
    );
    if (widget.type == CollectionBlockType.progress &&
        block == null &&
        _unitController.text.trim().isEmpty) {
      _unitController.text = 'EUR';
    }
    _selectedDate = block?.eventAt;
    if (widget.type == CollectionBlockType.progress) {
      final storedDueDate = block?.metadata['due_date'];
      if (storedDueDate != null && storedDueDate.isNotEmpty) {
        _selectedDate = DateTime.tryParse(storedDueDate) ?? _selectedDate;
      }
    }
    if (block?.eventAt != null) {
      _selectedTime = TimeOfDay.fromDateTime(block!.eventAt!);
    } else if (widget.type == CollectionBlockType.reminder ||
        widget.type == CollectionBlockType.timeline) {
      final initialAt = widget.type == CollectionBlockType.reminder
          ? DateTime.now().add(const Duration(hours: 1))
          : DateTime.now();
      _selectedDate = initialAt;
      _selectedTime = TimeOfDay.fromDateTime(initialAt);
    }
    _expiryDate = block?.expiryDate;
    _currencyCode = block?.currencyCode ?? 'USD';
    _category = block?.metadata['category'] ?? _defaultCategory(widget.type);
    if (widget.type == CollectionBlockType.reminder) {
      _category = block?.repeatInterval ?? _category;
      if (_category == 'General') _category = 'none';
    }
    _categoryController = TextEditingController(
      text: block == null ? '' : _initialCategoryLabel(_category),
    );
    _securityLevel = block?.metadata['security_level'] ?? 'Standard';
    _fieldType = block?.metadata['field_type'] ?? 'Short Text';
    if (widget.type == CollectionBlockType.input &&
        block == null &&
        _inputTypeAllowsCopy(_fieldType)) {
      _securityLevel = 'Quick';
    }
    _sectionDefaultCollapsed =
        block?.metadata[CollectionBlockMetadataKeys.sectionDefaultCollapsed] !=
        'false';
    _blockCustomIconKey = block?.metadata[CollectionBlockMetadataKeys.iconKey];
    _blockCustomIconEmoji =
        block?.metadata[CollectionBlockMetadataKeys.iconEmoji];
    _blockCustomIconImagePath =
        block?.metadata[CollectionBlockMetadataKeys.iconImagePath];

    if ((widget.type == CollectionBlockType.document ||
            widget.type == CollectionBlockType.image ||
            widget.type == CollectionBlockType.timeline) &&
        block != null) {
      _primeExistingPickedFile(block);
    }

    if (block != null && block.checklistItems.isNotEmpty) {
      _checklistItems.addAll(
        block.checklistItems
            .map(
              (item) => _ChecklistDraftItem(
                id: item.id,
                title: item.title,
                isDone: item.isDone,
              ),
            )
            .toList(growable: false),
      );
    } else if (widget.type == CollectionBlockType.checklist) {
      // Seeded in didChangeDependencies where context is available.
    }

    if (widget.type == CollectionBlockType.link) {
      _urlController.addListener(_onUrlChanged);
      if (_urlController.text.trim().isNotEmpty) {
        _fetchLinkPreview(_urlController.text.trim());
      }
    }

    if (widget.type == CollectionBlockType.location) {
      _locationController.addListener(_onLocationChanged);
      // Restore existing location on edit
      if (widget.initialBlock != null) {
        final lat = widget.initialBlock!.latitude;
        final lon = widget.initialBlock!.longitude;
        if (lat != null && lon != null) {
          _selectedLocation = AddressSuggestion(
            displayName: widget.initialBlock!.locationLabel ?? '',
            latitude: lat,
            longitude: lon,
          );
        }
      }
    }

    if (widget.type == CollectionBlockType.note) {
      _initNoteEditor(block);
    }

    _titleController.addListener(_onBlockPreviewChanged);
    _descriptionController.addListener(_onBlockPreviewChanged);
    _categoryController.addListener(_onDocumentCategoryLabelChanged);
    _labelController.addListener(_onBlockPreviewChanged);
    _valueController.addListener(_onBlockPreviewChanged);
    _amountController.addListener(_onBlockPreviewChanged);
    _targetAmountController.addListener(_onBlockPreviewChanged);
    _unitController.addListener(_onBlockPreviewChanged);
    _locationController.addListener(_onBlockPreviewChanged);
    _noteTitleFocusNode.addListener(_onNoteTitleFocusChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_checklistSeeded &&
        widget.type == CollectionBlockType.checklist &&
        _checklistItems.isEmpty) {
      _checklistSeeded = true;
      _checklistItems.addAll([
        _ChecklistDraftItem(
          id: _nextChecklistId(),
          title: context.l10n.collectionEntryHintReminderExample,
          isDone: false,
        ),
        _ChecklistDraftItem(id: _nextChecklistId(), title: '', isDone: false),
      ]);
    }
  }

  void _initNoteEditor(CollectionBlockEntity? block) {
    final editorState = EditorState(document: _noteDocumentFromBlock(block));
    _noteEditorState = editorState;
    _syncNoteEditorToDescription();
    _noteEditorSubscription = editorState.transactionStream.listen((_) {
      _syncNoteEditorToDescription();
      _onBlockPreviewChanged();
    });
  }

  Document _noteDocumentFromBlock(CollectionBlockEntity? block) {
    final documentJson = block?.metadata[_collectionNoteDocumentJsonKey]
        ?.trim();
    if (documentJson != null && documentJson.isNotEmpty) {
      try {
        return Document.fromJson(
          Map<String, dynamic>.from(jsonDecode(documentJson) as Map),
        );
      } catch (_) {
        // Fall back to markdown below for legacy collection notes.
      }
    }

    final markdown = block?.description.trim() ?? '';
    if (markdown.isEmpty) {
      return Document.blank(withInitialText: true);
    }
    return markdownToDocument(markdown);
  }

  void _syncNoteEditorToDescription() {
    final editorState = _noteEditorState;
    if (editorState == null) return;
    final markdown = documentToMarkdown(
      editorState.document,
      lineBreak: '\n',
    ).trim();
    if (_descriptionController.text == markdown) return;
    _descriptionController.value = TextEditingValue(
      text: markdown,
      selection: TextSelection.collapsed(offset: markdown.length),
    );
  }

  void _onUrlChanged() {
    _linkDebounce?.cancel();
    _linkDebounce = Timer(const Duration(milliseconds: 800), () {
      _fetchLinkPreview(_urlController.text.trim());
    });
  }

  void _onBlockPreviewChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _onNoteTitleFocusChanged() {
    if (!mounted || widget.type != CollectionBlockType.note) return;
    setState(() {});
  }

  void _onDocumentCategoryLabelChanged() {
    final label = _categoryController.text.trim();
    _category = label.isEmpty ? 'Other' : label;
    _onBlockPreviewChanged();
  }

  Future<void> _fetchLinkPreview(String url) async {
    if (url.isEmpty) {
      setState(() {
        _linkPreviewImage = null;
        _linkPreviewTitle = null;
        _linkPreviewDescription = null;
        _linkPreviewLoading = false;
      });
      return;
    }
    var normalized = url;
    if (!normalized.startsWith('http://') &&
        !normalized.startsWith('https://')) {
      normalized = 'https://$normalized';
    }
    setState(() => _linkPreviewLoading = true);
    final data = await LinkPreviewService().fetch(normalized);
    if (!mounted) return;
    setState(() {
      _linkPreviewLoading = false;
      _linkPreviewImage = data?.imageUrl;
      _linkPreviewTitle = data?.title;
      _linkPreviewDescription = data?.description;
      if (data != null) {
        if (_titleController.text.trim().isEmpty && data.title.isNotEmpty) {
          _titleController.text = data.title;
        }
        if (_domainController.text.trim().isEmpty && data.domain.isNotEmpty) {
          _domainController.text = data.domain;
        }
      }
    });
  }

  void _onLocationChanged() {
    _locationDebounce?.cancel();
    // If user edits after selecting, clear the selection
    if (_selectedLocation != null &&
        _locationController.text.trim() != _selectedLocation!.displayName) {
      setState(() {
        _selectedLocation = null;
      });
    }
    _locationDebounce = Timer(const Duration(milliseconds: 600), () {
      _searchLocation(_locationController.text.trim());
    });
  }

  Future<void> _searchLocation(String query) async {
    if (query.length < 3) {
      setState(() {
        _locationSuggestions = const [];
        _locationSearching = false;
      });
      return;
    }
    setState(() => _locationSearching = true);
    final results = await AddressLookupService().search(query: query);
    if (!mounted) return;
    setState(() {
      _locationSearching = false;
      _locationSuggestions = results;
    });
  }

  void _selectLocation(AddressSuggestion suggestion) {
    _locationDebounce?.cancel();
    _locationController.removeListener(_onLocationChanged);
    setState(() {
      _selectedLocation = suggestion;
      _locationSuggestions = const [];
      _locationController.text = suggestion.displayName;
    });
    _locationController.addListener(_onLocationChanged);
  }

  @override
  void dispose() {
    _linkDebounce?.cancel();
    _locationDebounce?.cancel();
    if (widget.type == CollectionBlockType.link) {
      _urlController.removeListener(_onUrlChanged);
    }
    if (widget.type == CollectionBlockType.location) {
      _locationController.removeListener(_onLocationChanged);
    }
    _noteEditorSubscription?.cancel();
    _titleController.removeListener(_onBlockPreviewChanged);
    _descriptionController.removeListener(_onBlockPreviewChanged);
    _categoryController.removeListener(_onDocumentCategoryLabelChanged);
    _labelController.removeListener(_onBlockPreviewChanged);
    _valueController.removeListener(_onBlockPreviewChanged);
    _amountController.removeListener(_onBlockPreviewChanged);
    _targetAmountController.removeListener(_onBlockPreviewChanged);
    _unitController.removeListener(_onBlockPreviewChanged);
    _locationController.removeListener(_onBlockPreviewChanged);
    _noteTitleFocusNode.removeListener(_onNoteTitleFocusChanged);
    _titleController.dispose();
    _subtitleController.dispose();
    _descriptionController.dispose();
    _urlController.dispose();
    _domainController.dispose();
    _amountController.dispose();
    _locationController.dispose();
    _unitFloorController.dispose();
    _labelController.dispose();
    _categoryController.dispose();
    _valueController.dispose();
    _targetAmountController.dispose();
    _unitController.dispose();
    _noteEditorFocusNode.dispose();
    _noteTitleFocusNode.dispose();
    for (final item in _checklistItems) {
      item.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = _screenTitle(context, widget.type);
    final palette = context.appPalette;
    if (widget.type == CollectionBlockType.note && _noteFullscreen) {
      return _noteFullscreenScaffold(context, title);
    }
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: palette.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _entrySheetHeader(context, title),
            Expanded(
              child: ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding:
                    widget.type == CollectionBlockType.document ||
                        widget.type == CollectionBlockType.image ||
                        widget.type == CollectionBlockType.link ||
                        widget.type == CollectionBlockType.location ||
                        widget.type == CollectionBlockType.note ||
                        widget.type == CollectionBlockType.progress ||
                        widget.type == CollectionBlockType.reminder ||
                        widget.type == CollectionBlockType.timeline ||
                        widget.type == CollectionBlockType.folder ||
                        widget.type == CollectionBlockType.section ||
                        widget.type == CollectionBlockType.input
                    ? const EdgeInsets.fromLTRB(22, 0, 22, 22)
                    : widget.type == CollectionBlockType.checklist
                    ? const EdgeInsets.fromLTRB(22, 4, 22, 22)
                    : const EdgeInsets.fromLTRB(18, 16, 18, 22),
                children: _buildContent(),
              ),
            ),
            if (widget.type != CollectionBlockType.document &&
                widget.type != CollectionBlockType.image &&
                widget.type != CollectionBlockType.checklist &&
                widget.type != CollectionBlockType.link &&
                widget.type != CollectionBlockType.location &&
                widget.type != CollectionBlockType.note &&
                widget.type != CollectionBlockType.progress &&
                widget.type != CollectionBlockType.reminder &&
                widget.type != CollectionBlockType.timeline &&
                widget.type != CollectionBlockType.folder &&
                widget.type != CollectionBlockType.section &&
                widget.type != CollectionBlockType.input)
              DecoratedBox(
                decoration: BoxDecoration(
                  color: palette.background,
                  border: Border(
                    top: BorderSide(
                      color: palette.stroke.withValues(alpha: 0.65),
                    ),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  minimum: const EdgeInsets.fromLTRB(18, 12, 18, 16),
                  child: CollectionsPrimaryButton(
                    label: _saveButtonLabel(context, widget.type),
                    icon: _saveButtonIcon(widget.type),
                    onPressed: _save,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _noteFullscreenScaffold(BuildContext context, String title) {
    final editorState = _noteEditorState;
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final showFullscreenChrome =
        _notePreviewMode || !keyboardOpen || _noteTitleFocusNode.hasFocus;
    final showLargeTitle =
        showFullscreenChrome &&
        (_notePreviewMode || !keyboardOpen || _noteTitleFocusNode.hasFocus);
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: noteEditorPaper,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showFullscreenChrome) _noteFullscreenHeader(context, title),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeOutCubic,
              child: showLargeTitle
                  ? Padding(
                      key: const ValueKey('note-fullscreen-title'),
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
                      child: _noteFullscreenTitleField(),
                    )
                  : const SizedBox.shrink(
                      key: ValueKey('note-fullscreen-title-collapsed'),
                    ),
            ),
            if (showFullscreenChrome)
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
                child: _noteModeControls(compact: true),
              ),
            Expanded(
              child: editorState == null
                  ? const SizedBox.shrink()
                  : _notePreviewMode
                  ? SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
                      child: _notePreviewPane(borderless: true),
                    )
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final toolbarReserve = showFullscreenChrome
                            ? 74.0
                            : 10.0;
                        final editorHeight =
                            (constraints.maxHeight - toolbarReserve)
                                .clamp(260.0, double.infinity)
                                .toDouble();
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(6, 0, 6, 10),
                          child: NoteAppFlowyInlineEditor(
                            editorState: editorState,
                            focusNode: _noteEditorFocusNode,
                            assetDirectoryName: 'collection_note_assets',
                            fileNamePrefix: _titleController.text.trim().isEmpty
                                ? 'collection_note'
                                : _titleController.text.trim(),
                            minHeight: editorHeight,
                            autoFocus: !widget.isEdit,
                            borderless: true,
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _noteFullscreenHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 8),
      child: Row(
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => Navigator.of(context).maybePop(),
                style: TextButton.styleFrom(
                  foregroundColor: noteEditorMuted,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                ),
                child: Text(
                  context.l10n.commonCancel,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontSize: 17,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
                color: noteEditorInk,
              ),
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Exit full screen',
                    onPressed: () => setState(() => _noteFullscreen = false),
                    icon: const Icon(Icons.fullscreen_exit_rounded),
                    color: noteEditorInk,
                  ),
                  TextButton(
                    onPressed: _save,
                    style: TextButton.styleFrom(
                      foregroundColor: noteEditorInk,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 10,
                      ),
                    ),
                    child: Text(
                      context.l10n.commonDone,
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _noteFullscreenTitleField() {
    return TextField(
      controller: _titleController,
      focusNode: _noteTitleFocusNode,
      maxLines: null,
      textCapitalization: TextCapitalization.sentences,
      style: const TextStyle(
        fontFamily: 'Manrope',
        fontSize: 34,
        height: 1.05,
        letterSpacing: -1.0,
        fontWeight: FontWeight.w800,
        color: noteEditorInk,
      ),
      decoration: const InputDecoration(
        hintText: 'Title',
        hintStyle: TextStyle(
          fontFamily: 'Manrope',
          fontSize: 34,
          height: 1.05,
          letterSpacing: -1.0,
          fontWeight: FontWeight.w800,
          color: Color(0xFFB8B1A8),
        ),
        border: InputBorder.none,
        isCollapsed: true,
      ),
    );
  }

  Widget _entrySheetHeader(BuildContext context, String title) {
    final palette = context.appPalette;
    final usesReferenceHeader =
        widget.type == CollectionBlockType.document ||
        widget.type == CollectionBlockType.image ||
        widget.type == CollectionBlockType.checklist ||
        widget.type == CollectionBlockType.link ||
        widget.type == CollectionBlockType.location ||
        widget.type == CollectionBlockType.note ||
        widget.type == CollectionBlockType.progress ||
        widget.type == CollectionBlockType.reminder ||
        widget.type == CollectionBlockType.timeline ||
        widget.type == CollectionBlockType.folder ||
        widget.type == CollectionBlockType.section ||
        widget.type == CollectionBlockType.input;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.background,
        border: usesReferenceHeader
            ? null
            : Border(
                bottom: BorderSide(
                  color: palette.stroke.withValues(alpha: 0.7),
                ),
              ),
      ),
      child: Padding(
        padding: usesReferenceHeader
            ? const EdgeInsets.fromLTRB(22, 14, 22, 8)
            : const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Row(
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  style: TextButton.styleFrom(
                    foregroundColor: palette.textSecondary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                  ),
                  child: Text(
                    context.l10n.commonCancel,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: usesReferenceHeader
                          ? FontWeight.w500
                          : FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: usesReferenceHeader ? 16 : 17,
                  fontWeight: usesReferenceHeader
                      ? FontWeight.w700
                      : FontWeight.w900,
                  letterSpacing: -0.2,
                  color: palette.textPrimary,
                ),
              ),
            ),
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _save,
                  style: TextButton.styleFrom(
                    foregroundColor: usesReferenceHeader
                        ? palette.textPrimary
                        : collectionsPrimary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                  ),
                  child: Text(
                    _entryHeaderActionLabel(context),
                    style: TextStyle(
                      fontSize: usesReferenceHeader ? 15 : 17,
                      fontWeight: usesReferenceHeader
                          ? FontWeight.w700
                          : FontWeight.w900,
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

  String _entryHeaderActionLabel(BuildContext context) {
    return switch (widget.type) {
      CollectionBlockType.note => context.l10n.commonDone,
      CollectionBlockType.reminder =>
        context.l10n.collectionEntryScheduleReminder,
      _ => context.l10n.commonSave,
    };
  }

  List<Widget> _buildContent() {
    final sections = <Widget>[];

    if (widget.type == CollectionBlockType.document) {
      return _buildDocumentContent();
    }

    if (widget.type == CollectionBlockType.folder) {
      return _buildFolderContent();
    }

    if (widget.type == CollectionBlockType.section) {
      return _buildSectionContent();
    }

    if (widget.type == CollectionBlockType.image) {
      return _buildImageContent();
    }

    if (widget.type == CollectionBlockType.checklist) {
      return _buildChecklistContent();
    }

    if (widget.type == CollectionBlockType.note) {
      return _buildNoteContent();
    }

    if (widget.type == CollectionBlockType.link) {
      return _buildLinkContent();
    }

    if (widget.type == CollectionBlockType.location) {
      return _buildLocationContent();
    }

    if (widget.type == CollectionBlockType.reminder) {
      return _buildReminderContent();
    }

    if (widget.type == CollectionBlockType.progress) {
      return _buildProgressContent();
    }

    if (widget.type == CollectionBlockType.timeline) {
      return _buildTimelineEventContent();
    }

    if (widget.type == CollectionBlockType.input) {
      return _buildInputFieldContent();
    }

    if (_showsGenericBlockPreview(widget.type)) {
      sections.add(_genericBlockPreviewCard(widget.type));
      sections.add(const SizedBox(height: 16));
    }

    if (widget.type == CollectionBlockType.document ||
        widget.type == CollectionBlockType.image ||
        widget.type == CollectionBlockType.timeline) {
      if (_pickedFileName != null) {
        sections.add(_pickedFileCard());
      } else {
        sections.add(
          CollectionsDashedUploadZone(
            title: _uploadTitle(context, widget.type),
            subtitle: _uploadSubtitle(context, widget.type),
            buttonLabel: context.l10n.collectionEntrySelectFile,
            icon: _uploadIcon(widget.type),
            onTap: _pickFile,
            onFileDrop: _handleFileDrop,
          ),
        );
      }
      sections.add(const SizedBox(height: 16));
    }

    if (widget.type != CollectionBlockType.expense &&
        widget.type != CollectionBlockType.folder &&
        widget.type != CollectionBlockType.section) {
      sections.add(
        CollectionsSectionLabel(
          label: context.l10n.collectionEntryDocumentInfo,
        ),
      );
      sections.add(const SizedBox(height: 8));
    }

    if (widget.type != CollectionBlockType.folder &&
        widget.type != CollectionBlockType.section) {
      sections.addAll(_buildIconPickerSection(widget.type));
    }

    if (widget.type == CollectionBlockType.expense) {
      sections.add(
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(18, 28, 18, 26),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                context.appPalette.surfaceSoft,
                context.appPalette.surface,
              ],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 4, bottom: 11),
                    child: Text(
                      _currencySymbol(_currencyCode),
                      style: const TextStyle(
                        fontSize: 46 / 1.45,
                        fontWeight: FontWeight.w700,
                        color: collectionsPrimary,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 180,
                    child: TextField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 68 / 1.45,
                        fontWeight: FontWeight.w800,
                        color: context.appPalette.textPrimary,
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        hintText: '0.00',
                        hintStyle: TextStyle(
                          color: context.appPalette.textMuted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                context.l10n.collectionEntryTapToEnterAmount,
                style: TextStyle(
                  fontSize: 17 / 1.45,
                  fontWeight: FontWeight.w500,
                  color: context.appPalette.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
      sections.add(const SizedBox(height: 18));
      sections.add(
        CollectionsSectionLabel(label: context.l10n.collectionEntryDescription),
      );
      sections.add(const SizedBox(height: 8));
      sections.add(
        _textField(
          _titleController,
          context.l10n.collectionEntryWhatWasThisFor,
        ),
      );
      sections.add(const SizedBox(height: 16));
      sections.add(
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CollectionsSectionLabel(
                    label: context.l10n.collectionEntryCurrency,
                  ),
                  const SizedBox(height: 8),
                  _expenseCurrencyDropdown(),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CollectionsSectionLabel(
                    label: context.l10n.collectionEntryDate,
                  ),
                  const SizedBox(height: 8),
                  _dateField(_selectedDate, () async {
                    final selected = await _pickDate(_selectedDate);
                    if (selected != null) {
                      setState(() => _selectedDate = selected);
                    }
                  }),
                ],
              ),
            ),
          ],
        ),
      );
      sections.add(const SizedBox(height: 16));
      sections.add(
        CollectionsSectionLabel(label: context.l10n.collectionEntryCategory),
      );
      sections.add(const SizedBox(height: 8));
      sections.add(
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final option in const [
              _ExpenseCategoryOption(
                label: 'Transport',
                icon: Icons.directions_car_filled_rounded,
              ),
              _ExpenseCategoryOption(
                label: 'Food',
                icon: Icons.restaurant_rounded,
              ),
              _ExpenseCategoryOption(
                label: 'Shopping',
                icon: Icons.shopping_bag_rounded,
              ),
              _ExpenseCategoryOption(label: 'Rent', icon: Icons.home_rounded),
              _ExpenseCategoryOption(
                label: 'Other',
                icon: Icons.more_horiz_rounded,
              ),
            ])
              _expenseCategoryChip(
                label: _expenseCategoryLabel(context, option.label),
                icon: option.icon,
                active: _category == option.label,
                onTap: () => setState(() => _category = option.label),
              ),
          ],
        ),
      );
      sections.add(const SizedBox(height: 18));
      sections.add(
        CollectionsSectionLabel(label: context.l10n.collectionEntryReceipt),
      );
      sections.add(const SizedBox(height: 8));
      if (_pickedFileName != null) {
        sections.add(_pickedFileCard());
      } else {
        sections.add(
          CollectionsDashedUploadZone(
            title: context.l10n.collectionEntryUploadReceipt,
            subtitle: context.l10n.collectionEntryUploadReceiptHint,
            icon: Icons.add_a_photo_rounded,
            onTap: _pickFile,
          ),
        );
      }
      sections.add(const SizedBox(height: 10));
      return sections;
    }

    if (widget.type == CollectionBlockType.image) {
      sections.add(_label(context.l10n.collectionEntryTitle));
      sections.add(
        _textField(
          _titleController,
          context.l10n.collectionEntryHintImageTitle,
        ),
      );
      sections.add(const SizedBox(height: 12));
      sections.add(_label(context.l10n.collectionEntryNotes));
      sections.add(
        _multilineField(
          _descriptionController,
          context.l10n.collectionEntryHintImageNotes,
        ),
      );
      sections.add(const SizedBox(height: 12));
      sections.add(_label(context.l10n.collectionEntrySecurityLevel));
      sections.add(const SizedBox(height: 8));
      sections.add(
        Wrap(
          spacing: 8,
          children: [
            for (final level in const [
              'Standard',
              'Confidential',
              'Top Secret',
            ])
              _chip(
                label: level,
                active: _securityLevel == level,
                onTap: () => setState(() => _securityLevel = level),
              ),
          ],
        ),
      );
      return sections;
    }

    sections.add(_label(context.l10n.collectionEntryTitle));
    sections.add(
      _textField(_titleController, context.l10n.collectionEntryTitle),
    );
    sections.add(const SizedBox(height: 12));
    sections.add(_label(context.l10n.collectionEntryDescription));
    sections.add(
      _multilineField(
        _descriptionController,
        context.l10n.collectionEntryDescription,
      ),
    );
    return sections;
  }

  List<Widget> _buildDocumentContent() {
    return [
      const SizedBox(height: 4),
      if (_hasAttachedFile)
        _documentFilePreviewCard()
      else
        _documentUploadCard(),
      const SizedBox(height: 14),
      _documentSectionLabel(context.l10n.collectionEntryDetails),
      const SizedBox(height: 8),
      _documentDetailsGroup(),
      const SizedBox(height: 14),
      ..._buildIconPickerSection(CollectionBlockType.document),
    ];
  }

  List<Widget> _buildFolderContent() {
    return [
      const SizedBox(height: 4),
      _documentSectionLabel(context.l10n.collectionEntryIconSection),
      const SizedBox(height: 8),
      _folderSectionIconEditor(
        type: CollectionBlockType.folder,
        helperText: context.l10n.collectionEntryFolderIconHelp,
      ),
      const SizedBox(height: 14),
      _folderSectionQuickIconGrid(CollectionBlockType.folder),
      const SizedBox(height: 18),
      _documentSectionLabel(context.l10n.collectionEntryDetails),
      const SizedBox(height: 8),
      _folderSectionDetailsGroup(isSection: false),
      if (widget.isEdit) ...[const SizedBox(height: 14), _folderDeleteRow()],
    ];
  }

  List<Widget> _buildSectionContent() {
    return [
      const SizedBox(height: 4),
      _documentSectionLabel(context.l10n.collectionEntryIconSection),
      const SizedBox(height: 8),
      _folderSectionIconEditor(
        type: CollectionBlockType.section,
        helperText: context.l10n.collectionEntrySectionIconHelp,
      ),
      const SizedBox(height: 14),
      _folderSectionSearchPreview(),
      const SizedBox(height: 10),
      _folderSectionQuickIconGrid(CollectionBlockType.section),
      const SizedBox(height: 18),
      _documentSectionLabel(context.l10n.collectionEntryDetails),
      const SizedBox(height: 8),
      _folderSectionDetailsGroup(isSection: true),
    ];
  }

  Widget _folderSectionIconEditor({
    required CollectionBlockType type,
    required String helperText,
  }) {
    final displaySelection =
        type == CollectionBlockType.folder && !_blockIconSelection.hasSelection
        ? const CollectionBlockIconSelection(emoji: '📂')
        : _blockIconSelection;
    return CollectionBlockIconPicker(
      type: type,
      title: _titleController.text,
      placeholderTitle: widget.isEdit
          ? _screenTitle(context, type)
          : _entryTitle(context, type),
      selection: displaySelection,
      onSearchIcon: _selectBlockIconKey,
      onEmoji: _selectBlockEmoji,
      onPickImage: _pickBlockIconImage,
      onClear: _clearBlockIcon,
      helperText: helperText,
      showSelectionSummary: false,
    );
  }

  Widget _folderSectionSearchPreview() {
    final palette = context.appPalette;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: palette.surfaceSoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded, size: 18, color: palette.textMuted),
          const SizedBox(width: 9),
          Text(
            context.l10n.collectionEntrySectionIconSearchHint,
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: palette.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _folderSectionQuickIconGrid(CollectionBlockType type) {
    final icons = type == CollectionBlockType.folder
        ? const [
            '📁',
            '📂',
            '🗂️',
            '🗃️',
            '📋',
            '📑',
            '🗄️',
            '🪪',
            '📦',
            '📬',
            '📨',
            '📜',
            '🧾',
            '💼',
            '🏛️',
            '🏠',
          ]
        : const [
            '🏛️',
            '⚡',
            '💡',
            '🚿',
            '🔌',
            '🔥',
            '💧',
            '🌿',
            '🪴',
            '🪵',
            '🛠️',
            '🪛',
            '🗝️',
            '🔧',
          ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: icons.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: type == CollectionBlockType.folder ? 8 : 7,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemBuilder: (context, index) =>
          _folderSectionQuickIconButton(emoji: icons[index]),
    );
  }

  Widget _folderSectionQuickIconButton({required String emoji}) {
    final palette = context.appPalette;
    final normalized = normalizeCollectionEmoji(emoji);
    final selected =
        normalizeCollectionEmoji(_blockCustomIconEmoji) == normalized ||
        (widget.type == CollectionBlockType.folder &&
            !_blockIconSelection.hasSelection &&
            normalized == '📂');
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        setState(() {
          _blockCustomIconEmoji = normalized;
          _blockCustomIconKey = null;
          _blockCustomIconImagePath = null;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: selected ? palette.textPrimary : palette.surfaceSoft,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? palette.textPrimary : palette.stroke,
          ),
        ),
        alignment: Alignment.center,
        child: Text(normalized, style: const TextStyle(fontSize: 20)),
      ),
    );
  }

  Widget _folderSectionDetailsGroup({required bool isSection}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        color: context.appPalette.surfaceSoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          _reminderTextField(
            label: context.l10n.collectionEntryTitle,
            controller: _titleController,
            hint: isSection
                ? context.l10n.collectionEntryHintSectionName
                : context.l10n.collectionEntryHintFolderName,
            focused: true,
          ),
          _locationDetailDivider(),
          _reminderTextField(
            label: context.l10n.collectionEntryDescriptionOptional,
            controller: _descriptionController,
            hint: isSection
                ? context.l10n.collectionEntryHintSectionDesc
                : context.l10n.collectionEntryHintFolderDesc,
            maxLines: 3,
          ),
          if (isSection) ...[
            _locationDetailDivider(),
            _sectionDefaultStateField(),
          ],
        ],
      ),
    );
  }

  Widget _sectionDefaultStateField() {
    final palette = context.appPalette;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _inputFieldLabel(context.l10n.collectionEntryDefaultState),
              const SizedBox(height: 4),
              Text(
                _sectionDefaultCollapsed
                    ? context.l10n.collectionEntryCollapsed
                    : context.l10n.collectionEntryExpanded,
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.12,
                  color: palette.textPrimary,
                ),
              ),
            ],
          ),
        ),
        Switch.adaptive(
          value: _sectionDefaultCollapsed,
          activeThumbColor: palette.background,
          activeTrackColor: palette.textPrimary,
          onChanged: (value) =>
              setState(() => _sectionDefaultCollapsed = value),
        ),
      ],
    );
  }

  Widget _folderDeleteRow() {
    final palette = context.appPalette;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: _deleteFolderFromEdit,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Text(
                context.l10n.collectionEntryDeleteFolder,
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: palette.danger,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 18, color: palette.danger),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteFolderFromEdit() async {
    final block = widget.initialBlock;
    if (block == null || block.type != CollectionBlockType.folder) {
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.collectionEntryDeleteFolder),
        content: Text(block.title),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(context.l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              context.l10n.commonDelete,
              style: TextStyle(color: context.appPalette.danger),
            ),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) {
      return;
    }
    await context.read<CollectionDetailCubit>().deleteBlock(block.id);
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
  }

  List<Widget> _buildImageContent() {
    return [
      const SizedBox(height: 4),
      _imageHeroPreview(),
      const SizedBox(height: 14),
      _documentSectionLabel(context.l10n.collectionEntryDetails),
      const SizedBox(height: 8),
      _documentInlineTextField(
        label: context.l10n.collectionEntryTitle,
        controller: _titleController,
        hint: context.l10n.collectionEntryHintImageTitle,
        focused: true,
      ),
      const SizedBox(height: 10),
      _documentInlineTextField(
        label: context.l10n.collectionEntryDescriptionOptional,
        controller: _descriptionController,
        hint: context.l10n.collectionEntryHintImageNotes,
        minLines: 1,
        maxLines: 2,
        filled: true,
      ),
      const SizedBox(height: 14),
      ..._buildIconPickerSection(CollectionBlockType.image),
    ];
  }

  List<Widget> _buildChecklistContent() {
    return [
      _checklistTitleField(),
      const SizedBox(height: 18),
      _checklistStatsHeader(),
      const SizedBox(height: 12),
      _checklistEditorList(),
    ];
  }

  List<Widget> _buildNoteContent() {
    final editorState = _noteEditorState;
    return [
      const SizedBox(height: 8),
      _noteTitleField(),
      const SizedBox(height: 14),
      _noteModeControls(),
      const SizedBox(height: 14),
      if (editorState != null && !_notePreviewMode)
        NoteAppFlowyInlineEditor(
          editorState: editorState,
          focusNode: _noteEditorFocusNode,
          assetDirectoryName: 'collection_note_assets',
          fileNamePrefix: _titleController.text.trim().isEmpty
              ? 'collection_note'
              : _titleController.text.trim(),
          autoFocus: !widget.isEdit,
        )
      else
        _notePreviewPane(),
      const SizedBox(height: 20),
      ..._buildIconPickerSection(CollectionBlockType.note),
    ];
  }

  List<Widget> _buildLinkContent() {
    return [
      const SizedBox(height: 4),
      _documentSectionLabel(context.l10n.collectionEntryUrl),
      const SizedBox(height: 8),
      _inputInlineTextField(
        label: context.l10n.collectionEntryPasteOrType,
        controller: _urlController,
        hint: context.l10n.collectionEntryHintUrl,
        focused: true,
        mono: true,
        keyboardType: TextInputType.url,
        textInputAction: TextInputAction.go,
        minLines: 1,
        maxLines: 2,
      ),
      const SizedBox(height: 18),
      _documentSectionLabel(_linkPreviewSectionLabel),
      const SizedBox(height: 8),
      _linkPreviewCard(),
      const SizedBox(height: 14),
      _documentSectionLabel(context.l10n.collectionEntryDetails),
      const SizedBox(height: 8),
      _inputInlineTextField(
        label: context.l10n.collectionEntryTitleOverride,
        controller: _titleController,
        hint: context.l10n.collectionEntryHintAutoTitle,
        filled: true,
      ),
      const SizedBox(height: 8),
      _inputInlineTextField(
        label: context.l10n.collectionEntryNotes,
        controller: _descriptionController,
        hint: context.l10n.collectionEntryHintLinkDesc,
        minLines: 1,
        maxLines: 3,
        filled: true,
      ),
      const SizedBox(height: 20),
      ..._buildIconPickerSection(CollectionBlockType.link),
    ];
  }

  String get _linkPreviewSectionLabel {
    if (_linkPreviewLoading) return context.l10n.collectionEntryPreviewFetching;
    if (_linkPreviewTitle != null || _linkPreviewImage != null) {
      return context.l10n.collectionEntryPreviewFetched;
    }
    return context.l10n.collectionEntryPreviewLabel;
  }

  List<Widget> _buildLocationContent() {
    final hasSelectedLocation = _selectedLocation != null;
    return [
      const SizedBox(height: 4),
      _documentSectionLabel(context.l10n.collectionEntryLocationSearchSection),
      const SizedBox(height: 8),
      _locationSearchField(),
      if (_locationSearching) ...[
        const SizedBox(height: 12),
        _locationLoadingCard(),
      ] else if (_locationSuggestions.isNotEmpty) ...[
        const SizedBox(height: 10),
        _locationSuggestionsCard(),
      ],
      const SizedBox(height: 18),
      _documentSectionLabel(
        hasSelectedLocation
            ? context.l10n.collectionEntryLocationResultMap
            : context.l10n.collectionEntryLocationResult,
      ),
      const SizedBox(height: 8),
      _locationMapCard(),
      const SizedBox(height: 12),
      _locationDetailsGroup(),
      const SizedBox(height: 8),
      _locationHelpText(),
      const SizedBox(height: 20),
      ..._buildIconPickerSection(CollectionBlockType.location),
    ];
  }

  Widget _locationSearchField() {
    final palette = context.appPalette;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(13, 10, 13, 10),
      decoration: BoxDecoration(
        color: palette.surfaceSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.stroke.withValues(alpha: 0.55)),
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded, size: 23, color: palette.textMuted),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _locationController,
              keyboardType: TextInputType.streetAddress,
              textInputAction: TextInputAction.search,
              scrollPadding: const EdgeInsets.only(bottom: 180),
              onSubmitted: (value) => _searchLocation(value.trim()),
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 15,
                height: 1.2,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.12,
                color: palette.textPrimary,
              ),
              decoration: InputDecoration.collapsed(
                hintText: context.l10n.collectionEntryHintAddress,
                hintStyle: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: palette.textMuted,
                ),
              ),
            ),
          ),
          if (_locationSearching) ...[
            const SizedBox(width: 10),
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
    );
  }

  Widget _locationLoadingCard() {
    return _locationPanel(
      child: const SizedBox(
        height: 46,
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2.2),
          ),
        ),
      ),
    );
  }

  Widget _locationSuggestionsCard() {
    final palette = context.appPalette;
    return _locationPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
            child: _inputFieldLabel(
              context.l10n.collectionEntryLocationSuggestions,
            ),
          ),
          for (var i = 0; i < _locationSuggestions.length; i++) ...[
            InkWell(
              onTap: () => _selectLocation(_locationSuggestions[i]),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 11),
                child: Row(
                  children: [
                    Container(
                      width: 31,
                      height: 31,
                      decoration: BoxDecoration(
                        color: palette.primarySoft,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.place_rounded,
                        size: 17,
                        color: palette.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _locationSuggestions[i].displayName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 13,
                          height: 1.24,
                          fontWeight: FontWeight.w600,
                          color: palette.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (i < _locationSuggestions.length - 1)
              Divider(
                height: 1,
                indent: 55,
                color: palette.stroke.withValues(alpha: 0.65),
              ),
          ],
        ],
      ),
    );
  }

  Widget _locationPanel({required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.appPalette.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.appPalette.stroke),
      ),
      child: child,
    );
  }

  Widget _locationMapCard() {
    final palette = context.appPalette;
    final selected = _selectedLocation;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 154,
        width: double.infinity,
        decoration: BoxDecoration(
          color: palette.surfaceSoft,
          border: Border.all(color: palette.stroke),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (selected != null)
              StaticMapPreview(
                latitude: selected.latitude,
                longitude: selected.longitude,
                height: 154,
              )
            else
              _locationMapEmptyState(),
            if (selected != null) _locationMapPin(),
          ],
        ),
      ),
    );
  }

  Widget _locationMapEmptyState() {
    final palette = context.appPalette;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            palette.surfaceSoft,
            palette.surface,
            palette.primarySoft.withValues(alpha: 0.55),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.map_outlined, size: 32, color: palette.textMuted),
            const SizedBox(height: 8),
            Text(
              context.l10n.collectionEntryLocationNoResultSelected,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: palette.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _locationMapPin() {
    final palette = context.appPalette;
    return Center(
      child: Transform.translate(
        offset: const Offset(0, -11),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: palette.danger,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 14,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Icon(
            Icons.location_on_rounded,
            color: palette.background,
            size: 23,
          ),
        ),
      ),
    );
  }

  Widget _locationDetailsGroup() {
    final selected = _selectedLocation;
    final address = selected?.displayName ?? _locationController.text.trim();
    final latitude = selected?.latitude ?? widget.initialBlock?.latitude;
    final longitude = selected?.longitude ?? widget.initialBlock?.longitude;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        color: context.appPalette.surfaceSoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          _locationEditableDetailField(
            label: context.l10n.collectionEntryLocationLabelField,
            controller: _titleController,
            hint: _suggestedLocationTitle,
          ),
          _locationDetailDivider(),
          _locationReadOnlyDetailField(
            label: context.l10n.collectionEntryLocationAddressField,
            value: address.isEmpty
                ? context.l10n.collectionEntryHintAddress
                : address,
            muted: address.isEmpty,
          ),
          _locationDetailDivider(),
          Row(
            children: [
              Expanded(
                child: _locationReadOnlyDetailField(
                  label: context.l10n.collectionEntryLocationLatitude,
                  value: _formatCoordinate(latitude),
                  mono: true,
                  muted: latitude == null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _locationReadOnlyDetailField(
                  label: context.l10n.collectionEntryLocationLongitude,
                  value: _formatCoordinate(longitude),
                  mono: true,
                  muted: longitude == null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _locationEditableDetailField({
    required String label,
    required TextEditingController controller,
    required String hint,
  }) {
    final palette = context.appPalette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _inputFieldLabel(label),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          textInputAction: TextInputAction.next,
          scrollPadding: const EdgeInsets.only(bottom: 180),
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 15,
            height: 1.22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.12,
            color: palette.textPrimary,
          ),
          decoration: InputDecoration.collapsed(
            hintText: hint,
            hintStyle: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: palette.textMuted,
            ),
          ),
        ),
      ],
    );
  }

  Widget _locationReadOnlyDetailField({
    required String label,
    required String value,
    bool mono = false,
    bool muted = false,
  }) {
    final palette = context.appPalette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _inputFieldLabel(label),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: mono ? 'JetBrains Mono' : 'Manrope',
            fontSize: mono ? 13 : 13.5,
            height: 1.25,
            fontWeight: FontWeight.w600,
            letterSpacing: mono ? 0.35 : -0.04,
            color: muted ? palette.textMuted : palette.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _locationDetailDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Divider(
        height: 1,
        color: context.appPalette.stroke.withValues(alpha: 0.65),
      ),
    );
  }

  Widget _locationHelpText() {
    return Text(
      context.l10n.collectionEntryLocationMapsHelp,
      style: TextStyle(
        fontFamily: 'Manrope',
        fontSize: 11.5,
        height: 1.4,
        fontWeight: FontWeight.w500,
        color: context.appPalette.textMuted,
      ),
    );
  }

  String get _suggestedLocationTitle {
    final title = _titleController.text.trim();
    if (title.isNotEmpty) return title;
    final selected = _selectedLocation?.displayName.split(',').first.trim();
    if (selected != null && selected.isNotEmpty) return selected;
    final typed = _locationController.text.trim();
    if (typed.isNotEmpty) return typed.split(',').first.trim();
    return context.l10n.collectionEntryHintLocationLabel;
  }

  String _formatCoordinate(double? value) {
    if (value == null) return '-';
    return value.toStringAsFixed(4);
  }

  List<Widget> _buildReminderContent() {
    return [
      const SizedBox(height: 4),
      _reminderFieldGroup(),
      const SizedBox(height: 18),
      _documentSectionLabel(context.l10n.collectionEntryReminderWhen),
      const SizedBox(height: 8),
      _reminderDateTimeWheel(),
      const SizedBox(height: 18),
      _documentSectionLabel(context.l10n.collectionEntryReminderRepeat),
      const SizedBox(height: 8),
      _reminderRepeatChoices(),
      const SizedBox(height: 8),
      _reminderHelpText(),
      const SizedBox(height: 20),
      ..._buildIconPickerSection(CollectionBlockType.reminder),
    ];
  }

  Widget _reminderFieldGroup() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        color: context.appPalette.surfaceSoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          _reminderTextField(
            label: context.l10n.collectionEntryTitle,
            controller: _titleController,
            hint: context.l10n.collectionEntryReminderHintTitle,
            focused: true,
          ),
          _locationDetailDivider(),
          _reminderTextField(
            label: context.l10n.collectionEntryReminderNote,
            controller: _descriptionController,
            hint: context.l10n.collectionEntryReminderHintNote,
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _reminderTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    bool focused = false,
    int maxLines = 1,
  }) {
    final palette = context.appPalette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _inputFieldLabel(label),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          maxLines: maxLines,
          textInputAction: maxLines == 1 ? TextInputAction.next : null,
          scrollPadding: const EdgeInsets.only(bottom: 180),
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 15,
            height: 1.22,
            fontWeight: focused ? FontWeight.w800 : FontWeight.w600,
            letterSpacing: -0.12,
            color: palette.textPrimary,
          ),
          decoration: InputDecoration.collapsed(
            hintText: hint,
            hintStyle: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: palette.textMuted,
            ),
          ),
        ),
      ],
    );
  }

  Widget _reminderDateTimeWheel() {
    final palette = context.appPalette;
    final dateTime = _reminderDateTimeForDisplay;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: palette.surfaceSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.stroke.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: _reminderWheelColumn(
              values: _reminderDateWheelValues(dateTime),
              onTap: _pickReminderDate,
            ),
          ),
          _reminderWheelDivider(),
          Expanded(
            flex: 2,
            child: _reminderWheelColumn(
              values: _reminderHourWheelValues(dateTime),
              mono: true,
              onTap: _pickReminderTime,
            ),
          ),
          _reminderWheelDivider(),
          Expanded(
            flex: 2,
            child: _reminderWheelColumn(
              values: _reminderMinuteWheelValues(dateTime),
              mono: true,
              onTap: _pickReminderTime,
            ),
          ),
        ],
      ),
    );
  }

  Widget _reminderWheelColumn({
    required List<String> values,
    required VoidCallback onTap,
    bool mono = false,
  }) {
    final palette = context.appPalette;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < values.length; i++)
              Padding(
                padding: EdgeInsets.symmetric(vertical: i == 2 ? 5 : 3),
                child: Text(
                  values[i],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: mono ? 'JetBrains Mono' : 'Manrope',
                    fontSize: i == 2 ? 16 : 12,
                    height: 1.1,
                    fontWeight: i == 2 ? FontWeight.w800 : FontWeight.w600,
                    letterSpacing: mono ? 0.4 : -0.08,
                    color: i == 2
                        ? palette.textPrimary
                        : palette.textMuted.withValues(
                            alpha: i == 0 || i == 4 ? 0.55 : 0.82,
                          ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _reminderWheelDivider() {
    return Container(
      width: 1,
      height: 86,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      color: context.appPalette.stroke.withValues(alpha: 0.65),
    );
  }

  List<String> _reminderDateWheelValues(DateTime dateTime) {
    return [
      DateFormat(
        'EEE · d MMM',
      ).format(dateTime.subtract(const Duration(days: 2))),
      DateFormat(
        'EEE · d MMM',
      ).format(dateTime.subtract(const Duration(days: 1))),
      DateFormat('EEE · d MMM').format(dateTime),
      DateFormat('EEE · d MMM').format(dateTime.add(const Duration(days: 1))),
      DateFormat('EEE · d MMM').format(dateTime.add(const Duration(days: 2))),
    ];
  }

  List<String> _reminderHourWheelValues(DateTime dateTime) {
    final hour = dateTime.hour;
    return [
      _twoDigits((hour - 2) % 24),
      _twoDigits((hour - 1) % 24),
      _twoDigits(hour),
      _twoDigits((hour + 1) % 24),
      _twoDigits((hour + 2) % 24),
    ];
  }

  List<String> _reminderMinuteWheelValues(DateTime dateTime) {
    final minute = dateTime.minute;
    return [
      _twoDigits((minute - 30) % 60),
      _twoDigits((minute - 15) % 60),
      _twoDigits(minute),
      _twoDigits((minute + 15) % 60),
      _twoDigits((minute + 30) % 60),
    ];
  }

  Future<void> _pickReminderDate() async {
    final selected = await _pickDate(
      _selectedDate ?? _reminderDateTimeForDisplay,
    );
    if (selected != null) {
      setState(() => _selectedDate = selected);
    }
  }

  Future<void> _pickReminderTime() async {
    final selected = await _pickTime(
      _selectedTime ?? TimeOfDay.fromDateTime(_reminderDateTimeForDisplay),
    );
    if (selected != null) {
      setState(() => _selectedTime = selected);
    }
  }

  DateTime get _reminderDateTimeForDisplay {
    final fallback = DateTime.now().add(const Duration(hours: 1));
    final date = _selectedDate ?? fallback;
    final time = _selectedTime ?? TimeOfDay.fromDateTime(fallback);
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  String _twoDigits(int value) => value.toString().padLeft(2, '0');

  Widget _reminderRepeatChoices() {
    final options = const ['none', 'weekly', 'monthly', 'quarterly', 'yearly'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < options.length; i++) ...[
            _reminderRepeatChoice(options[i]),
            if (i < options.length - 1) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  Widget _reminderRepeatChoice(String option) {
    final palette = context.appPalette;
    final active =
        _category == option || (option == 'none' && _category == 'General');
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () => setState(() => _category = option),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: active ? palette.textPrimary : palette.surfaceSoft,
          borderRadius: BorderRadius.circular(999),
          border: active ? null : Border.all(color: palette.stroke),
        ),
        child: Text(
          _repeatLabel(context, option),
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.08,
            color: active ? palette.background : palette.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _reminderHelpText() {
    return Text(
      context.l10n.collectionEntryReminderSystemHelp,
      style: TextStyle(
        fontFamily: 'Manrope',
        fontSize: 11.5,
        height: 1.4,
        fontWeight: FontWeight.w500,
        color: context.appPalette.textMuted,
      ),
    );
  }

  List<Widget> _buildTimelineEventContent() {
    return [
      const SizedBox(height: 4),
      _timelineEventFieldGroup(),
      const SizedBox(height: 18),
      _documentSectionLabel(context.l10n.collectionEntryTimelineWhen),
      const SizedBox(height: 8),
      _timelineDateTimeWheel(),
      const SizedBox(height: 18),
      _documentSectionLabel(context.l10n.collectionEntryTimelineCategory),
      const SizedBox(height: 8),
      _timelineCategoryChoices(),
      const SizedBox(height: 14),
      _timelineLinkedPickerRow(),
      const SizedBox(height: 20),
      ..._buildIconPickerSection(CollectionBlockType.timeline),
    ];
  }

  Widget _timelineEventFieldGroup() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        color: context.appPalette.surfaceSoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          _reminderTextField(
            label: context.l10n.collectionEntryTimelineEvent,
            controller: _titleController,
            hint: context.l10n.collectionEntryHintEventTitle,
            focused: true,
          ),
          _locationDetailDivider(),
          _reminderTextField(
            label: context.l10n.collectionEntryTimelineNotes,
            controller: _descriptionController,
            hint: context.l10n.collectionEntryHintEventDesc,
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _timelineDateTimeWheel() {
    final palette = context.appPalette;
    final dateTime = _timelineDateTimeForDisplay;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: palette.surfaceSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.stroke.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: _reminderWheelColumn(
              values: _reminderDateWheelValues(dateTime),
              onTap: _pickTimelineDate,
            ),
          ),
          _reminderWheelDivider(),
          Expanded(
            flex: 2,
            child: _reminderWheelColumn(
              values: _reminderHourWheelValues(dateTime),
              mono: true,
              onTap: _pickTimelineTime,
            ),
          ),
          _reminderWheelDivider(),
          Expanded(
            flex: 2,
            child: _reminderWheelColumn(
              values: _reminderMinuteWheelValues(dateTime),
              mono: true,
              onTap: _pickTimelineTime,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickTimelineDate() async {
    final selected = await _pickDate(
      _selectedDate ?? _timelineDateTimeForDisplay,
    );
    if (selected != null) {
      setState(() => _selectedDate = selected);
    }
  }

  Future<void> _pickTimelineTime() async {
    final selected = await _pickTime(
      _selectedTime ?? TimeOfDay.fromDateTime(_timelineDateTimeForDisplay),
    );
    if (selected != null) {
      setState(() => _selectedTime = selected);
    }
  }

  DateTime get _timelineDateTimeForDisplay {
    final fallback = DateTime.now();
    final date = _selectedDate ?? fallback;
    final time = _selectedTime ?? TimeOfDay.fromDateTime(fallback);
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Widget _timelineCategoryChoices() {
    final options = const ['Trip', 'Admin', 'Property', 'Health', 'Work'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < options.length; i++) ...[
            _timelineCategoryChoice(options[i]),
            if (i < options.length - 1) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  Widget _timelineCategoryChoice(String option) {
    final palette = context.appPalette;
    final active = _category == option;
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () => setState(() => _category = option),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: active ? palette.textPrimary : palette.surfaceSoft,
          borderRadius: BorderRadius.circular(999),
          border: active ? null : Border.all(color: palette.stroke),
        ),
        child: Text(
          _timelineCategoryLabel(context, option),
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.08,
            color: active ? palette.background : palette.textSecondary,
          ),
        ),
      ),
    );
  }

  String _timelineCategoryLabel(BuildContext context, String option) {
    return switch (option) {
      'Trip' => context.l10n.collectionEntryTimelineCategoryTrip,
      'Admin' => context.l10n.collectionEntryTimelineCategoryAdmin,
      'Property' => context.l10n.collectionEntryTimelineCategoryProperty,
      'Health' => context.l10n.collectionEntryTimelineCategoryHealth,
      'Work' => context.l10n.collectionEntryTimelineCategoryWork,
      _ => option,
    };
  }

  Widget _timelineLinkedPickerRow() {
    final palette = context.appPalette;
    final linked = _locationController.text.trim();
    final hasLinked = linked.isNotEmpty;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: _showTimelineLinkedSheet,
      child: Ink(
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
        decoration: BoxDecoration(
          color: palette.surfaceSoft,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: palette.stroke.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _inputFieldLabel(context.l10n.collectionEntryTimelineLinked),
                  const SizedBox(height: 5),
                  Text(
                    hasLinked
                        ? linked
                        : context.l10n.collectionEntryTimelineLinkedPlaceholder,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 14.5,
                      height: 1.2,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.12,
                      color: hasLinked
                          ? palette.textPrimary
                          : palette.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: palette.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showTimelineLinkedSheet() async {
    final controller = TextEditingController(
      text: _locationController.text.trim(),
    );
    try {
      final result = await showAdaptiveModal<String>(
        context: context,
        backgroundColor: context.appPalette.surface,
        builder: (sheetContext) {
          final palette = sheetContext.appPalette;
          return SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                18,
                8,
                18,
                18 + MediaQuery.viewInsetsOf(sheetContext).bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: palette.stroke,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          sheetContext
                              .l10n
                              .collectionEntryTimelineLinkedSheetTitle,
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.25,
                            color: palette.textPrimary,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        child: Text(sheetContext.l10n.commonCancel),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) =>
                        Navigator.of(sheetContext).pop(controller.text.trim()),
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: palette.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText:
                          sheetContext.l10n.collectionEntryTimelineLinkedHint,
                      filled: true,
                      fillColor: palette.surfaceSoft,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: palette.stroke),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: palette.stroke),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: palette.textPrimary,
                          width: 1.4,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  CollectionsPrimaryButton(
                    label: sheetContext.l10n.commonSave,
                    icon: Icons.check_rounded,
                    onPressed: () =>
                        Navigator.of(sheetContext).pop(controller.text.trim()),
                  ),
                ],
              ),
            ),
          );
        },
      );
      if (!mounted || result == null) return;
      setState(() {
        _locationController.text = result.trim();
      });
    } finally {
      controller.dispose();
    }
  }

  List<Widget> _buildProgressContent() {
    return [
      const SizedBox(height: 4),
      _progressTitleField(),
      const SizedBox(height: 14),
      _progressAmountDisplay(),
      const SizedBox(height: 12),
      _progressSlider(),
      const SizedBox(height: 18),
      _documentSectionLabel(context.l10n.collectionEntryProgressValues),
      const SizedBox(height: 8),
      _progressValuesGroup(),
      const SizedBox(height: 18),
      _documentSectionLabel(context.l10n.collectionEntryProgressType),
      const SizedBox(height: 8),
      _progressTypeChoices(),
      const SizedBox(height: 20),
      ..._buildIconPickerSection(CollectionBlockType.progress),
    ];
  }

  Widget _progressTitleField() {
    final palette = context.appPalette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _inputFieldLabel(context.l10n.collectionEntryTitle),
        const SizedBox(height: 5),
        TextField(
          controller: _titleController,
          scrollPadding: const EdgeInsets.only(bottom: 180),
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 22,
            height: 1.12,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
            color: palette.textPrimary,
          ),
          decoration: InputDecoration.collapsed(
            hintText: context.l10n.collectionEntryProgressHintTitle,
            hintStyle: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 22,
              height: 1.12,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
              color: palette.textMuted,
            ),
          ),
        ),
      ],
    );
  }

  Widget _progressAmountDisplay() {
    final palette = context.appPalette;
    final current = _progressCurrentValue;
    final target = _progressTargetValue;
    final percentage = _progressRatio;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.collectionEntryProgressCurrentOf(
            _formatProgressAmount(target),
          ),
          style: TextStyle(
            fontFamily: 'JetBrains Mono',
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.4,
            color: palette.textMuted,
          ),
        ),
        const SizedBox(height: 4),
        RichText(
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          text: TextSpan(
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 44,
              height: 1.02,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.6,
              color: palette.textPrimary,
            ),
            children: [
              TextSpan(text: _formatProgressAmount(current)),
              TextSpan(
                text: ' · ${(percentage * 100).round()}%',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.5,
                  color: palette.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _progressSlider() {
    final palette = context.appPalette;
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 5,
        activeTrackColor: palette.textPrimary,
        inactiveTrackColor: palette.stroke.withValues(alpha: 0.75),
        thumbColor: palette.textPrimary,
        overlayColor: palette.textPrimary.withValues(alpha: 0.08),
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
      ),
      child: Slider(value: _progressRatio, onChanged: _setProgressRatio),
    );
  }

  Widget _progressValuesGroup() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        color: context.appPalette.surfaceSoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _progressNumberField(
                  label: context.l10n.collectionEntryProgressCurrent,
                  controller: _amountController,
                  hint: '0',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _progressTextField(
                  label: context.l10n.collectionEntryProgressUnit,
                  controller: _unitController,
                  hint: 'EUR',
                  mono: true,
                ),
              ),
            ],
          ),
          _locationDetailDivider(),
          Row(
            children: [
              Expanded(
                child: _progressNumberField(
                  label: context.l10n.collectionEntryProgressTarget,
                  controller: _targetAmountController,
                  hint: '0',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: _progressDueField()),
            ],
          ),
          _locationDetailDivider(),
          _progressTextField(
            label: context.l10n.collectionEntryNotesOptional,
            controller: _descriptionController,
            hint: context.l10n.collectionEntryProgressHintDesc,
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _progressNumberField({
    required String label,
    required TextEditingController controller,
    required String hint,
  }) {
    return _progressTextField(
      label: label,
      controller: controller,
      hint: hint,
      mono: true,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
    );
  }

  Widget _progressTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    bool mono = false,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    final palette = context.appPalette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _inputFieldLabel(label),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          scrollPadding: const EdgeInsets.only(bottom: 180),
          style: TextStyle(
            fontFamily: mono ? 'JetBrains Mono' : 'Manrope',
            fontSize: mono ? 14 : 14.5,
            height: 1.22,
            fontWeight: FontWeight.w700,
            letterSpacing: mono ? 0.25 : -0.08,
            color: palette.textPrimary,
          ),
          decoration: InputDecoration.collapsed(
            hintText: hint,
            hintStyle: TextStyle(
              fontFamily: mono ? 'JetBrains Mono' : 'Manrope',
              fontSize: mono ? 14 : 14.5,
              fontWeight: FontWeight.w600,
              color: palette.textMuted,
            ),
          ),
        ),
      ],
    );
  }

  Widget _progressDueField() {
    final palette = context.appPalette;
    final value = _selectedDate == null
        ? context.l10n.collectionEntryOptional
        : DateFormat('d MMM').format(_selectedDate!);
    return InkWell(
      onTap: _pickProgressDueDate,
      borderRadius: BorderRadius.circular(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _inputFieldLabel(context.l10n.collectionEntryProgressDue),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 14.5,
              height: 1.22,
              fontWeight: FontWeight.w700,
              color: _selectedDate == null
                  ? palette.textMuted
                  : palette.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickProgressDueDate() async {
    final selected = await _pickDate(_selectedDate);
    if (selected != null) {
      setState(() => _selectedDate = selected);
    }
  }

  Widget _progressTypeChoices() {
    final options = const ['currency', 'quantity', 'distance', 'custom'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < options.length; i++) ...[
            _progressTypeChoice(options[i]),
            if (i < options.length - 1) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  Widget _progressTypeChoice(String type) {
    final palette = context.appPalette;
    final active = _progressType == type;
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () => _setProgressType(type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: active ? palette.textPrimary : palette.surfaceSoft,
          borderRadius: BorderRadius.circular(999),
          border: active ? null : Border.all(color: palette.stroke),
        ),
        child: Text(
          _progressTypeLabel(type),
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.08,
            color: active ? palette.background : palette.textSecondary,
          ),
        ),
      ),
    );
  }

  double get _progressCurrentValue => _parseAmount(_amountController.text) ?? 0;

  double get _progressTargetValue =>
      _parseAmount(_targetAmountController.text) ?? 0;

  double get _progressRatio {
    final target = _progressTargetValue;
    if (target <= 0) return 0;
    return (_progressCurrentValue / target).clamp(0.0, 1.0).toDouble();
  }

  void _setProgressRatio(double value) {
    final target = _progressTargetValue;
    if (target <= 0) return;
    final current = target * value;
    setState(() {
      _amountController.text = _trimProgressNumber(current);
    });
  }

  String _formatProgressAmount(double value) {
    final formatted = _trimProgressNumber(value);
    final unit = _unitController.text.trim();
    if (unit == r'$' || unit == '€' || unit == '£') {
      return '$unit$formatted';
    }
    if (unit == 'USD') return '\$$formatted';
    if (unit == 'EUR') return '€$formatted';
    if (unit == 'GBP') return '£$formatted';
    if (unit == '%') return '$formatted%';
    if (unit.isEmpty) return formatted;
    return '$formatted $unit';
  }

  String _trimProgressNumber(double value) {
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
  }

  String get _progressType {
    final unit = _unitController.text.trim();
    if (const ['EUR', 'USD', 'GBP', r'$', '€', '£'].contains(unit)) {
      return 'currency';
    }
    if (const ['km', 'mi', 'm'].contains(unit.toLowerCase())) {
      return 'distance';
    }
    if (unit.isEmpty || const ['pts', 'hrs', 'kg', '%'].contains(unit)) {
      return 'quantity';
    }
    return 'custom';
  }

  void _setProgressType(String type) {
    setState(() {
      _unitController.text = switch (type) {
        'currency' => 'EUR',
        'distance' => 'km',
        'quantity' => '',
        _ =>
          _unitController.text.trim().isEmpty
              ? context.l10n.collectionEntryProgressCustomUnit
              : _unitController.text.trim(),
      };
    });
  }

  String _progressTypeLabel(String type) {
    final l = context.l10n;
    return switch (type) {
      'currency' => l.collectionEntryProgressTypeCurrency,
      'quantity' => l.collectionEntryProgressTypeQuantity,
      'distance' => l.collectionEntryProgressTypeDistance,
      _ => l.collectionEntryProgressTypeCustom,
    };
  }

  Widget _noteTitleField() {
    final palette = context.appPalette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _inputFieldLabel(context.l10n.collectionEntryTitle),
        const SizedBox(height: 4),
        TextField(
          controller: _titleController,
          focusNode: _noteTitleFocusNode,
          scrollPadding: const EdgeInsets.only(bottom: 180),
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 22,
            height: 1.15,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
            color: palette.textPrimary,
          ),
          decoration: InputDecoration.collapsed(
            hintText: context.l10n.collectionEntryHintNoteTitle,
            hintStyle: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: palette.textMuted,
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildInputFieldContent() {
    return [
      const SizedBox(height: 4),
      _documentSectionLabel(context.l10n.collectionEntryInputTypeSection),
      const SizedBox(height: 8),
      _inputTypeChoiceRow(),
      const SizedBox(height: 18),
      _documentSectionLabel(context.l10n.collectionEntryInputFieldSection),
      const SizedBox(height: 8),
      _inputInlineTextField(
        label: context.l10n.collectionEntryLabel,
        controller: _labelController,
        hint: context.l10n.collectionEntryHintFieldLabel,
        focused: true,
      ),
      const SizedBox(height: 8),
      _inputInlineTextField(
        label: context.l10n.collectionEntryValue,
        controller: _valueController,
        hint: context.l10n.collectionEntryHintFieldValue,
        keyboardType: _inputValueKeyboardType(_fieldType),
        mono: _fieldType != 'Short Text',
      ),
      const SizedBox(height: 8),
      _inputPreviewCopyField(),
      const SizedBox(height: 8),
      _inputCopyHelpText(),
      const SizedBox(height: 20),
      ..._buildIconPickerSection(CollectionBlockType.input),
    ];
  }

  Widget _inputTypeChoiceRow() {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final type in const [
          'Short Text',
          'Number',
          'Date',
          'Phone',
          'URL',
        ])
          _inputTypeChip(type),
      ],
    );
  }

  Widget _inputTypeChip(String type) {
    final palette = context.appPalette;
    final active = _fieldType == type;
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () => _setInputFieldType(type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: active ? palette.textPrimary : palette.surfaceSoft,
          borderRadius: BorderRadius.circular(999),
          border: active ? null : Border.all(color: palette.stroke),
        ),
        child: Text(
          _fieldTypeLabel(context, type),
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.05,
            color: active ? palette.background : palette.textSecondary,
          ),
        ),
      ),
    );
  }

  void _setInputFieldType(String type) {
    setState(() {
      _fieldType = type;
      _securityLevel = _inputTypeAllowsCopy(type) ? 'Quick' : 'Standard';
    });
  }

  Widget _inputInlineTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    bool focused = false,
    bool filled = false,
    bool mono = false,
    int minLines = 1,
    int maxLines = 1,
    TextInputAction textInputAction = TextInputAction.next,
    TextInputType? keyboardType,
  }) {
    final palette = context.appPalette;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
      decoration: BoxDecoration(
        color: focused && !filled ? palette.surface : palette.surfaceSoft,
        borderRadius: BorderRadius.circular(12),
        border: focused
            ? Border.all(color: palette.textPrimary, width: 1.5)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _inputFieldLabel(label),
          const SizedBox(height: 4),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            minLines: minLines,
            maxLines: maxLines,
            textInputAction: textInputAction,
            scrollPadding: const EdgeInsets.only(bottom: 180),
            style: TextStyle(
              fontFamily: mono ? 'JetBrains Mono' : 'Manrope',
              fontSize: mono ? 13.5 : 15,
              height: 1.2,
              fontWeight: FontWeight.w600,
              letterSpacing: mono ? 0.45 : -0.12,
              color: palette.textPrimary,
            ),
            decoration: InputDecoration.collapsed(
              hintText: hint,
              hintStyle: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: palette.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputPreviewCopyField() {
    final palette = context.appPalette;
    final value = _valueController.text.trim();
    final hasValue = value.isNotEmpty;
    final preview = hasValue
        ? _formatInputPreview(value)
        : context.l10n.collectionEntryHintFieldValue;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: hasValue ? () => _copyInputPreview(value) : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
        decoration: BoxDecoration(
          color: palette.surfaceSoft,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _inputFieldLabel(context.l10n.collectionEntryInputPreviewCopy),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    preview,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 12.5,
                      height: 1.2,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.45,
                      color: hasValue ? palette.textPrimary : palette.textMuted,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.copy_rounded,
                  size: 18,
                  color: hasValue
                      ? palette.textSecondary
                      : palette.textMuted.withValues(alpha: 0.65),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _noteModeControls({bool compact = false}) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: compact ? 42 : 46,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: noteEditorChip,
              borderRadius: BorderRadius.circular(compact ? 16 : 18),
              border: Border.all(color: const Color(0xFFE7E0D7)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _noteModeSegment(
                    label: 'Edit',
                    selected: !_notePreviewMode,
                    onTap: () {
                      setState(() => _notePreviewMode = false);
                      _noteEditorFocusNode.requestFocus();
                    },
                  ),
                ),
                Expanded(
                  child: _noteModeSegment(
                    label: 'Preview',
                    selected: _notePreviewMode,
                    onTap: () {
                      _syncNoteEditorToDescription();
                      setState(() => _notePreviewMode = true);
                      FocusScope.of(context).unfocus();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        if (!_noteFullscreen) ...[
          const SizedBox(width: 10),
          Material(
            color: noteEditorChip,
            borderRadius: BorderRadius.circular(compact ? 16 : 18),
            child: InkWell(
              onTap: () {
                _syncNoteEditorToDescription();
                FocusScope.of(context).unfocus();
                setState(() => _noteFullscreen = true);
              },
              borderRadius: BorderRadius.circular(compact ? 16 : 18),
              child: SizedBox(
                height: compact ? 42 : 46,
                width: compact ? 42 : 48,
                child: const Icon(
                  Icons.fullscreen_rounded,
                  size: 22,
                  color: noteEditorInk,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _noteModeSegment({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: selected ? Colors.white : Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: selected ? noteEditorInk : noteEditorMuted,
            ),
          ),
        ),
      ),
    );
  }

  Widget _notePreviewPane({bool borderless = false}) {
    final markdown = _descriptionController.text.trim();
    final child = NoteMarkdownView(
      markdown: markdown,
      emptyLabel: 'Nothing to preview yet.',
      style: NoteMarkdownViewStyle.reference,
    );
    if (borderless) return child;
    return Container(
      constraints: const BoxConstraints(minHeight: 360),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
      decoration: BoxDecoration(
        color: noteEditorPaper,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE8E1D8)),
      ),
      child: child,
    );
  }

  Widget _inputFieldLabel(String label) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontFamily: 'JetBrains Mono',
        fontSize: 9.5,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.25,
        color: context.appPalette.textMuted,
      ),
    );
  }

  Widget _inputCopyHelpText() {
    return Text(
      context.l10n.collectionEntryInputCopyHelp,
      style: TextStyle(
        fontFamily: 'Manrope',
        fontSize: 11.5,
        height: 1.4,
        fontWeight: FontWeight.w500,
        color: context.appPalette.textMuted,
      ),
    );
  }

  String _formatInputPreview(String value) {
    final compact = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (compact.length <= 24) return compact;
    return '${compact.substring(0, 20)}…';
  }

  Future<void> _copyInputPreview(String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.commonCopied)));
  }

  TextInputType _inputValueKeyboardType(String fieldType) {
    return switch (fieldType) {
      'Number' => const TextInputType.numberWithOptions(decimal: true),
      'Phone' => TextInputType.phone,
      'URL' => TextInputType.url,
      _ => TextInputType.text,
    };
  }

  bool _inputTypeAllowsCopy(String fieldType) {
    return switch (fieldType) {
      'Short Text' || 'Number' || 'Phone' || 'URL' => true,
      _ => false,
    };
  }

  Future<String?> _persistFileFromPath({
    required String sourcePath,
    String? displayName,
    String fileNamePrefix = 'collection_block',
  }) async {
    final sourceName = (displayName ?? sourcePath.split(RegExp(r'[\\/]')).last)
        .trim();
    final stem = _fileNameStem(sourceName);
    final prefix = stem.isEmpty ? fileNamePrefix : '${fileNamePrefix}_$stem';
    return LocalAssetFileStore.copyIntoAppSupport(
      sourcePath: sourcePath,
      directoryName: 'collection_block_assets',
      fileNamePrefix: prefix,
    );
  }

  void _showUnableToSaveLocalFile() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Unable to save selected file locally.')),
    );
  }

  String _fileNameStem(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '';
    final dot = trimmed.lastIndexOf('.');
    if (dot <= 0) return trimmed;
    return trimmed.substring(0, dot);
  }

  Future<void> _pickFile() async {
    if (widget.type == CollectionBlockType.image) {
      final imageFile = await _pickImageBlockFile();
      if (imageFile == null || !mounted) return;

      final fileBytes = await imageFile.length();
      final typeLabel = imageFile.path.inferFileTypeLabel();
      final persisted = await _persistFileFromPath(
        sourcePath: imageFile.path,
        displayName: imageFile.name,
        fileNamePrefix: 'collection_image',
      );
      if (!mounted) return;
      if (persisted == null) {
        _showUnableToSaveLocalFile();
        return;
      }

      _seedDocumentTitleFromFileName(imageFile.name);
      setState(() {
        _pickedFilePath = persisted;
        _pickedFileName = imageFile.name;
        _pickedFileTypeLabel = typeLabel;
        _pickedFileSizeLabel = null;
        _pickedFileBytes = fileBytes;
        _clearExistingFile = false;
      });
      return;
    }

    final typeGroup = switch (widget.type) {
      CollectionBlockType.document => const XTypeGroup(
        label: 'Documents & Images',
        extensions: [
          'pdf',
          'doc',
          'docx',
          'txt',
          'rtf',
          'xls',
          'xlsx',
          'jpg',
          'jpeg',
          'png',
          'heic',
          'webp',
        ],
        uniformTypeIdentifiers: [
          'com.adobe.pdf',
          'org.openxmlformats.wordprocessingml.document',
          'com.microsoft.word.doc',
          'public.plain-text',
          'public.rtf',
          'org.openxmlformats.spreadsheetml.sheet',
          'com.microsoft.excel.xls',
          'public.jpeg',
          'public.png',
          'public.heic',
          'org.webmproject.webp',
          'public.image',
        ],
      ),
      CollectionBlockType.image => const XTypeGroup(
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
      _ => const XTypeGroup(
        label: 'All Files',
        extensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png', 'heic'],
        uniformTypeIdentifiers: [
          'com.adobe.pdf',
          'org.openxmlformats.wordprocessingml.document',
          'public.jpeg',
          'public.png',
          'public.heic',
          'public.image',
        ],
      ),
    };
    final file = await openFile(acceptedTypeGroups: [typeGroup]);
    if (file == null || !mounted) return;

    final fileBytes = await file.length();
    final typeLabel = file.path.inferFileTypeLabel();

    // Persist to permanent storage
    final persisted = await _persistFileFromPath(
      sourcePath: file.path,
      displayName: file.name,
      fileNamePrefix: widget.type == CollectionBlockType.image
          ? 'collection_image'
          : 'collection_document',
    );
    if (!mounted) return;
    if (persisted == null) {
      _showUnableToSaveLocalFile();
      return;
    }

    _seedDocumentTitleFromFileName(file.name);
    setState(() {
      _pickedFilePath = persisted;
      _pickedFileName = file.name;
      _pickedFileTypeLabel = typeLabel;
      _pickedFileSizeLabel = null;
      _pickedFileBytes = fileBytes;
      _clearExistingFile = false;
    });
  }

  Future<XFile?> _pickImageBlockFile() async {
    final imageTypeGroup = const XTypeGroup(
      label: 'Images',
      extensions: ['jpg', 'jpeg', 'png', 'heic', 'webp'],
      uniformTypeIdentifiers: [
        'public.jpeg',
        'public.png',
        'public.heic',
        'org.webmproject.webp',
        'public.image',
      ],
    );

    if (!(Platform.isIOS || Platform.isAndroid)) {
      return openFile(acceptedTypeGroups: [imageTypeGroup]);
    }

    final source = await showAdaptiveModal<_ImageBlockSource>(
      context: context,
      backgroundColor: context.appPalette.surface,
      builder: (sheetContext) {
        final palette = sheetContext.appPalette;
        final l10n = sheetContext.l10n;
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: palette.stroke,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 16),
                _ImageSourceActionTile(
                  icon: Icons.photo_library_outlined,
                  label: l10n.commonChooseFromGallery,
                  onTap: () =>
                      Navigator.of(sheetContext).pop(_ImageBlockSource.gallery),
                ),
                const SizedBox(height: 10),
                _ImageSourceActionTile(
                  icon: Icons.folder_open_rounded,
                  label: l10n.commonBrowseFiles,
                  onTap: () =>
                      Navigator.of(sheetContext).pop(_ImageBlockSource.files),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || source == null) return null;

    switch (source) {
      case _ImageBlockSource.gallery:
        return _imagePicker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 95,
          maxWidth: 3200,
          maxHeight: 3200,
        );
      case _ImageBlockSource.files:
        return openFile(acceptedTypeGroups: [imageTypeGroup]);
    }
  }

  Future<void> _pickDocumentImage(ImageSource source) async {
    if (!(Platform.isIOS || Platform.isAndroid)) {
      await _pickFile();
      return;
    }

    final imageFile = await _imagePicker.pickImage(
      source: source,
      imageQuality: 95,
      maxWidth: 3200,
      maxHeight: 3200,
    );
    if (imageFile == null || !mounted) return;

    final fileBytes = await imageFile.length();
    final typeLabel = imageFile.path.inferFileTypeLabel();
    final persisted = await _persistFileFromPath(
      sourcePath: imageFile.path,
      displayName: imageFile.name,
      fileNamePrefix: 'collection_image',
    );
    if (!mounted) return;
    if (persisted == null) {
      _showUnableToSaveLocalFile();
      return;
    }

    _seedDocumentTitleFromFileName(imageFile.name);
    setState(() {
      _pickedFilePath = persisted;
      _pickedFileName = imageFile.name;
      _pickedFileTypeLabel = typeLabel;
      _pickedFileSizeLabel = null;
      _pickedFileBytes = fileBytes;
      _clearExistingFile = false;
    });
  }

  Future<void> _handleFileDrop(String path) async {
    final file = File(path);
    if (!await file.exists() || !mounted) return;

    final fileBytes = await file.length();
    final typeLabel = path.inferFileTypeLabel();
    final persisted = await _persistFileFromPath(
      sourcePath: path,
      displayName: path.split(Platform.pathSeparator).last,
      fileNamePrefix: 'collection_document',
    );
    if (!mounted) return;
    if (persisted == null) {
      _showUnableToSaveLocalFile();
      return;
    }

    _seedDocumentTitleFromFileName(path.split(Platform.pathSeparator).last);
    setState(() {
      _pickedFilePath = persisted;
      _pickedFileName = path.split(Platform.pathSeparator).last;
      _pickedFileTypeLabel = typeLabel;
      _pickedFileSizeLabel = null;
      _pickedFileBytes = fileBytes;
      _clearExistingFile = false;
    });
  }

  Future<void> _pickBlockIconImage() async {
    final sourcePath = await _pickBlockIconImageSourcePath();
    if ((sourcePath ?? '').trim().isEmpty || !mounted) return;

    final sourceFile = File(sourcePath!.trim());
    if (!await sourceFile.exists()) return;

    final persisted = await _persistFileFromPath(
      sourcePath: sourcePath,
      displayName: sourcePath.split(Platform.pathSeparator).last,
      fileNamePrefix: 'collection_icon',
    );
    if (!mounted) return;
    if (persisted == null) {
      _showUnableToSaveLocalFile();
      return;
    }
    setState(() {
      _blockCustomIconImagePath = persisted;
      _blockCustomIconKey = null;
      _blockCustomIconEmoji = null;
    });
  }

  Future<String?> _pickBlockIconImageSourcePath() async {
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

  Future<void> _selectBlockIconKey() async {
    final selected = await showCollectionIconSearchSheet(
      context,
      searchCompanyBrands: _searchCompanyBrandsUseCase,
      downloadCompanyLogoToLocal: _downloadCompanyLogoToLocalUseCase,
      initialQuery: _titleController.text.trim(),
    );
    if (selected == null || !selected.hasSelection || !mounted) return;
    setState(() {
      _blockCustomIconKey = selected.iconKey?.trim();
      _blockCustomIconEmoji = selected.emoji?.trim();
      _blockCustomIconImagePath = selected.imagePath?.trim();
    });
  }

  Future<void> _selectBlockEmoji() async {
    final selected = await showCollectionEmojiPickerSheet(
      context,
      initialEmoji: _blockCustomIconEmoji ?? '',
    );
    if (!mounted) return;
    final trimmed = (selected ?? '').trim();
    if (trimmed.isEmpty) {
      return;
    }
    setState(() {
      _blockCustomIconEmoji = trimmed;
      _blockCustomIconKey = null;
      _blockCustomIconImagePath = null;
    });
  }

  void _clearBlockIcon() {
    setState(() {
      _blockCustomIconKey = null;
      _blockCustomIconEmoji = null;
      _blockCustomIconImagePath = null;
    });
  }

  List<Widget> _buildIconPickerSection(CollectionBlockType type) {
    return [
      CollectionsSectionLabel(label: context.l10n.collectionEntryChooseIcon),
      const SizedBox(height: 8),
      CollectionBlockIconPicker(
        type: type,
        title: _titleController.text,
        placeholderTitle: widget.isEdit
            ? _screenTitle(context, type)
            : _entryTitle(context, type),
        selection: _blockIconSelection,
        onSearchIcon: _selectBlockIconKey,
        onEmoji: _selectBlockEmoji,
        onPickImage: _pickBlockIconImage,
        onClear: _clearBlockIcon,
      ),
      const SizedBox(height: 16),
    ];
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Widget _linkPreviewCard() {
    final palette = context.appPalette;
    if (_linkPreviewLoading) {
      return _linkPreviewShell(
        padding: const EdgeInsets.all(16),
        child: const Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.4),
          ),
        ),
      );
    }

    final domain =
        (_domainController.text.trim().isNotEmpty
                ? _domainController.text.trim()
                : _deriveDomain(_urlController.text))
            ?.replaceFirst(RegExp(r'^www\.'), '') ??
        context.l10n.collectionEntryUrl;
    final title = (_linkPreviewTitle?.trim().isNotEmpty ?? false)
        ? _linkPreviewTitle!.trim()
        : (_titleController.text.trim().isNotEmpty
              ? _titleController.text.trim()
              : context.l10n.collectionEntryPreviewLabel);
    final description = (_linkPreviewDescription?.trim().isNotEmpty ?? false)
        ? _linkPreviewDescription!.trim()
        : (_descriptionController.text.trim().isNotEmpty
              ? _descriptionController.text.trim()
              : context.l10n.collectionEntryPreviewHint);

    return _linkPreviewShell(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          _linkPreviewThumb(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  domain,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.45,
                    color: palette.textMuted,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 13.5,
                    height: 1.2,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.05,
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 11.5,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                    color: palette.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _linkPreviewShell({
    required EdgeInsetsGeometry padding,
    required Widget child,
  }) {
    final palette = context.appPalette;
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.stroke),
      ),
      child: child,
    );
  }

  Widget _linkPreviewThumb() {
    final palette = context.appPalette;
    final imageUrl = _linkPreviewImage;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 56,
        height: 56,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (imageUrl != null && imageUrl.isNotEmpty)
              Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _linkPreviewThumbFallback(),
              )
            else
              _linkPreviewThumbFallback(),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-0.4, -0.4),
                  radius: 0.8,
                  colors: [
                    palette.surface.withValues(alpha: 0.55),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _linkPreviewThumbFallback() {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [context.appPalette.primarySoft, context.appPalette.stroke],
        ),
      ),
      child: Icon(
        Icons.link_rounded,
        size: 24,
        color: context.appPalette.primary,
      ),
    );
  }

  Widget _pickedFileCard() {
    return CollectionsSurfaceCard(
      radius: 18,
      padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: context.appPalette.surfaceSoft,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.description_rounded,
              size: 22,
              color: collectionsPrimary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _displayFileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: context.appPalette.textPrimary,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  [
                    _currentFileTypeLabel,
                    _currentFileSizeLabel,
                  ].where((s) => s.isNotEmpty).join(' • '),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: context.appPalette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _removePickedFile,
            icon: Icon(
              Icons.close_rounded,
              size: 20,
              color: context.appPalette.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  CollectionBlockIconSelection get _blockIconSelection =>
      CollectionBlockIconSelection(
        iconKey: _blockCustomIconKey,
        emoji: _blockCustomIconEmoji,
        imagePath: _blockCustomIconImagePath,
      );

  bool _showsGenericBlockPreview(CollectionBlockType type) {
    return switch (type) {
      CollectionBlockType.document => false,
      CollectionBlockType.expense => false,
      CollectionBlockType.link => false,
      CollectionBlockType.location => false,
      _ => true,
    };
  }

  Widget _genericBlockPreviewCard(CollectionBlockType type) {
    final palette = context.appPalette;
    final title = _draftPreviewTitle(type);
    final subtitle = _draftPreviewSubtitle(type);
    return CollectionsSurfaceCard(
      radius: 22,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Row(
        children: [
          buildCollectionBlockLeadingIcon(
            context,
            type: type,
            metadata: _blockIconSelection.toMetadata(),
            shellSize: 54,
            shellRadius: 17,
            iconSize: 25,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.25,
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.28,
                    fontWeight: FontWeight.w600,
                    color: palette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _draftPreviewTitle(CollectionBlockType type) {
    final primary = switch (type) {
      CollectionBlockType.input => _labelController.text.trim(),
      CollectionBlockType.location => _locationController.text.trim(),
      _ => _titleController.text.trim(),
    };
    if (primary.isNotEmpty) return primary;
    return widget.isEdit
        ? _screenTitle(context, type)
        : _entryTitle(context, type);
  }

  String _draftPreviewSubtitle(CollectionBlockType type) {
    return switch (type) {
      CollectionBlockType.folder =>
        _descriptionController.text.trim().isEmpty
            ? context.l10n.collectionEntryHintFolderDesc
            : _descriptionController.text.trim(),
      CollectionBlockType.section =>
        _descriptionController.text.trim().isEmpty
            ? context.l10n.collectionEntryHintSectionDesc
            : _descriptionController.text.trim(),
      CollectionBlockType.note =>
        _descriptionController.text.trim().isEmpty
            ? context.l10n.collectionEntryHintNoteContent
            : _descriptionController.text.trim(),
      CollectionBlockType.input =>
        _valueController.text.trim().isEmpty
            ? context.l10n.collectionEntryHintFieldValue
            : _valueController.text.trim(),
      CollectionBlockType.checklist => context.l10n.collectionEntryItemsCount(
        _checklistItems.length,
      ),
      CollectionBlockType.image =>
        _pickedFileName == null
            ? context.l10n.collectionEntryUploadImageHint
            : _displayFileName,
      CollectionBlockType.timeline =>
        _selectedDate == null
            ? context.l10n.collectionEntryDateTime
            : DateFormat('MMM d, y').format(_selectedDate!),
      CollectionBlockType.reminder =>
        _selectedDate == null
            ? context.l10n.collectionEntryReminderDateTime
            : DateFormat('MMM d, y').format(_selectedDate!),
      CollectionBlockType.progress =>
        _targetAmountController.text.trim().isEmpty
            ? context.l10n.collectionEntryProgressTarget
            : '${_amountController.text.trim().isEmpty ? '0' : _amountController.text.trim()} / ${_targetAmountController.text.trim()}',
      _ => _descriptionController.text.trim(),
    };
  }

  Widget _label(String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        value,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: context.appPalette.textPrimary,
        ),
      ),
    );
  }

  Widget _textField(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      scrollPadding: const EdgeInsets.only(bottom: 132),
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: context.appPalette.textPrimary,
      ),
      decoration: _inputDecoration(hint),
    );
  }

  Widget _multilineField(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      scrollPadding: const EdgeInsets.only(bottom: 156),
      minLines: 4,
      maxLines: 6,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: context.appPalette.textPrimary,
      ),
      decoration: _inputDecoration(hint),
    );
  }

  Widget _dateField(DateTime? value, VoidCallback onTap) {
    final label = value == null
        ? 'MM/DD/YYYY'
        : DateFormat('MM/dd/yyyy').format(value);
    final muted = value == null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: InputDecorator(
        decoration: _inputDecoration(
          '',
        ).copyWith(suffixIcon: Icon(Icons.calendar_today_rounded, size: 22)),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: muted
                ? context.appPalette.textMuted
                : context.appPalette.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _chip({
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active ? collectionsPrimary : context.appPalette.surfaceSoft,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: active ? collectionsPrimary : context.appPalette.stroke,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: active ? Colors.white : context.appPalette.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _expenseCurrencyDropdown() {
    const values = <String>['USD', 'EUR', 'GBP'];
    final safeValue = values.contains(_currencyCode) ? _currencyCode : 'USD';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: context.appPalette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.appPalette.stroke),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: safeValue,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: context.appPalette.textSecondary,
          ),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: context.appPalette.textPrimary,
          ),
          items: [
            for (final item in values)
              DropdownMenuItem<String>(
                value: item,
                child: Text(_currencyLabel(item)),
              ),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() => _currencyCode = value);
            }
          },
        ),
      ),
    );
  }

  Widget _expenseCategoryChip({
    required String label,
    required IconData icon,
    required bool active,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: active ? collectionsPrimary : context.appPalette.surfaceSoft,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: active ? collectionsPrimary : context.appPalette.stroke,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: active ? Colors.white : context.appPalette.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 16 / 1.45,
                fontWeight: FontWeight.w700,
                color: active ? Colors.white : context.appPalette.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _checklistTitleField() {
    final palette = context.appPalette;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.collectionEntryTitle.toUpperCase(),
            style: TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: 10,
              fontWeight: FontWeight.w500,
              letterSpacing: 1.2,
              color: palette.textMuted,
            ),
          ),
          const SizedBox(height: 5),
          TextField(
            controller: _titleController,
            scrollPadding: const EdgeInsets.only(bottom: 140),
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 22,
              height: 1.12,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
              color: palette.textPrimary,
            ),
            decoration: InputDecoration.collapsed(
              hintText: context.l10n.collectionEntryHintChecklist,
              hintStyle: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: palette.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _checklistStatsHeader() {
    final palette = context.appPalette;
    final total = _checklistItems.length;
    final done = _checklistItems.where((item) => item.isDone).length;
    final progress = total == 0 ? 0.0 : done / total;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                context.l10n.collectionEntryChecklistItemsSummary(total, done),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1.2,
                  color: palette.textMuted,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              context.l10n.collectionEntryChecklistReorder,
              style: TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
                color: palette.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 4,
            value: progress,
            backgroundColor: palette.surfaceSoft,
            valueColor: AlwaysStoppedAnimation<Color>(palette.textPrimary),
          ),
        ),
      ],
    );
  }

  Widget _checklistEditorList() {
    return Column(
      children: [
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          proxyDecorator: (child, index, animation) {
            return AnimatedBuilder(
              animation: animation,
              builder: (context, child) {
                final value = Curves.easeOut.transform(animation.value);
                return Transform.rotate(
                  angle: -0.006 * value,
                  child: Material(
                    color: Colors.transparent,
                    elevation: 10 * value,
                    shadowColor: Colors.black.withValues(alpha: 0.20),
                    borderRadius: BorderRadius.circular(12),
                    child: child,
                  ),
                );
              },
              child: child,
            );
          },
          itemCount: _checklistItems.length,
          onReorder: _reorderChecklistItems,
          itemBuilder: (context, index) {
            final item = _checklistItems[index];
            return Padding(
              key: ValueKey(item.id),
              padding: EdgeInsets.only(
                bottom: index == _checklistItems.length - 1 ? 0 : 8,
              ),
              child: _checklistEditRow(item, index),
            );
          },
        ),
        const SizedBox(height: 8),
        _addChecklistItemTile(),
      ],
    );
  }

  void _reorderChecklistItems(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _checklistItems.removeAt(oldIndex);
      _checklistItems.insert(newIndex, item);
    });
  }

  Widget _checklistEditRow(_ChecklistDraftItem item, int index) {
    final palette = context.appPalette;
    return AnimatedBuilder(
      animation: item.focusNode,
      builder: (context, _) {
        final focused = item.focusNode.hasFocus;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(
            color: focused ? palette.surface : palette.surfaceSoft,
            borderRadius: BorderRadius.circular(12),
            boxShadow: focused
                ? [
                    BoxShadow(
                      color: palette.textPrimary.withValues(alpha: 0.16),
                      blurRadius: 0,
                      spreadRadius: 1.5,
                    ),
                  ]
                : const [],
          ),
          child: Row(
            children: [
              ReorderableDragStartListener(
                index: index,
                child: _checklistDragHandle(),
              ),
              const SizedBox(width: 10),
              _checklistToggle(item),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: item.controller,
                  focusNode: item.focusNode,
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => setState(() {}),
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 14,
                    height: 1.2,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.1,
                    color: item.isDone
                        ? palette.textMuted
                        : palette.textPrimary,
                    decoration: item.isDone
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                    decorationColor: palette.textMuted,
                    decorationThickness: 1.4,
                  ),
                  decoration: InputDecoration.collapsed(
                    hintText: context.l10n.collectionEntryHintChecklistItem,
                    hintStyle: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: palette.textMuted,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _checklistDeleteButton(item),
            ],
          ),
        );
      },
    );
  }

  Widget _checklistDragHandle() {
    final color = context.appPalette.textMuted;
    return SizedBox(
      width: 14,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _checklistHandleLine(color, 14),
          const SizedBox(height: 3),
          _checklistHandleLine(color, 10),
          const SizedBox(height: 3),
          _checklistHandleLine(color, 14),
        ],
      ),
    );
  }

  Widget _checklistHandleLine(Color color, double width) {
    return Container(
      width: width,
      height: 1.5,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }

  Widget _checklistToggle(_ChecklistDraftItem item) {
    final palette = context.appPalette;
    return GestureDetector(
      onTap: () => setState(() => item.isDone = !item.isDone),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: item.isDone ? palette.textPrimary : Colors.transparent,
          border: Border.all(
            color: item.isDone ? palette.textPrimary : palette.stroke,
            width: 1.5,
          ),
        ),
        child: item.isDone
            ? Icon(Icons.check_rounded, size: 13, color: palette.surface)
            : null,
      ),
    );
  }

  Widget _checklistDeleteButton(_ChecklistDraftItem item) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _checklistItems.remove(item);
          item.dispose();
        });
      },
      child: SizedBox(
        width: 18,
        height: 18,
        child: Center(
          child: Text(
            '×',
            style: TextStyle(
              fontSize: 16,
              height: 1,
              fontWeight: FontWeight.w600,
              color: context.appPalette.textMuted,
            ),
          ),
        ),
      ),
    );
  }

  Widget _addChecklistItemTile() {
    return InkWell(
      onTap: () {
        final item = _ChecklistDraftItem(
          id: _nextChecklistId(),
          title: '',
          isDone: false,
        );
        setState(() {
          _checklistItems.add(item);
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            item.focusNode.requestFocus();
          }
        });
      },
      borderRadius: BorderRadius.circular(14),
      child: CustomPaint(
        painter: _DashedRoundedBorderPainter(color: context.appPalette.stroke),
        child: SizedBox(
          height: 45,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_rounded,
                size: 16,
                color: context.appPalette.textMuted,
              ),
              const SizedBox(width: 8),
              Text(
                context.l10n.collectionEntryAddChecklistItem,
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: context.appPalette.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<DateTime?> _pickDate(DateTime? initialDate) async {
    final now = DateTime.now();
    return showDatePicker(
      context: context,
      initialDate: initialDate ?? now,
      firstDate: DateTime(now.year - 20),
      lastDate: DateTime(now.year + 20),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: collectionsPrimary),
          ),
          child: child!,
        );
      },
    );
  }

  Future<TimeOfDay?> _pickTime(TimeOfDay? initialTime) {
    return showTimePicker(
      context: context,
      initialTime: initialTime ?? TimeOfDay.now(),
    );
  }

  String _nextChecklistId() {
    return 'check_${DateTime.now().microsecondsSinceEpoch}_${_checklistItems.length}';
  }

  void _save() {
    FocusManager.instance.primaryFocus?.unfocus();
    if (widget.type == CollectionBlockType.note) {
      _syncNoteEditorToDescription();
    }
    final now = DateTime.now();
    final title = _resolvedTitle();
    if (title.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.collectionEntryValidationTitle)),
      );
      return;
    }

    // Require file for document and image blocks
    final hasDocumentAsset =
        _pickedFilePath != null ||
        (!_clearExistingFile && widget.initialBlock?.filePath != null);
    if ((widget.type == CollectionBlockType.document ||
            widget.type == CollectionBlockType.image) &&
        !hasDocumentAsset) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.collectionEntrySelectFile)),
      );
      return;
    }

    final combinedDateTime = _combineDateTime(_selectedDate, _selectedTime);
    final amount = _parseAmount(_amountController.text);
    final block = CollectionBlockEntity(
      id: widget.initialBlock?.id ?? 'block_${now.microsecondsSinceEpoch}',
      collectionId: widget.collectionId,
      parentBlockId: widget.parentBlockId ?? widget.initialBlock?.parentBlockId,
      type: widget.type,
      title: title,
      subtitle: _resolvedSubtitle(amount),
      description: _descriptionController.text.trim(),
      createdAt: widget.initialBlock?.createdAt ?? now,
      updatedAt: now,
      imageUrl: _linkPreviewImage ?? widget.initialBlock?.imageUrl,
      filePath: _clearExistingFile
          ? null
          : (_pickedFilePath ?? widget.initialBlock?.filePath),
      fileType: _resolvedFileType(),
      fileSizeLabel: _resolvedStoredFileSizeLabel(),
      url: _urlController.text.trim().isEmpty
          ? null
          : _urlController.text.trim(),
      domainLabel: _domainController.text.trim().isEmpty
          ? _deriveDomain(_urlController.text)
          : _domainController.text.trim(),
      currencyCode: widget.type == CollectionBlockType.expense
          ? _currencyCode
          : null,
      amount:
          widget.type == CollectionBlockType.expense ||
              widget.type == CollectionBlockType.progress
          ? amount
          : null,
      eventAt:
          widget.type == CollectionBlockType.timeline ||
              widget.type == CollectionBlockType.expense ||
              widget.type == CollectionBlockType.reminder
          ? combinedDateTime
          : null,
      repeatInterval:
          widget.type == CollectionBlockType.reminder &&
              _category != 'none' &&
              _category != 'General'
          ? _category
          : null,
      expiryDate: widget.type == CollectionBlockType.document
          ? _expiryDate
          : null,
      latitude: widget.type == CollectionBlockType.location
          ? (_selectedLocation?.latitude ?? widget.initialBlock?.latitude)
          : null,
      longitude: widget.type == CollectionBlockType.location
          ? (_selectedLocation?.longitude ?? widget.initialBlock?.longitude)
          : null,
      locationLabel:
          _selectedLocation?.displayName ??
          (_locationController.text.trim().isEmpty
              ? widget.initialBlock?.locationLabel
              : _locationController.text.trim()),
      isCompleted: widget.type == CollectionBlockType.checklist
          ? _checklistItems.isNotEmpty &&
                _checklistItems.every((item) => item.isDone)
          : (widget.initialBlock?.isCompleted ?? false),
      statusLabel: _resolvedStatusLabel(),
      tags: _resolvedTags(),
      metadata: _resolvedMetadata(),
      checklistItems: _checklistItems
          .where((item) => item.controller.text.trim().isNotEmpty)
          .map(
            (item) => CollectionChecklistItemEntity(
              id: item.id,
              title: item.controller.text.trim(),
              isDone: item.isDone,
            ),
          )
          .toList(growable: false),
      position: widget.initialBlock?.position ?? 0,
    );

    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context).pop(block);
  }

  InputDecoration _inputDecoration(String hint) {
    final palette = context.appPalette;
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: palette.textMuted,
      ),
      filled: true,
      fillColor: palette.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: palette.stroke),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: palette.stroke),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: palette.primary, width: 1.2),
      ),
    );
  }

  String _resolvedTitle() {
    if (widget.type == CollectionBlockType.note) {
      final explicit = _titleController.text.trim();
      if (explicit.isNotEmpty) return explicit;
      final editorState = _noteEditorState;
      if (editorState != null) {
        final derived = NoteAppFlowyDocumentCodec.titleFromDocument(
          editorState.document,
        );
        if (derived.trim().isNotEmpty) return derived.trim();
      }
      return explicit;
    }
    if (widget.type == CollectionBlockType.input) {
      return _labelController.text.trim();
    }
    if (widget.type == CollectionBlockType.link) {
      final title = _titleController.text.trim();
      if (title.isNotEmpty) return title;
      final fetchedTitle = _linkPreviewTitle?.trim();
      if (fetchedTitle != null && fetchedTitle.isNotEmpty) return fetchedTitle;
      final domain = _deriveDomain(_urlController.text);
      if (domain != null && domain.isNotEmpty) return domain;
      return _urlController.text.trim();
    }
    if (widget.type == CollectionBlockType.location) {
      if (_titleController.text.trim().isNotEmpty) {
        return _titleController.text.trim();
      }
      if (_selectedLocation != null) {
        return _selectedLocation!.displayName.split(',').first.trim();
      }
      return _locationController.text.trim().isNotEmpty
          ? _locationController.text.trim()
          : context.l10n.collectionEntryAddLocation;
    }
    return _titleController.text.trim();
  }

  String _resolvedSubtitle(double? amount) {
    switch (widget.type) {
      case CollectionBlockType.document:
        return '${_docCategoryLabel(context, _category)} • ${_resolvedFileSize()}';
      case CollectionBlockType.note:
        return 'Note • ${_descriptionController.text.trim().split(RegExp(r'\\s+')).where((v) => v.isNotEmpty).length} words';
      case CollectionBlockType.input:
        return _valueController.text.trim();
      case CollectionBlockType.checklist:
        final completed = _checklistItems.where((item) => item.isDone).length;
        final total = _checklistItems
            .where((item) => item.controller.text.trim().isNotEmpty)
            .length;
        return '$completed of $total tasks';
      case CollectionBlockType.link:
        return _deriveDomain(_urlController.text) ?? 'Web resource';
      case CollectionBlockType.image:
        return 'IMG_${DateTime.now().millisecondsSinceEpoch}.JPG';
      case CollectionBlockType.expense:
        final value = amount ?? 0;
        return '${_currencyCode.toUpperCase()} ${value.toStringAsFixed(2)}';
      case CollectionBlockType.timeline:
        if (combinedDateTimeOrNull != null) {
          return DateFormat('MMM d, hh:mm a').format(combinedDateTimeOrNull!);
        }
        return _category;
      case CollectionBlockType.location:
        return _locationController.text.trim();
      case CollectionBlockType.folder:
        return '0 items';
      case CollectionBlockType.section:
        return '0 items';
      case CollectionBlockType.reminder:
        if (combinedDateTimeOrNull != null) {
          return DateFormat('MMM d, hh:mm a').format(combinedDateTimeOrNull!);
        }
        return context.l10n.collectionReminderScheduled;
      case CollectionBlockType.progress:
        final current = amount ?? 0;
        final target = double.tryParse(_targetAmountController.text) ?? 0;
        final pct = target > 0
            ? ((current / target) * 100).clamp(0, 100).toStringAsFixed(0)
            : '0';
        return '$pct% complete';
    }
  }

  DateTime? get combinedDateTimeOrNull =>
      _combineDateTime(_selectedDate, _selectedTime);

  String? _resolvedFileType() {
    if (_pickedFileTypeLabel != null) return _pickedFileTypeLabel;
    final existingType = widget.initialBlock?.fileType?.trim();
    if (existingType != null &&
        existingType.isNotEmpty &&
        !_clearExistingFile) {
      return existingType;
    }
    return switch (widget.type) {
      CollectionBlockType.document => 'PDF',
      CollectionBlockType.image => 'JPG',
      CollectionBlockType.expense => 'JPG',
      _ => null,
    };
  }

  String _resolvedFileSize() {
    if (_pickedFileBytes != null) return _formatFileSize(_pickedFileBytes!);
    final pickedLabel = (_pickedFileSizeLabel ?? '').trim();
    if (pickedLabel.isNotEmpty) return pickedLabel;
    final existingLabel = widget.initialBlock?.fileSizeLabel?.trim();
    if (existingLabel != null &&
        existingLabel.isNotEmpty &&
        !_clearExistingFile) {
      return existingLabel;
    }
    return switch (widget.type) {
      CollectionBlockType.document => '4.2 MB',
      CollectionBlockType.image => '4.2 MB',
      CollectionBlockType.expense => '1.2 MB',
      _ => '0 KB',
    };
  }

  String? _resolvedStatusLabel() {
    if (widget.type == CollectionBlockType.expense) {
      return 'Completed';
    }
    if (widget.type == CollectionBlockType.timeline) {
      return _category;
    }
    if (widget.type == CollectionBlockType.image) {
      return _securityLevel;
    }
    if (widget.type == CollectionBlockType.input) {
      return _category == 'Hidden' ? 'Private' : 'Active';
    }
    if (widget.type == CollectionBlockType.location) {
      return 'Active';
    }
    return widget.initialBlock?.statusLabel;
  }

  List<String> _resolvedTags() {
    if (widget.type == CollectionBlockType.link) {
      return ['link', 'resource'];
    }
    if (widget.type == CollectionBlockType.timeline) {
      return [_category.toLowerCase()];
    }
    if (widget.type == CollectionBlockType.expense) {
      return [_category.toLowerCase()];
    }
    return widget.initialBlock?.tags ?? const [];
  }

  Map<String, String> _resolvedMetadata() {
    final base = <String, String>{...widget.initialBlock?.metadata ?? const {}};

    switch (widget.type) {
      case CollectionBlockType.document:
        base['category'] = _category;
        if (_expiryDate != null) {
          base['expiry_date'] = DateFormat('MMM d, y').format(_expiryDate!);
        }
      case CollectionBlockType.note:
        final editorState = _noteEditorState;
        if (editorState == null) {
          base.remove(_collectionNoteDocumentJsonKey);
        } else {
          base[_collectionNoteDocumentJsonKey] = const JsonEncoder().convert(
            editorState.document.toJson(),
          );
        }
      case CollectionBlockType.section:
        base[CollectionBlockMetadataKeys.sectionDefaultCollapsed] =
            _sectionDefaultCollapsed ? 'true' : 'false';
      case CollectionBlockType.input:
        base['label'] = _labelController.text.trim();
        base['value'] = _valueController.text.trim();
        base['field_type'] = _fieldType;
        base['category'] = _category;
        base['security_level'] = _inputTypeAllowsCopy(_fieldType)
            ? 'Quick'
            : 'Standard';
      case CollectionBlockType.timeline:
        base['category'] = _category;
        if (_locationController.text.trim().isNotEmpty) {
          base['location'] = _locationController.text.trim();
        }
      case CollectionBlockType.location:
        base['unit_floor'] = _unitFloorController.text.trim();
      case CollectionBlockType.progress:
        base['target_amount'] = _targetAmountController.text.trim();
        base['unit'] = _unitController.text.trim();
        if (_selectedDate == null) {
          base.remove('due_date');
        } else {
          base['due_date'] = _selectedDate!.toIso8601String();
        }
      default:
        break;
    }
    _writeBlockIconMetadata(base);
    return base;
  }

  void _writeBlockIconMetadata(Map<String, String> metadata) {
    final iconKey = (_blockCustomIconKey ?? '').trim();
    final emoji = (_blockCustomIconEmoji ?? '').trim();
    final imagePath = (_blockCustomIconImagePath ?? '').trim();

    if (iconKey.isEmpty) {
      metadata.remove(CollectionBlockMetadataKeys.iconKey);
    } else {
      metadata[CollectionBlockMetadataKeys.iconKey] = iconKey;
    }

    if (emoji.isEmpty) {
      metadata.remove(CollectionBlockMetadataKeys.iconEmoji);
    } else {
      metadata[CollectionBlockMetadataKeys.iconEmoji] = emoji;
    }

    if (imagePath.isEmpty) {
      metadata.remove(CollectionBlockMetadataKeys.iconImagePath);
    } else {
      metadata[CollectionBlockMetadataKeys.iconImagePath] = imagePath;
    }
  }

  double? _parseAmount(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'[^0-9.]'), '');
    if (cleaned.trim().isEmpty) {
      return null;
    }
    return double.tryParse(cleaned);
  }

  DateTime? _combineDateTime(DateTime? date, TimeOfDay? time) {
    if (date == null) {
      return null;
    }
    if (time == null) {
      return DateTime(date.year, date.month, date.day);
    }
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  String _defaultCategory(CollectionBlockType type) {
    return switch (type) {
      CollectionBlockType.document => 'PropertyLease',
      CollectionBlockType.note => 'Personal',
      CollectionBlockType.expense => 'Transport',
      CollectionBlockType.timeline => 'Property',
      _ => 'General',
    };
  }

  String _screenTitle(BuildContext context, CollectionBlockType type) {
    if (!widget.isEdit) {
      return _entryTitle(context, type);
    }
    return switch (type) {
      CollectionBlockType.folder => context.l10n.collectionEntryEditFolder,
      CollectionBlockType.section => context.l10n.collectionEntryEditSection,
      CollectionBlockType.link => context.l10n.collectionEntryEditLink,
      CollectionBlockType.location => context.l10n.collectionEntryEditLocation,
      CollectionBlockType.note => context.l10n.collectionEntryEditNote,
      CollectionBlockType.progress => context.l10n.collectionEntryEditProgress,
      CollectionBlockType.reminder => context.l10n.collectionEntryEditReminder,
      CollectionBlockType.timeline => context.l10n.collectionEntryEditEvent,
      _ => 'Edit ${widget.type.label}',
    };
  }

  String _entryTitle(BuildContext context, CollectionBlockType type) {
    return switch (type) {
      CollectionBlockType.folder => context.l10n.collectionEntryAddFolder,
      CollectionBlockType.section => context.l10n.collectionEntryAddSection,
      CollectionBlockType.document => context.l10n.collectionEntryAddDocument,
      CollectionBlockType.note => context.l10n.collectionEntryAddNote,
      CollectionBlockType.input => context.l10n.collectionEntryAddInput,
      CollectionBlockType.checklist => context.l10n.collectionEntryAddChecklist,
      CollectionBlockType.link => context.l10n.collectionEntryAddLink,
      CollectionBlockType.image => context.l10n.collectionEntryAddImage,
      CollectionBlockType.expense => context.l10n.collectionEntryAddExpense,
      CollectionBlockType.timeline => context.l10n.collectionEntryAddEvent,
      CollectionBlockType.location => context.l10n.collectionEntryAddLocation,
      CollectionBlockType.reminder => context.l10n.collectionEntryAddReminder,
      CollectionBlockType.progress => context.l10n.collectionEntryAddProgress,
    };
  }

  String _saveButtonLabel(BuildContext context, CollectionBlockType type) {
    return switch (type) {
      CollectionBlockType.document =>
        widget.isEdit
            ? context.l10n.commonSave
            : context.l10n.collectionEntryAddDocument,
      CollectionBlockType.note => context.l10n.collectionEntrySaveNote,
      CollectionBlockType.input => context.l10n.collectionEntrySaveField,
      CollectionBlockType.checklist =>
        context.l10n.collectionEntrySaveChecklist,
      CollectionBlockType.link => context.l10n.collectionEntrySaveLink,
      CollectionBlockType.image => context.l10n.collectionEntrySaveImage,
      CollectionBlockType.expense => context.l10n.collectionEntrySaveExpense,
      CollectionBlockType.timeline => context.l10n.collectionEntrySaveEvent,
      CollectionBlockType.location => context.l10n.collectionEntrySaveVault,
      CollectionBlockType.folder =>
        widget.isEdit
            ? context.l10n.commonSave
            : context.l10n.collectionEntryCreateFolder,
      CollectionBlockType.section =>
        widget.isEdit
            ? context.l10n.commonSave
            : context.l10n.collectionEntryCreateSection,
      CollectionBlockType.reminder => context.l10n.collectionEntrySaveReminder,
      CollectionBlockType.progress => context.l10n.collectionEntrySaveProgress,
    };
  }

  IconData _saveButtonIcon(CollectionBlockType type) {
    return switch (type) {
      CollectionBlockType.document => Icons.add_rounded,
      CollectionBlockType.folder =>
        widget.isEdit ? Icons.save_rounded : Icons.create_new_folder_rounded,
      CollectionBlockType.section =>
        widget.isEdit ? Icons.save_rounded : Icons.view_agenda_rounded,
      _ => Icons.shield_rounded,
    };
  }

  String _uploadTitle(BuildContext context, CollectionBlockType type) {
    final l = context.l10n;
    return switch (type) {
      CollectionBlockType.document => l.collectionEntryUploadDocument,
      CollectionBlockType.image => l.collectionEntryUploadImage,
      CollectionBlockType.expense => l.collectionEntryUploadReceipt,
      CollectionBlockType.timeline => l.collectionEntryUploadFiles,
      _ => l.collectionEntryUploadDefault,
    };
  }

  String _uploadSubtitle(BuildContext context, CollectionBlockType type) {
    final l = context.l10n;
    return switch (type) {
      CollectionBlockType.document => l.collectionEntryUploadDocHint,
      CollectionBlockType.image => l.collectionEntryUploadImageHint,
      CollectionBlockType.expense => l.collectionEntryUploadReceiptHint,
      CollectionBlockType.timeline => l.collectionEntryUploadFileHint,
      _ => '',
    };
  }

  void _primeExistingPickedFile(CollectionBlockEntity block) {
    final rawPath = (block.filePath ?? '').trim();
    if (rawPath.isEmpty) return;
    _pickedFilePath = rawPath;
    _pickedFileName = rawPath.split(Platform.pathSeparator).last;
    _pickedFileTypeLabel = (block.fileType ?? '').trim().isNotEmpty
        ? block.fileType
        : rawPath.inferFileTypeLabel();
    final sizeLabel = (block.fileSizeLabel ?? '').trim();
    _pickedFileSizeLabel = sizeLabel.isEmpty ? null : sizeLabel;
    unawaited(_hydrateExistingFileBytes(rawPath));
  }

  Future<void> _hydrateExistingFileBytes(String rawPath) async {
    try {
      final resolvedPath = rawPath.startsWith('file://')
          ? Uri.parse(rawPath).toFilePath()
          : rawPath;
      final file = File(resolvedPath);
      if (!await file.exists()) return;
      final length = await file.length();
      if (!mounted || _pickedFilePath != rawPath) return;
      setState(() {
        _pickedFileBytes = length;
      });
    } catch (_) {
      // Ignore preview metadata failures for existing files.
    }
  }

  bool get _hasAttachedFile => (_pickedFilePath ?? '').trim().isNotEmpty;

  String? get _selectedFilePath {
    final rawPath =
        (_pickedFilePath ??
                (!_clearExistingFile ? widget.initialBlock?.filePath : null))
            ?.trim();
    return rawPath == null || rawPath.isEmpty ? null : rawPath;
  }

  String get _displayFileName {
    final rawName = (_pickedFileName ?? '').trim();
    if (rawName.isEmpty) return '';
    if (!rawName.startsWith('block_')) return rawName;
    final title = _titleController.text.trim();
    if (title.isEmpty) return rawName;
    final extensionIndex = rawName.lastIndexOf('.');
    final extension = extensionIndex == -1
        ? ''
        : rawName.substring(extensionIndex);
    return '$title$extension';
  }

  String get _currentFileTypeLabel => (_resolvedFileType() ?? '').trim();

  String get _currentFileSizeLabel => _resolvedFileSize();

  void _removePickedFile() {
    setState(() {
      _pickedFilePath = null;
      _pickedFileName = null;
      _pickedFileTypeLabel = null;
      _pickedFileSizeLabel = null;
      _pickedFileBytes = null;
      _clearExistingFile = true;
    });
  }

  void _seedDocumentTitleFromFileName(String fileName) {
    if (widget.type != CollectionBlockType.document &&
        widget.type != CollectionBlockType.image) {
      return;
    }
    if (_titleController.text.trim().isNotEmpty) return;
    final sanitized = fileName
        .replaceAll(RegExp(r'\.[^.]+$'), '')
        .replaceAll(RegExp(r'[_-]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (sanitized.isNotEmpty && !_looksGeneratedFileStem(sanitized)) {
      _titleController.text = sanitized;
    }
  }

  bool _looksGeneratedFileStem(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized.isEmpty) {
      return true;
    }
    if (RegExp(r'(^|[_\-\s])\d{10,}($|[_\-\s])').hasMatch(normalized)) {
      return true;
    }
    return normalized.startsWith('image picker') ||
        normalized.startsWith('image_picker') ||
        normalized.startsWith('img ');
  }

  void _previewPickedFile() {
    final filePath = _selectedFilePath;
    final resolvedPath = filePath == null
        ? ''
        : LocalAssetPathResolver.resolveRuntimePathSync(filePath);
    if (resolvedPath.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.collectionDetailNoFileAttached)),
      );
      return;
    }
    final file = File(resolvedPath);
    if (!file.existsSync()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.collectionDetailFileNotFound)),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DocumentFilePreviewPage(
          filePath: resolvedPath,
          title: _titleController.text.trim().isEmpty
              ? _displayFileName
              : _titleController.text.trim(),
          fileName: _displayFileName,
          mimeType: resolvedPath.inferMimeType(),
        ),
      ),
    );
  }

  String? _resolvedStoredFileSizeLabel() {
    if (_clearExistingFile) return null;
    final value = _resolvedFileSize().trim();
    return value.isEmpty ? null : value;
  }

  Widget _documentDetailsGroup() {
    return Column(
      children: [
        _documentInlineTextField(
          label: context.l10n.collectionEntryTitle,
          controller: _titleController,
          hint: context.l10n.collectionEntryHintDocTitle,
          focused: true,
        ),
        const SizedBox(height: 10),
        _documentInlineTextField(
          label: context.l10n.collectionEntryCategory,
          controller: _categoryController,
          hint: context.l10n.collectionEntryCategory,
          filled: true,
        ),
        const SizedBox(height: 10),
        _documentInlineTextField(
          label: context.l10n.collectionEntryNotesOptional,
          controller: _descriptionController,
          hint: context.l10n.collectionEntryHintDocumentNotes,
          minLines: 1,
          maxLines: 2,
          filled: true,
        ),
      ],
    );
  }

  Widget _imageHeroPreview() {
    final palette = context.appPalette;
    final filePath = _selectedFilePath;
    final resolvedPath = filePath == null
        ? ''
        : LocalAssetPathResolver.resolveRuntimePathSync(filePath);
    final imageProvider = resolvedPath.isEmpty
        ? null
        : resolveLocalFileImageProvider(resolvedPath);
    final hasImage = imageProvider != null;
    final title = hasImage
        ? _displayFileName
        : context.l10n.commonChooseFromGallery;
    final meta = hasImage
        ? _documentFileMetaLine
        : context.l10n.collectionEntryUploadImageHint;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _pickDocumentImage(ImageSource.gallery),
        borderRadius: BorderRadius.circular(18),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: AspectRatio(
            aspectRatio: 4 / 3,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (hasImage)
                  Image(image: imageProvider, fit: BoxFit.cover)
                else
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          palette.surfaceSoft,
                          palette.surfaceSoft.withValues(alpha: 0.56),
                        ],
                      ),
                    ),
                  ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(color: palette.stroke),
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                if (!hasImage)
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 66,
                          height: 66,
                          decoration: BoxDecoration(
                            color: palette.surface,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: palette.stroke),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.add_photo_alternate_rounded,
                            size: 30,
                            color: palette.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: palette.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          meta,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: palette.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (hasImage) ...[
                  Positioned(
                    left: 12,
                    right: 86,
                    bottom: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: palette.textPrimary.withValues(alpha: 0.86),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        [
                          'SELECTED',
                          _displayFileName,
                        ].where((value) => value.trim().isNotEmpty).join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.9,
                          color: palette.background,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: _imageHeroAction(
                      label: context.l10n.collectionEntryReplaceFile,
                      onTap: () => _pickDocumentImage(ImageSource.gallery),
                    ),
                  ),
                  Positioned(
                    right: 12,
                    bottom: 12,
                    child: _imageHeroAction(
                      label: context.l10n.collectionDetailRemove,
                      danger: true,
                      onTap: _removePickedFile,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _imageHeroAction({
    required String label,
    required VoidCallback onTap,
    bool danger = false,
  }) {
    final palette = context.appPalette;
    return Material(
      color: danger
          ? palette.surface.withValues(alpha: 0.92)
          : palette.textPrimary.withValues(alpha: 0.86),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: danger ? palette.danger : palette.background,
            ),
          ),
        ),
      ),
    );
  }

  Widget _documentSectionLabel(String label) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 3.2,
        color: context.appPalette.textMuted,
      ),
    );
  }

  Widget _documentInlineTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    bool focused = false,
    bool filled = false,
    int minLines = 1,
    int maxLines = 1,
  }) {
    final palette = context.appPalette;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
      decoration: BoxDecoration(
        color: filled ? palette.surfaceSoft : palette.surface,
        borderRadius: BorderRadius.circular(12),
        border: focused
            ? Border.all(color: palette.textPrimary, width: 1.8)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.35,
              color: palette.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          TextField(
            controller: controller,
            minLines: minLines,
            maxLines: maxLines,
            scrollPadding: const EdgeInsets.only(bottom: 140),
            style: TextStyle(
              fontSize: 15,
              height: 1.15,
              fontWeight: FontWeight.w600,
              color: palette.textPrimary,
            ),
            decoration: InputDecoration.collapsed(
              hintText: hint,
              hintStyle: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: palette.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showDocumentSourceSheet() async {
    final source = await showAdaptiveModal<_ImageBlockSource>(
      context: context,
      backgroundColor: context.appPalette.surface,
      builder: (sheetContext) {
        final palette = sheetContext.appPalette;
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: palette.stroke,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 16),
                _ImageSourceActionTile(
                  icon: Icons.folder_open_rounded,
                  label: sheetContext.l10n.collectionEntrySourceFiles,
                  onTap: () =>
                      Navigator.of(sheetContext).pop(_ImageBlockSource.files),
                ),
                const SizedBox(height: 10),
                _ImageSourceActionTile(
                  icon: Icons.photo_library_outlined,
                  label: sheetContext.l10n.collectionEntrySourcePhotos,
                  onTap: () =>
                      Navigator.of(sheetContext).pop(_ImageBlockSource.gallery),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (!mounted || source == null) return;

    switch (source) {
      case _ImageBlockSource.files:
        await _pickFile();
      case _ImageBlockSource.gallery:
        await _pickDocumentImage(ImageSource.gallery);
    }
  }

  Widget _documentUploadCard() {
    final card = _documentFileShell(
      onTap: _showDocumentSourceSheet,
      highlighted: _documentUploadDragging,
      title: _documentUploadDragging
          ? context.l10n.collectionUploadDropHere
          : context.l10n.collectionEntryAddDocument,
      meta: _uploadSubtitle(context, widget.type),
      actions: [
        _documentFileAction(
          label: context.l10n.collectionEntrySourceFiles,
          onTap: _pickFile,
        ),
        _documentFileAction(
          label: context.l10n.collectionEntrySourcePhotos,
          onTap: () => _pickDocumentImage(ImageSource.gallery),
        ),
      ],
    );

    if (!_supportsDesktopDrop(context)) {
      return card;
    }

    return DropTarget(
      onDragEntered: (_) => setState(() => _documentUploadDragging = true),
      onDragExited: (_) => setState(() => _documentUploadDragging = false),
      onDragDone: (details) {
        setState(() => _documentUploadDragging = false);
        final files = details.files;
        if (files.isNotEmpty) {
          _handleFileDrop(files.first.path);
        }
      },
      child: card,
    );
  }

  Widget _documentFilePreviewCard() {
    return _documentFileShell(
      title: _displayFileName,
      meta: _documentFileMetaLine,
      actions: [
        _documentFileAction(
          label: context.l10n.collectionEntryReplaceFile,
          onTap: _showDocumentSourceSheet,
        ),
        _documentFileAction(
          label: context.l10n.collectionDetailPreview,
          onTap: _previewPickedFile,
        ),
        _documentFileAction(
          label: context.l10n.collectionDetailRemove,
          danger: true,
          onTap: _removePickedFile,
        ),
      ],
    );
  }

  Widget _documentFileShell({
    required String title,
    required String meta,
    required List<Widget> actions,
    VoidCallback? onTap,
    bool highlighted = false,
  }) {
    final palette = context.appPalette;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: highlighted ? collectionsPrimary : palette.stroke,
              width: highlighted ? 1.6 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _documentFileThumbnail(),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: palette.textPrimary,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        meta,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: palette.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(spacing: 12, runSpacing: 6, children: actions),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _supportsDesktopDrop(BuildContext context) {
    final platform = Theme.of(context).platform;
    return platform == TargetPlatform.macOS ||
        platform == TargetPlatform.windows ||
        platform == TargetPlatform.linux;
  }

  Widget _documentFileThumbnail() {
    final palette = context.appPalette;
    final filePath = _selectedFilePath;
    final resolvedPath = filePath == null
        ? ''
        : LocalAssetPathResolver.resolveRuntimePathSync(filePath);
    final imageProvider = resolvedPath.isEmpty
        ? null
        : resolveLocalFileImageProvider(resolvedPath);
    return ClipRRect(
      borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
      child: Container(
        width: 92,
        height: 96,
        decoration: BoxDecoration(color: palette.surfaceSoft),
        child: imageProvider != null
            ? Image(image: imageProvider, fit: BoxFit.cover)
            : Center(child: _documentPaperIcon()),
      ),
    );
  }

  Widget _documentPaperIcon() {
    final palette = context.appPalette;
    return Container(
      width: 68,
      height: 72,
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: palette.stroke),
      ),
      padding: const EdgeInsets.fromLTRB(6, 0, 6, 0),
      child: Column(
        children: [
          Container(
            height: 10,
            decoration: BoxDecoration(
              color: palette.textPrimary.withValues(alpha: 0.82),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: 9),
          for (final width in const [46.0, 54.0, 50.0, 42.0, 54.0])
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: width,
                  height: 1.2,
                  color: palette.textMuted.withValues(alpha: 0.38),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _documentFileAction({
    required String label,
    required VoidCallback onTap,
    bool danger = false,
  }) {
    final palette = context.appPalette;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: danger ? palette.danger : palette.textPrimary,
          ),
        ),
      ),
    );
  }

  String get _documentFileMetaLine {
    return [
      _currentFileTypeLabel,
      _currentFileSizeLabel,
    ].where((value) => value.trim().isNotEmpty).join(' • ');
  }

  IconData _uploadIcon(CollectionBlockType type) {
    return switch (type) {
      CollectionBlockType.document => Icons.cloud_upload_rounded,
      CollectionBlockType.image => Icons.cloud_upload_rounded,
      CollectionBlockType.expense => Icons.add_a_photo_rounded,
      CollectionBlockType.timeline => Icons.upload_file_rounded,
      _ => Icons.upload_rounded,
    };
  }

  String? _deriveDomain(String rawUrl) {
    final value = rawUrl.trim();
    if (value.isEmpty) {
      return null;
    }
    final uri = Uri.tryParse(value);
    return uri?.host.isNotEmpty == true ? uri!.host : null;
  }

  String _fieldTypeLabel(BuildContext context, String value) {
    return switch (value) {
      'Short Text' => context.l10n.collectionFieldTypeShortText,
      'Number' => context.l10n.collectionFieldTypeNumber,
      'Date' => context.l10n.collectionFieldTypeDate,
      'Phone' => context.l10n.collectionFieldTypePhone,
      'URL' => context.l10n.credentialFieldWebsiteUrl,
      _ => value,
    };
  }

  String _docCategoryLabel(BuildContext context, String value) {
    return switch (value) {
      'PropertyLease' => context.l10n.collectionDocCategoryPropertyLease,
      'Identity' => context.l10n.collectionDocCategoryIdentity,
      'Travel' => context.l10n.collectionDocCategoryTravel,
      'Finance' => context.l10n.collectionDocCategoryFinance,
      'Other' => context.l10n.collectionDocCategoryOther,
      _ => value,
    };
  }

  String _initialCategoryLabel(String value) {
    return switch (value) {
      'PropertyLease' => 'Property Lease',
      _ => value,
    };
  }

  String _expenseCategoryLabel(BuildContext context, String value) {
    return switch (value) {
      'Transport' => context.l10n.collectionExpenseCategoryTransport,
      'Food' => context.l10n.collectionExpenseCategoryFood,
      'Shopping' => context.l10n.collectionExpenseCategoryShopping,
      'Rent' => context.l10n.collectionExpenseCategoryRent,
      'Other' => context.l10n.collectionExpenseCategoryOther,
      _ => value,
    };
  }

  String _repeatLabel(BuildContext context, String value) {
    final l = context.l10n;
    return switch (value) {
      'none' => l.collectionReminderOnce,
      'daily' => l.collectionReminderDaily,
      'weekly' => l.collectionReminderWeekly,
      'monthly' => l.collectionReminderMonthly,
      'quarterly' => l.collectionReminderQuarterly,
      'yearly' => l.collectionReminderYearly,
      _ => l.collectionReminderNone,
    };
  }

  String _currencySymbol(String code) {
    return switch (code) {
      'USD' => '\$',
      'EUR' => '€',
      'GBP' => '£',
      _ => code,
    };
  }

  String _currencyLabel(String code) {
    return switch (code) {
      'USD' => 'USD - \$',
      'EUR' => 'EUR - €',
      'GBP' => 'GBP - £',
      _ => code,
    };
  }
}

class _ChecklistDraftItem {
  _ChecklistDraftItem({
    required this.id,
    required String title,
    required this.isDone,
  }) : controller = TextEditingController(text: title);

  final String id;
  final TextEditingController controller;
  final FocusNode focusNode = FocusNode();
  bool isDone;

  void dispose() {
    controller.dispose();
    focusNode.dispose();
  }
}

enum _ImageBlockSource { gallery, files }

class _ImageSourceActionTile extends StatelessWidget {
  const _ImageSourceActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Material(
      color: palette.surfaceSoft,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 20, color: palette.textPrimary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: palette.textPrimary,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 22,
                color: palette.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExpenseCategoryOption {
  const _ExpenseCategoryOption({required this.label, required this.icon});

  final String label;
  final IconData icon;
}

class _DashedRoundedBorderPainter extends CustomPainter {
  const _DashedRoundedBorderPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    final rect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(16),
    );
    final path = Path()..addRRect(rect);
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = (distance + 8).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance += 13;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
