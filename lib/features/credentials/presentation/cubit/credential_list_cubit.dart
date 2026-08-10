import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pass_doc_manager/app/di/injection.dart';
import 'package:pass_doc_manager/domain/credentials/entities/credential_category.dart';
import 'package:pass_doc_manager/domain/credentials/entities/credential_summary_entity.dart';
import 'package:pass_doc_manager/domain/credentials/usecases/get_credential_summaries.dart';
import 'package:pass_doc_manager/features/credentials/presentation/cubit/credential_list_state.dart';

class CredentialListCubit extends Cubit<CredentialListState> {
  CredentialListCubit({GetCredentialSummaries? getCredentialSummaries})
    : _getCredentialSummaries = getCredentialSummaries ?? getIt(),
      super(const CredentialListState.initial());

  final GetCredentialSummaries _getCredentialSummaries;

  Future<void> load() async {
    emit(state.copyWith(status: CredentialListStatus.loading));

    try {
      final items = await _getCredentialSummaries(const NoParams());
      emit(
        state.copyWith(
          status: CredentialListStatus.loaded,
          items: items,
          filteredItems: _applyFilters(items: items),
          errorMessage: null,
        ),
      );
    } catch (_) {
      debugPrint('[CredentialList] Failed to load credentials');
      emit(
        state.copyWith(
          status: CredentialListStatus.error,
          errorMessage: null, // UI uses l10n.credentialsErrorLoad
        ),
      );
    }
  }

  void search(String query) {
    emit(
      state.copyWith(
        searchQuery: query,
        filteredItems: _applyFilters(searchQuery: query),
      ),
    );
  }

  void setSortMode(CredentialSortMode sortMode) {
    emit(
      state.copyWith(
        sortMode: sortMode,
        filteredItems: _applyFilters(sortMode: sortMode),
      ),
    );
  }

  void setQuickFilter(CredentialQuickFilter quickFilter) {
    emit(
      state.copyWith(
        quickFilter: quickFilter,
        categoryFilter: null,
        showWeak: false,
        showReused: false,
        showBreached: false,
        showMissingUrl: false,
        filteredItems: _applyFilters(
          quickFilter: quickFilter,
          clearCategoryFilter: true,
          showWeak: false,
          showReused: false,
          showBreached: false,
          showMissingUrl: false,
        ),
      ),
    );
  }

  void setCategoryFilter(CredentialCategory? category) {
    emit(
      state.copyWith(
        quickFilter: CredentialQuickFilter.all,
        categoryFilter: category,
        filteredItems: _applyFilters(
          quickFilter: CredentialQuickFilter.all,
          categoryFilter: category,
          clearCategoryFilter: category == null,
        ),
      ),
    );
  }

  void setSecurityFilters({
    bool? showWeak,
    bool? showReused,
    bool? showBreached,
    bool? showMissingUrl,
  }) {
    final nextShowWeak = showWeak ?? state.showWeak;
    final nextShowReused = showReused ?? state.showReused;
    final nextShowBreached = showBreached ?? state.showBreached;
    final nextShowMissingUrl = showMissingUrl ?? state.showMissingUrl;

    emit(
      state.copyWith(
        quickFilter: CredentialQuickFilter.all,
        showWeak: nextShowWeak,
        showReused: nextShowReused,
        showBreached: nextShowBreached,
        showMissingUrl: nextShowMissingUrl,
        filteredItems: _applyFilters(
          quickFilter: CredentialQuickFilter.all,
          showWeak: nextShowWeak,
          showReused: nextShowReused,
          showBreached: nextShowBreached,
          showMissingUrl: nextShowMissingUrl,
        ),
      ),
    );
  }

  void resetFilters() {
    emit(
      state.copyWith(
        sortMode: CredentialSortMode.recentlyUsed,
        quickFilter: CredentialQuickFilter.all,
        categoryFilter: null,
        showWeak: false,
        showReused: false,
        showBreached: false,
        showMissingUrl: false,
        filteredItems: _applyFilters(
          sortMode: CredentialSortMode.recentlyUsed,
          quickFilter: CredentialQuickFilter.all,
          clearCategoryFilter: true,
          showWeak: false,
          showReused: false,
          showBreached: false,
          showMissingUrl: false,
        ),
      ),
    );
  }

  List<CredentialSummaryEntity> topCredentials(int count) {
    if (state.items.length <= count) {
      return state.items;
    }
    return state.items.sublist(0, count);
  }

  List<CredentialSummaryEntity> _applyFilters({
    List<CredentialSummaryEntity>? items,
    String? searchQuery,
    CredentialSortMode? sortMode,
    CredentialQuickFilter? quickFilter,
    CredentialCategory? categoryFilter,
    bool clearCategoryFilter = false,
    bool? showWeak,
    bool? showReused,
    bool? showBreached,
    bool? showMissingUrl,
  }) {
    final source = items ?? state.items;
    final query = (searchQuery ?? state.searchQuery).trim().toLowerCase();
    final nextSortMode = sortMode ?? state.sortMode;
    final nextQuickFilter = quickFilter ?? state.quickFilter;
    final nextCategoryFilter = clearCategoryFilter
        ? null
        : categoryFilter ?? state.categoryFilter;
    final nextShowWeak = showWeak ?? state.showWeak;
    final nextShowReused = showReused ?? state.showReused;
    final nextShowBreached = showBreached ?? state.showBreached;
    final nextShowMissingUrl = showMissingUrl ?? state.showMissingUrl;
    final hasSecurityFilters =
        nextShowWeak ||
        nextShowReused ||
        nextShowBreached ||
        nextShowMissingUrl;

    final filtered = source
        .where((item) {
          if (query.isNotEmpty) {
            final service = item.displayName.toLowerCase();
            final username = item.username.toLowerCase();
            final category = item.category.label.toLowerCase();
            if (!service.contains(query) &&
                !username.contains(query) &&
                !category.contains(query)) {
              return false;
            }
          }

          if (nextCategoryFilter != null &&
              item.category != nextCategoryFilter) {
            return false;
          }

          switch (nextQuickFilter) {
            case CredentialQuickFilter.all:
              break;
            case CredentialQuickFilter.favorites:
              if (!item.isFavorite) {
                return false;
              }
              break;
            case CredentialQuickFilter.risk:
              if (!credentialIsRisk(item)) {
                return false;
              }
              break;
          }

          if (hasSecurityFilters) {
            final matchesWeak = nextShowWeak && credentialIsWeak(item);
            final matchesReused = nextShowReused && item.isReused;
            final matchesBreached = nextShowBreached && item.breachedCount > 0;
            final matchesMissingUrl = nextShowMissingUrl && item.isMissingUrl;
            if (!matchesWeak &&
                !matchesReused &&
                !matchesBreached &&
                !matchesMissingUrl) {
              return false;
            }
          }

          return true;
        })
        .toList(growable: false);

    return _sortItems(filtered, nextSortMode);
  }

  List<CredentialSummaryEntity> _sortItems(
    List<CredentialSummaryEntity> items,
    CredentialSortMode sortMode,
  ) {
    final sorted = [...items];
    switch (sortMode) {
      case CredentialSortMode.alphabetic:
        sorted.sort(
          (a, b) => a.displayName.toLowerCase().compareTo(
            b.displayName.toLowerCase(),
          ),
        );
      case CredentialSortMode.recentlyUsed:
        sorted.sort((a, b) {
          final byTime = (b.lastUsedAt?.millisecondsSinceEpoch ?? 0).compareTo(
            a.lastUsedAt?.millisecondsSinceEpoch ?? 0,
          );
          if (byTime != 0) {
            return byTime;
          }
          return a.displayName.toLowerCase().compareTo(
            b.displayName.toLowerCase(),
          );
        });
      case CredentialSortMode.riskFirst:
        sorted.sort((a, b) {
          final byRisk = _riskWeight(b).compareTo(_riskWeight(a));
          if (byRisk != 0) {
            return byRisk;
          }
          return a.displayName.toLowerCase().compareTo(
            b.displayName.toLowerCase(),
          );
        });
      case CredentialSortMode.recentlyAdded:
        sorted.sort((a, b) {
          final byTime = (b.createdAt?.millisecondsSinceEpoch ?? 0).compareTo(
            a.createdAt?.millisecondsSinceEpoch ?? 0,
          );
          if (byTime != 0) {
            return byTime;
          }
          return a.displayName.toLowerCase().compareTo(
            b.displayName.toLowerCase(),
          );
        });
    }
    return sorted;
  }

  int _riskWeight(CredentialSummaryEntity item) {
    var score = 0;
    if (item.breachedCount > 0) {
      score += 4;
    }
    if (item.isReused) {
      score += 3;
    }
    if (credentialIsWeak(item)) {
      score += 2;
    }
    if (item.isMissingUrl) {
      score += 1;
    }
    return score;
  }
}
