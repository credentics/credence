import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:pass_doc_manager/data/branding/apis/brandfetch_search_api.dart';
import 'package:pass_doc_manager/data/branding/datasources/local/company_logo_local_data_source.dart';
import 'package:pass_doc_manager/data/branding/datasources/remote/brandfetch_search_remote_data_source.dart';
import 'package:pass_doc_manager/data/branding/repositories/company_brand_repository_impl.dart';
import 'package:pass_doc_manager/data/credentials/datasources/local/credential_local_data_source.dart';
import 'package:pass_doc_manager/data/credentials/repositories/credential_repository_impl.dart';
import 'package:pass_doc_manager/data/bundles/datasources/local/bundles_local_data_source.dart';
import 'package:pass_doc_manager/data/bundles/repositories/bundles_repository_impl.dart';
import 'package:pass_doc_manager/data/tasks/datasources/local/tasks_local_data_source.dart';
import 'package:pass_doc_manager/data/tasks/repositories/tasks_repository_impl.dart';
import 'package:pass_doc_manager/features/bundles/infrastructure/services/bundle_export_service.dart';
import 'package:pass_doc_manager/data/collections/datasources/local/collections_local_data_source.dart';
import 'package:pass_doc_manager/data/collections/repositories/collections_repository_impl.dart';
import 'package:pass_doc_manager/data/documents/datasources/local/document_local_data_source.dart';
import 'package:pass_doc_manager/data/documents/repositories/document_repository_impl.dart';
import 'package:pass_doc_manager/data/notes/datasources/local/secure_notes_local_data_source.dart';
import 'package:pass_doc_manager/data/notes/repositories/secure_notes_repository_impl.dart';
import 'package:pass_doc_manager/data/password_tools/datasources/local/password_history_local_data_source.dart';
import 'package:pass_doc_manager/data/password_tools/repositories/password_tools_repository_impl.dart';
import 'package:pass_doc_manager/data/password_tools/services/local_password_tools_service.dart';
import 'package:pass_doc_manager/data/profile/datasources/local/profile_local_data_source.dart';
import 'package:pass_doc_manager/data/profile/repositories/profile_repository_impl.dart';
import 'package:pass_doc_manager/data/vault_portability/datasources/local/vault_snapshot_codec.dart';
import 'package:pass_doc_manager/data/vault_portability/datasources/local/vault_store_local_data_source.dart';
import 'package:pass_doc_manager/data/vault_portability/repositories/vault_portability_repository_impl.dart';
import 'package:pass_doc_manager/data/vault_sync/datasources/local/local_folder_sync_data_source.dart';
import 'package:pass_doc_manager/data/vault_sync/datasources/local/vault_sync_journal_local_data_source.dart';
import 'package:pass_doc_manager/data/vault_sync/datasources/local/vault_sync_prefs_local_data_source.dart';
import 'package:pass_doc_manager/data/vault_sync/datasources/remote/dropbox_sync_data_source.dart';
import 'package:pass_doc_manager/data/vault_sync/mirror/dropbox_mirror_data_source.dart';
import 'package:pass_doc_manager/data/vault_sync/mirror/google_drive_mirror_data_source.dart';
import 'package:pass_doc_manager/data/vault_sync/mirror/local_folder_mirror_data_source.dart';
import 'package:pass_doc_manager/data/vault_sync/mirror/vault_mirror_import_service.dart';
import 'package:pass_doc_manager/data/vault_sync/mirror/vault_mirror_workspace_builder.dart';
import 'package:pass_doc_manager/data/vault_sync/repositories/vault_sync_repository_impl.dart';
import 'package:pass_doc_manager/data/vault_sync/services/vault_sync_operation_builder.dart';
import 'package:pass_doc_manager/app/sync/vault_sync_coordinator.dart';
import 'package:pass_doc_manager/features/backup/data/datasources/local/backup_local_data_source.dart';
import 'package:pass_doc_manager/features/backup/data/datasources/local/backup_snapshot_builder.dart';
import 'package:pass_doc_manager/features/backup/data/repositories/backup_repository_impl.dart';
import 'package:pass_doc_manager/features/backup/domain/repositories/backup_repository.dart';
import 'package:pass_doc_manager/features/backup/domain/usecases/create_backup.dart';
import 'package:pass_doc_manager/features/backup/domain/usecases/restore_backup.dart';
import 'package:pass_doc_manager/features/backup/domain/usecases/list_backups.dart';
import 'package:pass_doc_manager/features/backup/domain/usecases/delete_backup.dart';
import 'package:pass_doc_manager/features/backup/domain/usecases/validate_chain.dart';
import 'package:pass_doc_manager/features/backup/infrastructure/services/backup_archive_service.dart';
import 'package:pass_doc_manager/features/backup/infrastructure/services/backup_chain_manager.dart';
import 'package:pass_doc_manager/features/backup/infrastructure/services/backup_crypto_service.dart';
import 'package:pass_doc_manager/features/backup/infrastructure/services/backup_integrity_service.dart';
import 'package:pass_doc_manager/features/backup/infrastructure/services/backup_replay_engine.dart';
import 'package:pass_doc_manager/features/backup/infrastructure/services/backup_retention_manager.dart';
import 'package:pass_doc_manager/domain/branding/repositories/company_brand_repository.dart';
import 'package:pass_doc_manager/domain/branding/usecases/download_company_logo_to_local.dart';
import 'package:pass_doc_manager/domain/branding/usecases/search_company_brands.dart';
import 'package:pass_doc_manager/domain/credentials/repositories/credential_repository.dart';
import 'package:pass_doc_manager/domain/credentials/usecases/create_credential.dart';
import 'package:pass_doc_manager/domain/credentials/usecases/get_credential_detail.dart';
import 'package:pass_doc_manager/domain/credentials/usecases/get_credential_summaries.dart';
import 'package:pass_doc_manager/domain/credentials/usecases/delete_credential.dart';
import 'package:pass_doc_manager/domain/credentials/usecases/mark_credential_used.dart';
import 'package:pass_doc_manager/domain/credentials/usecases/toggle_credential_favorite.dart';
import 'package:pass_doc_manager/domain/credentials/usecases/update_credential.dart';
import 'package:pass_doc_manager/data/credentials/services/breach_check_service.dart';
import 'package:pass_doc_manager/data/credentials/services/vault_breach_monitor.dart';
import 'package:pass_doc_manager/data/secure_share/services/secure_share_service.dart';
import 'package:pass_doc_manager/data/secure_share/repositories/secure_share_repository_impl.dart';
import 'package:pass_doc_manager/domain/secure_share/repositories/secure_share_repository.dart';
import 'package:pass_doc_manager/domain/secure_share/usecases/create_share_link.dart';
import 'package:pass_doc_manager/domain/bundles/repositories/bundle_repository.dart';
import 'package:pass_doc_manager/domain/tasks/repositories/task_repository.dart';
import 'package:pass_doc_manager/domain/tasks/usecases/create_task.dart';
import 'package:pass_doc_manager/domain/tasks/usecases/create_task_list.dart';
import 'package:pass_doc_manager/domain/tasks/usecases/delete_task.dart';
import 'package:pass_doc_manager/domain/tasks/usecases/delete_task_list.dart';
import 'package:pass_doc_manager/domain/tasks/usecases/get_task_list_detail.dart';
import 'package:pass_doc_manager/domain/tasks/usecases/get_task_lists.dart';
import 'package:pass_doc_manager/domain/tasks/usecases/reorder_tasks.dart';
import 'package:pass_doc_manager/domain/tasks/usecases/save_task.dart';
import 'package:pass_doc_manager/domain/tasks/usecases/save_task_list.dart';
import 'package:pass_doc_manager/domain/tasks/usecases/toggle_task.dart';
import 'package:pass_doc_manager/features/tasks/infrastructure/services/task_notification_service.dart';
import 'package:pass_doc_manager/domain/bundles/usecases/add_item_to_bundle.dart';
import 'package:pass_doc_manager/domain/bundles/usecases/create_bundle.dart';
import 'package:pass_doc_manager/domain/bundles/usecases/delete_bundle.dart';
import 'package:pass_doc_manager/domain/bundles/usecases/get_bundle_detail.dart';
import 'package:pass_doc_manager/domain/bundles/usecases/get_bundles.dart';
import 'package:pass_doc_manager/domain/bundles/usecases/remove_item_from_bundle.dart';
import 'package:pass_doc_manager/domain/bundles/usecases/save_bundle.dart';
import 'package:pass_doc_manager/domain/collections/repositories/collections_repository.dart';
import 'package:pass_doc_manager/domain/collections/usecases/create_collection.dart';
import 'package:pass_doc_manager/domain/collections/usecases/delete_collection.dart';
import 'package:pass_doc_manager/domain/collections/usecases/delete_collection_block.dart';
import 'package:pass_doc_manager/domain/collections/usecases/cancel_collection_block_reminder.dart';
import 'package:pass_doc_manager/domain/collections/usecases/schedule_collection_block_reminder.dart';
import 'package:pass_doc_manager/domain/collections/usecases/get_collection_detail.dart';
import 'package:pass_doc_manager/domain/collections/usecases/get_collections.dart';
import 'package:pass_doc_manager/domain/collections/usecases/reorder_collections.dart';
import 'package:pass_doc_manager/domain/collections/usecases/save_collection.dart';
import 'package:pass_doc_manager/domain/collections/usecases/save_collection_block.dart';
import 'package:pass_doc_manager/domain/documents/repositories/document_repository.dart';
import 'package:pass_doc_manager/domain/documents/usecases/archive_document.dart';
import 'package:pass_doc_manager/domain/documents/usecases/create_scanned_document.dart';
import 'package:pass_doc_manager/domain/documents/usecases/delete_document.dart';
import 'package:pass_doc_manager/domain/documents/usecases/force_expire_document.dart';
import 'package:pass_doc_manager/domain/documents/usecases/get_document_detail.dart';
import 'package:pass_doc_manager/domain/documents/usecases/get_document_library_overview.dart';
import 'package:pass_doc_manager/domain/documents/usecases/get_property_asset_records.dart';
import 'package:pass_doc_manager/domain/documents/usecases/get_identity_documents.dart';
import 'package:pass_doc_manager/domain/documents/usecases/get_vault_documents.dart';
import 'package:pass_doc_manager/domain/documents/usecases/get_expiring_documents.dart';
import 'package:pass_doc_manager/domain/documents/usecases/get_property_vaults.dart';
import 'package:pass_doc_manager/domain/documents/usecases/get_property_detail.dart';
import 'package:pass_doc_manager/domain/documents/usecases/get_travel_trip_detail.dart';
import 'package:pass_doc_manager/domain/documents/usecases/get_travel_trips.dart';
import 'package:pass_doc_manager/domain/documents/usecases/get_work_company_detail.dart';
import 'package:pass_doc_manager/domain/documents/usecases/get_work_company_vaults.dart';
import 'package:pass_doc_manager/domain/documents/usecases/replace_document_capture.dart';
import 'package:pass_doc_manager/domain/documents/usecases/set_primary_identity_document.dart';
import 'package:pass_doc_manager/domain/documents/usecases/toggle_document_favorite.dart';
import 'package:pass_doc_manager/domain/documents/usecases/update_document.dart';
import 'package:pass_doc_manager/domain/notes/repositories/secure_notes_repository.dart';
import 'package:pass_doc_manager/domain/notes/usecases/create_secure_note.dart';
import 'package:pass_doc_manager/domain/notes/usecases/delete_secure_note.dart';
import 'package:pass_doc_manager/domain/notes/usecases/get_secure_note.dart';
import 'package:pass_doc_manager/domain/notes/usecases/get_secure_notes.dart';
import 'package:pass_doc_manager/domain/notes/usecases/migrate_legacy_secure_notes.dart';
import 'package:pass_doc_manager/domain/notes/usecases/save_secure_note_snapshot.dart';
import 'package:pass_doc_manager/domain/password_tools/repositories/password_tools_repository.dart';
import 'package:pass_doc_manager/domain/password_tools/usecases/clear_generated_password_history.dart';
import 'package:pass_doc_manager/domain/password_tools/usecases/evaluate_password_health.dart';
import 'package:pass_doc_manager/domain/password_tools/usecases/get_generated_password_history.dart';
import 'package:pass_doc_manager/domain/password_tools/usecases/generate_password.dart';
import 'package:pass_doc_manager/domain/password_tools/usecases/save_generated_password_history_entry.dart';
import 'package:pass_doc_manager/domain/profile/repositories/profile_repository.dart';
import 'package:pass_doc_manager/domain/profile/usecases/generate_secure_profile_link.dart';
import 'package:pass_doc_manager/domain/profile/usecases/get_profile_dashboard.dart';
import 'package:pass_doc_manager/domain/profile/usecases/get_profile_share_options.dart';
import 'package:pass_doc_manager/domain/profile/usecases/save_profile.dart';
import 'package:pass_doc_manager/domain/profile/usecases/save_profile_share_options.dart';
import 'package:pass_doc_manager/domain/vault_portability/repositories/vault_portability_repository.dart';
import 'package:pass_doc_manager/domain/vault_portability/usecases/export_vault_data.dart';
import 'package:pass_doc_manager/domain/vault_portability/usecases/export_vault_with_files.dart';
import 'package:pass_doc_manager/domain/vault_portability/usecases/get_vault_portability_policy.dart';
import 'package:pass_doc_manager/domain/vault_portability/usecases/import_vault_data.dart';
import 'package:pass_doc_manager/domain/vault_sync/repositories/vault_sync_repository.dart';
import 'package:pass_doc_manager/domain/vault_sync/usecases/get_vault_sync_settings.dart';
import 'package:pass_doc_manager/domain/vault_sync/usecases/get_vault_sync_status.dart';
import 'package:pass_doc_manager/domain/vault_sync/usecases/import_vault_mirror_now.dart';
import 'package:pass_doc_manager/domain/vault_sync/usecases/run_vault_sync_now.dart';
import 'package:pass_doc_manager/domain/vault_sync/usecases/save_vault_sync_settings.dart';
import 'package:pass_doc_manager/features/documents/infrastructure/services/document_expiry_service.dart';
import 'package:pass_doc_manager/features/home/data/datasources/home_preferences_data_source.dart';
import 'package:pass_doc_manager/features/home/data/repositories/home_repository_impl.dart';
import 'package:pass_doc_manager/features/home/domain/repositories/home_repository.dart';
import 'package:pass_doc_manager/domain/vault_import/usecases/parse_import_file.dart';
import 'package:pass_doc_manager/domain/vault_import/usecases/execute_import.dart';
import 'package:pass_doc_manager/data/vault_health/repositories/vault_health_repository_impl.dart';
import 'package:pass_doc_manager/domain/vault_health/repositories/vault_health_repository.dart';
import 'package:pass_doc_manager/domain/vault_health/usecases/evaluate_vault_health.dart';
import 'package:pass_doc_manager/features/vault_health/presentation/cubit/vault_health_cubit.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  if (getIt.isRegistered<GetCredentialSummaries>()) {
    return;
  }

  final brandingDio = Dio();
  if (kDebugMode) {
    brandingDio.interceptors.add(
      LogInterceptor(
        request: true,
        requestHeader: true,
        requestBody: false,
        responseHeader: false,
        responseBody: true,
        error: true,
        logPrint: (line) => debugPrint('[Brandfetch] $line'),
      ),
    );
  }

  // Open all encrypted Hive boxes concurrently. Each `create()` call opens an
  // independent box, so they don't need to run sequentially. On a real device
  // this turns ~12× sequential disk+crypto warm-ups into a single parallel
  // burst — measured 3-4× faster cold start.
  final results = await Future.wait([
    CredentialLocalDataSource.create(),
    VaultStoreLocalDataSource.create(),
    VaultSyncPrefsLocalDataSource.create(),
    PasswordHistoryLocalDataSource.create(),
    DocumentLocalDataSource.create(),
    CollectionsLocalDataSource.create(),
    BundlesLocalDataSource.create(),
    TasksLocalDataSource.create(),
    ProfileLocalDataSource.create(),
    BackupLocalDataSource.create(),
    HomePreferencesDataSource.create(),
    VaultSyncJournalLocalDataSource.create(),
  ]);
  final credentialLocalDataSource = results[0] as CredentialLocalDataSource;
  final vaultStoreLocalDataSource = results[1] as VaultStoreLocalDataSource;
  final vaultSyncPrefsLocalDataSource =
      results[2] as VaultSyncPrefsLocalDataSource;
  final passwordHistoryLocalDataSource =
      results[3] as PasswordHistoryLocalDataSource;
  final documentLocalDataSource = results[4] as DocumentLocalDataSource;
  final collectionsLocalDataSource = results[5] as CollectionsLocalDataSource;
  final bundlesLocalDataSource = results[6] as BundlesLocalDataSource;
  final tasksLocalDataSource = results[7] as TasksLocalDataSource;
  final profileLocalDataSource = results[8] as ProfileLocalDataSource;
  final backupLocalDataSource = results[9] as BackupLocalDataSource;
  final homePreferencesDataSource = results[10] as HomePreferencesDataSource;
  final vaultSyncJournalLocalDataSource =
      results[11] as VaultSyncJournalLocalDataSource;

  getIt
    ..registerSingleton<CredentialLocalDataSource>(credentialLocalDataSource)
    ..registerSingleton<Dio>(brandingDio, instanceName: 'branding_dio')
    ..registerSingleton<VaultStoreLocalDataSource>(vaultStoreLocalDataSource)
    ..registerSingleton<VaultSyncPrefsLocalDataSource>(
      vaultSyncPrefsLocalDataSource,
    )
    ..registerSingleton<PasswordHistoryLocalDataSource>(
      passwordHistoryLocalDataSource,
    )
    ..registerSingleton<DocumentLocalDataSource>(documentLocalDataSource)
    ..registerSingleton<CollectionsLocalDataSource>(collectionsLocalDataSource)
    ..registerSingleton<BundlesLocalDataSource>(bundlesLocalDataSource)
    ..registerSingleton<TasksLocalDataSource>(tasksLocalDataSource)
    ..registerSingleton<ProfileLocalDataSource>(profileLocalDataSource)
    ..registerSingleton<BackupLocalDataSource>(backupLocalDataSource)
    ..registerSingleton<VaultSyncJournalLocalDataSource>(
      vaultSyncJournalLocalDataSource,
    )
    ..registerLazySingleton<SecureNotesLocalDataSource>(
      SecureNotesLocalDataSource.new,
    )
    ..registerLazySingleton<CredentialRepository>(
      () => CredentialRepositoryImpl(localDataSource: getIt()),
    )
    ..registerLazySingleton<CollectionsRepository>(
      () => CollectionsRepositoryImpl(localDataSource: getIt()),
    )
    ..registerLazySingleton<BundleRepository>(
      () => BundlesRepositoryImpl(localDataSource: getIt()),
    )
    ..registerLazySingleton<DocumentRepository>(
      () => DocumentRepositoryImpl(localDataSource: getIt()),
    )
    ..registerLazySingleton<SecureNotesRepository>(
      () => SecureNotesRepositoryImpl(
        local: getIt(),
        legacyCollectionsLocal: getIt(),
      ),
    )
    ..registerLazySingleton<ProfileRepository>(
      () => ProfileRepositoryImpl(localDataSource: getIt()),
    )
    ..registerLazySingleton<BrandfetchSearchApi>(
      () => BrandfetchSearchApi(getIt<Dio>(instanceName: 'branding_dio')),
    )
    ..registerLazySingleton<BrandfetchSearchRemoteDataSource>(
      () => BrandfetchSearchRemoteDataSource(api: getIt()),
    )
    ..registerLazySingleton<CompanyLogoLocalDataSource>(
      () => CompanyLogoLocalDataSource(
        dio: getIt<Dio>(instanceName: 'branding_dio'),
      ),
    )
    ..registerLazySingleton<CompanyBrandRepository>(
      () => CompanyBrandRepositoryImpl(
        remoteDataSource: getIt(),
        localDataSource: getIt(),
      ),
    )
    ..registerLazySingleton<LocalPasswordToolsService>(
      LocalPasswordToolsService.new,
    )
    ..registerLazySingleton<PasswordToolsRepository>(
      () => PasswordToolsRepositoryImpl(
        localService: getIt(),
        historyLocalDataSource: getIt(),
      ),
    )
    ..registerLazySingleton<VaultSnapshotCodec>(VaultSnapshotCodec.new)
    ..registerLazySingleton<VaultPortabilityRepository>(
      () => VaultPortabilityRepositoryImpl(
        localDataSource: getIt(),
        collectionsLocalDataSource: getIt(),
        bundlesLocalDataSource: getIt(),
        tasksLocalDataSource: getIt(),
        profileLocalDataSource: getIt(),
        snapshotCodec: getIt(),
        mirrorBuilder: getIt(),
        localMirrorDataSource: getIt(),
      ),
    )
    ..registerLazySingleton<LocalFolderSyncDataSource>(
      LocalFolderSyncDataSource.new,
    )
    ..registerLazySingleton<DropboxSyncDataSource>(
      () => DropboxSyncDataSource(dio: Dio()),
    )
    ..registerLazySingleton<LocalFolderMirrorDataSource>(
      LocalFolderMirrorDataSource.new,
    )
    ..registerLazySingleton<DropboxMirrorDataSource>(
      () => DropboxMirrorDataSource(dio: Dio()),
    )
    ..registerLazySingleton<GoogleDriveMirrorDataSource>(
      () => GoogleDriveMirrorDataSource(dio: Dio()),
    )
    ..registerLazySingleton<VaultSyncOperationBuilder>(
      VaultSyncOperationBuilder.new,
    )
    ..registerLazySingleton<VaultMirrorImportService>(
      () => VaultMirrorImportService(
        documentLocalDataSource: getIt(),
        collectionsLocalDataSource: getIt(),
        bundlesLocalDataSource: getIt(),
        tasksLocalDataSource: getIt(),
        credentialLocalDataSource: getIt(),
        profileLocalDataSource: getIt(),
        secureNotesLocalDataSource: getIt(),
      ),
    )
    ..registerLazySingleton<VaultMirrorWorkspaceBuilder>(
      () => VaultMirrorWorkspaceBuilder(
        documentLocalDataSource: getIt(),
        collectionsLocalDataSource: getIt(),
        bundlesLocalDataSource: getIt(),
        tasksLocalDataSource: getIt(),
        credentialLocalDataSource: getIt(),
        profileLocalDataSource: getIt(),
        secureNotesLocalDataSource: getIt(),
      ),
    )
    ..registerLazySingleton<VaultSyncRepository>(
      () => VaultSyncRepositoryImpl(
        prefsLocalDataSource: getIt(),
        mirrorBuilder: getIt(),
        localMirrorDataSource: getIt(),
        dropboxMirrorDataSource: getIt(),
        googleDriveMirrorDataSource: getIt(),
        mirrorImportService: getIt(),
        syncJournalLocalDataSource: getIt(),
        operationBuilder: getIt(),
      ),
    )
    ..registerLazySingleton<VaultSyncCoordinator>(
      () => VaultSyncCoordinator(repository: getIt()),
    )
    ..registerLazySingleton<GetCredentialDetail>(
      () => GetCredentialDetail(getIt()),
    )
    ..registerLazySingleton<GetCredentialSummaries>(
      () => GetCredentialSummaries(getIt()),
    )
    ..registerLazySingleton<CreateCredential>(() => CreateCredential(getIt()))
    ..registerLazySingleton<UpdateCredential>(() => UpdateCredential(getIt()))
    ..registerLazySingleton<MarkCredentialUsed>(
      () => MarkCredentialUsed(getIt()),
    )
    ..registerLazySingleton<DeleteCredential>(() => DeleteCredential(getIt()))
    ..registerLazySingleton<ToggleCredentialFavorite>(
      () => ToggleCredentialFavorite(getIt()),
    )
    ..registerLazySingleton<BreachCheckService>(BreachCheckService.new)
    ..registerLazySingleton<VaultBreachMonitor>(
      () => VaultBreachMonitor(
        breachCheckService: getIt(),
        credentialDataSource: getIt(),
      ),
    )
    ..registerLazySingleton<GetCollections>(() => GetCollections(getIt()))
    ..registerLazySingleton<GetCollectionDetail>(
      () => GetCollectionDetail(getIt()),
    )
    ..registerLazySingleton<CreateCollection>(() => CreateCollection(getIt()))
    ..registerLazySingleton<ReorderCollections>(
      () => ReorderCollections(getIt()),
    )
    ..registerLazySingleton<SaveCollection>(() => SaveCollection(getIt()))
    ..registerLazySingleton<SaveCollectionBlock>(
      () => SaveCollectionBlock(getIt()),
    )
    ..registerLazySingleton<DeleteCollectionBlock>(
      () => DeleteCollectionBlock(getIt()),
    )
    ..registerLazySingleton<ScheduleCollectionBlockReminder>(
      () => ScheduleCollectionBlockReminder(getIt()),
    )
    ..registerLazySingleton<CancelCollectionBlockReminder>(
      () => CancelCollectionBlockReminder(getIt()),
    )
    ..registerLazySingleton<DeleteCollection>(() => DeleteCollection(getIt()))
    // Bundles
    ..registerLazySingleton<GetBundles>(() => GetBundles(getIt()))
    ..registerLazySingleton<GetBundleDetail>(() => GetBundleDetail(getIt()))
    ..registerLazySingleton<CreateBundle>(() => CreateBundle(getIt()))
    ..registerLazySingleton<SaveBundle>(() => SaveBundle(getIt()))
    ..registerLazySingleton<DeleteBundle>(() => DeleteBundle(getIt()))
    ..registerLazySingleton<AddItemToBundle>(() => AddItemToBundle(getIt()))
    ..registerLazySingleton<RemoveItemFromBundle>(
      () => RemoveItemFromBundle(getIt()),
    )
    ..registerLazySingleton<BundleExportService>(
      () => BundleExportService(
        bundleRepository: getIt(),
        collectionsRepository: getIt(),
        credentialRepository: getIt(),
        documentRepository: getIt(),
      ),
    )
    // Tasks
    ..registerLazySingleton<TaskRepository>(
      () => TasksRepositoryImpl(localDataSource: getIt()),
    )
    ..registerLazySingleton<GetTaskLists>(() => GetTaskLists(getIt()))
    ..registerLazySingleton<GetTaskListDetail>(() => GetTaskListDetail(getIt()))
    ..registerLazySingleton<CreateTaskList>(() => CreateTaskList(getIt()))
    ..registerLazySingleton<SaveTaskList>(() => SaveTaskList(getIt()))
    ..registerLazySingleton<DeleteTaskList>(() => DeleteTaskList(getIt()))
    ..registerLazySingleton<CreateTask>(() => CreateTask(getIt()))
    ..registerLazySingleton<SaveTask>(() => SaveTask(getIt()))
    ..registerLazySingleton<ToggleTask>(() => ToggleTask(getIt()))
    ..registerLazySingleton<DeleteTask>(() => DeleteTask(getIt()))
    ..registerLazySingleton<ReorderTasks>(() => ReorderTasks(getIt()))
    ..registerLazySingleton<TaskNotificationService>(
      () => TaskNotificationService(taskRepository: getIt()),
    )
    // Backup system
    ..registerLazySingleton<BackupSnapshotBuilder>(BackupSnapshotBuilder.new)
    ..registerLazySingleton<BackupArchiveService>(BackupArchiveService.new)
    ..registerLazySingleton<BackupCryptoService>(BackupCryptoService.new)
    ..registerLazySingleton<BackupIntegrityService>(BackupIntegrityService.new)
    ..registerLazySingleton<BackupChainManager>(BackupChainManager.new)
    ..registerLazySingleton<BackupRetentionManager>(BackupRetentionManager.new)
    ..registerLazySingleton<BackupReplayEngine>(BackupReplayEngine.new)
    ..registerLazySingleton<BackupRepository>(
      () => BackupRepositoryImpl(
        localDataSource: getIt(),
        archiveService: getIt(),
        cryptoService: getIt(),
        integrityService: getIt(),
        chainManager: getIt(),
        replayEngine: getIt(),
        mirrorBuilder: getIt(),
        localMirrorDataSource: getIt(),
        mirrorImportService: getIt(),
      ),
    )
    ..registerLazySingleton<CreateBackup>(() => CreateBackup(getIt()))
    ..registerLazySingleton<RestoreBackup>(() => RestoreBackup(getIt()))
    ..registerLazySingleton<ListBackups>(() => ListBackups(getIt()))
    ..registerLazySingleton<DeleteBackup>(() => DeleteBackup(getIt()))
    ..registerLazySingleton<ValidateChain>(() => ValidateChain(getIt()))
    ..registerLazySingleton<GetDocumentLibraryOverview>(
      () => GetDocumentLibraryOverview(getIt()),
    )
    ..registerLazySingleton<GetIdentityDocuments>(
      () => GetIdentityDocuments(getIt()),
    )
    ..registerLazySingleton<GetVaultDocuments>(() => GetVaultDocuments(getIt()))
    ..registerLazySingleton<GetExpiringDocuments>(
      () => GetExpiringDocuments(getIt()),
    )
    ..registerLazySingleton<GetWorkCompanyVaults>(
      () => GetWorkCompanyVaults(getIt()),
    )
    ..registerLazySingleton<GetWorkCompanyDetail>(
      () => GetWorkCompanyDetail(getIt()),
    )
    ..registerLazySingleton<GetPropertyVaults>(() => GetPropertyVaults(getIt()))
    ..registerLazySingleton<GetPropertyDetail>(() => GetPropertyDetail(getIt()))
    ..registerLazySingleton<GetPropertyAssetRecords>(
      () => GetPropertyAssetRecords(getIt()),
    )
    ..registerLazySingleton<GetTravelTrips>(() => GetTravelTrips(getIt()))
    ..registerLazySingleton<GetTravelTripDetail>(
      () => GetTravelTripDetail(getIt()),
    )
    ..registerLazySingleton<GetDocumentDetail>(() => GetDocumentDetail(getIt()))
    ..registerLazySingleton<CreateScannedDocument>(
      () => CreateScannedDocument(getIt()),
    )
    ..registerLazySingleton<UpdateDocument>(() => UpdateDocument(getIt()))
    ..registerLazySingleton<ReplaceDocumentCapture>(
      () => ReplaceDocumentCapture(getIt()),
    )
    ..registerLazySingleton<ForceExpireDocument>(
      () => ForceExpireDocument(getIt()),
    )
    ..registerLazySingleton<DeleteDocument>(() => DeleteDocument(getIt()))
    ..registerLazySingleton<ArchiveDocument>(() => ArchiveDocument(getIt()))
    ..registerLazySingleton<ToggleDocumentFavorite>(
      () => ToggleDocumentFavorite(getIt()),
    )
    ..registerLazySingleton<SetPrimaryIdentityDocument>(
      () => SetPrimaryIdentityDocument(getIt()),
    )
    ..registerLazySingleton<GetSecureNotes>(() => GetSecureNotes(getIt()))
    ..registerLazySingleton<GetSecureNote>(() => GetSecureNote(getIt()))
    ..registerLazySingleton<CreateSecureNote>(() => CreateSecureNote(getIt()))
    ..registerLazySingleton<SaveSecureNoteSnapshot>(
      () => SaveSecureNoteSnapshot(getIt()),
    )
    ..registerLazySingleton<DeleteSecureNote>(() => DeleteSecureNote(getIt()))
    ..registerLazySingleton<MigrateLegacySecureNotes>(
      () => MigrateLegacySecureNotes(getIt()),
    )
    ..registerLazySingleton<SearchCompanyBrands>(
      () => SearchCompanyBrands(getIt()),
    )
    ..registerLazySingleton<DownloadCompanyLogoToLocal>(
      () => DownloadCompanyLogoToLocal(getIt()),
    )
    ..registerLazySingleton<GeneratePassword>(() => GeneratePassword(getIt()))
    ..registerLazySingleton<GetGeneratedPasswordHistory>(
      () => GetGeneratedPasswordHistory(getIt()),
    )
    ..registerLazySingleton<SaveGeneratedPasswordHistoryEntry>(
      () => SaveGeneratedPasswordHistoryEntry(getIt()),
    )
    ..registerLazySingleton<ClearGeneratedPasswordHistory>(
      () => ClearGeneratedPasswordHistory(getIt()),
    )
    ..registerLazySingleton<EvaluatePasswordHealth>(
      () => EvaluatePasswordHealth(getIt()),
    )
    ..registerLazySingleton<GetVaultSyncSettings>(
      () => GetVaultSyncSettings(getIt()),
    )
    ..registerLazySingleton<SaveVaultSyncSettings>(
      () => SaveVaultSyncSettings(getIt()),
    )
    ..registerLazySingleton<GetVaultSyncStatus>(
      () => GetVaultSyncStatus(getIt()),
    )
    ..registerLazySingleton<RunVaultSyncNow>(() => RunVaultSyncNow(getIt()))
    ..registerLazySingleton<ImportVaultMirrorNow>(
      () => ImportVaultMirrorNow(getIt()),
    )
    ..registerLazySingleton<ExportVaultData>(() => ExportVaultData(getIt()))
    ..registerLazySingleton<ExportVaultWithFiles>(
      () => ExportVaultWithFiles(getIt()),
    )
    ..registerLazySingleton<ImportVaultData>(() => ImportVaultData(getIt()))
    ..registerLazySingleton<GetProfileDashboard>(
      () => GetProfileDashboard(getIt()),
    )
    ..registerLazySingleton<SaveProfile>(() => SaveProfile(getIt()))
    ..registerLazySingleton<GetProfileShareOptions>(
      () => GetProfileShareOptions(getIt()),
    )
    ..registerLazySingleton<SaveProfileShareOptions>(
      () => SaveProfileShareOptions(getIt()),
    )
    ..registerLazySingleton<GenerateSecureProfileLink>(
      () => GenerateSecureProfileLink(getIt()),
    )
    ..registerLazySingleton<GetVaultPortabilityPolicy>(
      () => GetVaultPortabilityPolicy(getIt()),
    )
    ..registerLazySingleton<DocumentExpiryService>(
      () => DocumentExpiryService(documentDataSource: getIt()),
    )
    ..registerLazySingleton<SecureShareService>(SecureShareService.new)
    ..registerLazySingleton<SecureShareRepository>(
      () => SecureShareRepositoryImpl(getIt()),
    )
    ..registerLazySingleton<CreateShareLink>(() => CreateShareLink(getIt()))
    ..registerLazySingleton<ParseImportFile>(ParseImportFile.new)
    ..registerLazySingleton<ExecuteImport>(() => ExecuteImport(getIt()))
    ..registerLazySingleton<VaultHealthRepository>(
      () => VaultHealthRepositoryImpl(
        credentialDataSource: getIt(),
        documentDataSource: getIt(),
      ),
    )
    ..registerLazySingleton<EvaluateVaultHealth>(
      () => EvaluateVaultHealth(repository: getIt()),
    )
    ..registerLazySingleton<VaultHealthCubit>(
      () => VaultHealthCubit(evaluateVaultHealth: getIt()),
    );

  // Home dashboard
  getIt
    ..registerSingleton<HomePreferencesDataSource>(homePreferencesDataSource)
    ..registerLazySingleton<HomeRepository>(
      () => HomeRepositoryImpl(
        profileDataSource: getIt(),
        credentialDataSource: getIt(),
        documentDataSource: getIt(),
        collectionsDataSource: getIt(),
        preferencesDataSource: getIt(),
        taskRepository: getIt(),
      ),
    );
}
