import 'package:pass_doc_manager/domain/documents/entities/document_capture_source.dart';
import 'package:pass_doc_manager/domain/documents/entities/document_category_type.dart';
import 'package:pass_doc_manager/domain/documents/entities/document_detail_entity.dart';
import 'package:pass_doc_manager/domain/documents/entities/document_library_overview_entity.dart';
import 'package:pass_doc_manager/domain/documents/entities/identity_document_entity.dart';
import 'package:pass_doc_manager/domain/documents/entities/property_asset_record_entity.dart';
import 'package:pass_doc_manager/domain/documents/entities/property_asset_type.dart';
import 'package:pass_doc_manager/domain/documents/entities/property_vault_entity.dart';
import 'package:pass_doc_manager/domain/documents/entities/property_detail_entity.dart';
import 'package:pass_doc_manager/domain/documents/entities/travel_trip_detail_entity.dart';
import 'package:pass_doc_manager/domain/documents/entities/travel_trip_entity.dart';
import 'package:pass_doc_manager/domain/documents/entities/document_type.dart';
import 'package:pass_doc_manager/domain/documents/entities/vault_document_entity.dart';
import 'package:pass_doc_manager/domain/documents/entities/work_company_detail_entity.dart';
import 'package:pass_doc_manager/domain/documents/entities/work_company_vault_entity.dart';

abstract class DocumentRepository {
  Future<DocumentLibraryOverviewEntity> getLibraryOverview();

  Future<List<IdentityDocumentEntity>> getIdentityDocuments();

  Future<List<VaultDocumentEntity>> getVaultDocuments();

  Future<List<WorkCompanyVaultEntity>> getWorkCompanyVaults();

  Future<WorkCompanyDetailEntity> getWorkCompanyDetail({
    required String companyId,
  });

  Future<List<PropertyVaultEntity>> getPropertyVaults();

  Future<List<TravelTripEntity>> getTravelTrips();

  Future<PropertyDetailEntity> getPropertyDetail({required String propertyId});

  Future<TravelTripDetailEntity> getTravelTripDetail({required String tripId});

  Future<List<PropertyAssetRecordEntity>> getPropertyAssetRecords({
    required String propertyId,
    PropertyAssetType? assetType,
  });

  Future<DocumentDetailEntity> getDocumentDetail({required String documentId});

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
  });

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
  });

  Future<DocumentDetailEntity> replaceDocumentCapture({
    required String documentId,
    required DocumentCaptureSource source,
    required int scanPagesCount,
  });

  Future<DocumentDetailEntity> forceExpireDocument({
    required String documentId,
  });

  Future<void> deleteDocument({required String documentId});

  Future<void> archiveDocument({required String documentId});

  Future<void> toggleFavorite({
    required String documentId,
    required bool isFavorite,
  });

  Future<void> setPrimaryIdentityDocument({
    required String documentId,
    bool isPrimary = true,
  });
}
