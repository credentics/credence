import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pass_doc_manager/app/di/injection.dart';
import 'package:pass_doc_manager/core/utils/sensitive_clipboard.dart';
import 'package:pass_doc_manager/app/presentation/widgets/desktop_context_menu.dart';
import 'package:pass_doc_manager/app/presentation/widgets/desktop_list_item_wrapper.dart';
import 'package:pass_doc_manager/app/presentation/widgets/vault_error_state.dart';
import 'package:pass_doc_manager/app/theme/app_palette.dart';
import 'package:pass_doc_manager/domain/branding/usecases/download_company_logo_to_local.dart';
import 'package:pass_doc_manager/domain/branding/usecases/search_company_brands.dart';
import 'package:pass_doc_manager/domain/credentials/entities/credential_security_status.dart';
import 'package:pass_doc_manager/domain/credentials/entities/credential_summary_entity.dart';
import 'package:pass_doc_manager/domain/credentials/entities/credential_category.dart';
import 'package:pass_doc_manager/domain/credentials/usecases/create_credential.dart';
import 'package:pass_doc_manager/domain/credentials/usecases/get_credential_detail.dart';
import 'package:pass_doc_manager/domain/credentials/usecases/get_credential_summaries.dart';
import 'package:pass_doc_manager/domain/credentials/usecases/mark_credential_used.dart';
import 'package:pass_doc_manager/domain/credentials/usecases/toggle_credential_favorite.dart';
import 'package:pass_doc_manager/domain/documents/entities/document_category_type.dart';
import 'package:pass_doc_manager/domain/documents/usecases/get_document_library_overview.dart';
import 'package:pass_doc_manager/domain/documents/usecases/get_identity_documents.dart';
import 'package:pass_doc_manager/domain/documents/usecases/get_work_company_vaults.dart';
import 'package:pass_doc_manager/domain/password_tools/usecases/evaluate_password_health.dart';
import 'package:pass_doc_manager/domain/password_tools/usecases/generate_password.dart';
import 'package:pass_doc_manager/domain/vault_sync/usecases/get_vault_sync_settings.dart';
import 'package:pass_doc_manager/domain/vault_sync/usecases/get_vault_sync_status.dart';
import 'package:pass_doc_manager/domain/vault_sync/usecases/run_vault_sync_now.dart';
import 'package:pass_doc_manager/domain/vault_sync/usecases/save_vault_sync_settings.dart';
import 'package:pass_doc_manager/app/presentation/widgets/adaptive_modal.dart';
import 'package:pass_doc_manager/features/credentials/presentation/cubit/credential_detail_cubit.dart';
import 'package:pass_doc_manager/features/credentials/presentation/cubit/credential_list_cubit.dart';
import 'package:pass_doc_manager/features/credentials/presentation/cubit/credential_list_state.dart';
import 'package:pass_doc_manager/features/credentials/presentation/pages/credential_detail_page.dart';
import 'package:pass_doc_manager/features/credentials/presentation/widgets/credential_empty_state.dart';
import 'package:pass_doc_manager/features/credentials/presentation/widgets/credential_edit_sheet.dart';
import 'package:pass_doc_manager/features/credentials/presentation/widgets/credential_list_item_card.dart';
import 'package:pass_doc_manager/features/credentials/presentation/widgets/credentials_reference_ui.dart';
import 'package:pass_doc_manager/features/credentials/presentation/widgets/desktop_sidebar.dart';
import 'package:pass_doc_manager/features/collections/presentation/pages/collection_dashboard_page.dart';
import 'package:pass_doc_manager/features/collections/presentation/pages/collections_list_page.dart';
import 'package:pass_doc_manager/features/documents/presentation/pages/documents_library_page.dart';
import 'package:pass_doc_manager/features/documents/presentation/pages/identity_documents_page.dart';
import 'package:pass_doc_manager/features/documents/presentation/pages/work_hub_page.dart';
import 'package:pass_doc_manager/features/generator/presentation/pages/password_generator_page.dart';
import 'package:pass_doc_manager/features/credentials/presentation/widgets/credence_icon.dart';
import 'package:pass_doc_manager/features/settings/presentation/pages/vault_sync_settings_page.dart';
import 'package:pass_doc_manager/features/vault_import/presentation/pages/vault_import_page.dart';
import 'package:pass_doc_manager/l10n/l10n.dart';

class CredentialsListPage extends StatelessWidget {
  CredentialsListPage({
    super.key,
    GetCredentialSummaries? getCredentialSummaries,
    GetCredentialDetail? getCredentialDetail,
    CreateCredential? createCredential,
    MarkCredentialUsed? markCredentialUsed,
    GeneratePassword? generatePassword,
    SearchCompanyBrands? searchCompanyBrands,
    DownloadCompanyLogoToLocal? downloadCompanyLogoToLocal,
    EvaluatePasswordHealth? evaluatePasswordHealth,
    GetDocumentLibraryOverview? getDocumentLibraryOverview,
    GetIdentityDocuments? getIdentityDocuments,
    GetWorkCompanyVaults? getWorkCompanyVaults,
    GetVaultSyncSettings? getVaultSyncSettings,
    SaveVaultSyncSettings? saveVaultSyncSettings,
    GetVaultSyncStatus? getVaultSyncStatus,
    RunVaultSyncNow? runVaultSyncNow,
  }) : getCredentialSummaries = getCredentialSummaries ?? getIt(),
       getCredentialDetail = getCredentialDetail ?? getIt(),
       createCredential = createCredential ?? getIt(),
       markCredentialUsed = markCredentialUsed ?? getIt(),
       generatePassword = generatePassword ?? getIt(),
       searchCompanyBrands = searchCompanyBrands ?? getIt(),
       downloadCompanyLogoToLocal = downloadCompanyLogoToLocal ?? getIt(),
       evaluatePasswordHealth = evaluatePasswordHealth ?? getIt(),
       getDocumentLibraryOverview = getDocumentLibraryOverview ?? getIt(),
       getIdentityDocuments = getIdentityDocuments ?? getIt(),
       getWorkCompanyVaults = getWorkCompanyVaults ?? getIt(),
       getVaultSyncSettings = getVaultSyncSettings ?? getIt(),
       saveVaultSyncSettings = saveVaultSyncSettings ?? getIt(),
       getVaultSyncStatus = getVaultSyncStatus ?? getIt(),
       runVaultSyncNow = runVaultSyncNow ?? getIt();

  final GetCredentialSummaries getCredentialSummaries;
  final GetCredentialDetail getCredentialDetail;
  final CreateCredential createCredential;
  final MarkCredentialUsed markCredentialUsed;
  final GeneratePassword generatePassword;
  final SearchCompanyBrands searchCompanyBrands;
  final DownloadCompanyLogoToLocal downloadCompanyLogoToLocal;
  final EvaluatePasswordHealth evaluatePasswordHealth;
  final GetDocumentLibraryOverview getDocumentLibraryOverview;
  final GetIdentityDocuments getIdentityDocuments;
  final GetWorkCompanyVaults getWorkCompanyVaults;
  final GetVaultSyncSettings getVaultSyncSettings;
  final SaveVaultSyncSettings saveVaultSyncSettings;
  final GetVaultSyncStatus getVaultSyncStatus;
  final RunVaultSyncNow runVaultSyncNow;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          CredentialListCubit(getCredentialSummaries: getCredentialSummaries)
            ..load(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 1080) {
            return _DesktopCredentialsScene(
              getCredentialDetail: getCredentialDetail,
              createCredential: createCredential,
              markCredentialUsed: markCredentialUsed,
              generatePassword: generatePassword,
              searchCompanyBrands: searchCompanyBrands,
              downloadCompanyLogoToLocal: downloadCompanyLogoToLocal,
              evaluatePasswordHealth: evaluatePasswordHealth,
              getDocumentLibraryOverview: getDocumentLibraryOverview,
              getIdentityDocuments: getIdentityDocuments,
              getWorkCompanyVaults: getWorkCompanyVaults,
              getVaultSyncSettings: getVaultSyncSettings,
              saveVaultSyncSettings: saveVaultSyncSettings,
              getVaultSyncStatus: getVaultSyncStatus,
              runVaultSyncNow: runVaultSyncNow,
            );
          }

          return _MobileCredentialsStandaloneScene(
            isTablet: constraints.maxWidth >= 700,
            createCredential: createCredential,
            generatePassword: generatePassword,
            searchCompanyBrands: searchCompanyBrands,
            downloadCompanyLogoToLocal: downloadCompanyLogoToLocal,
            evaluatePasswordHealth: evaluatePasswordHealth,
            getCredentialDetail: getCredentialDetail,
            markCredentialUsed: markCredentialUsed,
          );
        },
      ),
    );
  }
}

class _MobileCredentialsStandaloneScene extends StatelessWidget {
  const _MobileCredentialsStandaloneScene({
    required this.isTablet,
    required this.createCredential,
    required this.generatePassword,
    required this.searchCompanyBrands,
    required this.downloadCompanyLogoToLocal,
    required this.evaluatePasswordHealth,
    required this.getCredentialDetail,
    required this.markCredentialUsed,
  });

  final bool isTablet;
  final CreateCredential createCredential;
  final GeneratePassword generatePassword;
  final SearchCompanyBrands searchCompanyBrands;
  final DownloadCompanyLogoToLocal downloadCompanyLogoToLocal;
  final EvaluatePasswordHealth evaluatePasswordHealth;
  final GetCredentialDetail getCredentialDetail;
  final MarkCredentialUsed markCredentialUsed;

  @override
  Widget build(BuildContext context) {
    final horizontal = isTablet ? 26.0 : 16.0;

    return Scaffold(
      backgroundColor: context.appPalette.background,
      body: SafeArea(
        child: CredentialsAccountsSection(
          horizontalPadding: horizontal,
          onAddPressed: () => openCreateCredentialFlow(
            context,
            createCredential,
            searchCompanyBrands,
            downloadCompanyLogoToLocal,
            evaluatePasswordHealth,
          ),
          onGeneratorTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => PasswordGeneratorPage(
                  generatePassword: generatePassword,
                  evaluatePasswordHealth: evaluatePasswordHealth,
                ),
              ),
            );
          },
          getCredentialDetail: getCredentialDetail,
          markCredentialUsed: markCredentialUsed,
        ),
      ),
    );
  }
}

class CredentialsAccountsSection extends StatelessWidget {
  CredentialsAccountsSection({
    super.key,
    this.horizontalPadding = 16,
    this.onAddPressed,
    this.onGeneratorTap,
    GetCredentialDetail? getCredentialDetail,
    MarkCredentialUsed? markCredentialUsed,
  }) : getCredentialDetail = getCredentialDetail ?? getIt(),
       markCredentialUsed = markCredentialUsed ?? getIt();

  final double horizontalPadding;
  final VoidCallback? onAddPressed;
  final VoidCallback? onGeneratorTap;
  final GetCredentialDetail getCredentialDetail;
  final MarkCredentialUsed markCredentialUsed;

  void _defaultAdd(BuildContext context) {
    openCreateCredentialFlow(
      context,
      getIt<CreateCredential>(),
      getIt<SearchCompanyBrands>(),
      getIt<DownloadCompanyLogoToLocal>(),
      getIt<EvaluatePasswordHealth>(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CredentialsReferencePage(
      child: BlocBuilder<CredentialListCubit, CredentialListState>(
        builder: (context, state) {
          final total = state.items.length;
          final weak = state.items.where(credentialIsWeak).length;
          final reused = state.items.where((item) => item.isReused).length;
          final riskyIds = state.items
              .where(credentialIsRisk)
              .map((item) => item.id)
              .toSet();
          final risk = riskyIds.length;
          final strong = (total - risk).clamp(0, total);
          final score = total == 0
              ? 100
              : ((strong / total) * 100).round().clamp(0, 100);
          final cubit = context.read<CredentialListCubit>();

          return LayoutBuilder(
            builder: (context, constraints) {
              final minHeight =
                  constraints.hasBoundedHeight && constraints.maxHeight > 36
                  ? constraints.maxHeight - 36
                  : 0.0;
              return SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  8,
                  horizontalPadding,
                  28,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: minHeight),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      CredentialsHeader(
                        eyebrow: total == 0
                            ? 'Vault is empty'
                            : '$total logins · $weak weak · $reused reused',
                        title: context.l10n.credentialsTitle,
                        trailing: CredentialsIconButton(
                          icon: Icons.add_rounded,
                          onTap: onAddPressed ?? () => _defaultAdd(context),
                        ),
                        padding: EdgeInsets.zero,
                      ),
                      const SizedBox(height: 16),
                      CredentialsSearchField(
                        hint: 'Search by service or email',
                        onChanged: context.read<CredentialListCubit>().search,
                        trailing: total == 0
                            ? null
                            : CredentialsFieldAction(
                                icon: Icons.tune_rounded,
                                onTap: () => _showFilterSheet(context),
                              ),
                      ),
                      if (total > 0) ...[
                        const SizedBox(height: 12),
                        CredentialsMetricStrip(
                          score: score,
                          strong: strong,
                          reused: reused,
                          weak: weak,
                        ),
                        const SizedBox(height: 14),
                        CredentialsChipRow(
                          children: [
                            CredentialsChip(
                              label: 'All · $total',
                              active:
                                  state.quickFilter ==
                                      CredentialQuickFilter.all &&
                                  state.categoryFilter == null &&
                                  !state.hasSecurityFilters,
                              onTap: cubit.resetFilters,
                            ),
                            CredentialsChip(
                              label:
                                  'Favorites · ${state.items.where((e) => e.isFavorite).length}',
                              active:
                                  state.quickFilter ==
                                  CredentialQuickFilter.favorites,
                              onTap: () => cubit.setQuickFilter(
                                CredentialQuickFilter.favorites,
                              ),
                            ),
                            CredentialsChip(
                              label: 'Risk · $risk',
                              active:
                                  state.quickFilter ==
                                  CredentialQuickFilter.risk,
                              onTap: () => cubit.setQuickFilter(
                                CredentialQuickFilter.risk,
                              ),
                            ),
                            ...credentialCategoryValues
                                .take(4)
                                .map(
                                  (category) => CredentialsChip(
                                    label: category.label,
                                    active: state.categoryFilter == category,
                                    onTap: () =>
                                        cubit.setCategoryFilter(category),
                                  ),
                                ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 14),
                      _MobileAccountsResults(
                        embeddedInParentScrollView: true,
                        onAddTap: onAddPressed ?? () => _defaultAdd(context),
                        onImportTap: () => _openImport(context),
                        onGeneratorTap:
                            onGeneratorTap ??
                            () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => PasswordGeneratorPage(),
                              ),
                            ),
                        getCredentialDetail: getCredentialDetail,
                        markCredentialUsed: markCredentialUsed,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _openImport(BuildContext context) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const VaultImportPage()));
    if (!context.mounted) {
      return;
    }
    await context.read<CredentialListCubit>().load();
  }

  Future<void> _showFilterSheet(BuildContext context) async {
    final cubit = context.read<CredentialListCubit>();
    await showAdaptiveModal<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: const _CredentialFilterSheet(),
      ),
    );
  }
}

class _MobileAccountsResults extends StatelessWidget {
  _MobileAccountsResults({
    this.embeddedInParentScrollView = false,
    required this.onAddTap,
    required this.onImportTap,
    required this.onGeneratorTap,
    required this.getCredentialDetail,
    required this.markCredentialUsed,
    ToggleCredentialFavorite? toggleCredentialFavorite,
  }) : toggleCredentialFavorite = toggleCredentialFavorite ?? getIt();

  final VoidCallback onAddTap;
  final VoidCallback onImportTap;
  final VoidCallback onGeneratorTap;
  final GetCredentialDetail getCredentialDetail;
  final MarkCredentialUsed markCredentialUsed;
  final ToggleCredentialFavorite toggleCredentialFavorite;
  final bool embeddedInParentScrollView;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocBuilder<CredentialListCubit, CredentialListState>(
      builder: (context, state) {
        if (state.status == CredentialListStatus.loading ||
            state.status == CredentialListStatus.initial) {
          return _resultViewport(
            const Center(child: CupertinoActivityIndicator(radius: 12)),
          );
        }

        if (state.status == CredentialListStatus.error) {
          return _resultViewport(
            VaultErrorState(
              icon: Icons.lock_outline_rounded,
              message: state.errorMessage ?? l10n.credentialsUnableLoadAccounts,
              onRetry: () => context.read<CredentialListCubit>().load(),
            ),
          );
        }

        final items = state.filteredItems;
        if (state.items.isEmpty) {
          return CredentialsEmptyReferenceState(
            onAddTap: onAddTap,
            onImportTap: onImportTap,
            onGeneratorTap: onGeneratorTap,
            scrollable: !embeddedInParentScrollView,
          );
        }
        if (items.isEmpty) {
          return _resultViewport(
            Center(
              child: Text(
                state.hasActiveFilters && state.searchQuery.trim().isEmpty
                    ? 'No credentials match these filters.'
                    : state.searchQuery.trim().isEmpty
                    ? l10n.credentialsNoAccountsFound
                    : l10n.credentialsNoResultsForQuery(
                        state.searchQuery.trim(),
                      ),
                textAlign: TextAlign.center,
                style: credentialsBodyStyle(
                  size: 14,
                  weight: FontWeight.w600,
                  color: CredentialsReferenceColors.muted,
                ),
              ),
            ),
          );
        }

        final favorites = items.where((item) => item.isFavorite).toList();
        final regular = items.where((item) => !item.isFavorite).toList();
        final grouped = _groupCredentialItems(regular);

        final children = <Widget>[
          _GeneratorQuickLaunchCard(onTap: onGeneratorTap),
          const SizedBox(height: 16),
          if (favorites.isNotEmpty) ...[
            CredentialsSectionLabel('Favorites · ${favorites.length}'),
            const SizedBox(height: 6),
            CredentialsListGroup(
              children: favorites
                  .map((item) => _itemRow(context, item))
                  .toList(growable: false),
            ),
            const SizedBox(height: 14),
          ],
          for (final entry in grouped.entries) ...[
            CredentialsSectionLabel(entry.key),
            const SizedBox(height: 6),
            CredentialsListGroup(
              children: entry.value
                  .map((item) => _itemRow(context, item))
                  .toList(growable: false),
            ),
            const SizedBox(height: 14),
          ],
        ];

        if (embeddedInParentScrollView) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          );
        }

        return ListView(
          padding: const EdgeInsets.only(bottom: 28),
          children: children,
        );
      },
    );
  }

  Widget _resultViewport(Widget child) {
    if (!embeddedInParentScrollView) {
      return child;
    }
    return SizedBox(height: 260, child: child);
  }

  Widget _itemRow(BuildContext context, CredentialSummaryEntity item) {
    final label = item.breachedCount > 0
        ? 'Breach'
        : item.status == CredentialSecurityStatus.warning
        ? 'Weak'
        : null;
    final status = item.breachedCount > 0
        ? CredentialSecurityStatus.warning
        : item.status;

    return DesktopListItemWrapper(
      onDoubleTap: () => _openDetail(context, item.id),
      contextActions: [
        ContextMenuAction(
          icon: Icons.copy_rounded,
          label: 'Copy Password',
          onSelected: () => _copyPassword(context, item.id),
        ),
        ContextMenuAction(
          icon: Icons.open_in_new_rounded,
          label: 'Open Details',
          onSelected: () => _openDetail(context, item.id),
        ),
        ContextMenuAction(
          icon: item.isFavorite
              ? Icons.star_outline_rounded
              : Icons.star_rounded,
          label: item.isFavorite ? 'Remove Favorite' : 'Add Favorite',
          onSelected: () => _toggleFavorite(context, item.id),
        ),
      ],
      child: CredentialsListRow(
        title: item.displayName,
        subtitle: item.username.trim().isEmpty
            ? _deriveServiceUrl(item.displayName)
            : item.username,
        status: status,
        statusLabel: label,
        brand: CredentialsBrandAvatar(
          serviceName: item.displayName,
          serviceUrl: _deriveServiceUrl(item.displayName),
          logoPath: item.logoPath,
          brandHex: item.brandHex,
          size: 44,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () => _toggleFavorite(context, item.id),
              child: Icon(
                item.isFavorite
                    ? Icons.star_rounded
                    : Icons.star_outline_rounded,
                color: item.isFavorite
                    ? const Color(0xFFC28A2A)
                    : CredentialsReferenceColors.muted,
                size: 19,
              ),
            ),
          ],
        ),
        onTap: () => _openDetail(context, item.id),
      ),
    );
  }

  Future<void> _openDetail(BuildContext context, String id) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider(
          create: (_) =>
              CredentialDetailCubit(getCredentialDetail: getCredentialDetail)
                ..load(credentialId: id),
          child: CredentialDetailPage(),
        ),
      ),
    );
    if (!context.mounted) {
      return;
    }
    await context.read<CredentialListCubit>().load();
  }

  Future<bool> _copyPassword(BuildContext context, String id) async {
    try {
      final detail = await getCredentialDetail(credentialId: id);
      await SensitiveClipboard.copy(detail.password);
      await markCredentialUsed(credentialId: id);
      if (!context.mounted) {
        return true;
      }
      await context.read<CredentialListCubit>().load();
      if (!context.mounted) {
        return true;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.commonPasswordCopiedSecurely)),
      );
      return true;
    } catch (_) {
      if (!context.mounted) {
        return false;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.commonUnableCopyPassword)),
      );
      return false;
    }
  }

  Future<void> _toggleFavorite(BuildContext context, String id) async {
    await toggleCredentialFavorite(credentialId: id);
    if (!context.mounted) {
      return;
    }
    await context.read<CredentialListCubit>().load();
    if (!context.mounted) {
      return;
    }
    final l10n = context.l10n;
    // Find the updated item to check new state
    final state = context.read<CredentialListCubit>().state;
    final updated = state.items.where((e) => e.id == id).firstOrNull;
    final message = (updated?.isFavorite ?? false)
        ? l10n.credentialFavoriteAdded
        : l10n.credentialFavoriteRemoved;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _GeneratorQuickLaunchCard extends StatelessWidget {
  const _GeneratorQuickLaunchCard({required this.onTap, this.compact = false});

  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final titleStyle = TextStyle(
      fontSize: compact ? 16 : 17,
      fontWeight: FontWeight.w700,
      color: compact ? Colors.white : palette.textPrimary,
    );
    final subtitleStyle = TextStyle(
      fontSize: compact ? 13 : 14,
      fontWeight: FontWeight.w500,
      color: compact
          ? Colors.white.withValues(alpha: 0.78)
          : palette.textSecondary,
      height: 1.1,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 12 : 14,
            vertical: compact ? 11 : 12,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: compact
                  ? const Color(0xFF1A57D6)
                  : const Color(0xFFDDD6F6),
            ),
            gradient: compact
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF2467E8), Color(0xFF1E5BD5)],
                  )
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      context.appPalette.surface,
                      context.appPalette.primarySoft,
                    ],
                  ),
            boxShadow: [
              BoxShadow(
                color: context.appPalette.shadow,
                blurRadius: 14,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              _GeneratorCuteIcon(compact: compact),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      context.l10n.credentialsGeneratorCardTitle,
                      style: titleStyle,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.l10n.credentialsGeneratorCardSubtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: subtitleStyle,
                    ),
                  ],
                ),
              ),
              Icon(
                CupertinoIcons.chevron_right,
                size: compact ? 18 : 16,
                color: compact
                    ? Colors.white
                    : context.appPalette.primaryAccent,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GeneratorCuteIcon extends StatelessWidget {
  const _GeneratorCuteIcon({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final boxSize = compact ? 46.0 : 52.0;
    return Container(
      width: boxSize,
      height: boxSize,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: compact
            ? Colors.white.withValues(alpha: 0.16)
            : context.appPalette.primary.withValues(alpha: 0.1),
      ),
      child: Icon(
        Icons.key_rounded,
        size: 24,
        color: compact ? Colors.white : context.appPalette.primary,
      ),
    );
  }
}

enum _DesktopMainSection {
  vault,
  documents,
  collections,
  identity,
  work,
  generator,
  settings,
}

class _DesktopCredentialsScene extends StatefulWidget {
  const _DesktopCredentialsScene({
    required this.getCredentialDetail,
    required this.createCredential,
    required this.markCredentialUsed,
    required this.generatePassword,
    required this.searchCompanyBrands,
    required this.downloadCompanyLogoToLocal,
    required this.evaluatePasswordHealth,
    required this.getDocumentLibraryOverview,
    required this.getIdentityDocuments,
    required this.getWorkCompanyVaults,
    required this.getVaultSyncSettings,
    required this.saveVaultSyncSettings,
    required this.getVaultSyncStatus,
    required this.runVaultSyncNow,
  });

  final GetCredentialDetail getCredentialDetail;
  final CreateCredential createCredential;
  final MarkCredentialUsed markCredentialUsed;
  final GeneratePassword generatePassword;
  final SearchCompanyBrands searchCompanyBrands;
  final DownloadCompanyLogoToLocal downloadCompanyLogoToLocal;
  final EvaluatePasswordHealth evaluatePasswordHealth;
  final GetDocumentLibraryOverview getDocumentLibraryOverview;
  final GetIdentityDocuments getIdentityDocuments;
  final GetWorkCompanyVaults getWorkCompanyVaults;
  final GetVaultSyncSettings getVaultSyncSettings;
  final SaveVaultSyncSettings saveVaultSyncSettings;
  final GetVaultSyncStatus getVaultSyncStatus;
  final RunVaultSyncNow runVaultSyncNow;

  @override
  State<_DesktopCredentialsScene> createState() =>
      _DesktopCredentialsSceneState();
}

class _DesktopCredentialsSceneState extends State<_DesktopCredentialsScene> {
  _DesktopMainSection _activeSection = _DesktopMainSection.vault;
  final GlobalKey<NavigatorState> _rightPaneNavKey =
      GlobalKey<NavigatorState>();

  DesktopSidebarSection get _sidebarSection {
    return switch (_activeSection) {
      _DesktopMainSection.vault => DesktopSidebarSection.vault,
      _DesktopMainSection.documents ||
      _DesktopMainSection.collections ||
      _DesktopMainSection.identity ||
      _DesktopMainSection.work => DesktopSidebarSection.documents,
      _DesktopMainSection.generator => DesktopSidebarSection.generator,
      _DesktopMainSection.settings => DesktopSidebarSection.settings,
    };
  }

  void _switchSection(_DesktopMainSection next) {
    // Always pop any pushed detail page back to the root before switching.
    final navState = _rightPaneNavKey.currentState;
    if (navState != null) {
      while (navState.canPop()) {
        navState.pop();
      }
    }
    if (_activeSection == next) {
      return;
    }
    setState(() {
      _activeSection = next;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          DesktopSidebar(
            activeSection: _sidebarSection,
            onVaultTap: () => _switchSection(_DesktopMainSection.vault),
            onDocumentsTap: () => _switchSection(_DesktopMainSection.documents),
            onGeneratorTap: () => _switchSection(_DesktopMainSection.generator),
            onSecurityTap: () => _switchSection(_DesktopMainSection.settings),
            onImportExportTap: () =>
                _switchSection(_DesktopMainSection.settings),
            onSettingsTap: () => _switchSection(_DesktopMainSection.settings),
          ),
          Expanded(
            child: Navigator(
              key: _rightPaneNavKey,
              onGenerateRoute: (routeSettings) {
                return MaterialPageRoute<void>(
                  settings: routeSettings,
                  builder: (context) {
                    final palette = context.appPalette;
                    return DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [palette.background, palette.backgroundAlt],
                        ),
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        layoutBuilder: (currentChild, previousChildren) {
                          return Stack(
                            alignment: Alignment.topCenter,
                            children: [
                              ...previousChildren,
                              if (currentChild != null) currentChild,
                            ],
                          );
                        },
                        child: switch (_activeSection) {
                          _DesktopMainSection.vault => _buildVaultSection(
                            context,
                          ),
                          _DesktopMainSection.documents => DocumentsLibraryPage(
                            key: const ValueKey('desktop-documents-section'),
                            embeddedDesktop: true,
                            getOverview: widget.getDocumentLibraryOverview,
                            onCollectionsTap: () =>
                                _switchSection(_DesktopMainSection.collections),
                            onCollectionTap: (collectionId) {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => CollectionDashboardPage(
                                    collectionId: collectionId,
                                  ),
                                ),
                              );
                            },
                            onCategoryTap: (category) {
                              if (category == DocumentCategoryType.identity) {
                                _switchSection(_DesktopMainSection.identity);
                                return;
                              }
                              if (category == DocumentCategoryType.work) {
                                _switchSection(_DesktopMainSection.work);
                                return;
                              }
                              final l10n = context.l10n;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    l10n.documentsPageComingSoon(
                                      category.label,
                                    ),
                                  ),
                                ),
                              );
                            },
                            onSyncNowTap: () =>
                                _switchSection(_DesktopMainSection.settings),
                          ),
                          _DesktopMainSection.collections =>
                            const CollectionsListPage(
                              key: ValueKey('desktop-collections-section'),
                              embeddedDesktop: true,
                            ),
                          _DesktopMainSection.identity => IdentityDocumentsPage(
                            key: const ValueKey('desktop-identity-section'),
                            embeddedDesktop: true,
                            getIdentityDocuments: widget.getIdentityDocuments,
                          ),
                          _DesktopMainSection.work => WorkHubPage(
                            key: const ValueKey('desktop-work-section'),
                            embeddedDesktop: true,
                            getWorkCompanyVaults: widget.getWorkCompanyVaults,
                          ),
                          _DesktopMainSection.generator =>
                            PasswordGeneratorPage(
                              key: const ValueKey('desktop-generator-section'),
                              embeddedDesktop: true,
                            ),
                          _DesktopMainSection.settings => VaultSyncSettingsPage(
                            key: const ValueKey('desktop-settings-section'),
                            embeddedDesktop: true,
                          ),
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVaultSection(BuildContext context) {
    return Column(
      key: const ValueKey('desktop-vault-section'),
      children: [
        _Header(
          horizontalPadding: 24,
          onAddPressed: () => openCreateCredentialFlow(
            context,
            widget.createCredential,
            widget.searchCompanyBrands,
            widget.downloadCompanyLogoToLocal,
            widget.evaluatePasswordHealth,
          ),
          onGeneratorPressed: () =>
              _switchSection(_DesktopMainSection.generator),
          onSettingsPressed: () => _switchSection(_DesktopMainSection.settings),
        ),
        Expanded(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 980),
              child: _CredentialResults(
                horizontalPadding: 24,
                desktopMode: true,
                onGeneratorTap: () =>
                    _switchSection(_DesktopMainSection.generator),
                getCredentialDetail: widget.getCredentialDetail,
                markCredentialUsed: widget.markCredentialUsed,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.horizontalPadding,
    required this.onAddPressed,
    required this.onGeneratorPressed,
    required this.onSettingsPressed,
  });

  final double horizontalPadding;
  final VoidCallback onAddPressed;
  final VoidCallback onGeneratorPressed;
  final VoidCallback onSettingsPressed;

  @override
  Widget build(BuildContext context) {
    final isCompact = horizontalPadding <= 16;
    final l10n = context.l10n;

    return Padding(
      padding: EdgeInsets.fromLTRB(horizontalPadding, 12, horizontalPadding, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(
              isCompact ? 12 : 16,
              isCompact ? 12 : 14,
              isCompact ? 12 : 14,
              isCompact ? 10 : 12,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  context.appPalette.surface,
                  context.appPalette.surfaceSoft,
                ],
              ),
              border: Border.all(color: context.appPalette.stroke),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x12000000),
                  blurRadius: 22,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const CredenceIcon(size: 38),
                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.credentialsTitle,
                            style: TextStyle(
                              fontSize: isCompact ? 18 : 20,
                              fontWeight: FontWeight.w700,
                              color: context.appPalette.textPrimary,
                              letterSpacing: -0.35,
                            ),
                          ),
                          SizedBox(height: 1),
                          Text(
                            l10n.credentialsDesktopSubtitle,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: context.appPalette.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _HeaderActionButton(
                      onPressed: onGeneratorPressed,
                      icon: Icons.auto_fix_high_rounded,
                      tooltip: l10n.tabGenerator,
                    ),
                    const SizedBox(width: 8),
                    _HeaderActionButton(
                      onPressed: onSettingsPressed,
                      icon: Icons.settings_rounded,
                      tooltip: l10n.settingsNavSettings,
                    ),
                    const SizedBox(width: 8),
                    _AddCredentialButton(onPressed: onAddPressed),
                  ],
                ),
                BlocBuilder<CredentialListCubit, CredentialListState>(
                  buildWhen: (previous, current) =>
                      previous.status != current.status ||
                      previous.items.length != current.items.length,
                  builder: (context, state) {
                    if (state.items.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    return Column(
                      children: [
                        const SizedBox(height: 12),
                        _HeaderSearchField(
                          onChanged: context.read<CredentialListCubit>().search,
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderActionButton extends StatelessWidget {
  const _HeaderActionButton({
    required this.onPressed,
    required this.icon,
    required this.tooltip,
  });

  final VoidCallback onPressed;
  final IconData icon;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: context.appPalette.surface,
              border: Border.all(color: context.appPalette.stroke),
            ),
            child: Icon(icon, size: 21, color: context.appPalette.textPrimary),
          ),
        ),
      ),
    );
  }
}

class _AddCredentialButton extends StatelessWidget {
  const _AddCredentialButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                context.appPalette.primaryAccent,
                context.appPalette.primary,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: context.appPalette.shadow,
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(Icons.add_rounded, size: 24, color: Colors.white),
        ),
      ),
    );
  }
}

class _HeaderSearchField extends StatelessWidget {
  const _HeaderSearchField({required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: context.appPalette.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: context.l10n.credentialsSearchHint,
        hintStyle: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: context.appPalette.textMuted,
        ),
        prefixIcon: Icon(
          CupertinoIcons.search,
          size: 18,
          color: context.appPalette.textSecondary,
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.76),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: context.appPalette.stroke),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: context.appPalette.primary, width: 1.3),
        ),
      ),
    );
  }
}

class _CredentialResults extends StatelessWidget {
  const _CredentialResults({
    required this.horizontalPadding,
    required this.desktopMode,
    required this.onGeneratorTap,
    required this.getCredentialDetail,
    required this.markCredentialUsed,
  });

  final double horizontalPadding;
  final bool desktopMode;
  final VoidCallback onGeneratorTap;
  final GetCredentialDetail getCredentialDetail;
  final MarkCredentialUsed markCredentialUsed;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CredentialListCubit, CredentialListState>(
      builder: (context, state) {
        if (state.status == CredentialListStatus.loading ||
            state.status == CredentialListStatus.initial) {
          return const Center(child: CupertinoActivityIndicator(radius: 14));
        }

        if (state.status == CredentialListStatus.error) {
          return VaultErrorState(
            icon: Icons.lock_outline_rounded,
            message:
                state.errorMessage ??
                context.l10n.credentialsUnableLoadAccounts,
            onRetry: () => context.read<CredentialListCubit>().load(),
          );
        }

        if (state.items.isEmpty) {
          return Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  0,
                  horizontalPadding,
                  8,
                ),
                child: _GeneratorQuickLaunchCard(
                  onTap: onGeneratorTap,
                  compact: false,
                ),
              ),
              const Expanded(child: CredentialEmptyState()),
            ],
          );
        }

        if (state.filteredItems.isEmpty) {
          final noResultMessage =
              state.hasActiveFilters && state.searchQuery.trim().isEmpty
              ? 'No credentials match these filters.'
              : state.searchQuery.trim().isEmpty
              ? context.l10n.credentialsNoAccountsFound
              : context.l10n.credentialsNoResultsForQuery(
                  state.searchQuery.trim(),
                );
          return Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  0,
                  horizontalPadding,
                  8,
                ),
                child: _GeneratorQuickLaunchCard(onTap: onGeneratorTap),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    noResultMessage,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
            ],
          );
        }

        return Padding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            0,
            horizontalPadding,
            8,
          ),
          child: desktopMode
              ? GridView.builder(
                  itemCount: state.filteredItems.length + 1,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 3.0,
                  ),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _GeneratorQuickLaunchCard(onTap: onGeneratorTap);
                    }
                    final item = state.filteredItems[index - 1];
                    return _itemCard(context, item);
                  },
                )
              : ListView.separated(
                  itemCount: state.filteredItems.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _GeneratorQuickLaunchCard(onTap: onGeneratorTap);
                    }
                    final item = state.filteredItems[index - 1];
                    return _itemCard(context, item);
                  },
                ),
        );
      },
    );
  }

  Widget _itemCard(BuildContext context, CredentialSummaryEntity item) {
    return CredentialListItemCard(
      item: item,
      onTap: () => _openDetails(context, item.id),
      onCopy: () => _copyPassword(context, item.id),
    );
  }

  Future<void> _openDetails(BuildContext context, String id) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider(
          create: (_) =>
              CredentialDetailCubit(getCredentialDetail: getCredentialDetail)
                ..load(credentialId: id),
          child: CredentialDetailPage(),
        ),
      ),
    );
    if (!context.mounted) {
      return;
    }
    await context.read<CredentialListCubit>().load();
  }

  Future<bool> _copyPassword(BuildContext context, String id) async {
    try {
      final detail = await getCredentialDetail(credentialId: id);
      await SensitiveClipboard.copy(detail.password);
      await markCredentialUsed(credentialId: id);
      if (!context.mounted) {
        return true;
      }
      await context.read<CredentialListCubit>().load();
      if (!context.mounted) {
        return true;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.commonPasswordCopiedSecurely)),
      );
      return true;
    } catch (_) {
      if (!context.mounted) {
        return false;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.commonUnableCopyPassword)),
      );
      return false;
    }
  }
}

String _deriveServiceUrl(String serviceName) {
  final normalized = serviceName.trim().toLowerCase().replaceAll(
    RegExp(r'[^a-z0-9]+'),
    '',
  );
  if (normalized.isEmpty) {
    return 'www.account.com';
  }
  return 'www.$normalized.com';
}

Map<String, List<CredentialSummaryEntity>> _groupCredentialItems(
  List<CredentialSummaryEntity> items,
) {
  final sorted = [...items]
    ..sort(
      (a, b) =>
          a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()),
    );
  final grouped = <String, List<CredentialSummaryEntity>>{};
  for (final item in sorted) {
    final name = item.displayName.trim();
    final key = name.isEmpty ? '#' : name.substring(0, 1).toUpperCase();
    grouped.putIfAbsent(key, () => <CredentialSummaryEntity>[]).add(item);
  }
  return grouped;
}

class _CredentialFilterSheet extends StatelessWidget {
  const _CredentialFilterSheet();

  @override
  Widget build(BuildContext context) {
    return CredentialsReferenceTheme(
      child: BlocBuilder<CredentialListCubit, CredentialListState>(
        builder: (context, state) {
          final total = state.items.length;
          final weak = state.items.where(credentialIsWeak).length;
          final reused = state.items.where((item) => item.isReused).length;
          final breached = state.items
              .where((item) => item.breachedCount > 0)
              .length;
          final missingUrl = state.items
              .where((item) => item.isMissingUrl)
              .length;
          final cubit = context.read<CredentialListCubit>();

          return FractionallySizedBox(
            heightFactor: 0.72,
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
              decoration: const BoxDecoration(
                color: CredentialsReferenceColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x33201E1B),
                    blurRadius: 40,
                    offset: Offset(0, -16),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 38,
                        height: 4,
                        decoration: BoxDecoration(
                          color: CredentialsReferenceColors.border,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Filter & sort',
                            style: credentialsDisplayStyle(size: 16),
                          ),
                        ),
                        CredentialsTextButton(
                          label: 'Reset',
                          onTap: cubit.resetFilters,
                          color: CredentialsReferenceColors.fg,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView(
                        children: [
                          const CredentialsSectionLabel('Sort by'),
                          const SizedBox(height: 8),
                          CredentialsListGroup(
                            children: [
                              _RadioFilterRow(
                                label: 'A → Z',
                                selected:
                                    state.sortMode ==
                                    CredentialSortMode.alphabetic,
                                onTap: () => cubit.setSortMode(
                                  CredentialSortMode.alphabetic,
                                ),
                              ),
                              _RadioFilterRow(
                                label: 'Recently used',
                                selected:
                                    state.sortMode ==
                                    CredentialSortMode.recentlyUsed,
                                onTap: () => cubit.setSortMode(
                                  CredentialSortMode.recentlyUsed,
                                ),
                              ),
                              _RadioFilterRow(
                                label: 'Risk first',
                                selected:
                                    state.sortMode ==
                                    CredentialSortMode.riskFirst,
                                onTap: () => cubit.setSortMode(
                                  CredentialSortMode.riskFirst,
                                ),
                              ),
                              _RadioFilterRow(
                                label: 'Recently added',
                                selected:
                                    state.sortMode ==
                                    CredentialSortMode.recentlyAdded,
                                onTap: () => cubit.setSortMode(
                                  CredentialSortMode.recentlyAdded,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const CredentialsSectionLabel('Security'),
                          const SizedBox(height: 8),
                          CredentialsListGroup(
                            children: [
                              _CheckFilterRow(
                                label: 'Show weak',
                                count: weak,
                                value: state.showWeak,
                                onTap: () => cubit.setSecurityFilters(
                                  showWeak: !state.showWeak,
                                ),
                              ),
                              _CheckFilterRow(
                                label: 'Show reused',
                                count: reused,
                                value: state.showReused,
                                onTap: () => cubit.setSecurityFilters(
                                  showReused: !state.showReused,
                                ),
                              ),
                              _CheckFilterRow(
                                label: 'Show breached',
                                count: breached,
                                value: state.showBreached,
                                onTap: () => cubit.setSecurityFilters(
                                  showBreached: !state.showBreached,
                                ),
                              ),
                              _CheckFilterRow(
                                label: 'Missing URL',
                                count: missingUrl,
                                value: state.showMissingUrl,
                                onTap: () => cubit.setSecurityFilters(
                                  showMissingUrl: !state.showMissingUrl,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const CredentialsSectionLabel('Category'),
                          const SizedBox(height: 8),
                          CredentialsChipRow(
                            children: [
                              CredentialsChip(
                                label: 'All · $total',
                                active: state.categoryFilter == null,
                                onTap: () => cubit.setCategoryFilter(null),
                              ),
                              ...credentialCategoryValues.map((category) {
                                final count = state.items
                                    .where((item) => item.category == category)
                                    .length;
                                return CredentialsChip(
                                  label: count == 0
                                      ? category.label
                                      : '${category.label} · $count',
                                  active: state.categoryFilter == category,
                                  onTap: () =>
                                      cubit.setCategoryFilter(category),
                                );
                              }),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    CredentialsPrimaryButton(
                      label: 'Apply · ${state.filteredItems.length} results',
                      onTap: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RadioFilterRow extends StatelessWidget {
  const _RadioFilterRow({
    required this.label,
    this.selected = false,
    this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          children: [
            Expanded(
              child: Text(label, style: credentialsBodyStyle(size: 13.5)),
            ),
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected
                    ? CredentialsReferenceColors.surface
                    : Colors.transparent,
                border: Border.all(
                  color: selected
                      ? CredentialsReferenceColors.fg
                      : CredentialsReferenceColors.border,
                  width: selected ? 5 : 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckFilterRow extends StatelessWidget {
  const _CheckFilterRow({
    required this.label,
    this.count,
    this.value = false,
    this.onTap,
  });

  final String label;
  final int? count;
  final bool value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final effectiveLabel = count == null ? label : '$label · $count';
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          children: [
            Expanded(
              child: Text(
                effectiveLabel,
                style: credentialsBodyStyle(size: 13.5),
              ),
            ),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: value
                    ? CredentialsReferenceColors.fg
                    : CredentialsReferenceColors.surface,
                borderRadius: BorderRadius.circular(5),
                border: value
                    ? null
                    : Border.all(color: CredentialsReferenceColors.border),
              ),
              child: value
                  ? const Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: Colors.white,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> openCreateCredentialFlow(
  BuildContext context,
  CreateCredential createCredential,
  SearchCompanyBrands searchCompanyBrands,
  DownloadCompanyLogoToLocal downloadCompanyLogoToLocal,
  EvaluatePasswordHealth evaluatePasswordHealth,
) async {
  final l10n = context.l10n;
  final isDesktop = MediaQuery.of(context).size.width >= 960;
  CredentialEditorResult? result;

  if (isDesktop) {
    result = await showDialog<CredentialEditorResult>(
      context: context,
      builder: (_) {
        return Dialog(
          elevation: 0,
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 30,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560, maxHeight: 860),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: CredentialEditSheet.create(
                searchCompanyBrands: searchCompanyBrands,
                downloadCompanyLogoToLocal: downloadCompanyLogoToLocal,
                evaluatePasswordHealth: evaluatePasswordHealth,
                presentation: CredentialSheetPresentation.embedded,
              ),
            ),
          ),
        );
      },
    );
  } else {
    result = await showAdaptiveModal<CredentialEditorResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) => CredentialEditSheet.create(
        searchCompanyBrands: searchCompanyBrands,
        downloadCompanyLogoToLocal: downloadCompanyLogoToLocal,
        evaluatePasswordHealth: evaluatePasswordHealth,
      ),
    );
  }

  if (result == null) {
    return;
  }

  try {
    await createCredential(result.toDraftEntity());
    if (!context.mounted) {
      return;
    }

    await context.read<CredentialListCubit>().load();
    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.credentialsAdded)));
  } catch (_) {
    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.credentialsUnableAdd)));
  }
}
