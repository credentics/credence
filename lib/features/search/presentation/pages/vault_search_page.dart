import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:pass_doc_manager/app/di/injection.dart';
import 'package:pass_doc_manager/app/presentation/widgets/vault_error_state.dart';
import 'package:pass_doc_manager/app/theme/app_palette.dart';
import 'package:pass_doc_manager/core/utils/document_display_resolver.dart';
import 'package:pass_doc_manager/core/constants/internal_collection_ids.dart';
import 'package:pass_doc_manager/core/extensions/local_file_type_extensions.dart';
import 'package:pass_doc_manager/core/utils/local_asset_path_resolver.dart';
import 'package:pass_doc_manager/domain/bundles/entities/bundle_entity.dart';
import 'package:pass_doc_manager/domain/bundles/entities/bundle_item_type.dart';
import 'package:pass_doc_manager/domain/bundles/usecases/get_bundles.dart';
import 'package:pass_doc_manager/domain/collections/entities/collection_block_entity.dart';
import 'package:pass_doc_manager/domain/collections/entities/collection_block_type.dart';
import 'package:pass_doc_manager/domain/collections/entities/collection_checklist_item_entity.dart';
import 'package:pass_doc_manager/domain/tasks/entities/task_entity.dart';
import 'package:pass_doc_manager/domain/tasks/entities/task_list_entity.dart';
import 'package:pass_doc_manager/domain/tasks/usecases/get_task_lists.dart';
import 'package:pass_doc_manager/features/bundles/presentation/widgets/add_to_bundle_sheet.dart';
import 'package:pass_doc_manager/features/bundles/presentation/widgets/bundles_reference_ui.dart';
import 'package:pass_doc_manager/features/bundles/presentation/pages/bundle_detail_page.dart';
import 'package:pass_doc_manager/features/collections/presentation/pages/collection_block_detail_page.dart';
import 'package:pass_doc_manager/features/collections/presentation/pages/collection_dashboard_page.dart';
import 'package:pass_doc_manager/features/collections/presentation/pages/collection_folder_detail_page.dart';
import 'package:pass_doc_manager/features/documents/presentation/pages/document_file_preview_page.dart';
import 'package:pass_doc_manager/features/search/presentation/widgets/search_reference_ui.dart';
import 'package:pass_doc_manager/features/tasks/presentation/pages/task_list_detail_page.dart';
import 'package:pass_doc_manager/l10n/l10n.dart';
import 'package:pass_doc_manager/data/collections/datasources/local/collections_local_data_source.dart';
import 'package:pass_doc_manager/data/collections/dtos/collection_record_dto.dart';
import 'package:pass_doc_manager/data/credentials/datasources/local/credential_local_data_source.dart';
import 'package:pass_doc_manager/data/credentials/dtos/credential_detail_dto.dart';
import 'package:pass_doc_manager/data/credentials/dtos/credential_summary_dto.dart';
import 'package:pass_doc_manager/data/documents/datasources/local/document_local_data_source.dart';
import 'package:pass_doc_manager/data/documents/dtos/document_record_dto.dart';

class VaultSearchPage extends StatefulWidget {
  const VaultSearchPage({
    super.key,
    this.onOpenCredential,
    this.onOpenDocument,
    this.onOpenCollection,
    this.pickMode = false,
    this.existingBundle,
    this.showBackButton = true,
    this.autoFocus = true,
  });

  final void Function(BuildContext context, String id)? onOpenCredential;
  final void Function(BuildContext context, String id)? onOpenDocument;
  final void Function(BuildContext context, String id)? onOpenCollection;

  /// When true, tapping a result toggles selection instead of navigating.
  /// A bottom action bar appears showing the selection count. On confirm:
  /// - If [existingBundle] is provided, pops with `List<BundleItemCandidate>`.
  /// - Otherwise, opens the "Add to bundle" sheet so the user picks a target.
  final bool pickMode;
  final bool showBackButton;
  final bool autoFocus;

  /// When present, items already in this bundle are rendered as disabled
  /// and cannot be re-selected.
  final BundleEntity? existingBundle;

  @override
  State<VaultSearchPage> createState() => _VaultSearchPageState();
}

class _VaultSearchPageState extends State<VaultSearchPage> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  List<_SearchResult> _results = const [];
  bool _isLoading = false;
  String _query = '';
  String _activeScope = _SearchScope.all;
  String? _searchError;
  Timer? _searchDebounce;
  final List<String> _recentQueries = <String>[];

  /// `<type>:<id>` keys of currently selected results (pick-mode only).
  final Set<String> _selected = {};
  final Map<String, _SearchResult> _selectedResultsByKey = {};

  @override
  void initState() {
    super.initState();
    if (widget.autoFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focusNode.requestFocus();
      });
    }
  }

  String _selectionKey(_SearchResult result) =>
      '${result.type.name}:${result.id}';

  BundleItemType _toBundleItemType(_ResultType type) {
    switch (type) {
      case _ResultType.credential:
        return BundleItemType.credential;
      case _ResultType.document:
        return BundleItemType.document;
      case _ResultType.collection:
        return BundleItemType.collection;
      case _ResultType.collectionBlock:
      case _ResultType.bundle:
      case _ResultType.taskList:
      case _ResultType.task:
        throw UnsupportedError(
          'This result type is not directly bundle-selectable.',
        );
    }
  }

  bool _isAlreadyInBundle(_SearchResult result) {
    final bundle = widget.existingBundle;
    if (bundle == null) return false;
    return bundle.containsRef(
      type: _toBundleItemType(result.type),
      refId: result.id,
    );
  }

  List<BundleItemCandidate> _asCandidates() {
    final picks = <BundleItemCandidate>[];
    for (final key in _selected) {
      final result = _selectedResultsByKey[key];
      if (result == null) continue;
      picks.add(
        BundleItemCandidate(
          type: _toBundleItemType(result.type),
          refId: result.id,
          displayName: result.title,
          subtitle: result.subtitle.isEmpty ? null : result.subtitle,
        ),
      );
    }
    return picks;
  }

  Future<void> _confirmPicks() async {
    final picks = _asCandidates();
    if (picks.isEmpty) return;
    if (widget.existingBundle != null) {
      Navigator.of(context).pop(picks);
      return;
    }
    final bundleId = await showAddToBundleSheet(context, candidates: picks);
    if (!mounted || bundleId == null) return;
    final l10n = context.l10n;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.bundleAddToSnackbar(picks.length))),
    );
    setState(() {
      _selected.clear();
      _selectedResultsByKey.clear();
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {});
    _searchDebounce?.cancel();
    _searchDebounce = Timer(
      const Duration(milliseconds: 180),
      () => _search(query),
    );
  }

  Future<void> _search(String query, {bool force = false}) async {
    final trimmed = _fold(query.trim());
    if (!force && trimmed == _query) return;
    _query = trimmed;

    if (trimmed.isEmpty) {
      setState(() {
        _results = const [];
        _isLoading = false;
        _searchError = null;
        _activeScope = _SearchScope.all;
      });
      return;
    }

    final palette = context.appPalette;

    setState(() {
      _isLoading = true;
      _searchError = null;
    });

    final results = <_SearchResult>[];
    var hadError = false;

    // Search credentials
    try {
      final credDs = getIt<CredentialLocalDataSource>();
      final creds = await credDs.getCredentialSummaries();
      final details = await Future.wait(
        creds.map((c) async {
          final detail = await _credentialDetailForSearch(credDs, c.id);
          return MapEntry(c.id, detail);
        }),
      );
      final detailById = Map<String, CredentialDetailDto?>.fromEntries(details);
      for (final c in creds) {
        final detail = detailById[c.id];
        final matchesCredential =
            _matchesAny(_credentialSearchFields(c, detail), trimmed) ||
            _matchesCredentialIntent(c, detail, trimmed);
        if (matchesCredential) {
          results.add(
            _SearchResult(
              id: c.id,
              title: c.displayName,
              subtitle: c.username,
              detail: _credentialDetailLabel(c, detail),
              type: _ResultType.credential,
              icon: Icons.lock_rounded,
              iconBg: palette.primarySoft,
              iconColor: const Color(0xFF3B82F6),
              groupLabel: 'Credentials',
              pathSegments: [
                'Credentials',
                _formatType(c.categoryKey),
                if (detail != null && detail.accountLabel.trim().isNotEmpty)
                  detail.accountLabel,
                if (c.username.trim().isNotEmpty) c.username,
              ],
              snippet: _snippet(detail?.notes ?? detail?.url ?? ''),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('[Search] Credential search failed: $e');
      hadError = true;
    }

    // Search documents
    try {
      final docDs = getIt<DocumentLocalDataSource>();
      final docs = await docDs.getDocuments();
      for (final d in docs) {
        final spec = DocumentDisplayResolver.resolve(d);
        final matchesDocument =
            _matchesAny(_documentSearchFields(d, spec), trimmed) ||
            _matchesDocumentIntent(d, trimmed);
        if (matchesDocument) {
          results.add(
            _SearchResult(
              id: d.id,
              title: spec.title.isEmpty ? d.fileName : spec.title,
              subtitle: spec.subtitle,
              detail: _docDetail(d, spec),
              type: _ResultType.document,
              icon: Icons.description_rounded,
              iconBg: const Color(0xFFE6F8F1),
              iconColor: const Color(0xFF059669),
              groupLabel: 'Documents',
              pathSegments: [
                'Documents',
                _formatType(d.categoryKey),
                if (d.documentType.trim().isNotEmpty)
                  _formatType(d.documentType),
              ],
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('[Search] Document search failed: $e');
      hadError = true;
    }

    // Search collections
    try {
      final colDs = getIt<CollectionsLocalDataSource>();
      final cols = await colDs.getCollections();
      for (final c in cols) {
        if (c.id == internalSecureNotesCollectionId) {
          continue;
        }
        final matchingBlocks = c.blocks
            .where((block) => _matchesCollectionBlock(c, block, trimmed))
            .toList(growable: false);
        final matchesCollection =
            _matchesCollectionRecord(c, trimmed) ||
            _matchesCollectionIntent(c, trimmed);

        if (matchesCollection || matchingBlocks.isNotEmpty) {
          results.add(
            _SearchResult(
              id: c.id,
              title: c.name,
              subtitle: c.subtitle.isNotEmpty
                  ? c.subtitle
                  : '${c.blocks.length} items',
              type: _ResultType.collection,
              icon: Icons.folder_special_rounded,
              iconBg: const Color(0xFFF3EFFF),
              iconColor: const Color(0xFF8B5CF6),
              groupLabel: 'Collections',
              pathSegments: ['Collections', '${c.blocks.length} items'],
            ),
          );
        }
        if (!widget.pickMode) {
          for (final block in matchingBlocks) {
            results.add(_collectionBlockResult(c, block));
          }
        }
      }
    } catch (e) {
      debugPrint('[Search] Collection search failed: $e');
      hadError = true;
    }

    if (!widget.pickMode) {
      try {
        final bundles = await getIt<GetBundles>()(const GetBundlesParams());
        for (final bundle in bundles) {
          final itemMatches = bundle.items
              .where((item) {
                return _matchesAny([
                  item.displayName,
                  item.subtitle ?? '',
                  item.type.name,
                  item.refId,
                ], trimmed);
              })
              .toList(growable: false);
          final matchesBundle =
              _matchesAny(_bundleSearchFields(bundle), trimmed) ||
              _matchesBundleIntent(bundle, trimmed);
          if (matchesBundle || itemMatches.isNotEmpty) {
            results.add(
              _SearchResult(
                id: bundle.id,
                title: bundle.title,
                subtitle: bundle.purpose ?? '${bundle.itemCount} items',
                detail: _formatType(bundle.status.storageKey),
                type: _ResultType.bundle,
                icon: Icons.folder_zip_rounded,
                iconBg: const Color(0xFFFFF2E8),
                iconColor: const Color(0xFFE15C2F),
                groupLabel: 'Bundles',
                pathSegments: [
                  'Bundles',
                  _formatType(bundle.status.storageKey),
                  '${bundle.itemCount} items',
                ],
                snippet: itemMatches.isEmpty
                    ? _snippet(bundle.description ?? bundle.purpose ?? '')
                    : itemMatches
                          .take(3)
                          .map((item) => item.displayName)
                          .join(' · '),
              ),
            );
          }
        }
      } catch (e) {
        debugPrint('[Search] Bundle search failed: $e');
        hadError = true;
      }

      try {
        final lists = await getIt<GetTaskLists>()(const GetTaskListsParams());
        for (final list in lists) {
          final matchingTasks = list.tasks
              .where((task) {
                return _matchesAny(
                      _taskSearchFields(listTitle: list.title, task: task),
                      trimmed,
                    ) ||
                    _matchesTaskIntent(task, trimmed);
              })
              .toList(growable: false);
          final matchesList =
              _matchesAny(_taskListSearchFields(list), trimmed) ||
              _matchesTaskListIntent(list, trimmed);
          if (matchesList || matchingTasks.isNotEmpty) {
            results.add(
              _SearchResult(
                id: list.id,
                title: list.title,
                subtitle: list.description ?? '${list.openCount} open',
                detail: '${list.doneCount} of ${list.totalCount} done',
                type: _ResultType.taskList,
                icon: Icons.checklist_rounded,
                iconBg: const Color(0xFFEFF6FF),
                iconColor: const Color(0xFF2563EB),
                groupLabel: 'Tasks',
                pathSegments: ['Tasks', 'List', '${list.totalCount} items'],
                snippet: _snippet(list.description ?? ''),
                taskListId: list.id,
              ),
            );
          }
          for (final task in matchingTasks) {
            results.add(
              _SearchResult(
                id: task.id,
                title: task.title,
                subtitle: list.title,
                detail: [
                  _formatType(task.priority.storageKey),
                  if (task.isDone) 'Done',
                  if (task.isDueToday) 'Due today',
                  if (task.isOverdue) 'Overdue',
                ].join(' · '),
                type: _ResultType.task,
                icon: task.isDone
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                iconBg: const Color(0xFFF4F4F5),
                iconColor: task.isDone
                    ? const Color(0xFF16A34A)
                    : const Color(0xFF52525B),
                groupLabel: 'Tasks',
                pathSegments: [
                  'Tasks',
                  list.title,
                  _formatType(task.priority.storageKey),
                ],
                snippet: _snippet(task.notes ?? ''),
                taskListId: list.id,
              ),
            );
          }
        }
      } catch (e) {
        debugPrint('[Search] Task search failed: $e');
        hadError = true;
      }
    }

    if (!mounted || _query != trimmed) return;
    results.sort((a, b) => _rank(a, trimmed).compareTo(_rank(b, trimmed)));
    setState(() {
      _results = results;
      _isLoading = false;
      _searchError = hadError ? context.l10n.searchPartialError : null;
    });
  }

  bool _matchesAny(Iterable<String?> values, String query) {
    final normalizedQuery = query.trim();
    if (normalizedQuery.isEmpty) return false;

    final haystack = _fold(
      values
          .whereType<String>()
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)
          .join(' '),
    );
    if (haystack.isEmpty) return false;
    if (haystack.contains(normalizedQuery)) return true;

    final tokens = _queryTokens(normalizedQuery);
    if (tokens.isEmpty) return false;
    return tokens.every(
      (token) => haystack.contains(token) || _fuzzyTokenMatch(haystack, token),
    );
  }

  List<String> _queryTokens(String query) {
    return query
        .split(RegExp(r'[^a-z0-9]+'))
        .map((token) => token.trim())
        .where((token) => token.length > 1 || int.tryParse(token) != null)
        .toSet()
        .toList(growable: false);
  }

  bool _fuzzyTokenMatch(String haystack, String token) {
    if (token.length < 4) return false;
    final threshold = token.length >= 7 ? 2 : 1;
    final words = haystack
        .split(RegExp(r'[^a-z0-9]+'))
        .where((word) => (word.length - token.length).abs() <= threshold)
        .where((word) => word.length >= 4);
    for (final word in words) {
      if (_levenshteinDistanceLimited(word, token, threshold) <= threshold) {
        return true;
      }
    }
    return false;
  }

  int _levenshteinDistanceLimited(String a, String b, int maxDistance) {
    if ((a.length - b.length).abs() > maxDistance) return maxDistance + 1;
    var previous = List<int>.generate(b.length + 1, (index) => index);
    for (var i = 0; i < a.length; i++) {
      final current = List<int>.filled(b.length + 1, 0);
      current[0] = i + 1;
      var rowMin = current[0];
      for (var j = 0; j < b.length; j++) {
        final insertion = current[j] + 1;
        final deletion = previous[j + 1] + 1;
        final substitution = previous[j] + (a[i] == b[j] ? 0 : 1);
        final value = insertion < deletion
            ? (insertion < substitution ? insertion : substitution)
            : (deletion < substitution ? deletion : substitution);
        current[j + 1] = value;
        if (value < rowMin) rowMin = value;
      }
      if (rowMin > maxDistance) return maxDistance + 1;
      previous = current;
    }
    return previous.last;
  }

  Future<CredentialDetailDto?> _credentialDetailForSearch(
    CredentialLocalDataSource dataSource,
    String id,
  ) async {
    try {
      return await dataSource.getCredentialDetailById(id: id);
    } catch (e) {
      debugPrint('[Search] Credential detail lookup failed for $id: $e');
      return null;
    }
  }

  Iterable<String> _credentialSearchFields(
    CredentialSummaryDto summary,
    CredentialDetailDto? detail,
  ) {
    final hasRisk =
        summary.hasWarning ||
        summary.breachedCount > 0 ||
        (detail != null && !detail.isSecure);
    return [
      summary.id,
      summary.displayName,
      summary.username,
      summary.categoryKey,
      'credential login password account',
      if (summary.isFavorite) 'favorite starred pinned',
      if (hasRisk) 'weak risk warning breached unsafe compromised',
      if (!hasRisk) 'strong secure healthy',
      if (detail != null) ...[
        detail.serviceName,
        detail.accountLabel,
        detail.url,
        _hostFromUrl(detail.url),
        detail.notes,
        detail.mfaRecovery,
        detail.lastSecurityUpdate,
      ],
    ];
  }

  bool _matchesCredentialIntent(
    CredentialSummaryDto summary,
    CredentialDetailDto? detail,
    String query,
  ) {
    final hasRisk =
        summary.hasWarning ||
        summary.breachedCount > 0 ||
        (detail != null && !detail.isSecure);
    if (_isWeakIntent(query) && hasRisk) return true;
    if (_isStrongIntent(query) && !hasRisk) return true;
    if (_isFavoriteIntent(query) && summary.isFavorite) return true;
    return false;
  }

  String _credentialDetailLabel(
    CredentialSummaryDto summary,
    CredentialDetailDto? detail,
  ) {
    final parts = <String>[
      _formatType(summary.categoryKey),
      if (summary.isFavorite) 'Favorite',
      if (summary.breachedCount > 0) 'Breached',
      if (summary.hasWarning || (detail != null && !detail.isSecure)) 'Weak',
    ];
    return parts.join(' • ');
  }

  Iterable<String> _documentSearchFields(
    DocumentRecordDto document,
    DocumentDisplaySpec spec,
  ) {
    return [
      document.id,
      document.title,
      document.fileName,
      spec.title,
      spec.subtitle,
      spec.dateLabel ?? '',
      document.categoryKey,
      document.documentType,
      document.identityGroupKey,
      document.identifierLabel,
      document.identifierValue,
      document.expiryAtIso,
      document.updatedAtIso,
      document.uploadDateIso,
      document.fileSizeLabel,
      document.captureSource,
      'document file scan pdf image',
      if (document.requiresAttention) 'attention expiring expires warning',
      if (document.isFavorite) 'favorite starred pinned',
      if (document.isPrimary) 'primary main',
      if (document.isArchived) 'archived archive',
      if (document.isVerifiedScan) 'verified scan',
      ...document.tags,
      ...document.structuredFields.expand(
        (field) => [field['label'] ?? '', field['value'] ?? ''],
      ),
    ];
  }

  bool _matchesDocumentIntent(DocumentRecordDto document, String query) {
    final expiry = _parseDate(document.expiryAtIso);
    final added =
        _parseDate(document.uploadDateIso) ?? _parseDate(document.updatedAtIso);
    if (_isExpiringIntent(query) &&
        (document.requiresAttention || _isWithinNextDays(expiry, 60))) {
      return true;
    }
    if (_isExpiredIntent(query) && _isPastDate(expiry)) return true;
    if (_isAttentionIntent(query) && document.requiresAttention) return true;
    if (_isRecentIntent(query) && _isWithinPastDays(added, 7)) return true;
    if (_isFavoriteIntent(query) && document.isFavorite) return true;
    if (_isArchivedIntent(query) && document.isArchived) return true;
    return false;
  }

  int _rank(_SearchResult result, String query) {
    final title = _fold(result.title);
    final subtitle = _fold(result.subtitle);
    final detail = _fold(result.detail);
    final snippet = _fold(result.snippet);
    final path = _fold(result.pathSegments.join(' '));
    final tokens = _queryTokens(query);
    var score = 80;

    if (title == query) {
      score = 0;
    } else if (title.startsWith(query)) {
      score = 5;
    } else if (title.contains(query)) {
      score = 10;
    } else if (tokens.isNotEmpty &&
        tokens.every((token) => title.contains(token))) {
      score = 16;
    } else if (subtitle.contains(query) || detail.contains(query)) {
      score = 24;
    } else if (tokens.isNotEmpty &&
        tokens.every((token) => '$subtitle $detail'.contains(token))) {
      score = 30;
    } else if (path.contains(query)) {
      score = 38;
    } else if (snippet.contains(query)) {
      score = 45;
    } else if (tokens.isNotEmpty &&
        tokens.every(
          (token) => '$title $subtitle $detail $path $snippet'.contains(token),
        )) {
      score = 52;
    }

    return score + _resultTypeBias(result.type);
  }

  int _resultTypeBias(_ResultType type) {
    switch (type) {
      case _ResultType.credential:
      case _ResultType.document:
        return 0;
      case _ResultType.collectionBlock:
        return 1;
      case _ResultType.collection:
      case _ResultType.bundle:
      case _ResultType.taskList:
        return 2;
      case _ResultType.task:
        return 3;
    }
  }

  String _fold(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp('[àáâãäåāăą]'), 'a')
        .replaceAll(RegExp('[çćč]'), 'c')
        .replaceAll(RegExp('[ď]'), 'd')
        .replaceAll(RegExp('[èéêëēėęě]'), 'e')
        .replaceAll(RegExp('[ìíîïīį]'), 'i')
        .replaceAll(RegExp('[ñń]'), 'n')
        .replaceAll(RegExp('[òóôõöøō]'), 'o')
        .replaceAll(RegExp('[ùúûüū]'), 'u')
        .replaceAll(RegExp('[ýÿ]'), 'y')
        .replaceAll(RegExp('[žźż]'), 'z');
  }

  String _snippet(String value) {
    final normalized = value.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.length <= 140) return normalized;
    return '${normalized.substring(0, 137)}...';
  }

  bool _matchesCollectionRecord(CollectionRecordDto collection, String query) {
    return _matchesAny(_collectionSearchFields(collection), query);
  }

  bool _matchesCollectionBlock(
    CollectionRecordDto collection,
    CollectionBlockRecordDto block,
    String query,
  ) {
    return _matchesAny(
          _collectionBlockSearchFields(collection, block),
          query,
        ) ||
        _matchesCollectionBlockIntent(block, query);
  }

  Iterable<String> _collectionSearchFields(CollectionRecordDto collection) {
    return [
      collection.id,
      collection.name,
      collection.subtitle,
      collection.iconKey,
      collection.iconEmoji ?? '',
      collection.startDateIso ?? '',
      collection.endDateIso ?? '',
      collection.updatedAtIso,
      'collection workspace folder vault',
      if (collection.isPinLocked) 'pin locked private secure',
      ...collection.blocks.expand(
        (block) => [
          block.title,
          block.subtitle,
          block.description,
          block.typeKey,
          block.url ?? '',
          block.domainLabel ?? '',
          block.locationLabel ?? '',
          ...block.tags,
        ],
      ),
    ];
  }

  bool _matchesCollectionIntent(CollectionRecordDto collection, String query) {
    if (_isRecentIntent(query) &&
        _isWithinPastDays(_parseDate(collection.updatedAtIso), 7)) {
      return true;
    }
    if (_isSecureIntent(query) && collection.isPinLocked) return true;
    return false;
  }

  Iterable<String> _collectionBlockSearchFields(
    CollectionRecordDto collection,
    CollectionBlockRecordDto block,
  ) {
    final ancestorPath = _collectionBlockAncestorTitles(
      collection,
      block,
    ).join(' ');
    final metadataFields = block.metadata.entries
        .where((entry) => !_isInternalCollectionMetadataKey(entry.key))
        .expand((entry) => [entry.key, entry.value]);

    return [
      collection.name,
      collection.subtitle,
      ancestorPath,
      block.id,
      block.title,
      block.subtitle,
      block.description,
      block.typeKey,
      block.url ?? '',
      block.domainLabel ?? '',
      block.locationLabel ?? '',
      block.currencyCode ?? '',
      block.statusLabel ?? '',
      block.fileType ?? '',
      block.fileSizeLabel ?? '',
      block.repeatInterval ?? '',
      block.amount?.toString() ?? '',
      block.createdAtIso,
      block.updatedAtIso,
      block.eventAtIso ?? '',
      block.expiryDateIso ?? '',
      _basenameForSearch(block.filePath),
      _basenameForSearch(block.imageUrl),
      'collection ${block.typeKey} block',
      if (block.isCompleted) 'completed done checked',
      ...block.tags,
      ...metadataFields,
      ...block.checklistItems.map(
        (item) => '${item.title} ${item.isDone ? "done completed" : "open"}',
      ),
    ];
  }

  bool _matchesCollectionBlockIntent(
    CollectionBlockRecordDto block,
    String query,
  ) {
    final eventAt = _parseDate(block.eventAtIso);
    final expiry = _parseDate(block.expiryDateIso);
    final created = _parseDate(block.createdAtIso);
    final updated = _parseDate(block.updatedAtIso);
    if (_isTodayIntent(query) &&
        (_isSameDay(eventAt, DateTime.now()) ||
            _isSameDay(expiry, DateTime.now()))) {
      return true;
    }
    if (_isExpiringIntent(query) && _isWithinNextDays(expiry, 60)) return true;
    if (_isExpiredIntent(query) && _isPastDate(expiry)) return true;
    if (_isRecentIntent(query) &&
        (_isWithinPastDays(created, 7) || _isWithinPastDays(updated, 7))) {
      return true;
    }
    if (_isDoneIntent(query) && block.isCompleted) return true;
    if (_isOpenIntent(query) && !block.isCompleted) return true;
    return false;
  }

  bool _isInternalCollectionMetadataKey(String key) {
    final normalized = key.trim().toLowerCase();
    return normalized.startsWith('ui_');
  }

  List<String> _collectionBlockAncestorTitles(
    CollectionRecordDto collection,
    CollectionBlockRecordDto block,
  ) {
    final byId = {for (final item in collection.blocks) item.id: item};
    final titles = <String>[];
    final visited = <String>{};
    var parentId = block.parentBlockId;

    while (parentId != null && parentId.trim().isNotEmpty) {
      if (!visited.add(parentId)) break;
      final parent = byId[parentId];
      if (parent == null) break;
      final title = parent.title.trim().isNotEmpty
          ? parent.title.trim()
          : _formatType(parent.typeKey);
      titles.insert(0, title);
      parentId = parent.parentBlockId;
    }
    return titles;
  }

  String _basenameForSearch(String? rawValue) {
    final value = (rawValue ?? '').trim();
    if (value.isEmpty) return '';
    final normalized = value.replaceAll('\\', '/');
    final segments = normalized
        .split('/')
        .where((segment) => segment.isNotEmpty);
    if (segments.isEmpty) return normalized;
    return segments.last;
  }

  _SearchResult _collectionBlockResult(
    CollectionRecordDto collection,
    CollectionBlockRecordDto block,
  ) {
    final blockType = CollectionBlockTypeX.fromKey(block.typeKey);
    final visual = _collectionBlockVisual(blockType);
    final ancestorTitles = _collectionBlockAncestorTitles(collection, block);
    final blockTitle = _collectionBlockTitle(block, blockType);
    final subtitleParts = <String>[
      collection.name,
      if (ancestorTitles.isNotEmpty) ancestorTitles.join(' / '),
    ];
    final detailParts = <String>[
      _formatType(block.typeKey),
      if (_basenameForSearch(block.filePath).isNotEmpty &&
          _basenameForSearch(block.filePath) != blockTitle)
        _basenameForSearch(block.filePath),
      if (_basenameForSearch(block.imageUrl).isNotEmpty &&
          _basenameForSearch(block.imageUrl) != blockTitle)
        _basenameForSearch(block.imageUrl),
      if ((block.fileType ?? '').trim().isNotEmpty) block.fileType!.trim(),
      if ((block.fileSizeLabel ?? '').trim().isNotEmpty)
        block.fileSizeLabel!.trim(),
      if ((block.statusLabel ?? '').trim().isNotEmpty)
        block.statusLabel!.trim(),
    ];

    return _SearchResult(
      id: block.id,
      title: blockTitle,
      subtitle: subtitleParts.join(' • '),
      detail: detailParts.join(' • '),
      type: _ResultType.collectionBlock,
      icon: visual.icon,
      iconBg: visual.iconBg,
      iconColor: visual.iconColor,
      groupLabel: _collectionBlockGroupLabel(blockType),
      pathSegments: [
        'Collections',
        collection.name,
        ...ancestorTitles,
        _formatType(block.typeKey),
      ],
      snippet: _collectionBlockSnippet(block),
      collectionId: collection.id,
      collectionBlock: block,
    );
  }

  String _collectionBlockGroupLabel(CollectionBlockType type) {
    switch (type) {
      case CollectionBlockType.note:
        return 'Notes';
      case CollectionBlockType.checklist:
        return 'Checklists';
      case CollectionBlockType.input:
        return 'Input fields';
      case CollectionBlockType.location:
        return 'Locations';
      case CollectionBlockType.reminder:
        return 'Reminders';
      case CollectionBlockType.progress:
        return 'Progress';
      case CollectionBlockType.timeline:
        return 'Timeline';
      case CollectionBlockType.link:
        return 'Links';
      case CollectionBlockType.expense:
        return 'Expenses';
      case CollectionBlockType.document:
      case CollectionBlockType.image:
        return 'Collection files';
      case CollectionBlockType.folder:
      case CollectionBlockType.section:
        return 'Collections';
    }
  }

  String _collectionBlockSnippet(CollectionBlockRecordDto block) {
    if (block.description.trim().isNotEmpty) return _snippet(block.description);
    if (block.checklistItems.isNotEmpty) {
      return block.checklistItems
          .take(5)
          .map((item) => '${item.isDone ? "[x]" : "[ ]"} ${item.title}')
          .join(' · ');
    }
    if (block.metadata.isNotEmpty) {
      return block.metadata.entries
          .where((entry) => !_isInternalCollectionMetadataKey(entry.key))
          .take(3)
          .map((entry) => '${entry.key}: ${entry.value}')
          .join(' · ');
    }
    return '';
  }

  String _collectionBlockTitle(
    CollectionBlockRecordDto block,
    CollectionBlockType blockType,
  ) {
    final title = block.title.trim();
    if (title.isNotEmpty) return title;
    final fileName = _basenameForSearch(block.filePath);
    if (fileName.isNotEmpty) return fileName;
    final imageName = _basenameForSearch(block.imageUrl);
    if (imageName.isNotEmpty) return imageName;
    return blockType.label;
  }

  _SearchResultVisual _collectionBlockVisual(CollectionBlockType type) {
    switch (type) {
      case CollectionBlockType.folder:
        return const _SearchResultVisual(
          icon: Icons.folder_rounded,
          iconBg: Color(0xFFF1F5FF),
          iconColor: Color(0xFF3B82F6),
        );
      case CollectionBlockType.section:
        return const _SearchResultVisual(
          icon: Icons.view_agenda_rounded,
          iconBg: Color(0xFFF1F5FF),
          iconColor: Color(0xFF64748B),
        );
      case CollectionBlockType.document:
        return const _SearchResultVisual(
          icon: Icons.description_rounded,
          iconBg: Color(0xFFEFFBF5),
          iconColor: Color(0xFF059669),
        );
      case CollectionBlockType.note:
        return const _SearchResultVisual(
          icon: Icons.sticky_note_2_rounded,
          iconBg: Color(0xFFFFF7E8),
          iconColor: Color(0xFFD97706),
        );
      case CollectionBlockType.input:
        return const _SearchResultVisual(
          icon: Icons.text_fields_rounded,
          iconBg: Color(0xFFF4F4F5),
          iconColor: Color(0xFF52525B),
        );
      case CollectionBlockType.checklist:
        return const _SearchResultVisual(
          icon: Icons.checklist_rounded,
          iconBg: Color(0xFFEFF6FF),
          iconColor: Color(0xFF2563EB),
        );
      case CollectionBlockType.link:
        return const _SearchResultVisual(
          icon: Icons.link_rounded,
          iconBg: Color(0xFFF5F3FF),
          iconColor: Color(0xFF7C3AED),
        );
      case CollectionBlockType.image:
        return const _SearchResultVisual(
          icon: Icons.image_rounded,
          iconBg: Color(0xFFFFF7ED),
          iconColor: Color(0xFFEA580C),
        );
      case CollectionBlockType.expense:
        return const _SearchResultVisual(
          icon: Icons.receipt_long_rounded,
          iconBg: Color(0xFFFDF2F8),
          iconColor: Color(0xFFDB2777),
        );
      case CollectionBlockType.timeline:
        return const _SearchResultVisual(
          icon: Icons.event_rounded,
          iconBg: Color(0xFFF5F3FF),
          iconColor: Color(0xFF7C3AED),
        );
      case CollectionBlockType.location:
        return const _SearchResultVisual(
          icon: Icons.location_on_rounded,
          iconBg: Color(0xFFEEF2FF),
          iconColor: Color(0xFF4F46E5),
        );
      case CollectionBlockType.reminder:
        return const _SearchResultVisual(
          icon: Icons.alarm_rounded,
          iconBg: Color(0xFFFFF7ED),
          iconColor: Color(0xFFF97316),
        );
      case CollectionBlockType.progress:
        return const _SearchResultVisual(
          icon: Icons.stacked_line_chart_rounded,
          iconBg: Color(0xFFECFDF5),
          iconColor: Color(0xFF10B981),
        );
    }
  }

  String _docDetail(DocumentRecordDto d, DocumentDisplaySpec spec) {
    final parts = <String>[];
    if (spec.dateLabel != null && spec.dateLabel!.isNotEmpty) {
      parts.add(spec.dateLabel!);
    }
    if (d.fileSizeLabel.trim().isNotEmpty) parts.add(d.fileSizeLabel.trim());
    final tags = d.tags.where((t) => t.trim().isNotEmpty).take(3).join(', ');
    if (tags.isNotEmpty) parts.add(tags);
    return parts.join(' \u2022 ');
  }

  Iterable<String> _bundleSearchFields(BundleEntity bundle) {
    return [
      bundle.id,
      bundle.title,
      bundle.purpose ?? '',
      bundle.description ?? '',
      bundle.status.storageKey,
      bundle.templateKey ?? '',
      bundle.createdAt.toIso8601String(),
      bundle.updatedAt.toIso8601String(),
      bundle.lastExportedAt?.toIso8601String() ?? '',
      bundle.lastExportPath ?? '',
      'bundle packet pack export share ready',
      if (bundle.lastExportedAt != null) 'exported shared',
      ...bundle.items.expand(
        (item) => [
          item.id,
          item.refId,
          item.displayName,
          item.subtitle ?? '',
          item.type.name,
          item.addedAt.toIso8601String(),
        ],
      ),
      ...bundle.history.expand(
        (event) => [
          event.id,
          event.kind.storageKey,
          event.detail ?? '',
          event.at.toIso8601String(),
        ],
      ),
    ];
  }

  bool _matchesBundleIntent(BundleEntity bundle, String query) {
    if (_isRecentIntent(query) && _isWithinPastDays(bundle.updatedAt, 7)) {
      return true;
    }
    if (_isExportedIntent(query) && bundle.lastExportedAt != null) return true;
    if (_isOpenIntent(query) && bundle.isEmpty) return true;
    return false;
  }

  Iterable<String> _taskListSearchFields(TaskListEntity list) {
    return [
      list.id,
      list.title,
      list.description ?? '',
      list.iconKey,
      list.accentColorHex,
      list.createdAt.toIso8601String(),
      list.updatedAt.toIso8601String(),
      'task todo checklist list',
      if (list.isArchived) 'archived archive',
      if (list.openCount > 0) 'open pending active',
      if (list.doneCount > 0) 'done completed finished',
      if (list.overdueCount > 0) 'overdue late',
      if (list.pinnedOpenCount > 0) 'pinned important',
      ...list.tasks.expand(
        (task) => _taskSearchFields(listTitle: list.title, task: task),
      ),
    ];
  }

  bool _matchesTaskListIntent(TaskListEntity list, String query) {
    if (_isTodayIntent(query) && list.tasks.any((task) => task.isDueToday)) {
      return true;
    }
    if (_isOverdueIntent(query) && list.overdueCount > 0) return true;
    if (_isDoneIntent(query) && list.doneCount > 0) return true;
    if (_isOpenIntent(query) && list.openCount > 0) return true;
    if (_isPinnedIntent(query) && list.pinnedOpenCount > 0) return true;
    if (_isArchivedIntent(query) && list.isArchived) return true;
    if (_isRecentIntent(query) && _isWithinPastDays(list.updatedAt, 7)) {
      return true;
    }
    return false;
  }

  Iterable<String> _taskSearchFields({
    required String listTitle,
    required TaskEntity task,
  }) {
    return [
      task.id,
      listTitle,
      task.title,
      task.notes ?? '',
      task.priority.storageKey,
      task.linkedRef?.displayNameSnapshot ?? '',
      task.linkedRef?.type ?? '',
      task.linkedRef?.refId ?? '',
      task.createdAt.toIso8601String(),
      task.updatedAt.toIso8601String(),
      task.completedAt?.toIso8601String() ?? '',
      task.dueDate?.toIso8601String() ?? '',
      'task todo checklist item',
      if (task.isDone) 'done completed finished checked',
      if (!task.isDone) 'open pending active',
      if (task.isPinned) 'pinned important',
      if (task.isDueToday) 'today due',
      if (task.isOverdue) 'overdue late',
    ];
  }

  bool _matchesTaskIntent(TaskEntity task, String query) {
    if (_isTodayIntent(query) && task.isDueToday) return true;
    if (_isOverdueIntent(query) && task.isOverdue) return true;
    if (_isDoneIntent(query) && task.isDone) return true;
    if (_isOpenIntent(query) && !task.isDone) return true;
    if (_isPinnedIntent(query) && task.isPinned) return true;
    if (_isRecentIntent(query) && _isWithinPastDays(task.updatedAt, 7)) {
      return true;
    }
    return false;
  }

  String _hostFromUrl(String value) {
    final raw = value.trim();
    if (raw.isEmpty) return '';
    final withScheme = raw.contains('://') ? raw : 'https://$raw';
    return Uri.tryParse(withScheme)?.host.replaceFirst('www.', '') ?? '';
  }

  bool _queryHasAny(String query, Set<String> words) {
    final tokens = _queryTokens(query).toSet();
    return tokens.any(words.contains);
  }

  bool _isWeakIntent(String query) => _queryHasAny(query, {
    'weak',
    'risk',
    'risks',
    'warning',
    'warnings',
    'breach',
    'breached',
    'unsafe',
    'compromised',
  });

  bool _isStrongIntent(String query) =>
      _queryHasAny(query, {'strong', 'healthy', 'safe', 'secure'});

  bool _isSecureIntent(String query) =>
      _queryHasAny(query, {'secure', 'locked', 'private', 'pin'});

  bool _isFavoriteIntent(String query) => _queryHasAny(query, {
    'favorite',
    'favorites',
    'star',
    'starred',
    'pinned',
  });

  bool _isPinnedIntent(String query) =>
      _queryHasAny(query, {'pin', 'pinned', 'important'});

  bool _isExpiringIntent(String query) => _queryHasAny(query, {
    'expiring',
    'expires',
    'expiry',
    'expiration',
    'soon',
    'renew',
    'renewal',
  });

  bool _isExpiredIntent(String query) =>
      _queryHasAny(query, {'expired', 'past'});

  bool _isAttentionIntent(String query) => _queryHasAny(query, {
    'attention',
    'alert',
    'alerts',
    'warning',
    'warnings',
  });

  bool _isRecentIntent(String query) =>
      _queryHasAny(query, {'added', 'recent', 'new', 'week', 'updated'});

  bool _isTodayIntent(String query) => _queryHasAny(query, {'today', 'due'});

  bool _isOverdueIntent(String query) =>
      _queryHasAny(query, {'overdue', 'late'});

  bool _isDoneIntent(String query) =>
      _queryHasAny(query, {'done', 'completed', 'finished', 'checked'});

  bool _isOpenIntent(String query) =>
      _queryHasAny(query, {'open', 'pending', 'active', 'missing', 'empty'});

  bool _isArchivedIntent(String query) =>
      _queryHasAny(query, {'archived', 'archive'});

  bool _isExportedIntent(String query) =>
      _queryHasAny(query, {'exported', 'shared', 'sent'});

  DateTime? _parseDate(String? raw) {
    final value = (raw ?? '').trim();
    if (value.isEmpty) return null;
    return DateTime.tryParse(value)?.toLocal();
  }

  bool _isWithinPastDays(DateTime? value, int days) {
    if (value == null) return false;
    final now = DateTime.now();
    final lowerBound = now.subtract(Duration(days: days));
    return value.isAfter(lowerBound) && !value.isAfter(now);
  }

  bool _isWithinNextDays(DateTime? value, int days) {
    if (value == null) return false;
    final now = DateTime.now();
    final upperBound = now.add(Duration(days: days));
    return !value.isBefore(now) && !value.isAfter(upperBound);
  }

  bool _isPastDate(DateTime? value) {
    if (value == null) return false;
    final today = _dateOnly(DateTime.now());
    return _dateOnly(value).isBefore(today);
  }

  bool _isSameDay(DateTime? value, DateTime target) {
    if (value == null) return false;
    final left = _dateOnly(value);
    final right = _dateOnly(target);
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }

  DateTime _dateOnly(DateTime value) {
    final local = value.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  String _formatType(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return 'Document';
    return trimmed
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    if (widget.pickMode) {
      return _buildBundlePickerScaffold(context);
    }
    return _buildScaffold(context);
  }

  Widget _buildBundlePickerScaffold(BuildContext context) {
    final palette = context.appPalette;
    final bundle = widget.existingBundle;
    return BundleReferencePage(
      maxWidth: 560,
      bottomNavigationBar: _selected.isEmpty
          ? null
          : _bundlePickerActionBar(palette),
      child: Column(
        children: [
          BundleRefHeader(
            title: context.l10n.bundleAddItems,
            meta: bundle == null
                ? 'PICK FROM VAULT'
                : '${bundle.title.toUpperCase()} · ${_selected.length} SELECTED',
            leading: BundleRefIconButton(
              icon: Icons.arrow_back_ios_new_rounded,
              onTap: () => Navigator.of(context).maybePop(),
              size: 42,
            ),
          ),
          BundleRefSearchField(
            controller: _controller,
            hintText: 'Search bundles, items, files...',
            onChanged: (value) {
              setState(() {});
              _search(value);
            },
          ),
          const SizedBox(height: 10),
          _BundlePickerChips(results: _results),
          const SizedBox(height: 12),
          Expanded(child: _buildBundlePickerResults()),
        ],
      ),
    );
  }

  Widget _bundlePickerActionBar(AppPalette palette) {
    final l10n = context.l10n;
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 10, 22, 14),
        decoration: BoxDecoration(
          color: palette.background.withValues(alpha: 0.96),
          border: Border(top: BorderSide(color: palette.stroke)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                l10n.bundleSearchSelectedCount(_selected.length),
                style: TextStyle(
                  fontFamily: bundleFontMono,
                  color: palette.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.35,
                ),
              ),
            ),
            TextButton(
              onPressed: () => setState(() {
                _selected.clear();
                _selectedResultsByKey.clear();
              }),
              child: Text(
                l10n.bundleSearchClearSelection,
                style: const TextStyle(
                  fontFamily: bundleFontBody,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 40,
              child: FilledButton.icon(
                onPressed: _confirmPicks,
                icon: const Icon(Icons.check_rounded, size: 17),
                label: Text(
                  widget.existingBundle != null
                      ? l10n.bundleSearchAddSelected
                      : l10n.bundleSearchAddToBundle,
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: palette.textPrimary,
                  foregroundColor: palette.surface,
                  textStyle: const TextStyle(
                    fontFamily: bundleFontBody,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBundlePickerResults() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (_query.isEmpty) {
      return const _BundlePickerEmptyState();
    }
    if (_results.isEmpty && _searchError != null) {
      return VaultErrorState(
        icon: Icons.search_off_rounded,
        message: _searchError!,
        onRetry: () => _search(_query),
      );
    }
    if (_results.isEmpty) {
      return _BundlePickerMessage(
        icon: Icons.search_off_rounded,
        title: context.l10n.searchNoResults,
        subtitle: context.l10n.searchNoResultsSubtitle,
      );
    }

    final credentials = _results
        .where((result) => result.type == _ResultType.credential)
        .toList(growable: false);
    final documents = _results
        .where((result) => result.type == _ResultType.document)
        .toList(growable: false);
    final collections = _results
        .where((result) => result.type == _ResultType.collection)
        .toList(growable: false);

    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 96),
      children: [
        if (_searchError != null) ...[
          _BundlePickerWarning(message: _searchError!),
          const SizedBox(height: 12),
        ],
        if (documents.isNotEmpty) ...[
          BundleSectionLabel(
            label: '${context.l10n.searchDocuments} · ${documents.length}',
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: 8),
          _bundlePickerGroupCard(documents),
          const SizedBox(height: 16),
        ],
        if (credentials.isNotEmpty) ...[
          BundleSectionLabel(
            label: '${context.l10n.searchCredentials} · ${credentials.length}',
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: 8),
          _bundlePickerGroupCard(credentials),
          const SizedBox(height: 16),
        ],
        if (collections.isNotEmpty) ...[
          BundleSectionLabel(
            label: '${context.l10n.searchCollections} · ${collections.length}',
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: 8),
          _bundlePickerGroupCard(collections),
        ],
      ],
    );
  }

  Widget _bundlePickerGroupCard(List<_SearchResult> items) {
    final palette = context.appPalette;
    return BundleCardShell(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            _bundlePickerRow(items[i]),
            if (i < items.length - 1)
              Divider(height: 1, indent: 66, color: palette.stroke),
          ],
        ],
      ),
    );
  }

  Widget _bundlePickerRow(_SearchResult result) {
    final palette = context.appPalette;
    final alreadyInBundle = _isAlreadyInBundle(result);
    final selected = _selected.contains(_selectionKey(result));
    return Opacity(
      opacity: alreadyInBundle ? 0.55 : 1,
      child: InkWell(
        onTap: alreadyInBundle ? null : () => _onTap(result),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              _BundlePickerCheck(
                selected: selected,
                alreadyInBundle: alreadyInBundle,
              ),
              const SizedBox(width: 10),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: result.iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(result.icon, size: 17, color: result.iconColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: bundleFontBody,
                        color: palette.textPrimary,
                        fontSize: 12.8,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.08,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        if (result.subtitle.trim().isNotEmpty)
                          result.subtitle.trim(),
                        if (result.detail.trim().isNotEmpty)
                          result.detail.trim(),
                      ].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: bundleFontBody,
                        color: palette.textMuted,
                        fontSize: 10.8,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (alreadyInBundle)
                _BundlePickerTag(label: 'IN BUNDLE', color: palette.textMuted)
              else if (selected)
                _BundlePickerTag(label: 'SELECTED', color: palette.primary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScaffold(BuildContext context) {
    final palette = context.appPalette;

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: SearchRefHeader(
                title: 'Search',
                showCancel: widget.showBackButton,
                onCancel: () => Navigator.of(context).maybePop(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: SearchRefInput(
                controller: _controller,
                focusNode: _focusNode,
                hintText: 'Search credentials, documents, collections...',
                onChanged: _onSearchChanged,
                onClear: () {
                  _searchDebounce?.cancel();
                  _controller.clear();
                  _search('');
                },
                showCommandHint: !widget.pickMode,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 0, 0),
              child: SearchRefScopeChips(
                options: _scopeOptions,
                activeKey: _activeScope,
                onChanged: (scope) => setState(() => _activeScope = scope),
              ),
            ),
            Expanded(child: _buildClassicResults()),
            if (widget.pickMode && _selected.isNotEmpty)
              _pickModeActionBar(palette),
          ],
        ),
      ),
    );
  }

  Widget _pickModeActionBar(AppPalette palette) {
    final l10n = context.l10n;
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: palette.surface,
          border: Border(top: BorderSide(color: palette.stroke)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                l10n.bundleSearchSelectedCount(_selected.length),
                style: TextStyle(
                  color: palette.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: () => setState(() {
                _selected.clear();
                _selectedResultsByKey.clear();
              }),
              child: Text(l10n.bundleSearchClearSelection),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: _confirmPicks,
              icon: const Icon(Icons.check_rounded, size: 18),
              label: Text(
                widget.existingBundle != null
                    ? l10n.bundleSearchAddSelected
                    : l10n.bundleSearchAddToBundle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassicResults() {
    if (_isLoading) {
      return SearchRefMessage(
        icon: Icons.sync_rounded,
        title: 'Searching vault...',
        subtitle: 'Index stays local on this device.',
      );
    }
    if (_query.isEmpty) {
      return _emptyState();
    }
    if (_results.isEmpty && _searchError != null) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          SearchRefStatusBanner(
            icon: Icons.warning_amber_rounded,
            title: 'Search is partially unavailable',
            subtitle: _searchError!,
          ),
          const SizedBox(height: 24),
          SearchRefMessage(
            icon: Icons.search_off_rounded,
            title: context.l10n.searchNoResults,
            subtitle: context.l10n.searchNoResultsSubtitle,
          ),
          TextButton(
            onPressed: () => _search(_query, force: true),
            child: const Text('Retry search'),
          ),
        ],
      );
    }
    if (_results.isEmpty) {
      return _noResults();
    }
    return Column(
      children: [
        if (_searchError != null)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFFCC80)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  size: 18,
                  color: Color(0xFFE8890C),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _searchError!,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF7A5500),
                    ),
                  ),
                ),
              ],
            ),
          ),
        Expanded(child: _resultsList()),
      ],
    );
  }

  Widget _emptyState() {
    final palette = context.appPalette;

    final recent = _recentQueries.take(5).toList(growable: false);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        if (recent.isNotEmpty) ...[
          SearchRefGroupHeader(
            label: 'Recent',
            count: recent.length,
            trailing: 'Clear',
          ),
          for (final query in recent)
            SearchRefRecentRow(
              query: query,
              onTap: () => _applyQuery(query),
              onRemove: () => setState(() => _recentQueries.remove(query)),
            ),
          const SizedBox(height: 4),
        ],
        SearchRefGroupHeader(label: 'Quick actions', count: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            SearchRefSuggestedChip(
              label: 'Expiring soon',
              dotColor: palette.warning,
              onTap: () => _applyQuery('expiring soon'),
            ),
            SearchRefSuggestedChip(
              label: 'Weak passwords',
              dotColor: palette.danger,
              onTap: () => _applyQuery('weak'),
            ),
            SearchRefSuggestedChip(
              label: 'Added this week',
              onTap: () => _applyQuery('added'),
            ),
            SearchRefSuggestedChip(
              label: 'Tasks today',
              dotColor: palette.primary,
              onTap: () => _applyQuery('tasks today'),
            ),
            SearchRefSuggestedChip(
              label: 'Overdue tasks',
              dotColor: palette.danger,
              onTap: () => _applyQuery('overdue tasks'),
            ),
            SearchRefSuggestedChip(
              label: 'Favorites',
              onTap: () => _applyQuery('favorites'),
            ),
          ],
        ),
        const SizedBox(height: 28),
        SearchRefMessage(
          icon: Icons.search_rounded,
          title: context.l10n.searchTitle,
          subtitle: context.l10n.searchFindAll,
        ),
        const SearchRefFooter(
          text: 'Local-only index · nothing leaves the device',
        ),
      ],
    );
  }

  Widget _noResults() {
    return SearchRefMessage(
      icon: Icons.search_off_rounded,
      title: context.l10n.searchNoResults,
      subtitle: context.l10n.searchNoResultsSubtitle,
    );
  }

  Widget _resultsList() {
    final visible = _filteredResults;
    if (visible.isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 28, 16, 24),
        children: const [
          SearchRefMessage(
            icon: Icons.filter_alt_off_rounded,
            title: 'No matches in this scope',
            subtitle: 'Switch back to All to see every result.',
          ),
          SearchRefFooter(text: 'Scope filters never hide data permanently'),
        ],
      );
    }
    final grouped = <String, List<_SearchResult>>{};
    for (final result in visible) {
      grouped
          .putIfAbsent(result.groupLabel, () => <_SearchResult>[])
          .add(result);
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
      children: [
        if (_searchError != null) ...[
          SearchRefStatusBanner(
            icon: Icons.warning_amber_rounded,
            title: 'Some sources could not be searched',
            subtitle: _searchError!,
          ),
          const SizedBox(height: 6),
        ],
        for (final entry in grouped.entries) ...[
          _sectionLabel(entry.key, entry.value.length),
          _groupCard(entry.value),
          const SizedBox(height: 4),
        ],
        SearchRefFooter(
          text: 'Accent-insensitive · ${_results.length} results · local index',
        ),
      ],
    );
  }

  List<_SearchResult> get _filteredResults {
    if (_activeScope == _SearchScope.all) return _results;
    return _results
        .where((result) => result.scopeKey == _activeScope)
        .toList(growable: false);
  }

  List<SearchScopeOption> get _scopeOptions {
    int count(String scope) => scope == _SearchScope.all
        ? _results.length
        : _results.where((result) => result.scopeKey == scope).length;
    return [
      SearchScopeOption(
        key: _SearchScope.all,
        label: 'All',
        count: _results.length,
      ),
      SearchScopeOption(
        key: _SearchScope.credentials,
        label: 'Cred',
        count: count(_SearchScope.credentials),
      ),
      SearchScopeOption(
        key: _SearchScope.documents,
        label: 'Docs',
        count: count(_SearchScope.documents),
      ),
      SearchScopeOption(
        key: _SearchScope.collections,
        label: 'Coll',
        count: count(_SearchScope.collections),
      ),
      SearchScopeOption(
        key: _SearchScope.bundles,
        label: 'Bundles',
        count: count(_SearchScope.bundles),
      ),
      SearchScopeOption(
        key: _SearchScope.tasks,
        label: 'Tasks',
        count: count(_SearchScope.tasks),
      ),
    ];
  }

  void _applyQuery(String query) {
    _searchDebounce?.cancel();
    _controller.text = query;
    _controller.selection = TextSelection.collapsed(offset: query.length);
    _focusNode.requestFocus();
    _search(query, force: true);
  }

  void _rememberQuery() {
    final raw = _controller.text.trim();
    if (raw.length < 2) return;
    _recentQueries.removeWhere((item) => _fold(item) == _fold(raw));
    _recentQueries.insert(0, raw);
    if (_recentQueries.length > 5) {
      _recentQueries.removeRange(5, _recentQueries.length);
    }
  }

  Widget _sectionLabel(String label, int count) {
    return SearchRefGroupHeader(label: label, count: count);
  }

  Widget _groupCard(List<_SearchResult> items) {
    final palette = context.appPalette;

    return DecoratedBox(
      decoration: const BoxDecoration(),
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            _resultRow(items[i]),
            if (i < items.length - 1)
              Divider(height: 1, indent: 48, color: palette.stroke),
          ],
        ],
      ),
    );
  }

  Widget _resultRow(_SearchResult result) {
    final isPick = widget.pickMode;
    final alreadyInBundle = _isAlreadyInBundle(result);
    final selected = _selected.contains(_selectionKey(result));

    return SearchRefResultRow(
      title: result.title,
      query: _query,
      pathSegments: result.pathSegments,
      icon: result.icon,
      iconBackground: result.iconBg,
      iconColor: result.iconColor,
      snippet: result.snippet,
      disabled: alreadyInBundle,
      onTap: alreadyInBundle ? null : () => _onTap(result),
      trailing: isPick
          ? _pickIndicator(
              palette: context.appPalette,
              selected: selected,
              alreadyInBundle: alreadyInBundle,
            )
          : null,
    );
  }

  Widget _pickIndicator({
    required AppPalette palette,
    required bool selected,
    required bool alreadyInBundle,
  }) {
    if (alreadyInBundle) {
      return Icon(Icons.check_circle, size: 20, color: palette.success);
    }
    return Icon(
      selected
          ? Icons.check_circle_rounded
          : Icons.radio_button_unchecked_rounded,
      size: 20,
      color: selected ? palette.primary : palette.textMuted,
    );
  }

  void _onTap(_SearchResult result) {
    _rememberQuery();
    if (widget.pickMode) {
      setState(() {
        final key = _selectionKey(result);
        if (_selected.contains(key)) {
          _selected.remove(key);
          _selectedResultsByKey.remove(key);
        } else {
          _selected.add(key);
          _selectedResultsByKey[key] = result;
        }
      });
      return;
    }
    switch (result.type) {
      case _ResultType.credential:
        widget.onOpenCredential?.call(context, result.id);
      case _ResultType.document:
        widget.onOpenDocument?.call(context, result.id);
      case _ResultType.collection:
        if (widget.onOpenCollection != null) {
          widget.onOpenCollection!.call(context, result.id);
        } else {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => CollectionDashboardPage(collectionId: result.id),
            ),
          );
        }
      case _ResultType.collectionBlock:
        _openCollectionBlock(result);
      case _ResultType.bundle:
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => BundleDetailPage(bundleId: result.id),
          ),
        );
      case _ResultType.taskList:
      case _ResultType.task:
        final listId = result.taskListId ?? result.id;
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => TaskListDetailPage(listId: listId),
          ),
        );
    }
  }

  Future<void> _openCollectionBlock(_SearchResult result) async {
    final collectionId = result.collectionId;
    final blockDto = result.collectionBlock;
    if (collectionId == null || blockDto == null) return;

    final block = _toCollectionBlockEntity(blockDto);
    if (block.isFolder || block.isSection) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => CollectionFolderDetailPage(
            collectionId: collectionId,
            folderId: block.id,
          ),
        ),
      );
      return;
    }

    if (block.type == CollectionBlockType.document ||
        block.type == CollectionBlockType.image) {
      _previewCollectionFile(block);
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            CollectionBlockDetailPage(collectionId: collectionId, block: block),
      ),
    );
  }

  void _previewCollectionFile(CollectionBlockEntity block) {
    final path = (block.filePath ?? block.imageUrl ?? '').trim();
    final resolvedPath = LocalAssetPathResolver.resolveRuntimePathSync(path);
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
      MaterialPageRoute<void>(
        builder: (_) => DocumentFilePreviewPage(
          filePath: resolvedPath,
          title: block.title,
          fileName: resolvedPath.split('/').last,
          mimeType: resolvedPath.inferMimeType(),
        ),
      ),
    );
  }

  CollectionBlockEntity _toCollectionBlockEntity(CollectionBlockRecordDto dto) {
    final createdAt = DateTime.tryParse(dto.createdAtIso) ?? DateTime.now();
    final updatedAt = DateTime.tryParse(dto.updatedAtIso) ?? createdAt;
    return CollectionBlockEntity(
      id: dto.id,
      collectionId: dto.collectionId,
      parentBlockId: dto.parentBlockId,
      type: CollectionBlockTypeX.fromKey(dto.typeKey),
      title: dto.title,
      subtitle: dto.subtitle,
      description: dto.description,
      createdAt: createdAt,
      updatedAt: updatedAt,
      imageUrl: dto.imageUrl,
      fileType: dto.fileType,
      fileSizeLabel: dto.fileSizeLabel,
      url: dto.url,
      domainLabel: dto.domainLabel,
      currencyCode: dto.currencyCode,
      amount: dto.amount,
      eventAt: dto.eventAtIso == null
          ? null
          : DateTime.tryParse(dto.eventAtIso!),
      expiryDate: dto.expiryDateIso == null
          ? null
          : DateTime.tryParse(dto.expiryDateIso!),
      latitude: dto.latitude,
      longitude: dto.longitude,
      locationLabel: dto.locationLabel,
      isCompleted: dto.isCompleted,
      statusLabel: dto.statusLabel,
      tags: dto.tags,
      metadata: dto.metadata,
      checklistItems: dto.checklistItems
          .map(
            (item) => CollectionChecklistItemEntity(
              id: item.id,
              title: item.title,
              isDone: item.isDone,
            ),
          )
          .toList(growable: false),
      position: dto.position,
      filePath: dto.filePath,
      repeatInterval: dto.repeatInterval,
    );
  }
}

class _BundlePickerChips extends StatelessWidget {
  const _BundlePickerChips({required this.results});

  final List<_SearchResult> results;

  @override
  Widget build(BuildContext context) {
    final counts = <_ResultType, int>{
      for (final type in _ResultType.values) type: 0,
    };
    for (final result in results) {
      counts[result.type] = (counts[result.type] ?? 0) + 1;
    }
    final chips = <({String label, int count})>[
      (label: 'All', count: results.length),
      (label: 'Documents', count: counts[_ResultType.document] ?? 0),
      (label: 'Credentials', count: counts[_ResultType.credential] ?? 0),
      (label: 'Collections', count: counts[_ResultType.collection] ?? 0),
    ];
    return SizedBox(
      width: double.infinity,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 22),
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var index = 0; index < chips.length; index++) ...[
              _BundlePickerChip(
                label: '${chips[index].label} · ${chips[index].count}',
                active: index == 0,
              ),
              if (index < chips.length - 1) const SizedBox(width: 6),
            ],
          ],
        ),
      ),
    );
  }
}

class _BundlePickerChip extends StatelessWidget {
  const _BundlePickerChip({required this.label, required this.active});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: active ? palette.textPrimary : palette.surfaceSoft,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: active ? palette.textPrimary : palette.stroke,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: bundleFontMono,
          color: active ? palette.surface : palette.textMuted,
          fontSize: 9.8,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.35,
        ),
      ),
    );
  }
}

class _BundlePickerCheck extends StatelessWidget {
  const _BundlePickerCheck({
    required this.selected,
    required this.alreadyInBundle,
  });

  final bool selected;
  final bool alreadyInBundle;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final isOn = selected || alreadyInBundle;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: isOn ? palette.textPrimary : Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isOn ? palette.textPrimary : palette.strokeStrong,
          width: 1.4,
        ),
      ),
      child: isOn
          ? Icon(Icons.check_rounded, color: palette.surface, size: 15)
          : null,
    );
  }
}

class _BundlePickerTag extends StatelessWidget {
  const _BundlePickerTag({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: bundleFontMono,
          color: color,
          fontSize: 8.8,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.35,
        ),
      ),
    );
  }
}

class _BundlePickerEmptyState extends StatelessWidget {
  const _BundlePickerEmptyState();

  @override
  Widget build(BuildContext context) {
    return const _BundlePickerMessage(
      icon: Icons.search_rounded,
      title: 'Find items for this bundle',
      subtitle:
          'Search documents, credentials, and collections from your vault.',
    );
  }
}

class _BundlePickerMessage extends StatelessWidget {
  const _BundlePickerMessage({
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
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: palette.surfaceSoft,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, size: 26, color: palette.textMuted),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: bundleFontDisplay,
                color: palette.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.16,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: bundleFontBody,
                color: palette.textMuted,
                fontSize: 12.5,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BundlePickerWarning extends StatelessWidget {
  const _BundlePickerWarning({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.warning.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.warning.withValues(alpha: 0.24)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, size: 18, color: palette.warning),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontFamily: bundleFontBody,
                color: palette.textPrimary,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _ResultType {
  credential,
  document,
  collection,
  collectionBlock,
  bundle,
  taskList,
  task,
}

class _SearchScope {
  const _SearchScope._();

  static const all = 'all';
  static const credentials = 'credentials';
  static const documents = 'documents';
  static const collections = 'collections';
  static const bundles = 'bundles';
  static const tasks = 'tasks';
}

class _SearchResultVisual {
  const _SearchResultVisual({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
}

class _SearchResult {
  const _SearchResult({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.type,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.groupLabel,
    required this.pathSegments,
    this.detail = '',
    this.snippet = '',
    this.collectionId,
    this.collectionBlock,
    this.taskListId,
  });

  final String id;
  final String title;
  final String subtitle;
  final String detail;
  final _ResultType type;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String groupLabel;
  final List<String> pathSegments;
  final String snippet;
  final String? collectionId;
  final CollectionBlockRecordDto? collectionBlock;
  final String? taskListId;

  String get scopeKey {
    switch (type) {
      case _ResultType.credential:
        return _SearchScope.credentials;
      case _ResultType.document:
        return _SearchScope.documents;
      case _ResultType.collection:
      case _ResultType.collectionBlock:
        return _SearchScope.collections;
      case _ResultType.bundle:
        return _SearchScope.bundles;
      case _ResultType.taskList:
      case _ResultType.task:
        return _SearchScope.tasks;
    }
  }
}
