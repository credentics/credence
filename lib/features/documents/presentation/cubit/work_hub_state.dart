import 'package:pass_doc_manager/domain/documents/entities/work_company_vault_entity.dart';

enum WorkHubViewStatus { initial, loading, ready, error }

enum WorkHubFilter { all, recent, pinned }

class WorkHubState {
  const WorkHubState({
    required this.viewStatus,
    required this.companies,
    required this.query,
    required this.filter,
    required this.errorMessage,
  });

  const WorkHubState.initial()
    : viewStatus = WorkHubViewStatus.initial,
      companies = const [],
      query = '',
      filter = WorkHubFilter.all,
      errorMessage = null;

  final WorkHubViewStatus viewStatus;
  final List<WorkCompanyVaultEntity> companies;
  final String query;
  final WorkHubFilter filter;
  final String? errorMessage;

  bool get showFeaturedCard => visibleCompanies.isNotEmpty;

  List<WorkCompanyVaultEntity> get visibleCompanies {
    Iterable<WorkCompanyVaultEntity> result = companies;

    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isNotEmpty) {
      result = result.where((company) {
        return company.companyName.toLowerCase().contains(normalizedQuery) ||
            company.roleLabel.toLowerCase().contains(normalizedQuery) ||
            company.addressLabel.toLowerCase().contains(normalizedQuery) ||
            company.contactLabel.toLowerCase().contains(normalizedQuery);
      });
    }

    switch (filter) {
      case WorkHubFilter.all:
        break;
      case WorkHubFilter.recent:
        result = result.where(
          (company) =>
              company.lastAccessAt != null ||
              DateTime.now().difference(company.lastUpdatedAt).inDays <= 14,
        );
        break;
      case WorkHubFilter.pinned:
        result = result.where((company) => company.isPinned);
        break;
    }

    return result.toList(growable: false);
  }

  WorkHubState copyWith({
    WorkHubViewStatus? viewStatus,
    List<WorkCompanyVaultEntity>? companies,
    String? query,
    WorkHubFilter? filter,
    String? errorMessage,
    bool clearError = false,
  }) {
    return WorkHubState(
      viewStatus: viewStatus ?? this.viewStatus,
      companies: companies ?? this.companies,
      query: query ?? this.query,
      filter: filter ?? this.filter,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
