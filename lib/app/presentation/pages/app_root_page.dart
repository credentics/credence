import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pass_doc_manager/app/di/injection.dart';
import 'package:pass_doc_manager/app/platform/desktop_menu_bar.dart';
import 'package:pass_doc_manager/app/platform/desktop_platform.dart';
import 'package:pass_doc_manager/app/platform/desktop_shortcuts.dart';
import 'package:pass_doc_manager/app/platform/desktop_window_manager.dart';
import 'package:pass_doc_manager/app/presentation/widgets/desktop_nav_sidebar.dart';
import 'package:pass_doc_manager/app/presentation/widgets/credence_ui.dart';
import 'package:pass_doc_manager/app/sync/vault_sync_coordinator.dart';
import 'package:pass_doc_manager/app/sync/vault_data_refresh_signal.dart';
import 'package:pass_doc_manager/app/theme/app_palette.dart';
import 'package:pass_doc_manager/domain/documents/entities/document_category_type.dart';
import 'package:pass_doc_manager/features/credentials/presentation/cubit/credential_detail_cubit.dart';
import 'package:pass_doc_manager/features/credentials/presentation/cubit/credential_list_cubit.dart';
import 'package:pass_doc_manager/features/credentials/presentation/pages/credentials_list_page.dart';
import 'package:pass_doc_manager/features/credentials/presentation/pages/credential_detail_page.dart';
import 'package:pass_doc_manager/features/home/domain/repositories/home_repository.dart';
import 'package:pass_doc_manager/features/home/presentation/cubit/home_cubit.dart';
import 'package:pass_doc_manager/features/home/presentation/pages/home_dashboard_page.dart';
import 'package:pass_doc_manager/features/collections/presentation/pages/collection_dashboard_page.dart';
import 'package:pass_doc_manager/features/bundles/presentation/pages/bundles_list_page.dart';
import 'package:pass_doc_manager/features/backup/presentation/cubit/backup_cubit.dart';
import 'package:pass_doc_manager/features/backup/presentation/cubit/backup_state.dart';
import 'package:pass_doc_manager/features/backup/presentation/cubit/shared_backup_cubit.dart';
import 'package:pass_doc_manager/features/backup/presentation/pages/backup_settings_page.dart';
import 'package:pass_doc_manager/features/collections/presentation/pages/collections_list_page.dart';
import 'package:pass_doc_manager/features/tasks/presentation/pages/task_lists_page.dart';
import 'package:pass_doc_manager/features/documents/presentation/pages/document_detail_page.dart';
import 'package:pass_doc_manager/features/documents/presentation/pages/documents_library_page.dart';
import 'package:pass_doc_manager/features/documents/presentation/pages/identity_documents_page.dart';
import 'package:pass_doc_manager/features/documents/presentation/pages/work_hub_page.dart';
import 'package:pass_doc_manager/features/generator/presentation/pages/password_generator_page.dart';
import 'package:pass_doc_manager/features/notes/presentation/pages/secure_notes_page.dart';
import 'package:pass_doc_manager/features/profile/presentation/pages/profile_page.dart';
import 'package:pass_doc_manager/features/search/presentation/pages/vault_search_page.dart';
import 'package:pass_doc_manager/features/settings/presentation/pages/vault_sync_settings_page.dart';
import 'package:pass_doc_manager/features/vault_health/presentation/cubit/vault_health_cubit.dart';
import 'package:pass_doc_manager/features/vault_health/presentation/pages/vault_health_page.dart';
import 'package:pass_doc_manager/features/vault_sync/presentation/widgets/vault_sync_status_banner.dart';
import 'package:pass_doc_manager/l10n/l10n.dart';

class AppRootPage extends StatelessWidget {
  const AppRootPage({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Desktop: use sidebar navigation (macOS/Windows/Linux or wide window)
        if (DesktopPlatform.isDesktop ||
            constraints.maxWidth >= DesktopPlatform.sidebarBreakpoint) {
          return MultiBlocProvider(
            providers: [
              BlocProvider(create: (_) => CredentialListCubit()..load()),
              BlocProvider.value(value: sharedBackupCubit),
            ],
            child: const _DesktopRootShell(),
          );
        }

        // Mobile / narrow tablet: keep bottom nav
        return MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => CredentialListCubit()..load()),
            BlocProvider.value(value: sharedBackupCubit),
          ],
          child: _MobileRootShellPage(
            isTablet: constraints.maxWidth >= DesktopPlatform.tabletBreakpoint,
          ),
        );
      },
    );
  }
}

class BackupOperationRootOverlay extends StatelessWidget {
  const BackupOperationRootOverlay({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BackupCubit, BackupState>(
      buildWhen: (previous, current) =>
          previous.isCreating != current.isCreating ||
          previous.isUploading != current.isUploading ||
          previous.isRestoring != current.isRestoring ||
          previous.operationMessage != current.operationMessage ||
          previous.operationProgress != current.operationProgress,
      builder: (context, state) {
        final isActive =
            state.isCreating || state.isUploading || state.isRestoring;
        if (!isActive) return const SizedBox.shrink();
        return BackupLiveIslandOverlay(
          state: state,
          compact: true,
          onTap: onTap,
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// DESKTOP ROOT SHELL — sidebar + content area
// ═══════════════════════════════════════════════════════════════════════════════

class _DesktopRootShell extends StatefulWidget {
  const _DesktopRootShell();

  @override
  State<_DesktopRootShell> createState() => _DesktopRootShellState();
}

class _DesktopRootShellState extends State<_DesktopRootShell>
    with WidgetsBindingObserver {
  DesktopNavSection _activeSection = DesktopNavSection.home;
  bool _sidebarCollapsed = false;
  StreamSubscription<int>? _dataRefreshSubscription;
  int _dataRefreshGeneration = VaultDataRefreshSignal.generation;

  void _setSection(DesktopNavSection section) {
    if (_activeSection == section) return;
    setState(() => _activeSection = section);
    _updateWindowTitle(section);
  }

  void _toggleSidebar() {
    setState(() => _sidebarCollapsed = !_sidebarCollapsed);
  }

  void _updateWindowTitle(DesktopNavSection section) {
    final label = switch (section) {
      DesktopNavSection.home => 'Home',
      DesktopNavSection.credentials => 'Credentials',
      DesktopNavSection.documents => 'Documents',
      DesktopNavSection.collections => 'Collections',
      DesktopNavSection.bundles => 'Bundles',
      DesktopNavSection.tasks => 'Tasks',
      DesktopNavSection.generator => 'Generator',
      DesktopNavSection.vaultHealth => 'Vault Health',
      DesktopNavSection.profile => 'Profile',
      DesktopNavSection.settings => 'Settings',
    };
    setDesktopWindowTitle(label);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    getIt<VaultSyncCoordinator>().start();
    _dataRefreshSubscription = VaultDataRefreshSignal.changes.listen((
      generation,
    ) {
      if (!mounted) return;
      setState(() => _dataRefreshGeneration = generation);
    });
    _updateWindowTitle(_activeSection);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _dataRefreshSubscription?.cancel();
    getIt<VaultSyncCoordinator>().stop();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      getIt<VaultSyncCoordinator>().handleAppResumed();
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;

    return DesktopMenuBarWrapper(
      onNewCredential: () => _setSection(DesktopNavSection.credentials),
      onNewCollection: () => _setSection(DesktopNavSection.collections),
      onSearch: _openSearch,
      onSettings: () => _setSection(DesktopNavSection.settings),
      onToggleSidebar: _toggleSidebar,
      onLockVault: _lockVault,
      child: DesktopShortcutsWrapper(
        onNewCredential: () => _setSection(DesktopNavSection.credentials),
        onSearch: _openSearch,
        onSettings: () => _setSection(DesktopNavSection.settings),
        onLockVault: _lockVault,
        onToggleSidebar: _toggleSidebar,
        child: Scaffold(
          backgroundColor: palette.background,
          body: Stack(
            children: [
              Row(
                children: [
                  DesktopNavSidebar(
                    activeSection: _activeSection,
                    onSectionChanged: _setSection,
                    isCollapsed: _sidebarCollapsed,
                    onToggleCollapsed: _toggleSidebar,
                  ),
                  Expanded(child: ClipRect(child: _buildContent(context))),
                ],
              ),
              const Positioned(
                right: 24,
                bottom: 24,
                child: VaultSyncStatusBanner(desktop: true),
              ),
              BackupOperationRootOverlay(onTap: _openBackupRestoreFlow),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: KeyedSubtree(
        key: ValueKey(_activeSection),
        child: switch (_activeSection) {
          DesktopNavSection.home => BlocProvider(
            create: (_) => HomeCubit(repository: getIt<HomeRepository>()),
            child: HomeDashboardPage(
              key: ValueKey('desktop-home-$_dataRefreshGeneration'),
              horizontalPadding: 26,
              onOpenCredentialDetail: _openCredentialDetail,
              onOpenDocumentDetail: _openDocumentDetail,
              onOpenCollectionDetail: _openCollectionDetail,
              onOpenCredentials: () =>
                  _setSection(DesktopNavSection.credentials),
              onOpenDocuments: () => _setSection(DesktopNavSection.documents),
              onOpenCollections: () =>
                  _setSection(DesktopNavSection.collections),
              onOpenTasks: () => _setSection(DesktopNavSection.tasks),
              onOpenBundles: () => _setSection(DesktopNavSection.bundles),
            ),
          ),
          DesktopNavSection.credentials => CredentialsAccountsSection(
            key: const ValueKey('desktop-credentials'),
            horizontalPadding: 26,
            onGeneratorTap: () => _setSection(DesktopNavSection.generator),
          ),
          DesktopNavSection.documents => DocumentsLibraryPage(
            key: ValueKey('desktop-documents-$_dataRefreshGeneration'),
            embeddedDesktop: true,
            onCategoryTap: _handleDocumentCategoryTap,
            onCollectionsTap: () => _setSection(DesktopNavSection.collections),
            onCollectionTap: (collectionId) =>
                _openCollectionDetail(context, collectionId),
            onBundlesTap: () => _setSection(DesktopNavSection.bundles),
            onTasksTap: () => _setSection(DesktopNavSection.tasks),
            onSecureNotesTap: _openSecureNotesFlow,
            onSyncNowTap: () => _setSection(DesktopNavSection.settings),
          ),
          DesktopNavSection.collections => CollectionsListPage(
            key: ValueKey('desktop-collections-$_dataRefreshGeneration'),
          ),
          DesktopNavSection.bundles => const BundlesListPage(
            key: ValueKey('desktop-bundles'),
            embeddedDesktop: true,
          ),
          DesktopNavSection.tasks => const TaskListsPage(
            key: ValueKey('desktop-tasks'),
            embeddedDesktop: true,
          ),
          DesktopNavSection.generator => PasswordGeneratorPage(
            key: const ValueKey('desktop-generator'),
          ),
          DesktopNavSection.vaultHealth => BlocProvider.value(
            value: getIt<VaultHealthCubit>(),
            child: VaultHealthPage(
              key: const ValueKey('desktop-vault-health'),
              onNavigateToCredential: _openCredentialDetail,
              onNavigateToDocument: _openDocumentDetail,
            ),
          ),
          DesktopNavSection.profile => ProfilePage(
            key: const ValueKey('desktop-profile'),
          ),
          DesktopNavSection.settings => VaultSyncSettingsPage(
            key: const ValueKey('desktop-settings'),
          ),
        },
      ),
    );
  }

  Future<void> _openCredentialDetail(
    BuildContext context,
    String credentialId,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider(
          create: (_) =>
              CredentialDetailCubit()..load(credentialId: credentialId),
          child: CredentialDetailPage(),
        ),
      ),
    );
  }

  Future<void> _openDocumentDetail(
    BuildContext context,
    String documentId,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DocumentDetailPage(documentId: documentId),
      ),
    );
  }

  Future<void> _openCollectionDetail(
    BuildContext context,
    String collectionId,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CollectionDashboardPage(collectionId: collectionId),
      ),
    );
  }

  Future<void> _handleDocumentCategoryTap(DocumentCategoryType category) async {
    final page = switch (category) {
      DocumentCategoryType.identity => const IdentityDocumentsPage(),
      DocumentCategoryType.work => WorkHubPage(),
      _ => null,
    };

    if (page != null) {
      await Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => page));
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.documentsPageComingSoon(category.label)),
      ),
    );
  }

  void _openSearch() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => VaultSearchPage(
          onOpenCredential: _openCredentialDetail,
          onOpenDocument: _openDocumentDetail,
          onOpenCollection: _openCollectionDetail,
        ),
      ),
    );
  }

  void _lockVault() {
    // Pop back to the app root and trigger the lock state
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _openBackupRestoreFlow() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const BackupSettingsPage()));
  }

  Future<void> _openSecureNotesFlow() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const SecureNotesPage()));
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// MOBILE ROOT SHELL — design-gallery bottom navigation
// ═══════════════════════════════════════════════════════════════════════════════

enum _MobileRootTab { home, vault, docs, search, me }

class _MobileRootShellPage extends StatefulWidget {
  const _MobileRootShellPage({required this.isTablet});

  final bool isTablet;

  @override
  State<_MobileRootShellPage> createState() => _MobileRootShellPageState();
}

class _MobileRootShellPageState extends State<_MobileRootShellPage>
    with WidgetsBindingObserver {
  _MobileRootTab _activeTab = _MobileRootTab.home;
  StreamSubscription<int>? _dataRefreshSubscription;
  int _dataRefreshGeneration = VaultDataRefreshSignal.generation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    getIt<VaultSyncCoordinator>().start();
    _dataRefreshSubscription = VaultDataRefreshSignal.changes.listen((
      generation,
    ) {
      if (!mounted) return;
      setState(() => _dataRefreshGeneration = generation);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _dataRefreshSubscription?.cancel();
    getIt<VaultSyncCoordinator>().stop();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      getIt<VaultSyncCoordinator>().handleAppResumed();
    }
  }

  void _setActiveTab(_MobileRootTab nextTab) {
    if (_activeTab == nextTab) return;
    setState(() => _activeTab = nextTab);
    if (nextTab == _MobileRootTab.vault) {
      context.read<CredentialListCubit>().load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = widget.isTablet ? 26.0 : 22.0;

    final palette = context.appPalette;

    return Scaffold(
      backgroundColor: palette.background,
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: IndexedStack(
              index: _activeTab.index,
              children: [
                BlocProvider(
                  create: (_) => HomeCubit(repository: getIt<HomeRepository>()),
                  child: HomeDashboardPage(
                    key: ValueKey('root-home-tab-$_dataRefreshGeneration'),
                    horizontalPadding: horizontalPadding,
                    onOpenCredentialDetail: _openCredentialDetail,
                    onOpenDocumentDetail: _openDocumentDetail,
                    onOpenCollectionDetail: _openCollectionDetail,
                    onOpenCredentials: () =>
                        _setActiveTab(_MobileRootTab.vault),
                    onOpenDocuments: () => _setActiveTab(_MobileRootTab.docs),
                    onOpenCollections: _openCollectionsFlow,
                    onOpenTasks: _openTasksFlow,
                    onOpenBundles: _openBundlesFlow,
                  ),
                ),
                CredentialsAccountsSection(
                  key: const ValueKey('root-vault-tab'),
                  horizontalPadding: horizontalPadding,
                  onGeneratorTap: _openGeneratorFlow,
                ),
                DocumentsLibraryPage(
                  key: ValueKey('root-docs-tab-$_dataRefreshGeneration'),
                  onCategoryTap: _handleDocumentCategoryTap,
                  onCollectionsTap: _openCollectionsFlow,
                  onCollectionTap: (collectionId) =>
                      _openCollectionDetail(context, collectionId),
                  onBundlesTap: _openBundlesFlow,
                  onTasksTap: _openTasksFlow,
                  onSecureNotesTap: _openSecureNotesFlow,
                  onSyncNowTap: _openSettingsFlow,
                ),
                VaultSearchPage(
                  key: const ValueKey('root-search-tab'),
                  showBackButton: false,
                  autoFocus: false,
                  onOpenCredential: _openCredentialDetail,
                  onOpenDocument: _openDocumentDetail,
                  onOpenCollection: _openCollectionDetail,
                ),
                ProfilePage(key: const ValueKey('root-me-tab')),
              ],
            ),
          ),
          const Positioned(
            left: 16,
            right: 16,
            bottom: 10,
            child: VaultSyncStatusBanner(),
          ),
          BackupOperationRootOverlay(onTap: _openBackupRestoreFlow),
        ],
      ),
      bottomNavigationBar: CredenceBottomNav(
        items: _bottomNavItems(context),
        activeIndex: _activeTab.index,
        onTap: (index) => _setActiveTab(_MobileRootTab.values[index]),
      ),
    );
  }

  List<CredenceBottomNavItem> _bottomNavItems(BuildContext context) {
    final l10n = context.l10n;
    return [
      CredenceBottomNavItem(
        label: l10n.navHome,
        iconAsset: 'assets/nav/home_outline.svg',
        selectedIconAsset: 'assets/nav/home_selected.svg',
      ),
      CredenceBottomNavItem(
        label: l10n.navVault,
        iconAsset: 'assets/nav/vault_outline.svg',
        selectedIconAsset: 'assets/nav/vault_selected.svg',
      ),
      CredenceBottomNavItem(
        label: l10n.navDocs,
        iconAsset: 'assets/nav/docs_outline.svg',
        selectedIconAsset: 'assets/nav/docs_selected.svg',
      ),
      CredenceBottomNavItem(
        label: l10n.navSearch,
        iconAsset: 'assets/nav/search_outline.svg',
        selectedIconAsset: 'assets/nav/search_selected.svg',
      ),
      CredenceBottomNavItem(
        label: l10n.navMe,
        iconAsset: 'assets/nav/me_outline.svg',
        selectedIconAsset: 'assets/nav/me_selected.svg',
      ),
    ];
  }

  Future<void> _openGeneratorFlow() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => PasswordGeneratorPage()));
  }

  Future<void> _openCredentialDetail(
    BuildContext context,
    String credentialId,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider(
          create: (_) =>
              CredentialDetailCubit()..load(credentialId: credentialId),
          child: CredentialDetailPage(),
        ),
      ),
    );
  }

  Future<void> _openDocumentDetail(
    BuildContext context,
    String documentId,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DocumentDetailPage(documentId: documentId),
      ),
    );
  }

  Future<void> _openCollectionDetail(
    BuildContext context,
    String collectionId,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CollectionDashboardPage(collectionId: collectionId),
      ),
    );
  }

  Future<void> _handleDocumentCategoryTap(DocumentCategoryType category) async {
    if (category == DocumentCategoryType.identity) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const IdentityDocumentsPage()),
      );
      return;
    }
    if (category == DocumentCategoryType.work) {
      await Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => WorkHubPage()));
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.documentsPageComingSoon(category.label)),
      ),
    );
  }

  Future<void> _openSettingsFlow() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => VaultSyncSettingsPage()));
  }

  Future<void> _openBackupRestoreFlow() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const BackupSettingsPage()));
  }

  Future<void> _openCollectionsFlow() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const CollectionsListPage()),
    );
  }

  Future<void> _openBundlesFlow() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const BundlesListPage()));
  }

  Future<void> _openTasksFlow() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const TaskListsPage()));
  }

  Future<void> _openSecureNotesFlow() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const SecureNotesPage()));
  }
}
