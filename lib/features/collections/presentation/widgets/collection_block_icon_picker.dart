import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pass_doc_manager/app/presentation/widgets/generic_app_bar.dart';
import 'package:pass_doc_manager/app/theme/app_palette.dart';
import 'package:pass_doc_manager/domain/branding/entities/company_brand_search_result_entity.dart';
import 'package:pass_doc_manager/domain/branding/usecases/download_company_logo_to_local.dart';
import 'package:pass_doc_manager/domain/branding/usecases/search_company_brands.dart';
import 'package:pass_doc_manager/domain/collections/entities/collection_block_metadata_keys.dart';
import 'package:pass_doc_manager/domain/collections/entities/collection_block_type.dart';
import 'package:pass_doc_manager/features/collections/presentation/widgets/collections_ui.dart';
import 'package:pass_doc_manager/features/credentials/presentation/widgets/company_logo_avatar.dart';
import 'package:pass_doc_manager/l10n/l10n.dart';

class CollectionBlockIconSelection {
  const CollectionBlockIconSelection({
    this.iconKey,
    this.emoji,
    this.imagePath,
  });

  final String? iconKey;
  final String? emoji;
  final String? imagePath;

  bool get hasSelection =>
      (iconKey ?? '').trim().isNotEmpty ||
      normalizeCollectionEmoji(emoji).isNotEmpty ||
      (imagePath ?? '').trim().isNotEmpty;

  Map<String, String> toMetadata() {
    return <String, String>{
      if ((iconKey ?? '').trim().isNotEmpty)
        CollectionBlockMetadataKeys.iconKey: iconKey!.trim(),
      if (normalizeCollectionEmoji(emoji).isNotEmpty)
        CollectionBlockMetadataKeys.iconEmoji: normalizeCollectionEmoji(emoji),
      if ((imagePath ?? '').trim().isNotEmpty)
        CollectionBlockMetadataKeys.iconImagePath: imagePath!.trim(),
    };
  }
}

class CollectionBlockIconPicker extends StatelessWidget {
  const CollectionBlockIconPicker({
    super.key,
    required this.type,
    required this.title,
    required this.placeholderTitle,
    required this.selection,
    required this.onSearchIcon,
    required this.onEmoji,
    required this.onPickImage,
    this.onClear,
    this.helperText,
    this.showSelectionSummary = true,
  });

  final CollectionBlockType type;
  final String title;
  final String placeholderTitle;
  final CollectionBlockIconSelection selection;
  final VoidCallback onSearchIcon;
  final VoidCallback onEmoji;
  final VoidCallback onPickImage;
  final VoidCallback? onClear;
  final String? helperText;
  final bool showSelectionSummary;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final metadata = selection.toMetadata();
    final previewTitle = title.trim().isEmpty ? placeholderTitle : title.trim();
    final activeMode = _activeMode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.10),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: buildCollectionBlockLeadingIcon(
                context,
                type: type,
                metadata: metadata,
                shellSize: 64,
                shellRadius: 18,
                iconSize: 28,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _IconPickerTabStrip(
                    activeMode: activeMode,
                    onSearchIcon: onSearchIcon,
                    onEmoji: onEmoji,
                    onPickImage: onPickImage,
                  ),
                  const SizedBox(height: 7),
                  Text(
                    helperText ?? context.l10n.collectionEntryBlockIconHint,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
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
        if (showSelectionSummary) ...[
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            decoration: BoxDecoration(
              color: palette.surfaceSoft,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: palette.stroke.withValues(alpha: 0.55)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: RichText(
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.25,
                        fontWeight: FontWeight.w600,
                        color: palette.textSecondary,
                      ),
                      children: [
                        TextSpan(
                          text: previewTitle,
                          style: TextStyle(
                            color: palette.textPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        TextSpan(text: ' · ${_selectionLabel(context)}'),
                      ],
                    ),
                  ),
                ),
                if (selection.hasSelection && onClear != null) ...[
                  const SizedBox(width: 10),
                  _IconPickerResetButton(onTap: onClear!),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  _IconPickerMode get _activeMode {
    if ((selection.imagePath ?? '').trim().isNotEmpty) {
      return _IconPickerMode.photo;
    }
    if (normalizeCollectionEmoji(selection.emoji).isNotEmpty) {
      return _IconPickerMode.emoji;
    }
    return _IconPickerMode.search;
  }

  String _selectionLabel(BuildContext context) {
    if ((selection.imagePath ?? '').trim().isNotEmpty) {
      return context.l10n.collectionEntryLocalImageSelected;
    }
    if (normalizeCollectionEmoji(selection.emoji).isNotEmpty) {
      return context.l10n.collectionEntryEmojiSelected;
    }
    if ((selection.iconKey ?? '').trim().isNotEmpty) {
      return collectionIconLabel(selection.iconKey!);
    }
    return context.l10n.collectionEntryBlockIconHint;
  }
}

enum _IconPickerMode { search, emoji, photo }

class _IconPickerTabStrip extends StatelessWidget {
  const _IconPickerTabStrip({
    required this.activeMode,
    required this.onSearchIcon,
    required this.onEmoji,
    required this.onPickImage,
  });

  final _IconPickerMode activeMode;
  final VoidCallback onSearchIcon;
  final VoidCallback onEmoji;
  final VoidCallback onPickImage;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: palette.surfaceSoft,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          _IconPickerTab(
            label: context.l10n.collectionEntrySearchIcon,
            active: activeMode == _IconPickerMode.search,
            onTap: onSearchIcon,
          ),
          _IconPickerTab(
            label: context.l10n.collectionEntryUseEmoji,
            active: activeMode == _IconPickerMode.emoji,
            onTap: onEmoji,
          ),
          _IconPickerTab(
            label: context.l10n.collectionEntrySourcePhotos,
            active: activeMode == _IconPickerMode.photo,
            onTap: onPickImage,
          ),
        ],
      ),
    );
  }
}

class _IconPickerTab extends StatelessWidget {
  const _IconPickerTab({
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
    return Expanded(
      child: Material(
        color: active ? palette.surface : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: active ? palette.textPrimary : palette.textMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _IconPickerResetButton extends StatelessWidget {
  const _IconPickerResetButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Text(
          context.l10n.commonRemove,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: palette.danger,
          ),
        ),
      ),
    );
  }
}

Future<CollectionBlockIconSelection?> showCollectionIconSearchSheet(
  BuildContext context, {
  required SearchCompanyBrands searchCompanyBrands,
  required DownloadCompanyLogoToLocal downloadCompanyLogoToLocal,
  String initialQuery = '',
}) {
  return Navigator.of(context).push<CollectionBlockIconSelection>(
    MaterialPageRoute<CollectionBlockIconSelection>(
      builder: (_) => _CollectionIconSearchPage(
        initialQuery: initialQuery,
        searchCompanyBrands: searchCompanyBrands,
        downloadCompanyLogoToLocal: downloadCompanyLogoToLocal,
      ),
      fullscreenDialog: true,
    ),
  );
}

Future<String?> showCollectionEmojiPickerSheet(
  BuildContext context, {
  String initialEmoji = '',
}) {
  return Navigator.of(context).push<String>(
    MaterialPageRoute<String>(
      builder: (_) => _CollectionEmojiPickerPage(initialEmoji: initialEmoji),
      fullscreenDialog: true,
    ),
  );
}

class _CollectionIconSearchPage extends StatefulWidget {
  const _CollectionIconSearchPage({
    required this.initialQuery,
    required this.searchCompanyBrands,
    required this.downloadCompanyLogoToLocal,
  });

  final String initialQuery;
  final SearchCompanyBrands searchCompanyBrands;
  final DownloadCompanyLogoToLocal downloadCompanyLogoToLocal;

  @override
  State<_CollectionIconSearchPage> createState() =>
      _CollectionIconSearchPageState();
}

class _CollectionIconSearchPageState extends State<_CollectionIconSearchPage> {
  late final TextEditingController _controller;
  Timer? _debounce;
  int _searchToken = 0;
  bool _isSearching = false;
  String? _selectingDomain;
  List<CompanyBrandSearchResultEntity> _brandSuggestions =
      const <CompanyBrandSearchResultEntity>[];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery.trim());
    if (_controller.text.trim().length >= 2) {
      _scheduleLookup(_controller.text.trim());
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final query = _controller.text.trim();
    final localMatches = searchCollectionIconKeys(
      query,
    ).take(16).toList(growable: false);
    final hasResults = _brandSuggestions.isNotEmpty || localMatches.isNotEmpty;

    return Scaffold(
      backgroundColor: palette.background,
      appBar: GenericAppBar(
        backgroundColor: palette.background,
        centerTitle: false,
        titleSpacing: 0,
        onBackPressed: () => Navigator.of(context).maybePop(),
        title: context.l10n.collectionEntrySearchIcon,
        titleStyle: TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.w700,
          color: palette.textPrimary,
        ),
      ),
      body: SafeArea(
        top: false,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              24 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            children: [
              CollectionsSurfaceCard(
                radius: 20,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                child: TextField(
                  controller: _controller,
                  autofocus: true,
                  textInputAction: TextInputAction.search,
                  onChanged: _scheduleLookup,
                  decoration: InputDecoration(
                    hintText: context.l10n.collectionEntrySearchIcon,
                    border: InputBorder.none,
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: palette.textMuted,
                    ),
                    suffixIcon: query.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              _controller.clear();
                              _debounce?.cancel();
                              _searchToken++;
                              setState(() {
                                _isSearching = false;
                                _brandSuggestions =
                                    const <CompanyBrandSearchResultEntity>[];
                              });
                            },
                            icon: Icon(
                              Icons.close_rounded,
                              color: palette.textMuted,
                            ),
                          ),
                  ),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: palette.textPrimary,
                  ),
                ),
              ),
              if (_isSearching) ...[
                const SizedBox(height: 14),
                const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.2),
                  ),
                ),
              ],
              if (_brandSuggestions.isNotEmpty) ...[
                const SizedBox(height: 16),
                ..._brandSuggestions.map((suggestion) {
                  final isSelecting = _selectingDomain == suggestion.domain;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _BrandResultTile(
                      suggestion: suggestion,
                      isBusy: isSelecting,
                      onTap: () => _selectBrandSuggestion(suggestion),
                    ),
                  );
                }),
              ],
              if (localMatches.isNotEmpty) ...[
                const SizedBox(height: 16),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: localMatches.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.96,
                  ),
                  itemBuilder: (context, index) {
                    final iconKey = localMatches[index];
                    return InkWell(
                      onTap: () {
                        FocusManager.instance.primaryFocus?.unfocus();
                        Navigator.of(
                          context,
                        ).pop(CollectionBlockIconSelection(iconKey: iconKey));
                      },
                      borderRadius: BorderRadius.circular(18),
                      child: Ink(
                        decoration: BoxDecoration(
                          color: palette.surfaceSoft,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: palette.stroke),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              collectionIconFromKey(iconKey),
                              size: 24,
                              color: palette.textPrimary,
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                              ),
                              child: Text(
                                collectionIconLabel(iconKey),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: palette.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
              if (!_isSearching && !hasResults) ...[
                const SizedBox(height: 20),
                Text(
                  context.l10n.collectionEntryNoIconsFound,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: palette.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _scheduleLookup(String rawQuery) {
    final query = rawQuery.trim();
    _debounce?.cancel();
    if (query.length < 2) {
      _searchToken++;
      if (_brandSuggestions.isNotEmpty || _isSearching) {
        setState(() {
          _isSearching = false;
          _brandSuggestions = const <CompanyBrandSearchResultEntity>[];
        });
      }
      return;
    }

    final token = ++_searchToken;
    _debounce = Timer(const Duration(milliseconds: 260), () async {
      if (!mounted) {
        return;
      }
      setState(() => _isSearching = true);
      try {
        final results = await widget.searchCompanyBrands(query: query);
        if (!mounted || token != _searchToken) {
          return;
        }
        final current = _controller.text.trim();
        if (current != query) {
          return;
        }
        final merged = <String>{};
        final filtered = <CompanyBrandSearchResultEntity>[];
        for (final item in results) {
          final key = '${item.name.trim().toLowerCase()}|${item.domain}';
          if (!merged.add(key)) {
            continue;
          }
          filtered.add(item);
          if (filtered.length >= 8) {
            break;
          }
        }
        setState(() {
          _isSearching = false;
          _brandSuggestions = filtered;
        });
      } catch (_) {
        if (!mounted || token != _searchToken) {
          return;
        }
        setState(() {
          _isSearching = false;
          _brandSuggestions = const <CompanyBrandSearchResultEntity>[];
        });
      }
    });
  }

  Future<void> _selectBrandSuggestion(
    CompanyBrandSearchResultEntity suggestion,
  ) async {
    if (_selectingDomain != null) {
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _selectingDomain = suggestion.domain);
    try {
      final localPath = await widget.downloadCompanyLogoToLocal(
        iconUrl: suggestion.iconUrl,
        domain: suggestion.domain,
      );
      if (!mounted) {
        return;
      }
      if ((localPath ?? '').trim().isEmpty) {
        setState(() => _selectingDomain = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.collectionEntryNoIconsFound)),
        );
        return;
      }
      Navigator.of(
        context,
      ).pop(CollectionBlockIconSelection(imagePath: localPath!.trim()));
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _selectingDomain = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.collectionEntryNoIconsFound)),
      );
    }
  }
}

class _BrandResultTile extends StatelessWidget {
  const _BrandResultTile({
    required this.suggestion,
    required this.isBusy,
    required this.onTap,
  });

  final CompanyBrandSearchResultEntity suggestion;
  final bool isBusy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return InkWell(
      onTap: isBusy ? null : onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: palette.stroke),
          boxShadow: [
            BoxShadow(
              color: palette.shadow,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            CompanyLogoAvatar(
              serviceName: suggestion.name,
              serviceUrl: suggestion.domain,
              imageUrl: suggestion.iconUrl,
              size: 44,
              borderRadius: BorderRadius.circular(14),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    suggestion.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: palette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    suggestion.domain,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: palette.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            isBusy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2.1),
                  )
                : Icon(Icons.chevron_right_rounded, color: palette.textMuted),
          ],
        ),
      ),
    );
  }
}

class _CollectionEmojiPickerPage extends StatefulWidget {
  const _CollectionEmojiPickerPage({required this.initialEmoji});

  final String initialEmoji;

  @override
  State<_CollectionEmojiPickerPage> createState() =>
      _CollectionEmojiPickerPageState();
}

class _CollectionEmojiPickerPageState
    extends State<_CollectionEmojiPickerPage> {
  static const List<String> _suggested = <String>[
    '📁',
    '🗂️',
    '🧳',
    '🏠',
    '🏢',
    '🎓',
    '💼',
    '💳',
    '✈️',
    '📚',
    '🛠️',
    '⭐',
    '❤️',
    '🔒',
    '📌',
    '🧾',
  ];

  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: normalizeCollectionEmoji(widget.initialEmoji),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final value = normalizeCollectionEmoji(_controller.text);

    return Scaffold(
      backgroundColor: palette.background,
      appBar: GenericAppBar(
        backgroundColor: palette.background,
        centerTitle: false,
        titleSpacing: 0,
        onBackPressed: () => Navigator.of(context).maybePop(),
        title: context.l10n.collectionEntryUseEmoji,
        titleStyle: TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.w700,
          color: palette.textPrimary,
        ),
      ),
      body: SafeArea(
        top: false,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              24 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            children: [
              CollectionsSurfaceCard(
                radius: 24,
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Container(
                      width: 82,
                      height: 82,
                      decoration: BoxDecoration(
                        color: palette.primarySoft,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      alignment: Alignment.center,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          value.isEmpty ? '🙂' : value,
                          maxLines: 1,
                          softWrap: false,
                          style: const TextStyle(fontSize: 34),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _controller,
                      autofocus: true,
                      textInputAction: TextInputAction.done,
                      onChanged: (_) => setState(() {}),
                      onSubmitted: (_) => _save(),
                      inputFormatters: const [_SingleEmojiTextInputFormatter()],
                      decoration: InputDecoration(
                        hintText: context.l10n.collectionEntryEmojiHint,
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
                            color: palette.primary,
                            width: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final emoji in _suggested)
                    InkWell(
                      onTap: () {
                        FocusManager.instance.primaryFocus?.unfocus();
                        Navigator.of(context).pop(emoji);
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Ink(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: palette.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: palette.stroke),
                        ),
                        child: Center(
                          child: Text(
                            emoji,
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              CollectionsPrimaryButton(
                label: context.l10n.commonSave,
                icon: Icons.check_rounded,
                onPressed: value.isEmpty ? null : _save,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _save() {
    final value = normalizeCollectionEmoji(_controller.text);
    if (value.isEmpty) {
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context).pop(value);
  }
}

class _SingleEmojiTextInputFormatter extends TextInputFormatter {
  const _SingleEmojiTextInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final normalized = normalizeCollectionEmoji(newValue.text);
    return TextEditingValue(
      text: normalized,
      selection: TextSelection.collapsed(offset: normalized.length),
      composing: TextRange.empty,
    );
  }
}
