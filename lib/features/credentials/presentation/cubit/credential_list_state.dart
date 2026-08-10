import 'package:pass_doc_manager/domain/credentials/entities/credential_category.dart';
import 'package:pass_doc_manager/domain/credentials/entities/credential_security_status.dart';
import 'package:pass_doc_manager/domain/credentials/entities/credential_summary_entity.dart';

enum CredentialListStatus { initial, loading, loaded, error }

enum CredentialSortMode { alphabetic, recentlyUsed, riskFirst, recentlyAdded }

enum CredentialQuickFilter { all, favorites, risk }

const Object _unset = Object();

class CredentialListState {
  const CredentialListState({
    required this.status,
    required this.items,
    required this.filteredItems,
    required this.searchQuery,
    required this.sortMode,
    required this.quickFilter,
    required this.categoryFilter,
    required this.showWeak,
    required this.showReused,
    required this.showBreached,
    required this.showMissingUrl,
    required this.errorMessage,
  });

  const CredentialListState.initial()
    : status = CredentialListStatus.initial,
      items = const [],
      filteredItems = const [],
      searchQuery = '',
      sortMode = CredentialSortMode.recentlyUsed,
      quickFilter = CredentialQuickFilter.all,
      categoryFilter = null,
      showWeak = false,
      showReused = false,
      showBreached = false,
      showMissingUrl = false,
      errorMessage = null;

  final CredentialListStatus status;
  final List<CredentialSummaryEntity> items;
  final List<CredentialSummaryEntity> filteredItems;
  final String searchQuery;
  final CredentialSortMode sortMode;
  final CredentialQuickFilter quickFilter;
  final CredentialCategory? categoryFilter;
  final bool showWeak;
  final bool showReused;
  final bool showBreached;
  final bool showMissingUrl;
  final String? errorMessage;

  bool get hasSecurityFilters =>
      showWeak || showReused || showBreached || showMissingUrl;

  bool get hasActiveFilters =>
      quickFilter != CredentialQuickFilter.all ||
      categoryFilter != null ||
      hasSecurityFilters ||
      sortMode != CredentialSortMode.recentlyUsed;

  CredentialListState copyWith({
    CredentialListStatus? status,
    List<CredentialSummaryEntity>? items,
    List<CredentialSummaryEntity>? filteredItems,
    String? searchQuery,
    CredentialSortMode? sortMode,
    CredentialQuickFilter? quickFilter,
    Object? categoryFilter = _unset,
    bool? showWeak,
    bool? showReused,
    bool? showBreached,
    bool? showMissingUrl,
    Object? errorMessage = _unset,
  }) {
    return CredentialListState(
      status: status ?? this.status,
      items: items ?? this.items,
      filteredItems: filteredItems ?? this.filteredItems,
      searchQuery: searchQuery ?? this.searchQuery,
      sortMode: sortMode ?? this.sortMode,
      quickFilter: quickFilter ?? this.quickFilter,
      categoryFilter: identical(categoryFilter, _unset)
          ? this.categoryFilter
          : categoryFilter as CredentialCategory?,
      showWeak: showWeak ?? this.showWeak,
      showReused: showReused ?? this.showReused,
      showBreached: showBreached ?? this.showBreached,
      showMissingUrl: showMissingUrl ?? this.showMissingUrl,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

bool credentialIsWeak(CredentialSummaryEntity item) {
  return item.status == CredentialSecurityStatus.warning &&
      !item.isReused &&
      item.breachedCount == 0;
}

bool credentialIsRisk(CredentialSummaryEntity item) {
  return credentialIsWeak(item) || item.isReused || item.breachedCount > 0;
}
