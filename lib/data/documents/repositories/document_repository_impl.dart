import 'dart:convert';
import 'dart:math';

import 'package:pass_doc_manager/data/documents/datasources/local/document_local_data_source.dart';
import 'package:pass_doc_manager/data/documents/dtos/document_record_dto.dart';
import 'package:pass_doc_manager/domain/documents/entities/document_capture_source.dart';
import 'package:pass_doc_manager/domain/documents/entities/document_category_summary_entity.dart';
import 'package:pass_doc_manager/domain/documents/entities/document_category_type.dart';
import 'package:pass_doc_manager/domain/documents/entities/document_country.dart';
import 'package:pass_doc_manager/domain/documents/entities/document_detail_entity.dart';
import 'package:pass_doc_manager/domain/documents/entities/document_library_overview_entity.dart';
import 'package:pass_doc_manager/domain/documents/entities/document_metadata_field_labels.dart';
import 'package:pass_doc_manager/domain/documents/entities/document_recent_activity_entity.dart';
import 'package:pass_doc_manager/domain/documents/entities/document_structured_field_entity.dart';
import 'package:pass_doc_manager/domain/documents/entities/document_type.dart';
import 'package:pass_doc_manager/domain/documents/entities/identity_document_entity.dart';
import 'package:pass_doc_manager/domain/documents/entities/identity_document_holder_relation.dart';
import 'package:pass_doc_manager/domain/documents/entities/identity_document_group.dart';
import 'package:pass_doc_manager/domain/documents/entities/identity_document_status.dart';
import 'package:pass_doc_manager/domain/documents/entities/identity_document_type_labels.dart';
import 'package:pass_doc_manager/domain/documents/entities/property_vault_entity.dart';
import 'package:pass_doc_manager/domain/documents/entities/property_asset_record_entity.dart';
import 'package:pass_doc_manager/domain/documents/entities/property_asset_summary_entity.dart';
import 'package:pass_doc_manager/domain/documents/entities/property_asset_type.dart';
import 'package:pass_doc_manager/domain/documents/entities/property_detail_entity.dart';
import 'package:pass_doc_manager/domain/documents/entities/travel_budget_allocation_entity.dart';
import 'package:pass_doc_manager/domain/documents/entities/travel_budget_entity.dart';
import 'package:pass_doc_manager/domain/documents/entities/travel_document_entity.dart';
import 'package:pass_doc_manager/domain/documents/entities/travel_expense_category.dart';
import 'package:pass_doc_manager/domain/documents/entities/travel_expense_entity.dart';
import 'package:pass_doc_manager/domain/documents/entities/travel_trip_detail_entity.dart';
import 'package:pass_doc_manager/domain/documents/entities/travel_trip_entity.dart';
import 'package:pass_doc_manager/domain/documents/entities/travel_timeline_event_entity.dart';
import 'package:pass_doc_manager/domain/documents/entities/trip_event_category.dart';
import 'package:pass_doc_manager/domain/documents/entities/vault_document_entity.dart';
import 'package:pass_doc_manager/domain/documents/entities/work_company_detail_entity.dart';
import 'package:pass_doc_manager/domain/documents/entities/work_company_folder_summary_entity.dart';
import 'package:pass_doc_manager/domain/documents/entities/work_company_recent_activity_entity.dart';
import 'package:pass_doc_manager/domain/documents/entities/work_company_vault_entity.dart';
import 'package:pass_doc_manager/domain/documents/entities/work_document_folder_type.dart';
import 'package:pass_doc_manager/domain/documents/entities/work_statement_entity.dart';
import 'package:pass_doc_manager/domain/documents/repositories/document_repository.dart';

class DocumentRepositoryImpl implements DocumentRepository {
  const DocumentRepositoryImpl({required this.localDataSource});

  final DocumentLocalDataSource localDataSource;

  static const List<DocumentCategoryType> _orderedCategories = [
    DocumentCategoryType.identity,
    DocumentCategoryType.work,
    DocumentCategoryType.vehicle,
    DocumentCategoryType.health,
    DocumentCategoryType.other,
  ];
  static const String _travelRecordTypeTripProfile = 'trip_profile';
  static const String _travelRecordTypeTimelineEvent = 'timeline_event';
  static const String _travelRecordTypeExpense = 'expense';
  static const String _travelRecordTypeBudget = 'budget';
  static const String _travelRecordTypeWalletDocument = 'wallet_document';

  @override
  Future<DocumentLibraryOverviewEntity> getLibraryOverview() async {
    final rows = await _getActiveRows();
    final visibleRows = rows
        .where(_isVisibleInLibraryOverview)
        .toList(growable: false);
    final categoryBuckets = <DocumentCategoryType, List<DocumentRecordDto>>{};

    for (final row in visibleRows) {
      final category = _categoryFromKey(row.categoryKey);
      categoryBuckets
          .putIfAbsent(category, () => <DocumentRecordDto>[])
          .add(row);
    }

    final categories = _orderedCategories
        .map((category) {
          final items =
              categoryBuckets[category] ?? const <DocumentRecordDto>[];
          final attentionCount = items.where(_requiresAttention).length;
          return DocumentCategorySummaryEntity(
            category: category,
            documentsCount: items.length,
            actionRequiredCount: attentionCount,
          );
        })
        .toList(growable: false);

    final recentActivity = visibleRows
        .take(8)
        .map((row) {
          return DocumentRecentActivityEntity(
            documentId: row.id,
            fileName: row.fileName.trim().isEmpty ? row.title : row.fileName,
            category: _categoryFromKey(row.categoryKey),
            updatedAt: _parseIsoOrNow(row.updatedAtIso),
            filesCount: _referenceFilesCount(row),
          );
        })
        .toList(growable: false);

    final attentionDocumentsCount = visibleRows
        .where(_requiresAttention)
        .length;

    return DocumentLibraryOverviewEntity(
      categories: categories,
      recentActivity: recentActivity,
      attentionDocumentsCount: attentionDocumentsCount,
      totalDocumentsCount: visibleRows.length,
    );
  }

  @override
  Future<List<IdentityDocumentEntity>> getIdentityDocuments() async {
    final rows = await _getActiveRows();
    final now = DateTime.now();

    final identityDocs =
        rows
            .where(
              (row) =>
                  _categoryFromKey(row.categoryKey) ==
                  DocumentCategoryType.identity,
            )
            .map((row) {
              final expiryDate = _parseIsoOrFallback(
                row.expiryAtIso,
                fallback: now.add(const Duration(days: 3650)),
              );
              final addedDate = _parseIsoOrNow(
                row.uploadDateIso.trim().isEmpty
                    ? row.updatedAtIso
                    : row.uploadDateIso,
              );
              final updatedAt = _parseIsoNullable(row.updatedAtIso);
              final lastUpdatedAt =
                  updatedAt != null && updatedAt.isAfter(addedDate)
                  ? updatedAt
                  : null;
              final status = _statusFor(
                expiryDate: expiryDate,
                requiresAttention: row.requiresAttention,
                now: now,
              );

              return IdentityDocumentEntity(
                id: row.id,
                typeLabel: _identityLabelFromRawType(row.documentType),
                issuer: row.title,
                country: _countryFromRecord(row),
                countryName: _countryNameForRecord(row),
                identifierLabel: row.identifierLabel.trim().isEmpty
                    ? 'ID Number'
                    : row.identifierLabel,
                identifierValue: row.identifierValue.trim().isEmpty
                    ? '-'
                    : row.identifierValue,
                expiryDate: expiryDate,
                addedDate: addedDate,
                lastUpdatedAt: lastUpdatedAt,
                status: status,
                group: _groupFromKey(row.identityGroupKey),
                isPrimary: row.isPrimary,
                holderRelation: _holderRelationFromRecord(row),
              );
            })
            .toList(growable: false)
          ..sort((a, b) {
            if (a.isPrimary != b.isPrimary) {
              return a.isPrimary ? -1 : 1;
            }
            return a.expiryDate.compareTo(b.expiryDate);
          });

    return identityDocs;
  }

  @override
  Future<List<VaultDocumentEntity>> getVaultDocuments() async {
    final rows = await _getActiveRows();
    final documents =
        rows
            .where(_isSelectableVaultDocumentRow)
            .map(_vaultDocumentFromRow)
            .toList(growable: false)
          ..sort((a, b) {
            final aPriority = _vaultDocumentPriority(a);
            final bPriority = _vaultDocumentPriority(b);
            if (aPriority != bPriority) {
              return aPriority.compareTo(bPriority);
            }
            final updatedAtComparison = b.updatedAt.compareTo(a.updatedAt);
            if (updatedAtComparison != 0) {
              return updatedAtComparison;
            }
            return a.documentName.toLowerCase().compareTo(
              b.documentName.toLowerCase(),
            );
          });
    return documents;
  }

  @override
  Future<List<WorkCompanyVaultEntity>> getWorkCompanyVaults() async {
    final rows = await _getActiveRows();
    final workRows = rows
        .where(
          (row) =>
              _categoryFromKey(row.categoryKey) == DocumentCategoryType.work,
        )
        .toList(growable: false);

    final grouped = <String, List<DocumentRecordDto>>{};
    for (final row in workRows) {
      final companyId = _workCompanyIdFromRow(row);
      grouped.putIfAbsent(companyId, () => <DocumentRecordDto>[]).add(row);
    }

    final vaults =
        grouped.entries
            .map((entry) {
              final companyRows = entry.value;
              final sorted = [...companyRows]
                ..sort(
                  (a, b) => _parseIsoOrNow(
                    b.updatedAtIso,
                  ).compareTo(_parseIsoOrNow(a.updatedAtIso)),
                );
              final latest = sorted.first;
              final profileRow = _latestCompanyProfileRow(companyRows);
              final metadataRow = profileRow ?? latest;
              final statementRows = companyRows
                  .where(_isWorkStatementRow)
                  .toList(growable: false);
              final totalStorageBytes = statementRows.fold<int>(
                0,
                (sum, row) =>
                    sum + _approxBytesFromSizeLabel(row.fileSizeLabel),
              );
              final lastAccess = _firstNonEmptyString([
                _firstCanonicalClaimValue(
                  latest,
                  DocumentMetadataFieldLabels.workLastAccessAt,
                ),
                _firstCanonicalClaimValue(
                  metadataRow,
                  DocumentMetadataFieldLabels.workLastAccessAt,
                ),
              ]);
              final role = _firstCanonicalClaimValue(
                metadataRow,
                DocumentMetadataFieldLabels.workRole,
              );
              final contact = _firstCanonicalClaimValue(
                metadataRow,
                DocumentMetadataFieldLabels.workContact,
              );
              final address = _firstNonEmptyString([
                _firstCanonicalClaimValue(
                  metadataRow,
                  DocumentMetadataFieldLabels.workAddress,
                ),
                _firstCanonicalClaimValue(
                  metadataRow,
                  DocumentMetadataFieldLabels.workLocation,
                ),
              ]);
              final startedAtRaw = _firstCanonicalClaimValue(
                metadataRow,
                DocumentMetadataFieldLabels.workStartDate,
              );
              final finishedAtRaw = _firstCanonicalClaimValue(
                metadataRow,
                DocumentMetadataFieldLabels.workEndDate,
              );
              final pinned = _firstCanonicalClaimValue(
                metadataRow,
                DocumentMetadataFieldLabels.workPinned,
              );
              final logoPath = _firstNonEmptyString([
                _firstCanonicalClaimValue(
                  metadataRow,
                  DocumentMetadataFieldLabels.workCompanyLogoPath,
                ),
                _firstStructuredFieldValue(
                  row: metadataRow,
                  labels: const [
                    'preview image path',
                    'logo',
                    'logo path',
                    'company logo',
                  ],
                ),
              ]);
              return WorkCompanyVaultEntity(
                companyId: entry.key,
                companyName: _workCompanyNameFromRow(metadataRow),
                profileDocumentId: profileRow?.id,
                documentsCount: statementRows.length,
                lastUpdatedAt: _parseIsoOrNow(latest.updatedAtIso),
                lastAccessAt: lastAccess.trim().isEmpty
                    ? null
                    : DateTime.tryParse(lastAccess)?.toLocal(),
                isPinned: (pinned ?? '').trim().toLowerCase() == 'true',
                totalStorageBytes: totalStorageBytes,
                roleLabel: (role ?? '').trim(),
                contactLabel: (contact ?? '').trim(),
                addressLabel: address,
                startedAt: _parseFlexibleDate(startedAtRaw),
                finishedAt: _parseFlexibleDate(finishedAtRaw),
                companyLogoPath: logoPath.trim().isEmpty ? null : logoPath,
              );
            })
            .toList(growable: false)
          ..sort((a, b) {
            if (a.isPinned != b.isPinned) {
              return a.isPinned ? -1 : 1;
            }
            return b.lastUpdatedAt.compareTo(a.lastUpdatedAt);
          });

    return vaults;
  }

  @override
  Future<WorkCompanyDetailEntity> getWorkCompanyDetail({
    required String companyId,
  }) async {
    final rows = await _getActiveRows();
    final companyRows = rows
        .where(
          (row) =>
              _categoryFromKey(row.categoryKey) == DocumentCategoryType.work &&
              _workCompanyIdFromRow(row) == companyId,
        )
        .toList(growable: false);
    if (companyRows.isEmpty) {
      throw StateError('Work company not found for id: $companyId');
    }

    final sorted = [...companyRows]
      ..sort(
        (a, b) => _parseIsoOrNow(
          b.updatedAtIso,
        ).compareTo(_parseIsoOrNow(a.updatedAtIso)),
      );
    final latest = sorted.first;
    final profileRow = _latestCompanyProfileRow(companyRows);
    final metadataRow = profileRow ?? latest;
    final statementRows = companyRows
        .where(_isWorkStatementRow)
        .toList(growable: false);
    final effectiveStatementRows = statementRows.isEmpty
        ? companyRows
        : statementRows;

    final folderCounts = <WorkDocumentFolderType, int>{};
    final statements =
        effectiveStatementRows
            .map((row) {
              final folderType = _workFolderFromRow(row);
              folderCounts[folderType] = (folderCounts[folderType] ?? 0) + 1;
              return WorkStatementEntity(
                documentId: row.id,
                title: _workStatementTitle(row),
                folderType: folderType,
                updatedAt: _parseIsoOrNow(row.updatedAtIso),
                statementDate: _workStatementDate(row),
                netAmountLabel: _workStatementNetAmount(row),
                statusLabel: _workStatementStatus(row),
                isArchived: row.isArchived,
                filesCount: _referenceFilesCount(row),
                label: _workStatementLabel(row),
              );
            })
            .toList(growable: false)
          ..sort((a, b) {
            final aDate = a.statementDate ?? a.updatedAt;
            final bDate = b.statementDate ?? b.updatedAt;
            return bDate.compareTo(aDate);
          });

    final folderSummaries =
        folderCounts.entries
            .map(
              (entry) => WorkCompanyFolderSummaryEntity(
                folderType: entry.key,
                documentsCount: entry.value,
              ),
            )
            .toList(growable: false)
          ..sort((a, b) => a.folderType.index.compareTo(b.folderType.index));

    final recentRows = sorted
        .where(_isWorkStatementRow)
        .take(6)
        .toList(growable: false);
    final recentSource = recentRows.isEmpty ? sorted.take(6) : recentRows;
    final recentActivity = recentSource
        .map((row) {
          return WorkCompanyRecentActivityEntity(
            documentId: row.id,
            title: _workStatementTitle(row),
            subtitle: _workRecentSubtitle(row),
            updatedAt: _parseIsoOrNow(row.updatedAtIso),
            filesCount: _referenceFilesCount(row),
          );
        })
        .toList(growable: false);

    final role = _firstCanonicalClaimValue(
      metadataRow,
      DocumentMetadataFieldLabels.workRole,
    );
    final contact = _firstCanonicalClaimValue(
      metadataRow,
      DocumentMetadataFieldLabels.workContact,
    );
    final address = _firstNonEmptyString([
      _firstCanonicalClaimValue(
        metadataRow,
        DocumentMetadataFieldLabels.workAddress,
      ),
      _firstCanonicalClaimValue(
        metadataRow,
        DocumentMetadataFieldLabels.workLocation,
      ),
    ]);
    final startDate = _firstCanonicalClaimValue(
      metadataRow,
      DocumentMetadataFieldLabels.workStartDate,
    );
    final endDate = _firstCanonicalClaimValue(
      metadataRow,
      DocumentMetadataFieldLabels.workEndDate,
    );
    final logoPath = _firstNonEmptyString([
      _firstCanonicalClaimValue(
        metadataRow,
        DocumentMetadataFieldLabels.workCompanyLogoPath,
      ),
      _firstStructuredFieldValue(
        row: metadataRow,
        labels: const ['logo', 'logo path', 'company logo'],
      ),
    ]);
    final lastAccess = _firstNonEmptyString([
      _firstCanonicalClaimValue(
        latest,
        DocumentMetadataFieldLabels.workLastAccessAt,
      ),
      _firstCanonicalClaimValue(
        metadataRow,
        DocumentMetadataFieldLabels.workLastAccessAt,
      ),
    ]);
    final parsedLastAccess = lastAccess.trim().isEmpty
        ? null
        : DateTime.tryParse(lastAccess)?.toLocal();
    final quotaMbRaw = _firstCanonicalClaimValue(
      metadataRow,
      DocumentMetadataFieldLabels.workStorageQuotaMb,
    );
    final quotaMb = double.tryParse((quotaMbRaw ?? '').trim()) ?? 10240;
    final usedBytes = effectiveStatementRows.fold<int>(
      0,
      (sum, row) => sum + _approxBytesFromSizeLabel(row.fileSizeLabel),
    );

    return WorkCompanyDetailEntity(
      companyId: companyId,
      companyName: _workCompanyNameFromRow(metadataRow),
      profileDocumentId: profileRow?.id,
      companyLogoPath: logoPath.trim().isEmpty ? null : logoPath,
      documentsCount: effectiveStatementRows.length,
      totalStorageBytes: usedBytes,
      storageQuotaBytes: (quotaMb * 1024 * 1024).round(),
      lastAccessAt: parsedLastAccess ?? _parseIsoOrNow(latest.updatedAtIso),
      startedAt: _parseFlexibleDate(startDate),
      finishedAt: _parseFlexibleDate(endDate),
      roleLabel: (role ?? '').trim(),
      contactLabel: (contact ?? '').trim(),
      addressLabel: address,
      folderSummaries: folderSummaries,
      recentActivity: recentActivity,
      statements: statements,
    );
  }

  @override
  Future<List<PropertyVaultEntity>> getPropertyVaults() async {
    final rows = await _getActiveRows();
    final propertyRows = rows
        .where(
          (row) =>
              _categoryFromKey(row.categoryKey) ==
              DocumentCategoryType.property,
        )
        .toList(growable: false);
    if (propertyRows.isEmpty) {
      return const <PropertyVaultEntity>[];
    }

    final grouped = <String, List<DocumentRecordDto>>{};
    for (final row in propertyRows) {
      final propertyId = _propertyIdFromRow(row);
      grouped.putIfAbsent(propertyId, () => <DocumentRecordDto>[]).add(row);
    }

    final vaults =
        grouped.entries
            .map((entry) {
              final rowsByProperty = entry.value;
              final sorted = [...rowsByProperty]
                ..sort(
                  (a, b) => _parseIsoOrNow(
                    b.updatedAtIso,
                  ).compareTo(_parseIsoOrNow(a.updatedAtIso)),
                );
              final latest = sorted.first;
              final profileRow = _latestPropertyProfileRow(rowsByProperty);
              final metadataRow = profileRow ?? latest;
              final documentRows = rowsByProperty
                  .where(_isPropertyDocumentRow)
                  .toList(growable: false);

              return PropertyVaultEntity(
                propertyId: entry.key,
                propertyName: _propertyNameFromRow(metadataRow),
                propertyTypeLabel: _propertyTypeFromRow(metadataRow),
                ownershipStatusLabel: _propertyOwnershipStatusFromRow(
                  metadataRow,
                ),
                fullAddress: _propertyAddressFromRow(metadataRow),
                addressSuggestionJson: _propertyAddressSuggestionJsonFromRow(
                  metadataRow,
                ),
                lastUpdatedAt: _parseIsoOrNow(latest.updatedAtIso),
                documentsCount: documentRows.length,
                profileDocumentId: profileRow?.id,
              );
            })
            .toList(growable: false)
          ..sort((a, b) => b.lastUpdatedAt.compareTo(a.lastUpdatedAt));

    return vaults;
  }

  @override
  Future<List<TravelTripEntity>> getTravelTrips() async {
    final rows = await _getActiveRows();
    final travelRows = rows
        .where(
          (row) =>
              _categoryFromKey(row.categoryKey) == DocumentCategoryType.travel,
        )
        .toList(growable: false);
    if (travelRows.isEmpty) {
      return const <TravelTripEntity>[];
    }

    final grouped = <String, List<DocumentRecordDto>>{};
    for (final row in travelRows) {
      final tripId = _travelTripIdFromRow(row);
      grouped.putIfAbsent(tripId, () => <DocumentRecordDto>[]).add(row);
    }

    final now = DateTime.now();
    final trips =
        grouped.entries
            .map((entry) => _travelTripFromRows(entry.key, entry.value))
            .toList(growable: false)
          ..sort((a, b) {
            final aEnded = _dateOnly(a.endDate).isBefore(_dateOnly(now));
            final bEnded = _dateOnly(b.endDate).isBefore(_dateOnly(now));
            if (aEnded != bEnded) {
              return aEnded ? 1 : -1;
            }
            if (!aEnded) {
              return a.startDate.compareTo(b.startDate);
            }
            return b.endDate.compareTo(a.endDate);
          });

    return trips;
  }

  @override
  Future<PropertyDetailEntity> getPropertyDetail({
    required String propertyId,
  }) async {
    final rows = await _getActiveRows();
    final propertyRows = rows
        .where(
          (row) =>
              _categoryFromKey(row.categoryKey) ==
                  DocumentCategoryType.property &&
              _propertyIdFromRow(row) == propertyId,
        )
        .toList(growable: false);
    if (propertyRows.isEmpty) {
      throw StateError('Property not found for id: $propertyId');
    }

    final sorted = [...propertyRows]
      ..sort(
        (a, b) => _parseIsoOrNow(
          b.updatedAtIso,
        ).compareTo(_parseIsoOrNow(a.updatedAtIso)),
      );
    final latest = sorted.first;
    final profileRow = _latestPropertyProfileRow(propertyRows);
    final metadataRow = profileRow ?? latest;
    final documentRows = propertyRows
        .where(_isPropertyDocumentRow)
        .toList(growable: false);
    final effectiveDocumentRows = documentRows.isEmpty
        ? const <DocumentRecordDto>[]
        : documentRows;

    final assetCounts = <PropertyAssetType, int>{
      for (final type in PropertyAssetType.values) type: 0,
    };
    for (final row in effectiveDocumentRows) {
      final assetType = _propertyAssetTypeFromRow(row);
      assetCounts[assetType] = (assetCounts[assetType] ?? 0) + 1;
    }

    final assetSummaries = PropertyAssetType.values
        .map(
          (type) => PropertyAssetSummaryEntity(
            assetType: type,
            itemsCount: assetCounts[type] ?? 0,
          ),
        )
        .toList(growable: false);

    final latestActivityRow = effectiveDocumentRows.isEmpty
        ? latest
        : sorted.firstWhere(_isPropertyDocumentRow, orElse: () => latest);
    final lastActivityLabel = _firstNonEmptyString([
      latestActivityRow.title,
      latestActivityRow.fileName,
      _propertyNameFromRow(metadataRow),
    ]);

    return PropertyDetailEntity(
      propertyId: propertyId,
      propertyName: _propertyNameFromRow(metadataRow),
      propertyTypeLabel: _propertyTypeFromRow(metadataRow),
      ownershipStatusLabel: _propertyOwnershipStatusFromRow(metadataRow),
      fullAddress: _propertyAddressFromRow(metadataRow),
      addressSuggestionJson: _propertyAddressSuggestionJsonFromRow(metadataRow),
      occupancyStatusLabel: _propertyOccupancyStatusFromRow(metadataRow),
      monthlyAmountLabel: _propertyMonthlyAmountFromRow(metadataRow),
      lastUpdatedAt: _parseIsoOrNow(latestActivityRow.updatedAtIso),
      lastActivityLabel: lastActivityLabel,
      profileDocumentId: profileRow?.id,
      assetSummaries: assetSummaries,
    );
  }

  @override
  Future<TravelTripDetailEntity> getTravelTripDetail({
    required String tripId,
  }) async {
    final rows = await _getActiveRows();
    final tripRows = rows
        .where(
          (row) =>
              _categoryFromKey(row.categoryKey) ==
                  DocumentCategoryType.travel &&
              _travelTripIdFromRow(row) == tripId,
        )
        .toList(growable: false);
    if (tripRows.isEmpty) {
      throw StateError('Travel trip not found for id: $tripId');
    }

    final trip = _travelTripFromRows(tripId, tripRows);
    final timelineEvents =
        tripRows
            .where(_isTravelTimelineEventRow)
            .map(_travelTimelineEventFromRow)
            .toList(growable: false)
          ..sort((a, b) => a.startAt.compareTo(b.startAt));
    final expenses =
        tripRows
            .where(_isTravelExpenseRow)
            .map(_travelExpenseFromRow)
            .toList(growable: false)
          ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    final walletDocuments =
        tripRows
            .where(_isTravelWalletDocumentRow)
            .map(_travelDocumentFromRow)
            .toList(growable: false)
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    final budgetRow = _latestTravelBudgetRow(tripRows);
    final budget = budgetRow == null ? null : _travelBudgetFromRow(budgetRow);
    final destinationsCount = timelineEvents
        .map((event) => event.locationLabel.trim().toLowerCase())
        .where((location) => location.isNotEmpty)
        .toSet()
        .length;
    final now = DateTime.now();
    final upcoming =
        timelineEvents
            .where((event) => event.startAt.isAfter(now))
            .toList(growable: false)
          ..sort((a, b) => a.startAt.compareTo(b.startAt));
    final reminderEvent = upcoming.isNotEmpty
        ? upcoming.first
        : (timelineEvents.isNotEmpty ? timelineEvents.last : null);
    final reminderTitle = reminderEvent == null
        ? ''
        : 'Upcoming: ${reminderEvent.title}';
    final reminderSubtitle = reminderEvent == null
        ? ''
        : _travelReminderSubtitle(reminderEvent, now);

    return TravelTripDetailEntity(
      trip: trip,
      timelineEvents: timelineEvents,
      expenses: expenses,
      walletDocuments: walletDocuments,
      destinationsCount: destinationsCount,
      budget: budget,
      upcomingReminderTitle: reminderTitle,
      upcomingReminderSubtitle: reminderSubtitle,
    );
  }

  @override
  Future<List<PropertyAssetRecordEntity>> getPropertyAssetRecords({
    required String propertyId,
    PropertyAssetType? assetType,
  }) async {
    final rows = await _getActiveRows();
    final propertyRows = rows
        .where(
          (row) =>
              _categoryFromKey(row.categoryKey) ==
                  DocumentCategoryType.property &&
              _propertyIdFromRow(row) == propertyId &&
              _isPropertyDocumentRow(row),
        )
        .toList(growable: false);
    if (propertyRows.isEmpty) {
      return const <PropertyAssetRecordEntity>[];
    }

    final records =
        propertyRows
            .map((row) {
              final resolvedAssetType = _propertyAssetTypeFromRow(row);
              return PropertyAssetRecordEntity(
                documentId: row.id,
                assetType: resolvedAssetType,
                title: _propertyRecordTitle(row),
                fileName: _propertyRecordFileName(row),
                fileSizeLabel: row.fileSizeLabel.trim().isEmpty
                    ? '1.8 MB'
                    : row.fileSizeLabel,
                updatedAt: _parseIsoOrNow(row.updatedAtIso),
                issueDate: _propertyIssueDateFromRow(row),
                paymentAmountLabel: _propertyPaymentAmountFromRow(row),
                paymentDate: _propertyPaymentDateFromRow(row),
              );
            })
            .where((item) => assetType == null || item.assetType == assetType)
            .toList(growable: false)
          ..sort((a, b) {
            final aDate = a.paymentDate ?? a.issueDate ?? a.updatedAt;
            final bDate = b.paymentDate ?? b.issueDate ?? b.updatedAt;
            return bDate.compareTo(aDate);
          });

    return records;
  }

  @override
  Future<DocumentDetailEntity> getDocumentDetail({
    required String documentId,
  }) async {
    final row = await localDataSource.getDocumentById(id: documentId);
    if (row == null) {
      throw StateError('Document not found for id: $documentId');
    }
    return _toDetailEntity(row);
  }

  @override
  Future<DocumentDetailEntity> createScannedDocument({
    required DocumentType type,
    required DocumentCaptureSource source,
    required int scanPagesCount,
    DocumentCategoryType? categoryOverride,
    String? documentTypeKeyOverride,
    String? issuerOverride,
    String? identifierLabelOverride,
    String? identifierValueOverride,
    DateTime? expiryDateOverride,
    List<Map<String, String>>? structuredFieldsOverride,
    List<String>? tagsOverride,
  }) async {
    final now = DateTime.now().toUtc();
    final template = _templateForType(type, now.toLocal());
    final rawTypeKey = _resolveRawTypeKey(
      type: type,
      fallbackRawTypeKey: template.rawTypeKey,
      overrideRawTypeKey: documentTypeKeyOverride,
    );
    final id = localDataSource.nextDocumentId(prefix: type.key);
    final issuer = (issuerOverride ?? '').trim().isEmpty
        ? template.issuer
        : issuerOverride!.trim();
    final identifierLabel = (identifierLabelOverride ?? '').trim().isEmpty
        ? template.identifierLabel
        : identifierLabelOverride!.trim();
    final identifierValue = (identifierValueOverride ?? '').trim().isEmpty
        ? template.identifierValue
        : identifierValueOverride!.trim();
    final expiryDate = expiryDateOverride ?? template.expiryDate;
    final structuredFields =
        structuredFieldsOverride != null && structuredFieldsOverride.isNotEmpty
        ? _sanitizeStructuredFields(structuredFieldsOverride)
        : template.structuredFields;
    final tags = tagsOverride != null && tagsOverride.isNotEmpty
        ? tagsOverride.where((tag) => tag.trim().isNotEmpty).toList()
        : template.tags;
    final resolvedCategory = categoryOverride ?? template.category;

    final hasExistingPrimaryIdentity = (await _getActiveRows()).any(
      (row) =>
          _categoryFromKey(row.categoryKey) == DocumentCategoryType.identity &&
          row.isPrimary,
    );
    final shouldSetPrimary =
        resolvedCategory == DocumentCategoryType.identity &&
        !hasExistingPrimaryIdentity;

    final row = DocumentRecordDto(
      id: id,
      title: issuer,
      fileName: '${template.fileStem}_${now.millisecondsSinceEpoch}.pdf',
      categoryKey: resolvedCategory.key,
      updatedAtIso: now.toIso8601String(),
      documentType: rawTypeKey,
      identityGroupKey: template.identityGroup,
      identifierLabel: identifierLabel,
      identifierValue: identifierValue,
      expiryAtIso: expiryDate?.toUtc().toIso8601String() ?? '',
      requiresAttention: _shouldRequireAttention(expiryDate, now.toLocal()),
      structuredFields: structuredFields,
      tags: tags,
      uploadDateIso: now.toIso8601String(),
      fileSizeLabel: _sizeLabel(scanPagesCount),
      isVerifiedScan: true,
      isFavorite: false,
      isPrimary: shouldSetPrimary,
      captureSource: source.key,
      scanPagesCount: max(1, scanPagesCount),
    );

    await localDataSource.saveDocument(row);
    return _toDetailEntity(row);
  }

  @override
  Future<DocumentDetailEntity> updateDocument({
    required String documentId,
    required DocumentType type,
    required DocumentCaptureSource source,
    required int scanPagesCount,
    DocumentCategoryType? categoryOverride,
    String? documentTypeKeyOverride,
    String? issuerOverride,
    String? identifierLabelOverride,
    String? identifierValueOverride,
    DateTime? expiryDateOverride,
    List<Map<String, String>>? structuredFieldsOverride,
    List<String>? tagsOverride,
  }) async {
    final existing = await localDataSource.getDocumentById(id: documentId);
    if (existing == null) {
      throw StateError('Document not found for id: $documentId');
    }

    final now = DateTime.now().toUtc();
    final template = _templateForType(type, now.toLocal());
    final rawTypeKey = _resolveRawTypeKey(
      type: type,
      fallbackRawTypeKey: template.rawTypeKey,
      overrideRawTypeKey: documentTypeKeyOverride,
    );
    final issuer = (issuerOverride ?? '').trim().isEmpty
        ? existing.title
        : issuerOverride!.trim();
    final identifierLabel = (identifierLabelOverride ?? '').trim().isEmpty
        ? existing.identifierLabel
        : identifierLabelOverride!.trim();
    final identifierValue = (identifierValueOverride ?? '').trim().isEmpty
        ? existing.identifierValue
        : identifierValueOverride!.trim();
    final expiryDate =
        expiryDateOverride ??
        DateTime.tryParse(existing.expiryAtIso)?.toLocal();
    final structuredFields =
        structuredFieldsOverride != null && structuredFieldsOverride.isNotEmpty
        ? _sanitizeStructuredFields(structuredFieldsOverride)
        : (existing.structuredFields.isNotEmpty
              ? existing.structuredFields
              : template.structuredFields);
    final tags = tagsOverride != null && tagsOverride.isNotEmpty
        ? tagsOverride.where((tag) => tag.trim().isNotEmpty).toList()
        : (existing.tags.isNotEmpty ? existing.tags : template.tags);
    final resolvedScanPages = max(
      1,
      scanPagesCount <= 0 ? existing.scanPagesCount : scanPagesCount,
    );

    final updated = _copyRecord(
      existing,
      title: issuer,
      categoryKey: (categoryOverride ?? template.category).key,
      updatedAtIso: now.toIso8601String(),
      uploadDateIso: existing.uploadDateIso.trim().isEmpty
          ? existing.updatedAtIso
          : existing.uploadDateIso,
      documentType: rawTypeKey,
      identityGroupKey: template.identityGroup,
      identifierLabel: identifierLabel,
      identifierValue: identifierValue,
      expiryAtIso: expiryDate?.toUtc().toIso8601String() ?? '',
      requiresAttention: _shouldRequireAttention(expiryDate, now.toLocal()),
      structuredFields: structuredFields,
      tags: tags,
      fileSizeLabel: _sizeLabel(resolvedScanPages),
      captureSource: source.key,
      scanPagesCount: resolvedScanPages,
    );

    await localDataSource.saveDocument(updated);
    return _toDetailEntity(updated);
  }

  @override
  Future<DocumentDetailEntity> replaceDocumentCapture({
    required String documentId,
    required DocumentCaptureSource source,
    required int scanPagesCount,
  }) async {
    final existing = await localDataSource.getDocumentById(id: documentId);
    if (existing == null) {
      throw StateError('Document not found for id: $documentId');
    }

    final now = DateTime.now().toUtc();
    final expiryDate = DateTime.tryParse(existing.expiryAtIso)?.toLocal();

    final updated = _copyRecord(
      existing,
      updatedAtIso: now.toIso8601String(),
      uploadDateIso: existing.uploadDateIso.trim().isEmpty
          ? existing.updatedAtIso
          : existing.uploadDateIso,
      fileSizeLabel: _sizeLabel(scanPagesCount),
      isVerifiedScan: true,
      captureSource: source.key,
      scanPagesCount: max(1, scanPagesCount),
      requiresAttention: _shouldRequireAttention(expiryDate, now.toLocal()),
    );

    await localDataSource.saveDocument(updated);
    return _toDetailEntity(updated);
  }

  @override
  Future<DocumentDetailEntity> forceExpireDocument({
    required String documentId,
  }) async {
    final existing = await localDataSource.getDocumentById(id: documentId);
    if (existing == null) {
      throw StateError('Document not found for id: $documentId');
    }

    final now = DateTime.now().toLocal();
    final forcedExpiry = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 1));
    final nowIso = DateTime.now().toUtc().toIso8601String();
    final updated = _copyRecord(
      existing,
      updatedAtIso: nowIso,
      expiryAtIso: forcedExpiry.toUtc().toIso8601String(),
      requiresAttention: true,
      structuredFields: _structuredFieldsWithForcedExpiry(
        existing.structuredFields,
        forcedExpiry,
      ),
    );

    await localDataSource.saveDocument(updated);
    return _toDetailEntity(updated);
  }

  @override
  Future<void> deleteDocument({required String documentId}) {
    return localDataSource.deleteDocumentById(id: documentId);
  }

  @override
  Future<void> archiveDocument({required String documentId}) async {
    final existing = await localDataSource.getDocumentById(id: documentId);
    if (existing == null) {
      return;
    }
    if (existing.isArchived) {
      return;
    }
    final nowIso = DateTime.now().toUtc().toIso8601String();
    final updated = _copyRecord(
      existing,
      updatedAtIso: nowIso,
      isArchived: true,
      archivedAtIso: nowIso,
    );
    await localDataSource.saveDocument(updated);
  }

  @override
  Future<void> toggleFavorite({
    required String documentId,
    required bool isFavorite,
  }) async {
    final existing = await localDataSource.getDocumentById(id: documentId);
    if (existing == null) {
      return;
    }

    final updated = _copyRecord(existing, isFavorite: isFavorite);
    await localDataSource.saveDocument(updated);
  }

  @override
  Future<void> setPrimaryIdentityDocument({
    required String documentId,
    bool isPrimary = true,
  }) async {
    final rows = await localDataSource.getDocuments();
    DocumentRecordDto? target;
    for (final row in rows) {
      if (row.id == documentId) {
        target = row;
        break;
      }
    }
    if (target == null) {
      return;
    }
    if (_categoryFromKey(target.categoryKey) != DocumentCategoryType.identity ||
        target.isArchived) {
      return;
    }

    final nowIso = DateTime.now().toUtc().toIso8601String();
    if (target.isPrimary == isPrimary) {
      return;
    }

    final updated = _copyRecord(
      target,
      isPrimary: isPrimary,
      updatedAtIso: nowIso,
    );
    await localDataSource.saveDocument(updated);
  }

  DocumentDetailEntity _toDetailEntity(DocumentRecordDto row) {
    final type = _documentTypeFromRaw(row.documentType);
    final category = _categoryFromKey(row.categoryKey);
    final expiryDate = DateTime.tryParse(row.expiryAtIso)?.toLocal();
    final now = DateTime.now();

    final status = expiryDate == null
        ? (row.requiresAttention
              ? IdentityDocumentStatus.expiringSoon
              : IdentityDocumentStatus.valid)
        : _statusFor(
            expiryDate: expiryDate,
            requiresAttention: row.requiresAttention,
            now: now,
          );

    final fields = row.structuredFields.isNotEmpty
        ? row.structuredFields
              .map(
                (field) => DocumentStructuredFieldEntity(
                  label: field['label'] ?? '',
                  value: field['value'] ?? '',
                ),
              )
              .where(
                (field) =>
                    field.label.trim().isNotEmpty &&
                    field.value.trim().isNotEmpty,
              )
              .toList(growable: false)
        : _fallbackStructuredFields(row, type, expiryDate);

    return DocumentDetailEntity(
      id: row.id,
      type: type,
      category: category,
      screenTitle: _detailScreenTitle(type: type, rawTypeKey: row.documentType),
      issuer: row.title,
      fileName: row.fileName,
      structuredFields: fields,
      tags: row.tags.isEmpty ? _defaultTagsForType(type) : row.tags,
      uploadDate: _parseIsoOrNow(
        row.uploadDateIso.trim().isEmpty ? row.updatedAtIso : row.uploadDateIso,
      ),
      fileSizeLabel: row.fileSizeLabel,
      isVerifiedScan: row.isVerifiedScan,
      isFavorite: row.isFavorite,
      isPrimary: row.isPrimary,
      status: status,
      captureSource: _captureSourceFromKey(row.captureSource),
      scanPagesCount: row.scanPagesCount <= 0 ? 1 : row.scanPagesCount,
      referenceFilesCount: _referenceFilesCount(row),
      updatedAt: _parseIsoOrNow(row.updatedAtIso),
      expiryDate: expiryDate,
    );
  }

  List<DocumentStructuredFieldEntity> _fallbackStructuredFields(
    DocumentRecordDto row,
    DocumentType type,
    DateTime? expiryDate,
  ) {
    final expiryValue = expiryDate == null ? '-' : _formatDate(expiryDate);
    final idLabel = row.identifierLabel.trim().isEmpty
        ? (type == DocumentType.passport ? 'Passport Number' : 'ID Number')
        : row.identifierLabel;
    final idValue = row.identifierValue.trim().isEmpty
        ? '-'
        : row.identifierValue;

    return switch (type) {
      DocumentType.passport => [
        DocumentStructuredFieldEntity(label: idLabel, value: idValue),
        DocumentStructuredFieldEntity(label: 'Nationality', value: row.title),
        const DocumentStructuredFieldEntity(
          label: 'Birth Date',
          value: '14 JUN 1992',
        ),
        DocumentStructuredFieldEntity(label: 'Expiry Date', value: expiryValue),
        DocumentStructuredFieldEntity(
          label: 'Issuing Country',
          value: row.title,
        ),
      ],
      DocumentType.idCard => [
        DocumentStructuredFieldEntity(label: idLabel, value: idValue),
        const DocumentStructuredFieldEntity(
          label: 'Full Name',
          value: 'Sarah J. Williams',
        ),
        DocumentStructuredFieldEntity(label: 'Nationality', value: row.title),
        const DocumentStructuredFieldEntity(
          label: 'Birth Date',
          value: '12 MAY 1995',
        ),
        DocumentStructuredFieldEntity(label: 'Expiry Date', value: expiryValue),
      ],
      DocumentType.driversLicense => [
        DocumentStructuredFieldEntity(label: idLabel, value: idValue),
        const DocumentStructuredFieldEntity(
          label: 'Categories',
          value: 'A, B, B1, BE',
        ),
        DocumentStructuredFieldEntity(
          label: 'Issuing Authority',
          value: row.title,
        ),
        const DocumentStructuredFieldEntity(
          label: 'Issue Date',
          value: '05 MAY 2021',
        ),
        DocumentStructuredFieldEntity(label: 'Expiry Date', value: expiryValue),
      ],
      DocumentType.other => [
        DocumentStructuredFieldEntity(label: 'Document ID', value: idValue),
        DocumentStructuredFieldEntity(
          label: 'Category',
          value: _toSentenceCase(row.categoryKey),
        ),
        DocumentStructuredFieldEntity(
          label: 'Updated',
          value: _formatDate(_parseIsoOrNow(row.updatedAtIso)),
        ),
      ],
    };
  }

  _DocumentTemplate _templateForType(DocumentType type, DateTime now) {
    final suffix = (1000 + Random().nextInt(9000)).toString();

    return switch (type) {
      DocumentType.passport => _DocumentTemplate(
        category: DocumentCategoryType.identity,
        rawTypeKey: 'passport',
        identityGroup: IdentityDocumentGroup.travel.key,
        issuer: 'United Kingdom',
        identifierLabel: 'Passport Number',
        identifierValue: 'A12$suffix',
        expiryDate: DateTime(now.year + 6, now.month, now.day),
        fileStem: 'Passport',
        tags: const ['Travel', 'ID', 'Personal'],
        structuredFields: [
          {'label': 'Passport Number', 'value': 'A12$suffix'},
          {'label': 'Nationality', 'value': 'United Kingdom'},
          {'label': 'Birth Date', 'value': '14 JUN 1992'},
          {
            'label': 'Expiry Date',
            'value': _formatDate(DateTime(now.year + 6, now.month, now.day)),
          },
          {'label': 'Issuing Country', 'value': 'United Kingdom'},
        ],
      ),
      DocumentType.idCard => _DocumentTemplate(
        category: DocumentCategoryType.identity,
        rawTypeKey: 'id_card',
        identityGroup: IdentityDocumentGroup.personal.key,
        issuer: 'United States',
        identifierLabel: 'ID Number',
        identifierValue: 'C87$suffix',
        expiryDate: DateTime(now.year + 3, now.month, now.day),
        fileStem: 'ID_Card',
        tags: const ['Travel', 'ID', 'Personal'],
        structuredFields: [
          {'label': 'ID Number', 'value': 'C87$suffix'},
          {'label': 'Full Name', 'value': 'Sarah J. Williams'},
          {'label': 'Nationality', 'value': 'United States'},
          {'label': 'Birth Date', 'value': '12 MAY 1995'},
          {
            'label': 'Expiry Date',
            'value': _formatDate(DateTime(now.year + 3, now.month, now.day)),
          },
        ],
      ),
      DocumentType.driversLicense => _DocumentTemplate(
        category: DocumentCategoryType.identity,
        rawTypeKey: 'drivers_license',
        identityGroup: IdentityDocumentGroup.personal.key,
        issuer: 'California State',
        identifierLabel: 'License Number',
        identifierValue: 'DL-99$suffix',
        expiryDate: DateTime(now.year + 4, now.month, now.day),
        fileStem: 'Driver_License',
        tags: const ['Driving', 'ID', 'Essential'],
        structuredFields: [
          {'label': 'License Number', 'value': 'DL-99$suffix'},
          {'label': 'Categories', 'value': 'A, B, B1, BE'},
          {'label': 'Issuing Authority', 'value': 'California DMV'},
          {'label': 'Issue Date', 'value': '05 MAY 2021'},
          {
            'label': 'Expiry Date',
            'value': _formatDate(DateTime(now.year + 4, now.month, now.day)),
          },
        ],
      ),
      DocumentType.other => _DocumentTemplate(
        category: DocumentCategoryType.other,
        rawTypeKey: 'other',
        identityGroup: '',
        issuer: 'Other Documents',
        identifierLabel: 'Document ID',
        identifierValue: 'DOC-$suffix',
        expiryDate: null,
        fileStem: 'Document',
        tags: const ['Document'],
        structuredFields: [
          {'label': 'Document ID', 'value': 'DOC-$suffix'},
          {'label': 'Category', 'value': 'Other'},
          {'label': 'Updated', 'value': _formatDate(now)},
        ],
      ),
    };
  }

  bool _requiresAttention(DocumentRecordDto row) {
    if (row.requiresAttention) {
      return true;
    }

    final expiry = DateTime.tryParse(row.expiryAtIso)?.toLocal();
    if (expiry == null) {
      return false;
    }

    final today = _dateOnly(DateTime.now());
    final expiryDate = _dateOnly(expiry);
    if (expiryDate.isBefore(today)) {
      return true;
    }

    return expiryDate.difference(today).inDays <= 120;
  }

  bool _shouldRequireAttention(DateTime? expiryDate, DateTime now) {
    if (expiryDate == null) {
      return false;
    }
    final today = _dateOnly(now);
    final expiry = _dateOnly(expiryDate);
    if (expiry.isBefore(today)) {
      return true;
    }
    return expiry.difference(today).inDays <= 120;
  }

  DateTime _parseIsoOrNow(String raw) {
    final parsed = DateTime.tryParse(raw)?.toLocal();
    return parsed ?? DateTime.now();
  }

  DateTime? _parseIsoNullable(String raw) {
    if (raw.trim().isEmpty) {
      return null;
    }
    return DateTime.tryParse(raw)?.toLocal();
  }

  DateTime _parseIsoOrFallback(String raw, {required DateTime fallback}) {
    final parsed = DateTime.tryParse(raw)?.toLocal();
    return parsed ?? fallback;
  }

  IdentityDocumentStatus _statusFor({
    required DateTime expiryDate,
    required bool requiresAttention,
    required DateTime now,
  }) {
    final today = _dateOnly(now);
    final expiry = _dateOnly(expiryDate);
    if (expiry.isBefore(today)) {
      return IdentityDocumentStatus.expired;
    }

    if (requiresAttention || expiry.difference(today).inDays <= 120) {
      return IdentityDocumentStatus.expiringSoon;
    }

    return IdentityDocumentStatus.valid;
  }

  DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  String _fileNameFromPathValue(String rawPath) {
    final value = rawPath.trim();
    if (value.isEmpty) {
      return '';
    }
    final normalized = value.replaceAll('\\', '/');
    final index = normalized.lastIndexOf('/');
    if (index < 0 || index == normalized.length - 1) {
      return normalized;
    }
    return normalized.substring(index + 1);
  }

  TravelTripEntity _travelTripFromRows(
    String tripId,
    List<DocumentRecordDto> rows,
  ) {
    final sorted = [...rows]
      ..sort(
        (a, b) => _parseIsoOrNow(
          b.updatedAtIso,
        ).compareTo(_parseIsoOrNow(a.updatedAtIso)),
      );
    final latest = sorted.first;
    final profileRow = _latestTravelProfileRow(rows);
    final metadataRow = profileRow ?? latest;
    final timelineRows = rows
        .where(_isTravelTimelineEventRow)
        .toList(growable: false);
    final expenseRows = rows.where(_isTravelExpenseRow).toList(growable: false);
    final walletRows = rows
        .where(_isTravelWalletDocumentRow)
        .toList(growable: false);
    final totalSpent = expenseRows.fold<double>(
      0,
      (sum, row) => sum + _travelExpenseAmountFromRow(row),
    );
    final eventDocumentsCount = timelineRows.fold<int>(
      0,
      (sum, row) => sum + _travelEventDocumentsCountFromRow(row),
    );
    final startDate =
        _travelTripStartDateFromRow(metadataRow) ??
        _parseIsoOrNow(latest.updatedAtIso);
    final endDate = _travelTripEndDateFromRow(metadataRow) ?? startDate;
    final currencyCode = _firstNonEmptyString([
      for (final row in expenseRows)
        _firstCanonicalClaimValue(
          row,
          DocumentMetadataFieldLabels.travelExpenseCurrency,
        ),
      _firstCanonicalClaimValue(
        metadataRow,
        DocumentMetadataFieldLabels.travelBudgetCurrency,
      ),
      'USD',
    ]).toUpperCase();

    return TravelTripEntity(
      tripId: tripId,
      profileDocumentId: profileRow?.id,
      title: _travelTripTitleFromRow(metadataRow),
      destinationSummary: _travelDestinationFromRow(metadataRow),
      notes: _travelTripNotesFromRow(metadataRow),
      startDate: _dateOnly(startDate),
      endDate: _dateOnly(endDate),
      coverImagePath: _travelCoverImageFromRow(metadataRow),
      timelineEventsCount: timelineRows.length,
      documentsCount: walletRows.length + eventDocumentsCount,
      expensesCount: expenseRows.length,
      totalSpent: totalSpent,
      currencyCode: currencyCode,
      lastUpdatedAt: _parseIsoOrNow(latest.updatedAtIso),
    );
  }

  String _travelTripIdFromRow(DocumentRecordDto row) {
    final claim = _firstCanonicalClaimValue(
      row,
      DocumentMetadataFieldLabels.travelTripId,
    );
    final direct = _firstStructuredFieldValue(
      row: row,
      labels: const ['trip id', 'travel trip id'],
    );
    final value = _firstNonEmptyString([claim, direct]);
    if (value.trim().isNotEmpty) {
      return _slugify(value);
    }
    final titleFromClaim = _travelTripTitleFromRow(row);
    if (titleFromClaim.trim().isNotEmpty) {
      return _slugify(titleFromClaim);
    }
    return _slugify(row.title);
  }

  String _travelRecordTypeFromRow(DocumentRecordDto row) {
    final claim = _firstCanonicalClaimValue(
      row,
      DocumentMetadataFieldLabels.travelRecordType,
    );
    final direct = _firstStructuredFieldValue(
      row: row,
      labels: const ['record type', 'travel record type'],
    );
    final resolved = _firstNonEmptyString([claim, direct]).trim().toLowerCase();
    if (resolved.isNotEmpty) {
      return resolved;
    }
    final rawType = row.documentType.trim().toLowerCase();
    if (rawType.startsWith('travel_')) {
      return rawType.replaceFirst('travel_', '');
    }
    return _travelRecordTypeWalletDocument;
  }

  bool _isTravelTripProfileRow(DocumentRecordDto row) =>
      _travelRecordTypeFromRow(row) == _travelRecordTypeTripProfile;

  bool _isTravelTimelineEventRow(DocumentRecordDto row) =>
      _travelRecordTypeFromRow(row) == _travelRecordTypeTimelineEvent;

  bool _isTravelExpenseRow(DocumentRecordDto row) =>
      _travelRecordTypeFromRow(row) == _travelRecordTypeExpense;

  bool _isTravelBudgetRow(DocumentRecordDto row) =>
      _travelRecordTypeFromRow(row) == _travelRecordTypeBudget;

  bool _isTravelWalletDocumentRow(DocumentRecordDto row) =>
      _travelRecordTypeFromRow(row) == _travelRecordTypeWalletDocument;

  DocumentRecordDto? _latestTravelProfileRow(List<DocumentRecordDto> rows) {
    final profileRows = rows
        .where(_isTravelTripProfileRow)
        .toList(growable: false);
    if (profileRows.isEmpty) {
      return null;
    }
    profileRows.sort(
      (a, b) => _parseIsoOrNow(
        b.updatedAtIso,
      ).compareTo(_parseIsoOrNow(a.updatedAtIso)),
    );
    return profileRows.first;
  }

  DocumentRecordDto? _latestTravelBudgetRow(List<DocumentRecordDto> rows) {
    final budgetRows = rows.where(_isTravelBudgetRow).toList(growable: false);
    if (budgetRows.isEmpty) {
      return null;
    }
    budgetRows.sort(
      (a, b) => _parseIsoOrNow(
        b.updatedAtIso,
      ).compareTo(_parseIsoOrNow(a.updatedAtIso)),
    );
    return budgetRows.first;
  }

  String _travelTripTitleFromRow(DocumentRecordDto row) {
    final claim = _firstCanonicalClaimValue(
      row,
      DocumentMetadataFieldLabels.travelTripTitle,
    );
    final direct = _firstStructuredFieldValue(
      row: row,
      labels: const ['trip title', 'title'],
    );
    return _firstNonEmptyString([claim, direct, row.title, 'Trip']);
  }

  String _travelDestinationFromRow(DocumentRecordDto row) {
    final claim = _firstCanonicalClaimValue(
      row,
      DocumentMetadataFieldLabels.travelDestination,
    );
    final direct = _firstStructuredFieldValue(
      row: row,
      labels: const ['destination', 'location'],
    );
    return _firstNonEmptyString([claim, direct, row.identifierValue]);
  }

  String _travelTripNotesFromRow(DocumentRecordDto row) {
    final claim = _firstCanonicalClaimValue(
      row,
      DocumentMetadataFieldLabels.travelNotes,
    );
    final direct = _firstStructuredFieldValue(
      row: row,
      labels: const ['trip notes', 'notes'],
    );
    return _firstNonEmptyString([claim, direct]);
  }

  DateTime? _travelTripStartDateFromRow(DocumentRecordDto row) {
    final claim = _firstCanonicalClaimValue(
      row,
      DocumentMetadataFieldLabels.travelStartDate,
    );
    final direct = _firstStructuredFieldValue(
      row: row,
      labels: const ['start date', 'trip start date'],
    );
    return _parseFlexibleDate(claim) ?? _parseFlexibleDate(direct);
  }

  DateTime? _travelTripEndDateFromRow(DocumentRecordDto row) {
    final claim = _firstCanonicalClaimValue(
      row,
      DocumentMetadataFieldLabels.travelEndDate,
    );
    final direct = _firstStructuredFieldValue(
      row: row,
      labels: const ['end date', 'trip end date'],
    );
    return _parseFlexibleDate(claim) ?? _parseFlexibleDate(direct);
  }

  String? _travelCoverImageFromRow(DocumentRecordDto row) {
    final claim = _firstCanonicalClaimValue(
      row,
      DocumentMetadataFieldLabels.travelCoverImagePath,
    );
    final direct = _firstStructuredFieldValue(
      row: row,
      labels: const ['cover image path', 'cover path'],
    );
    final value = _firstNonEmptyString([claim, direct]);
    return value.trim().isEmpty ? null : value;
  }

  int _travelEventDocumentsCountFromRow(DocumentRecordDto row) {
    final claim = _firstCanonicalClaimValue(
      row,
      DocumentMetadataFieldLabels.travelEventDocumentsCount,
    );
    final direct = _firstStructuredFieldValue(
      row: row,
      labels: const ['documents count', 'document count'],
    );
    return int.tryParse(_firstNonEmptyString([claim, direct]).trim()) ?? 0;
  }

  TravelTimelineEventEntity _travelTimelineEventFromRow(DocumentRecordDto row) {
    final dateRaw = _firstCanonicalClaimValue(
      row,
      DocumentMetadataFieldLabels.travelEventDate,
    );
    final timeRaw = _firstCanonicalClaimValue(
      row,
      DocumentMetadataFieldLabels.travelEventTime,
    );
    final fallbackDate = _parseIsoOrNow(row.updatedAtIso);
    final startAt = _travelDateTimeFromRaw(
      dateRaw: dateRaw,
      timeRaw: timeRaw,
      fallback: fallbackDate,
    );
    final previewPath = _firstNonEmptyString([
      _firstCanonicalClaimValue(
        row,
        DocumentMetadataFieldLabels.travelEventPreviewImagePath,
      ),
      _firstCanonicalClaimValue(
        row,
        DocumentMetadataFieldLabels.previewImagePath,
      ),
    ]);

    return TravelTimelineEventEntity(
      eventId: row.id,
      tripId: _travelTripIdFromRow(row),
      category: parseTripEventCategory(
        _firstNonEmptyString([
          _firstCanonicalClaimValue(
            row,
            DocumentMetadataFieldLabels.travelEventCategory,
          ),
          _firstStructuredFieldValue(
            row: row,
            labels: const ['event category', 'category'],
          ),
        ]),
      ),
      title: _firstNonEmptyString([
        _firstCanonicalClaimValue(
          row,
          DocumentMetadataFieldLabels.travelTripTitle,
        ),
        _firstStructuredFieldValue(
          row: row,
          labels: const ['event title', 'title'],
        ),
        row.title,
      ]),
      locationLabel: _firstNonEmptyString([
        _firstCanonicalClaimValue(
          row,
          DocumentMetadataFieldLabels.travelEventLocation,
        ),
        _firstStructuredFieldValue(
          row: row,
          labels: const ['location', 'address', 'location / address'],
        ),
      ]),
      startAt: startAt,
      providerLabel: _firstNonEmptyString([
        _firstCanonicalClaimValue(
          row,
          DocumentMetadataFieldLabels.travelEventProvider,
        ),
        _firstStructuredFieldValue(
          row: row,
          labels: const ['provider', 'airline / provider', 'organizer'],
        ),
      ]),
      confirmationCode: _firstNonEmptyString([
        _firstCanonicalClaimValue(
          row,
          DocumentMetadataFieldLabels.travelEventConfirmation,
        ),
        _firstStructuredFieldValue(
          row: row,
          labels: const [
            'confirmation',
            'reservation number',
            'booking reference',
          ],
        ),
      ]),
      documentsCount: _travelEventDocumentsCountFromRow(row),
      notes: _firstNonEmptyString([
        _firstCanonicalClaimValue(row, DocumentMetadataFieldLabels.travelNotes),
        _firstStructuredFieldValue(row: row, labels: const ['notes']),
      ]),
      previewImagePath: previewPath.trim().isEmpty ? null : previewPath,
      updatedAt: _parseIsoOrNow(row.updatedAtIso),
    );
  }

  TravelExpenseEntity _travelExpenseFromRow(DocumentRecordDto row) {
    final amount = _travelExpenseAmountFromRow(row);
    final dateRaw = _firstCanonicalClaimValue(
      row,
      DocumentMetadataFieldLabels.travelExpenseDate,
    );
    final timeRaw = _firstCanonicalClaimValue(
      row,
      DocumentMetadataFieldLabels.travelExpenseTime,
    );
    final fallbackDate = _parseIsoOrNow(row.updatedAtIso);
    final occurredAt = _travelDateTimeFromRaw(
      dateRaw: dateRaw,
      timeRaw: timeRaw,
      fallback: fallbackDate,
    );
    final receiptPath = _firstNonEmptyString([
      _firstCanonicalClaimValue(
        row,
        DocumentMetadataFieldLabels.referenceAssetPath,
      ),
      _firstCanonicalClaimValue(
        row,
        DocumentMetadataFieldLabels.frontImagePath,
      ),
    ]);

    return TravelExpenseEntity(
      expenseId: row.id,
      tripId: _travelTripIdFromRow(row),
      category: parseTravelExpenseCategory(
        _firstNonEmptyString([
          _firstCanonicalClaimValue(
            row,
            DocumentMetadataFieldLabels.travelExpenseCategory,
          ),
          _firstStructuredFieldValue(
            row: row,
            labels: const ['expense category', 'category'],
          ),
        ]),
      ),
      title: _firstNonEmptyString([
        _firstStructuredFieldValue(
          row: row,
          labels: const ['expense title', 'title'],
        ),
        row.title,
      ]),
      amount: amount,
      currencyCode: _firstNonEmptyString([
        _firstCanonicalClaimValue(
          row,
          DocumentMetadataFieldLabels.travelExpenseCurrency,
        ),
        _firstStructuredFieldValue(row: row, labels: const ['currency']),
        'USD',
      ]).toUpperCase(),
      locationLabel: _firstNonEmptyString([
        _firstCanonicalClaimValue(
          row,
          DocumentMetadataFieldLabels.travelExpenseLocation,
        ),
        _firstStructuredFieldValue(row: row, labels: const ['location']),
      ]),
      occurredAt: occurredAt,
      notes: _firstNonEmptyString([
        _firstCanonicalClaimValue(row, DocumentMetadataFieldLabels.travelNotes),
        _firstStructuredFieldValue(row: row, labels: const ['notes']),
      ]),
      receiptPath: receiptPath.trim().isEmpty ? null : receiptPath,
      updatedAt: _parseIsoOrNow(row.updatedAtIso),
    );
  }

  double _travelExpenseAmountFromRow(DocumentRecordDto row) {
    final claim = _firstCanonicalClaimValue(
      row,
      DocumentMetadataFieldLabels.travelExpenseAmount,
    );
    final direct = _firstStructuredFieldValue(
      row: row,
      labels: const ['amount', 'amount paid', 'expense amount'],
    );
    return _travelAmountOrZero(_firstNonEmptyString([claim, direct]));
  }

  TravelBudgetEntity _travelBudgetFromRow(DocumentRecordDto row) {
    final totalRaw = _firstNonEmptyString([
      _firstCanonicalClaimValue(
        row,
        DocumentMetadataFieldLabels.travelBudgetTotal,
      ),
      _firstStructuredFieldValue(
        row: row,
        labels: const ['total budget', 'budget total'],
      ),
    ]);
    final currencyCode = _firstNonEmptyString([
      _firstCanonicalClaimValue(
        row,
        DocumentMetadataFieldLabels.travelBudgetCurrency,
      ),
      _firstStructuredFieldValue(row: row, labels: const ['currency']),
      'USD',
    ]).toUpperCase();
    return TravelBudgetEntity(
      tripId: _travelTripIdFromRow(row),
      totalBudget: _travelAmountOrZero(totalRaw),
      currencyCode: currencyCode,
      allocations: _travelBudgetAllocationsFromRow(row),
      updatedAt: _parseIsoOrNow(row.updatedAtIso),
    );
  }

  List<TravelBudgetAllocationEntity> _travelBudgetAllocationsFromRow(
    DocumentRecordDto row,
  ) {
    final rawJson = _firstCanonicalClaimValue(
      row,
      DocumentMetadataFieldLabels.travelBudgetAllocationsJson,
    );
    if ((rawJson ?? '').trim().isEmpty) {
      return const <TravelBudgetAllocationEntity>[];
    }
    try {
      final decoded = jsonDecode(rawJson!);
      if (decoded is! List) {
        return const <TravelBudgetAllocationEntity>[];
      }
      return decoded
          .whereType<Map>()
          .map(
            (item) => TravelBudgetAllocationEntity(
              category: parseTravelExpenseCategory(
                (item['category'] ?? '').toString(),
              ),
              amount: _travelAmountOrZero((item['amount'] ?? '').toString()),
            ),
          )
          .toList(growable: false);
    } catch (_) {
      return const <TravelBudgetAllocationEntity>[];
    }
  }

  TravelDocumentEntity _travelDocumentFromRow(DocumentRecordDto row) {
    final filePath = _firstNonEmptyString([
      _firstCanonicalClaimValue(
        row,
        DocumentMetadataFieldLabels.referenceAssetPath,
      ),
      _firstCanonicalClaimValue(
        row,
        DocumentMetadataFieldLabels.frontImagePath,
      ),
    ]);
    final title = _firstNonEmptyString([
      _firstStructuredFieldValue(
        row: row,
        labels: const ['document title', 'title'],
      ),
      row.title,
    ]);
    final documentType = _firstNonEmptyString([
      _firstCanonicalClaimValue(
        row,
        DocumentMetadataFieldLabels.travelDocumentType,
      ),
      _firstStructuredFieldValue(row: row, labels: const ['document type']),
      'Document',
    ]);
    final fileName = _firstNonEmptyString([
      _firstCanonicalClaimValue(
        row,
        DocumentMetadataFieldLabels.referenceAssetName,
      ),
      row.fileName,
      title,
    ]);
    final linkedEventId = _firstCanonicalClaimValue(
      row,
      DocumentMetadataFieldLabels.travelLinkedEventId,
    );
    return TravelDocumentEntity(
      documentId: row.id,
      tripId: _travelTripIdFromRow(row),
      title: title,
      documentTypeLabel: documentType,
      fileName: fileName,
      fileSizeLabel: row.fileSizeLabel.trim().isEmpty
          ? '1.0 MB'
          : row.fileSizeLabel,
      updatedAt: _parseIsoOrNow(row.updatedAtIso),
      filePath: filePath.trim().isEmpty ? null : filePath,
      linkedEventId: (linkedEventId ?? '').trim().isEmpty
          ? null
          : linkedEventId,
    );
  }

  DateTime _travelDateTimeFromRaw({
    required String? dateRaw,
    required String? timeRaw,
    required DateTime fallback,
  }) {
    final date = _parseFlexibleDate(dateRaw) ?? fallback;
    final totalMinutes = _minutesFromTimeLabel(timeRaw);
    if (totalMinutes == null) {
      return DateTime(
        date.year,
        date.month,
        date.day,
        fallback.hour,
        fallback.minute,
      );
    }
    final hour = totalMinutes ~/ 60;
    final minute = totalMinutes % 60;
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  int? _minutesFromTimeLabel(String? raw) {
    final value = (raw ?? '').trim().toLowerCase();
    if (value.isEmpty) {
      return null;
    }
    final match = RegExp(
      r'^(\d{1,2}):(\d{2})(?:\s*([ap]m))?$',
    ).firstMatch(value);
    if (match == null) {
      return null;
    }
    var hour = int.tryParse(match.group(1) ?? '');
    final minute = int.tryParse(match.group(2) ?? '');
    final marker = match.group(3);
    if (hour == null || minute == null || minute > 59 || minute < 0) {
      return null;
    }
    if (marker != null) {
      if (hour < 1 || hour > 12) {
        return null;
      }
      if (marker == 'pm' && hour != 12) {
        hour += 12;
      }
      if (marker == 'am' && hour == 12) {
        hour = 0;
      }
    } else if (hour > 23 || hour < 0) {
      return null;
    }
    return (hour * 60) + minute;
  }

  double _travelAmountOrZero(String rawValue) {
    final normalized = rawValue
        .trim()
        .replaceAll(',', '')
        .replaceAll(RegExp(r'[^0-9.\-]'), '');
    return double.tryParse(normalized) ?? 0;
  }

  String _travelReminderSubtitle(
    TravelTimelineEventEntity event,
    DateTime now,
  ) {
    final delta = event.startAt.difference(now);
    if (delta.inMinutes.abs() < 60) {
      final minutes = delta.inMinutes.abs();
      return delta.isNegative
          ? '$minutes min ago • ${event.locationLabel}'
          : 'in $minutes min • ${event.locationLabel}';
    }
    if (delta.inHours.abs() < 24) {
      final hours = delta.inHours.abs();
      return delta.isNegative
          ? '$hours h ago • ${event.locationLabel}'
          : 'in $hours h • ${event.locationLabel}';
    }
    final days = delta.inDays.abs();
    return delta.isNegative
        ? '$days d ago • ${event.locationLabel}'
        : 'in $days d • ${event.locationLabel}';
  }

  String _workCompanyNameFromRow(DocumentRecordDto row) {
    final claimName = _firstCanonicalClaimValue(
      row,
      DocumentMetadataFieldLabels.workCompanyName,
    );
    final directName = _firstStructuredFieldValue(
      row: row,
      labels: const [
        'company',
        'company name',
        'employer',
        'organization',
        'issuer',
      ],
    );
    return _firstNonEmptyString([claimName, directName, row.title, 'Company']);
  }

  String _workCompanyIdFromRow(DocumentRecordDto row) {
    final claimId = _firstCanonicalClaimValue(
      row,
      DocumentMetadataFieldLabels.workCompanyId,
    );
    if ((claimId ?? '').trim().isNotEmpty) {
      return _slugify(claimId!);
    }
    return _slugify(_workCompanyNameFromRow(row));
  }

  String _workRecordTypeFromRow(DocumentRecordDto row) {
    final claimType = _firstCanonicalClaimValue(
      row,
      DocumentMetadataFieldLabels.workRecordType,
    );
    final directType = _firstStructuredFieldValue(
      row: row,
      labels: const ['work record type', 'record type', 'entry type'],
    );
    final resolvedType = _firstNonEmptyString([
      claimType,
      directType,
    ]).trim().toLowerCase();
    if (resolvedType.isNotEmpty) {
      return resolvedType;
    }
    final rawType = row.documentType.trim().toLowerCase();
    if (rawType == 'work_company_profile' || rawType == 'company_profile') {
      return 'company_profile';
    }
    return 'statement';
  }

  bool _isWorkCompanyProfileRow(DocumentRecordDto row) {
    final type = _workRecordTypeFromRow(row);
    if (type == 'company_profile' || type == 'profile') {
      return true;
    }
    final rawType = row.documentType.trim().toLowerCase();
    return rawType == 'work_company_profile' || rawType == 'company_profile';
  }

  bool _isWorkStatementRow(DocumentRecordDto row) {
    return !_isWorkCompanyProfileRow(row);
  }

  bool _isVisibleInLibraryOverview(DocumentRecordDto row) {
    final category = _categoryFromKey(row.categoryKey);
    if (category == DocumentCategoryType.property ||
        category == DocumentCategoryType.travel) {
      return false;
    }
    if (category == DocumentCategoryType.work) {
      return _isWorkStatementRow(row);
    }
    return true;
  }

  String _propertyNameFromRow(DocumentRecordDto row) {
    final claim = _firstCanonicalClaimValue(
      row,
      DocumentMetadataFieldLabels.propertyName,
    );
    final direct = _firstStructuredFieldValue(
      row: row,
      labels: const ['property name', 'name', 'nickname'],
    );
    return _firstNonEmptyString([claim, direct, row.title, 'Property']);
  }

  String _propertyIdFromRow(DocumentRecordDto row) {
    final claim = _firstCanonicalClaimValue(
      row,
      DocumentMetadataFieldLabels.propertyId,
    );
    final direct = _firstStructuredFieldValue(
      row: row,
      labels: const ['property id', 'id'],
    );
    final value = _firstNonEmptyString([claim, direct]);
    if (value.trim().isNotEmpty) {
      return _slugify(value);
    }
    return _slugify(_propertyNameFromRow(row));
  }

  String _propertyRecordTypeFromRow(DocumentRecordDto row) {
    final claim = _firstCanonicalClaimValue(
      row,
      DocumentMetadataFieldLabels.propertyRecordType,
    );
    final direct = _firstStructuredFieldValue(
      row: row,
      labels: const ['property record type', 'record type', 'entry type'],
    );
    final resolved = _firstNonEmptyString([claim, direct]).trim().toLowerCase();
    if (resolved.isNotEmpty) {
      return resolved;
    }
    final rawType = row.documentType.trim().toLowerCase();
    if (rawType == 'property_profile') {
      return 'property_profile';
    }
    final normalizedTags = row.tags
        .map((tag) => tag.trim().toLowerCase())
        .where((tag) => tag.isNotEmpty)
        .toSet();
    if (normalizedTags.contains('property_profile') ||
        normalizedTags.contains('profile')) {
      return 'property_profile';
    }
    return 'document';
  }

  bool _isPropertyProfileRow(DocumentRecordDto row) {
    final type = _propertyRecordTypeFromRow(row);
    if (type == 'property_profile' || type == 'profile') {
      return true;
    }
    return row.documentType.trim().toLowerCase() == 'property_profile';
  }

  bool _isPropertyDocumentRow(DocumentRecordDto row) {
    return !_isPropertyProfileRow(row);
  }

  DocumentRecordDto? _latestPropertyProfileRow(List<DocumentRecordDto> rows) {
    final profiles = rows.where(_isPropertyProfileRow).toList(growable: false);
    if (profiles.isEmpty) {
      return null;
    }
    final sorted = [...profiles]
      ..sort(
        (a, b) => _parseIsoOrNow(
          b.updatedAtIso,
        ).compareTo(_parseIsoOrNow(a.updatedAtIso)),
      );
    return sorted.first;
  }

  String _propertyTypeFromRow(DocumentRecordDto row) {
    final claim = _firstCanonicalClaimValue(
      row,
      DocumentMetadataFieldLabels.propertyType,
    );
    final direct = _firstStructuredFieldValue(
      row: row,
      labels: const ['property type', 'type'],
    );
    final value = _firstNonEmptyString([claim, direct]);
    if (value.trim().isEmpty) {
      return '';
    }
    return _toSentenceCase(
      value
          .trim()
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
          .replaceAll(RegExp(r'^_+|_+$'), ''),
    );
  }

  String _propertyOwnershipStatusFromRow(DocumentRecordDto row) {
    final claim = _firstCanonicalClaimValue(
      row,
      DocumentMetadataFieldLabels.propertyOwnershipStatus,
    );
    final direct = _firstStructuredFieldValue(
      row: row,
      labels: const ['ownership status', 'ownership', 'status'],
    );
    final normalized = _firstNonEmptyString([
      claim,
      direct,
    ]).trim().toLowerCase();
    if (normalized.contains('rent') || normalized.contains('lease')) {
      return 'Rental';
    }
    if (normalized.contains('own')) {
      return 'Owned';
    }
    return '';
  }

  String _propertyAddressFromRow(DocumentRecordDto row) {
    final claim = _firstCanonicalClaimValue(
      row,
      DocumentMetadataFieldLabels.propertyFullAddress,
    );
    final direct = _firstStructuredFieldValue(
      row: row,
      labels: const ['full address', 'address', 'location'],
    );
    return _firstNonEmptyString([claim, direct]);
  }

  String _propertyAddressSuggestionJsonFromRow(DocumentRecordDto row) {
    final claim = _firstCanonicalClaimValue(
      row,
      DocumentMetadataFieldLabels.propertyAddressSuggestionJson,
    );
    final direct = _firstStructuredFieldValue(
      row: row,
      labels: const [
        'property address suggestion json',
        'address suggestion json',
      ],
    );
    return _firstNonEmptyString([claim, direct]);
  }

  PropertyAssetType _propertyAssetTypeFromRow(DocumentRecordDto row) {
    final claim = _firstCanonicalClaimValue(
      row,
      DocumentMetadataFieldLabels.propertyAssetType,
    );
    final direct = _firstStructuredFieldValue(
      row: row,
      labels: const ['property asset type', 'asset type', 'document group'],
    );
    final normalizedClaim = _firstNonEmptyString([
      claim,
      direct,
    ]).trim().toLowerCase();
    if (normalizedClaim.contains('contract') ||
        normalizedClaim.contains('lease') ||
        normalizedClaim.contains('deed') ||
        normalizedClaim.contains('agreement')) {
      return PropertyAssetType.contracts;
    }
    if (normalizedClaim.contains('insurance') ||
        normalizedClaim.contains('policy') ||
        normalizedClaim.contains('coverage')) {
      return PropertyAssetType.insurance;
    }
    if (normalizedClaim.contains('payment') ||
        normalizedClaim.contains('rent') ||
        normalizedClaim.contains('invoice') ||
        normalizedClaim.contains('receipt')) {
      return PropertyAssetType.payments;
    }
    if (normalizedClaim.contains('maintenance') ||
        normalizedClaim.contains('repair') ||
        normalizedClaim.contains('service') ||
        normalizedClaim.contains('request')) {
      return PropertyAssetType.maintenance;
    }
    if (normalizedClaim.contains('other') ||
        normalizedClaim.contains('misc') ||
        normalizedClaim.contains('general')) {
      return PropertyAssetType.others;
    }
    if (normalizedClaim.contains('document') || normalizedClaim.isNotEmpty) {
      return PropertyAssetType.documents;
    }

    final source = <String>[
      row.documentType,
      row.title,
      row.fileName,
      row.identifierLabel,
      row.identifierValue,
      ...row.tags,
    ].join(' ').toLowerCase();
    if (source.contains('contract') ||
        source.contains('lease') ||
        source.contains('deed') ||
        source.contains('agreement')) {
      return PropertyAssetType.contracts;
    }
    if (source.contains('insurance') ||
        source.contains('policy') ||
        source.contains('coverage')) {
      return PropertyAssetType.insurance;
    }
    if (source.contains('payment') ||
        source.contains('rent') ||
        source.contains('invoice') ||
        source.contains('receipt')) {
      return PropertyAssetType.payments;
    }
    if (source.contains('maintenance') ||
        source.contains('repair') ||
        source.contains('service') ||
        source.contains('request')) {
      return PropertyAssetType.maintenance;
    }
    if (source.contains('other') || source.contains('misc')) {
      return PropertyAssetType.others;
    }
    return PropertyAssetType.documents;
  }

  String _propertyOccupancyStatusFromRow(DocumentRecordDto row) {
    final claim = _firstCanonicalClaimValue(
      row,
      DocumentMetadataFieldLabels.propertyOccupancyStatus,
    );
    final direct = _firstStructuredFieldValue(
      row: row,
      labels: const ['occupancy status', 'resident status', 'tenant status'],
    );
    final raw = _firstNonEmptyString([claim, direct]).trim();
    if (raw.isNotEmpty) {
      return _toSentenceCase(raw.toLowerCase().replaceAll(' ', '_'));
    }
    final ownership = _propertyOwnershipStatusFromRow(row).trim().toLowerCase();
    if (ownership.contains('rent')) {
      return 'Rented';
    }
    if (ownership.contains('own')) {
      return 'Resident Occupied';
    }
    return 'Status Unknown';
  }

  String _propertyMonthlyAmountFromRow(DocumentRecordDto row) {
    final claim = _firstCanonicalClaimValue(
      row,
      DocumentMetadataFieldLabels.propertyMonthlyAmount,
    );
    final direct = _firstStructuredFieldValue(
      row: row,
      labels: const ['monthly amount', 'monthly rent', 'rent amount'],
    );
    final raw = _firstNonEmptyString([claim, direct]).trim();
    if (raw.isEmpty) {
      return '';
    }
    if (raw.contains(RegExp(r'[$€£]|/'))) {
      return raw;
    }
    return '\$$raw/mo';
  }

  DateTime? _propertyIssueDateFromRow(DocumentRecordDto row) {
    final claim = _firstCanonicalClaimValue(
      row,
      DocumentMetadataFieldLabels.propertyIssueDate,
    );
    final direct = _firstStructuredFieldValue(
      row: row,
      labels: const ['issue date', 'issued on', 'issued at', 'date'],
    );
    return _parseFlexibleDate(claim) ?? _parseFlexibleDate(direct);
  }

  String _propertyPaymentAmountFromRow(DocumentRecordDto row) {
    final claim = _firstCanonicalClaimValue(
      row,
      DocumentMetadataFieldLabels.propertyPaymentAmount,
    );
    final direct = _firstStructuredFieldValue(
      row: row,
      labels: const [
        'amount paid',
        'payment amount',
        'rent payment amount',
        'rent amount',
        'paid amount',
      ],
    );
    return _firstNonEmptyString([claim, direct]).trim();
  }

  DateTime? _propertyPaymentDateFromRow(DocumentRecordDto row) {
    final claim = _firstCanonicalClaimValue(
      row,
      DocumentMetadataFieldLabels.propertyPaymentDate,
    );
    final direct = _firstStructuredFieldValue(
      row: row,
      labels: const [
        'payment date',
        'rent payment date',
        'paid on',
        'payment on',
      ],
    );
    return _parseFlexibleDate(claim) ?? _parseFlexibleDate(direct);
  }

  String _propertyRecordTitle(DocumentRecordDto row) {
    final direct = _firstStructuredFieldValue(
      row: row,
      labels: const ['document title', 'title', 'record title'],
    );
    final identifierValue = row.identifierValue.trim();
    if ((direct ?? '').trim().isNotEmpty) {
      return direct!.trim();
    }
    if (identifierValue.isNotEmpty && identifierValue != '-') {
      return identifierValue;
    }
    final title = row.title.trim();
    if (title.isNotEmpty) {
      return title;
    }
    final fileName = row.fileName.trim();
    if (fileName.isNotEmpty) {
      final dot = fileName.lastIndexOf('.');
      return dot > 0 ? fileName.substring(0, dot) : fileName;
    }
    return 'Property Document';
  }

  String _propertyRecordFileName(DocumentRecordDto row) {
    final fromReference = _firstStructuredFieldValue(
      row: row,
      labels: const ['reference asset name', 'file name', 'filename'],
    );
    if ((fromReference ?? '').trim().isNotEmpty) {
      return fromReference!.trim();
    }
    final fromPath = _firstStructuredFieldValue(
      row: row,
      labels: const ['reference asset path', 'file path'],
    );
    if ((fromPath ?? '').trim().isNotEmpty) {
      final resolved = _fileNameFromPathValue(fromPath!);
      if (resolved.isNotEmpty) {
        return resolved;
      }
    }
    final fallback = row.fileName.trim();
    return fallback.isNotEmpty ? fallback : row.title.trim();
  }

  DocumentRecordDto? _latestCompanyProfileRow(List<DocumentRecordDto> rows) {
    final profiles = rows
        .where(_isWorkCompanyProfileRow)
        .toList(growable: false);
    if (profiles.isEmpty) {
      return null;
    }
    final sorted = [...profiles]
      ..sort(
        (a, b) => _parseIsoOrNow(
          b.updatedAtIso,
        ).compareTo(_parseIsoOrNow(a.updatedAtIso)),
      );
    return sorted.first;
  }

  WorkDocumentFolderType _workFolderFromRow(DocumentRecordDto row) {
    final claimFolder = _firstCanonicalClaimValue(
      row,
      DocumentMetadataFieldLabels.workFolderType,
    );
    if ((claimFolder ?? '').trim().isNotEmpty) {
      return parseWorkDocumentFolderType(claimFolder!);
    }
    final directFolder = _firstStructuredFieldValue(
      row: row,
      labels: const ['folder', 'folder type', 'document folder', 'category'],
    );
    if ((directFolder ?? '').trim().isNotEmpty) {
      return parseWorkDocumentFolderType(directFolder!);
    }
    final fieldText = row.structuredFields
        .map((field) => '${field['label'] ?? ''} ${field['value'] ?? ''}')
        .join(' ');
    final text =
        '${row.title} ${row.fileName} ${row.identifierLabel} ${row.identifierValue} ${row.tags.join(' ')} $fieldText'
            .toLowerCase();
    if (text.contains('pay') ||
        text.contains('salary') ||
        text.contains('payroll') ||
        text.contains('payslip') ||
        text.contains('bulletin de paie') ||
        text.contains('fiche de paie')) {
      return WorkDocumentFolderType.payslips;
    }
    if (text.contains('tax') || text.contains('w2') || text.contains('w-2')) {
      return WorkDocumentFolderType.taxForms;
    }
    if (text.contains('benefit') || text.contains('insurance')) {
      return WorkDocumentFolderType.benefits;
    }
    if (text.contains('contract') || text.contains('agreement')) {
      return WorkDocumentFolderType.contracts;
    }
    if (text.contains('offboard') ||
        text.contains('resignation') ||
        text.contains('termination') ||
        text.contains('exit interview') ||
        text.contains('handover')) {
      return WorkDocumentFolderType.offboarding;
    }
    if (text.contains('milestone') || text.contains('promotion')) {
      return WorkDocumentFolderType.milestones;
    }
    if (text.contains('attestation') ||
        text.contains('employment certificate') ||
        text.contains('certificate of employment') ||
        text.contains('work certificate') ||
        text.contains('reference letter') ||
        text.contains('employer letter')) {
      return WorkDocumentFolderType.other;
    }
    return WorkDocumentFolderType.other;
  }

  String _workStatementTitle(DocumentRecordDto row) {
    final claimTitle = _firstCanonicalClaimValue(
      row,
      DocumentMetadataFieldLabels.workStatementTitle,
    );
    final directTitle = _firstStructuredFieldValue(
      row: row,
      labels: const ['title', 'statement title', 'document title'],
    );
    final identifierValue = row.identifierValue.trim();
    final identifierLabel = row.identifierLabel.trim().toLowerCase();
    if ((claimTitle ?? '').trim().isNotEmpty) {
      return claimTitle!.trim();
    }
    if ((directTitle ?? '').trim().isNotEmpty) {
      return directTitle!.trim();
    }
    if (identifierValue.isNotEmpty &&
        identifierValue != '-' &&
        (identifierLabel.contains('title') ||
            identifierLabel.contains('record') ||
            identifierLabel.contains('statement'))) {
      return identifierValue;
    }
    final fileName = row.fileName.trim();
    if (fileName.isNotEmpty) {
      final dot = fileName.lastIndexOf('.');
      return dot > 0 ? fileName.substring(0, dot) : fileName;
    }
    return row.title.trim().isEmpty ? 'Statement' : row.title.trim();
  }

  DateTime? _workStatementDate(DocumentRecordDto row) {
    final claimDate = _firstCanonicalClaimValue(
      row,
      DocumentMetadataFieldLabels.workStatementDate,
    );
    final directDate = _firstStructuredFieldValue(
      row: row,
      labels: const [
        'statement date',
        'document date',
        'period',
        'period start',
        'month',
        'date',
      ],
    );
    return _parseFlexibleDate(claimDate) ?? _parseFlexibleDate(directDate);
  }

  String _workStatementNetAmount(DocumentRecordDto row) {
    final claimAmount = _firstCanonicalClaimValue(
      row,
      DocumentMetadataFieldLabels.workStatementNetAmount,
    );
    final directAmount = _firstStructuredFieldValue(
      row: row,
      labels: const ['net amount', 'net pay', 'amount', 'net take-home'],
    );
    final rawAmount = _firstNonEmptyString([claimAmount, directAmount]).trim();
    if (rawAmount.isEmpty || rawAmount == '-') {
      return '';
    }
    if (RegExp(
      r'[\$€£¥]|[A-Z]{3}\s*\d',
      caseSensitive: false,
    ).hasMatch(rawAmount)) {
      return rawAmount;
    }
    final currencyCode = _firstNonEmptyString([
      _firstCanonicalClaimValue(
        row,
        DocumentMetadataFieldLabels.workStatementCurrency,
      ),
      _firstStructuredFieldValue(row: row, labels: const ['currency']),
    ]);
    if (currencyCode.trim().isEmpty) {
      return rawAmount;
    }
    return '${currencyCode.trim()} $rawAmount';
  }

  String _workStatementStatus(DocumentRecordDto row) {
    if (row.isArchived) {
      return 'Archived';
    }
    final claimStatus = _firstCanonicalClaimValue(
      row,
      DocumentMetadataFieldLabels.workStatementStatus,
    );
    if ((claimStatus ?? '').trim().isNotEmpty) {
      return _toSentenceCase(claimStatus!);
    }
    if (_requiresAttention(row)) {
      return 'Expiring';
    }
    return 'Active';
  }

  String _workStatementLabel(DocumentRecordDto row) {
    final savedLabel =
        (_firstCanonicalClaimValue(
                  row,
                  DocumentMetadataFieldLabels.workStatementLabel,
                ) ??
                '')
            .trim();
    final title = _workStatementTitle(row).trim().toLowerCase();
    if (savedLabel.isNotEmpty && savedLabel.toLowerCase() != title) {
      return savedLabel;
    }
    final documentType =
        _firstStructuredFieldValue(
          row: row,
          labels: const ['document type', 'type'],
        ) ??
        '';
    if (documentType.trim().isNotEmpty) {
      return documentType.trim();
    }
    return _workFolderFromRow(row).label;
  }

  String _workRecentSubtitle(DocumentRecordDto row) {
    final folder = _workFolderFromRow(row);
    return '${folder.label} • ${_formatDate(_parseIsoOrNow(row.updatedAtIso))}';
  }

  int _referenceFilesCount(DocumentRecordDto row) {
    final paths = <String>{};

    void addPath(String? raw) {
      final value = (raw ?? '').trim();
      if (value.isEmpty) {
        return;
      }
      paths.add(value.toLowerCase());
    }

    final assetsJson = _firstStructuredFieldValue(
      row: row,
      labels: const [DocumentMetadataFieldLabels.referenceAssetsJson],
    );
    if ((assetsJson ?? '').trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(assetsJson!);
        if (decoded is List) {
          for (final item in decoded) {
            if (item is Map) {
              addPath(item['path']?.toString());
            }
          }
        }
      } catch (_) {
        // Ignore malformed legacy payloads and fall back to path fields below.
      }
    }

    addPath(
      _firstStructuredFieldValue(
        row: row,
        labels: const [DocumentMetadataFieldLabels.referenceAssetPath],
      ),
    );
    addPath(
      _firstStructuredFieldValue(
        row: row,
        labels: const [DocumentMetadataFieldLabels.frontImagePath],
      ),
    );
    addPath(
      _firstStructuredFieldValue(
        row: row,
        labels: const [DocumentMetadataFieldLabels.backImagePath],
      ),
    );

    if (paths.isNotEmpty) {
      return paths.length;
    }
    return row.scanPagesCount > 1 ? row.scanPagesCount : 1;
  }

  String _firstNonEmptyString(Iterable<String?> values) {
    for (final value in values) {
      final trimmed = (value ?? '').trim();
      if (trimmed.isNotEmpty) {
        return trimmed;
      }
    }
    return '';
  }

  String _slugify(String value) {
    final normalized = value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    if (normalized.isEmpty) {
      return 'work_company';
    }
    return normalized;
  }

  DateTime? _parseFlexibleDate(String? raw) {
    final value = (raw ?? '').trim();
    if (value.isEmpty) {
      return null;
    }
    final parsedIso = DateTime.tryParse(value)?.toLocal();
    if (parsedIso != null) {
      return parsedIso;
    }
    final slashMatch = RegExp(
      r'^(\d{1,2})[\/\-](\d{1,2})[\/\-](\d{2,4})$',
    ).firstMatch(value);
    if (slashMatch == null) {
      return null;
    }
    final first = int.tryParse(slashMatch.group(1)!);
    final second = int.tryParse(slashMatch.group(2)!);
    var year = int.tryParse(slashMatch.group(3)!);
    if (first == null || second == null || year == null) {
      return null;
    }
    if (year < 100) {
      year = year < 50 ? 2000 + year : 1900 + year;
    }
    final day = first;
    final month = second;
    if (day < 1 || day > 31 || month < 1 || month > 12) {
      return null;
    }
    return DateTime(year, month, day);
  }

  int _approxBytesFromSizeLabel(String raw) {
    final match = RegExp(
      r'([0-9]+(?:\.[0-9]+)?)\s*(b|kb|mb|gb|tb)',
      caseSensitive: false,
    ).firstMatch(raw.trim());
    if (match == null) {
      return 0;
    }
    final value = double.tryParse(match.group(1) ?? '');
    if (value == null) {
      return 0;
    }
    final unit = (match.group(2) ?? '').toLowerCase();
    final multiplier = switch (unit) {
      'tb' => 1024 * 1024 * 1024 * 1024,
      'gb' => 1024 * 1024 * 1024,
      'mb' => 1024 * 1024,
      'kb' => 1024,
      _ => 1,
    };
    return (value * multiplier).round();
  }

  DocumentCategoryType _categoryFromKey(String raw) {
    final normalized = raw.trim().toLowerCase();
    return switch (normalized) {
      'identity' => DocumentCategoryType.identity,
      'work' => DocumentCategoryType.work,
      'property' => DocumentCategoryType.property,
      'vehicle' => DocumentCategoryType.vehicle,
      'health' => DocumentCategoryType.health,
      'travel' => DocumentCategoryType.travel,
      _ => DocumentCategoryType.other,
    };
  }

  IdentityDocumentGroup _groupFromKey(String raw) {
    final normalized = raw.trim().toLowerCase();
    return normalized == IdentityDocumentGroup.travel.key
        ? IdentityDocumentGroup.travel
        : IdentityDocumentGroup.personal;
  }

  DocumentType _documentTypeFromRaw(String raw) {
    final normalized = IdentityDocumentTypeLabels.normalizeRawTypeKey(raw);
    return switch (normalized) {
      IdentityDocumentTypeLabels.passport => DocumentType.passport,
      IdentityDocumentTypeLabels.driversLicense => DocumentType.driversLicense,
      IdentityDocumentTypeLabels.idCard ||
      IdentityDocumentTypeLabels.nationalId ||
      IdentityDocumentTypeLabels.residencePermit => DocumentType.idCard,
      _ => DocumentType.other,
    };
  }

  String _identityLabelFromRawType(String raw) {
    return IdentityDocumentTypeLabels.labelFromRawType(raw);
  }

  bool _isSelectableVaultDocumentRow(DocumentRecordDto row) {
    final category = _categoryFromKey(row.categoryKey);
    if (category != DocumentCategoryType.travel) {
      return true;
    }
    return !_isTravelTripProfileRow(row) &&
        !_isTravelTimelineEventRow(row) &&
        !_isTravelExpenseRow(row) &&
        !_isTravelBudgetRow(row);
  }

  VaultDocumentEntity _vaultDocumentFromRow(DocumentRecordDto row) {
    return VaultDocumentEntity(
      documentId: row.id,
      documentName: _vaultDocumentNameFromRow(row),
      documentTypeLabel: _vaultDocumentTypeLabelFromRow(row),
      category: _categoryFromKey(row.categoryKey),
      updatedAt: _parseIsoOrNow(row.updatedAtIso),
      expiryDate: _vaultExpiryDateFromRow(row),
    );
  }

  String _vaultDocumentNameFromRow(DocumentRecordDto row) {
    return _firstNonEmptyString([
      _firstCanonicalClaimValue(
        row,
        DocumentMetadataFieldLabels.referenceAssetName,
      ),
      _firstStructuredFieldValue(
        row: row,
        labels: const ['document title', 'title', 'name'],
      ),
      row.fileName,
      row.title,
      'Document',
    ]);
  }

  String _vaultDocumentTypeLabelFromRow(DocumentRecordDto row) {
    final directType = _firstNonEmptyString([
      _firstCanonicalClaimValue(
        row,
        DocumentMetadataFieldLabels.travelDocumentType,
      ),
      _firstStructuredFieldValue(
        row: row,
        labels: const ['document type', 'type'],
      ),
      row.documentType,
    ]);
    final normalizedType = IdentityDocumentTypeLabels.normalizeRawTypeKey(
      directType,
    );
    if (normalizedType == IdentityDocumentTypeLabels.passport ||
        normalizedType == IdentityDocumentTypeLabels.driversLicense ||
        normalizedType == IdentityDocumentTypeLabels.idCard ||
        normalizedType == IdentityDocumentTypeLabels.nationalId ||
        normalizedType == IdentityDocumentTypeLabels.residencePermit) {
      return IdentityDocumentTypeLabels.labelFromRawType(normalizedType);
    }

    final lowerType = normalizedType.toLowerCase();
    if (lowerType.contains('visa')) {
      return 'Visa';
    }
    if (lowerType.contains('travel_insurance') ||
        (lowerType.contains('insurance') && lowerType.contains('travel'))) {
      return 'Travel Insurance';
    }

    if (directType.trim().isNotEmpty) {
      return _toSentenceCase(
        directType.trim().toLowerCase().replaceAll(' ', '_'),
      );
    }
    return 'Document';
  }

  DateTime? _vaultExpiryDateFromRow(DocumentRecordDto row) {
    final rowExpiry = _parseIsoNullable(row.expiryAtIso);
    if (rowExpiry != null) {
      return rowExpiry;
    }
    final expiryRaw = _firstNonEmptyString([
      _firstCanonicalClaimValue(row, DocumentMetadataFieldLabels.expiryDate),
      _firstCanonicalClaimValue(
        row,
        DocumentMetadataFieldLabels.claimExpiryDate,
      ),
      _firstStructuredFieldValue(
        row: row,
        labels: const ['expiry date', 'expiration date', 'date of expiry'],
      ),
    ]);
    if (expiryRaw.trim().isEmpty) {
      return null;
    }
    final flexible = _parseFlexibleDate(expiryRaw);
    if (flexible != null) {
      return flexible;
    }
    return _parseIsoNullable(expiryRaw);
  }

  int _vaultDocumentPriority(VaultDocumentEntity item) {
    final text = '${item.documentTypeLabel} ${item.documentName}'
        .trim()
        .toLowerCase();
    if (text.contains('passport')) {
      return 0;
    }
    if (text.contains('national id') ||
        text.contains('id card') ||
        text.contains('residence permit')) {
      return 1;
    }
    if (text.contains('driver')) {
      return 2;
    }
    if (text.contains('visa')) {
      return 3;
    }
    if (text.contains('travel insurance') ||
        (text.contains('insurance') && text.contains('travel'))) {
      return 4;
    }
    if (item.category == DocumentCategoryType.identity) {
      return 5;
    }
    return 10;
  }

  String _countryNameForRecord(DocumentRecordDto row) {
    final rawType = row.documentType.trim().toLowerCase();
    final countryValue = switch (rawType) {
      'passport' =>
        _firstStructuredFieldValue(row: row, labels: const ['nationality']) ??
            _firstStructuredFieldValue(
              row: row,
              labels: const ['issuing country', 'country'],
            ),
      'residence_permit' => _firstStructuredFieldValue(
        row: row,
        labels: const ['issuing country', 'country'],
      ),
      _ => _firstStructuredFieldValue(
        row: row,
        labels: const ['issuing country', 'country', 'nationality'],
      ),
    };

    if ((countryValue ?? '').trim().isNotEmpty) {
      return _normalizeCountryName(countryValue!.trim());
    }
    return _normalizeCountryName(row.title);
  }

  IdentityDocumentHolderRelation _holderRelationFromRecord(
    DocumentRecordDto row,
  ) {
    final claimRelation = _firstCanonicalClaimValue(
      row,
      DocumentMetadataFieldLabels.holderRelation,
    );
    if ((claimRelation ?? '').trim().isNotEmpty) {
      return parseIdentityDocumentHolderRelation(claimRelation);
    }
    final directRelation = _firstStructuredFieldValue(
      row: row,
      labels: const [
        'holder relation',
        'document holder relation',
        'relation',
        'relationship',
      ],
    );
    if ((directRelation ?? '').trim().isNotEmpty) {
      return parseIdentityDocumentHolderRelation(directRelation);
    }
    return IdentityDocumentHolderRelation.owner;
  }

  String? _firstCanonicalClaimValue(DocumentRecordDto row, String claimKey) {
    for (final field in row.structuredFields) {
      final rawLabel = (field['label'] ?? '').trim();
      if (rawLabel.isEmpty) {
        continue;
      }
      final canonical = DocumentMetadataFieldLabels.toCanonicalClaimKey(
        rawLabel,
      );
      if (canonical != claimKey) {
        continue;
      }
      final value = (field['value'] ?? '').trim();
      if (value.isNotEmpty) {
        return value;
      }
    }
    return null;
  }

  String? _firstStructuredFieldValue({
    required DocumentRecordDto row,
    required List<String> labels,
  }) {
    for (final expectedLabel in labels) {
      final expected = expectedLabel.trim().toLowerCase();
      for (final field in row.structuredFields) {
        final label = (field['label'] ?? '').trim().toLowerCase();
        if (label != expected) {
          continue;
        }
        final value = (field['value'] ?? '').trim();
        if (value.isNotEmpty) {
          return value;
        }
      }
    }
    return null;
  }

  DocumentCountry _countryFromRecord(DocumentRecordDto row) {
    final normalized = _countryNameForRecord(row).toLowerCase();
    if (normalized == 'united states') {
      return DocumentCountry.unitedStates;
    }
    if (normalized == 'united kingdom') {
      return DocumentCountry.unitedKingdom;
    }
    if (normalized == 'france') {
      return DocumentCountry.france;
    }
    if (normalized == 'germany') {
      return DocumentCountry.germany;
    }
    if (normalized == 'italy') {
      return DocumentCountry.italy;
    }
    if (normalized == 'spain') {
      return DocumentCountry.spain;
    }
    if (normalized == 'canada') {
      return DocumentCountry.canada;
    }
    if (normalized == 'switzerland') {
      return DocumentCountry.switzerland;
    }
    if (normalized == 'turkey') {
      return DocumentCountry.turkey;
    }
    if (normalized == 'tunisia') {
      return DocumentCountry.tunisia;
    }
    if (normalized == 'united arab emirates') {
      return DocumentCountry.unitedArabEmirates;
    }
    if (normalized == 'european union') {
      return DocumentCountry.europeanUnion;
    }
    return DocumentCountry.unknown;
  }

  String _normalizeCountryName(String raw) {
    final value = raw.trim();
    if (value.isEmpty) {
      return '';
    }

    final normalized = value.toLowerCase();
    if (normalized.contains('united states') ||
        normalized == 'usa' ||
        normalized == 'us') {
      return 'United States';
    }
    if (normalized.contains('united kingdom') ||
        normalized == 'uk' ||
        normalized == 'gb' ||
        normalized.contains('great britain')) {
      return 'United Kingdom';
    }
    if (normalized.contains('california')) {
      return 'United States';
    }
    if (normalized.contains('france')) {
      return 'France';
    }
    if (normalized.contains('germany')) {
      return 'Germany';
    }
    if (normalized.contains('italy')) {
      return 'Italy';
    }
    if (normalized.contains('spain')) {
      return 'Spain';
    }
    if (normalized.contains('canada')) {
      return 'Canada';
    }
    if (normalized.contains('switzerland')) {
      return 'Switzerland';
    }
    if (normalized.contains('turkey')) {
      return 'Turkey';
    }
    if (normalized.contains('tunisia')) {
      return 'Tunisia';
    }
    if (normalized.contains('united arab emirates') || normalized == 'uae') {
      return 'United Arab Emirates';
    }
    if (normalized.contains('european union') || normalized == 'eu') {
      return 'European Union';
    }

    return value;
  }

  String _detailScreenTitle({
    required DocumentType type,
    required String rawTypeKey,
  }) {
    final normalizedRawType = IdentityDocumentTypeLabels.normalizeRawTypeKey(
      rawTypeKey,
    );
    if (normalizedRawType == 'property_profile') {
      return 'Property Details';
    }
    if (normalizedRawType == IdentityDocumentTypeLabels.residencePermit) {
      return 'Residence Permit Details';
    }
    return switch (type) {
      DocumentType.passport => 'Passport Details',
      DocumentType.idCard => 'ID Card Details',
      DocumentType.driversLicense => "Driver's License",
      DocumentType.other => 'Other Documents',
    };
  }

  String _resolveRawTypeKey({
    required DocumentType type,
    required String fallbackRawTypeKey,
    required String? overrideRawTypeKey,
  }) {
    final normalizedOverride = (overrideRawTypeKey ?? '').trim().toLowerCase();
    if (normalizedOverride.isEmpty) {
      return fallbackRawTypeKey;
    }

    return switch (type) {
      DocumentType.idCard =>
        normalizedOverride == 'residence_permit' ||
                normalizedOverride == 'id_card' ||
                normalizedOverride == 'national_id'
            ? normalizedOverride
            : fallbackRawTypeKey,
      DocumentType.passport =>
        normalizedOverride == 'passport'
            ? normalizedOverride
            : fallbackRawTypeKey,
      DocumentType.driversLicense =>
        normalizedOverride == 'drivers_license'
            ? normalizedOverride
            : fallbackRawTypeKey,
      DocumentType.other => normalizedOverride,
    };
  }

  List<String> _defaultTagsForType(DocumentType type) {
    return switch (type) {
      DocumentType.passport => const ['Travel', 'ID', 'Personal'],
      DocumentType.idCard => const ['Travel', 'ID', 'Personal'],
      DocumentType.driversLicense => const ['Driving', 'ID', 'Essential'],
      DocumentType.other => const ['Document'],
    };
  }

  DocumentCaptureSource _captureSourceFromKey(String raw) {
    final normalized = raw.trim().toLowerCase();
    return normalized == DocumentCaptureSource.gallery.key
        ? DocumentCaptureSource.gallery
        : DocumentCaptureSource.camera;
  }

  String _sizeLabel(int pages) {
    final value = 1.2 + (max(1, pages) * 0.6);
    return '${value.toStringAsFixed(1)} MB';
  }

  List<Map<String, String>> _sanitizeStructuredFields(
    List<Map<String, String>> raw,
  ) {
    final result = <Map<String, String>>[];
    for (final field in raw) {
      final label = (field['label'] ?? '').trim();
      final value = (field['value'] ?? '').trim();
      if (label.isEmpty || value.isEmpty) {
        continue;
      }
      result.add({'label': label, 'value': value});
    }
    return result;
  }

  String _formatDate(DateTime date) {
    const monthNames = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];

    final month = monthNames[date.month - 1];
    final day = date.day.toString().padLeft(2, '0');
    return '$day $month ${date.year}';
  }

  List<Map<String, String>> _structuredFieldsWithForcedExpiry(
    List<Map<String, String>> source,
    DateTime forcedExpiry,
  ) {
    final forcedExpiryLabel = _formatDate(forcedExpiry);
    var foundExpiryField = false;
    final fields = <Map<String, String>>[];

    for (final field in source) {
      final label = (field['label'] ?? '').trim();
      final value = (field['value'] ?? '').trim();
      if (label.isEmpty) {
        continue;
      }

      final canonical = DocumentMetadataFieldLabels.toCanonicalClaimKey(label);
      if (canonical == DocumentMetadataFieldLabels.expiryDate ||
          _isExpiryDisplayLabel(label)) {
        foundExpiryField = true;
        fields.add({'label': label, 'value': forcedExpiryLabel});
        continue;
      }

      if (value.isNotEmpty) {
        fields.add({'label': label, 'value': value});
      }
    }

    if (!foundExpiryField) {
      fields.add({'label': 'Expiry Date', 'value': forcedExpiryLabel});
    }

    return fields;
  }

  bool _isExpiryDisplayLabel(String label) {
    final compact = label.trim().toLowerCase().replaceAll(
      RegExp(r'[\s_\-.]'),
      '',
    );
    return compact == 'expirydate' ||
        compact == 'expirationdate' ||
        compact == 'dateofexpiry' ||
        compact == 'expires';
  }

  String _toSentenceCase(String raw) {
    if (raw.trim().isEmpty) {
      return 'Identity Document';
    }

    final words = raw
        .split('_')
        .where((part) => part.trim().isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .toList(growable: false);
    if (words.isEmpty) {
      return 'Identity Document';
    }
    return words.join(' ');
  }

  DocumentRecordDto _copyRecord(
    DocumentRecordDto source, {
    String? title,
    String? fileName,
    String? categoryKey,
    String? updatedAtIso,
    String? documentType,
    String? identityGroupKey,
    String? identifierLabel,
    String? identifierValue,
    String? expiryAtIso,
    List<Map<String, String>>? structuredFields,
    List<String>? tags,
    String? uploadDateIso,
    String? fileSizeLabel,
    bool? isVerifiedScan,
    bool? isFavorite,
    bool? isPrimary,
    bool? isArchived,
    String? archivedAtIso,
    String? captureSource,
    int? scanPagesCount,
    bool? requiresAttention,
  }) {
    return DocumentRecordDto(
      id: source.id,
      title: title ?? source.title,
      fileName: fileName ?? source.fileName,
      categoryKey: categoryKey ?? source.categoryKey,
      updatedAtIso: updatedAtIso ?? source.updatedAtIso,
      documentType: documentType ?? source.documentType,
      identityGroupKey: identityGroupKey ?? source.identityGroupKey,
      identifierLabel: identifierLabel ?? source.identifierLabel,
      identifierValue: identifierValue ?? source.identifierValue,
      expiryAtIso: expiryAtIso ?? source.expiryAtIso,
      requiresAttention: requiresAttention ?? source.requiresAttention,
      structuredFields: structuredFields ?? source.structuredFields,
      tags: tags ?? source.tags,
      uploadDateIso: uploadDateIso ?? source.uploadDateIso,
      fileSizeLabel: fileSizeLabel ?? source.fileSizeLabel,
      isVerifiedScan: isVerifiedScan ?? source.isVerifiedScan,
      isFavorite: isFavorite ?? source.isFavorite,
      isPrimary: isPrimary ?? source.isPrimary,
      isArchived: isArchived ?? source.isArchived,
      archivedAtIso: archivedAtIso ?? source.archivedAtIso,
      captureSource: captureSource ?? source.captureSource,
      scanPagesCount: scanPagesCount ?? source.scanPagesCount,
    );
  }

  Future<List<DocumentRecordDto>> _getActiveRows() async {
    final rows = await localDataSource.getDocuments();
    return rows.where((row) => !row.isArchived).toList(growable: false);
  }
}

class _DocumentTemplate {
  const _DocumentTemplate({
    required this.category,
    required this.rawTypeKey,
    required this.identityGroup,
    required this.issuer,
    required this.identifierLabel,
    required this.identifierValue,
    required this.expiryDate,
    required this.fileStem,
    required this.tags,
    required this.structuredFields,
  });

  final DocumentCategoryType category;
  final String rawTypeKey;
  final String identityGroup;
  final String issuer;
  final String identifierLabel;
  final String identifierValue;
  final DateTime? expiryDate;
  final String fileStem;
  final List<String> tags;
  final List<Map<String, String>> structuredFields;
}
