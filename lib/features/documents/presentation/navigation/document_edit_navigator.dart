import 'package:flutter/material.dart';
import 'package:pass_doc_manager/domain/documents/entities/document_category_type.dart';
import 'package:pass_doc_manager/domain/documents/entities/document_detail_entity.dart';
import 'package:pass_doc_manager/domain/documents/entities/document_metadata_field_labels.dart';
import 'package:pass_doc_manager/domain/documents/entities/property_vault_entity.dart';
import 'package:pass_doc_manager/features/documents/presentation/pages/id_entry_page.dart';
import 'package:pass_doc_manager/features/documents/presentation/pages/identity_document_entry_page.dart';
import 'package:pass_doc_manager/features/documents/presentation/pages/property_entry_page.dart';
import 'package:pass_doc_manager/features/documents/presentation/pages/property_document_entry_page.dart';
import 'package:pass_doc_manager/features/documents/presentation/pages/work_document_manual_entry_page.dart';
import 'package:pass_doc_manager/features/documents/presentation/pages/work_payslip_entry_page.dart';

class DocumentEditNavigator {
  const DocumentEditNavigator._();

  static Widget buildEditPage({required DocumentDetailEntity detail}) {
    final editFlow = _resolveEditFlow(detail);

    return switch (editFlow) {
      _DocumentEditFlow.workPayslip => WorkPayslipEntryPage(
        initialCompanyName: _firstMatch(detail, const [
          DocumentMetadataFieldLabels.workCompanyName,
        ]),
        initialCompanyLogoPath: _firstMatch(detail, const [
          DocumentMetadataFieldLabels.workCompanyLogoPath,
        ]),
        documentToEdit: detail,
      ),
      _DocumentEditFlow.work => WorkDocumentManualEntryPage(
        documentToEdit: detail,
      ),
      _DocumentEditFlow.propertyProfile => PropertyEntryPage(
        propertyToEdit: _propertyFromDetail(detail),
      ),
      _DocumentEditFlow.propertyDocument => PropertyDocumentEntryPage(
        propertyId: _propertyIdFromDetail(detail),
        propertyName: _propertyNameFromDetail(detail),
        documentToEdit: detail,
      ),
      _DocumentEditFlow.identity => IdentityDocumentEntryPage(
        initialType: detail.type,
        documentToEdit: detail,
      ),
      _DocumentEditFlow.fallback => IdEntryPage(
        type: detail.type,
        documentToEdit: detail,
      ),
    };
  }

  static _DocumentEditFlow _resolveEditFlow(DocumentDetailEntity detail) {
    switch (detail.category) {
      case DocumentCategoryType.work:
        if (_isPayslip(detail)) return _DocumentEditFlow.workPayslip;
        return _DocumentEditFlow.work;
      case DocumentCategoryType.identity:
        return _DocumentEditFlow.identity;
      case DocumentCategoryType.property:
        return _isPropertyProfile(detail)
            ? _DocumentEditFlow.propertyProfile
            : _DocumentEditFlow.propertyDocument;
      case DocumentCategoryType.travel:
      case DocumentCategoryType.vehicle:
      case DocumentCategoryType.health:
      case DocumentCategoryType.other:
        break;
    }

    final tags = detail.tags
        .map((tag) => tag.trim().toLowerCase())
        .where((tag) => tag.isNotEmpty)
        .toSet();
    if (tags.contains('work')) {
      return _DocumentEditFlow.work;
    }
    if (tags.contains('identity')) {
      return _DocumentEditFlow.identity;
    }

    final canonicalClaims = detail.structuredFields
        .map(
          (field) =>
              DocumentMetadataFieldLabels.toCanonicalClaimKey(field.label),
        )
        .whereType<String>()
        .toSet();
    if (_hasWorkClaims(canonicalClaims)) {
      return _DocumentEditFlow.work;
    }
    if (_hasPropertyClaims(canonicalClaims)) {
      return _isPropertyProfile(detail)
          ? _DocumentEditFlow.propertyProfile
          : _DocumentEditFlow.propertyDocument;
    }

    return _DocumentEditFlow.fallback;
  }

  static bool _isPayslip(DocumentDetailEntity detail) {
    final tags = detail.tags.map((t) => t.trim().toLowerCase()).toSet();
    if (tags.contains('payslips') || tags.contains('payslip')) return true;
    final folderType = _firstMatch(detail, const [
      DocumentMetadataFieldLabels.workFolderType,
    ]).trim().toLowerCase();
    return folderType == 'payslips' || folderType == 'payslip';
  }

  static bool _hasWorkClaims(Set<String> canonicalClaims) {
    const claims = <String>{
      DocumentMetadataFieldLabels.workCompanyId,
      DocumentMetadataFieldLabels.workCompanyName,
      DocumentMetadataFieldLabels.workFolderType,
      DocumentMetadataFieldLabels.workRecordType,
      DocumentMetadataFieldLabels.workStatementDate,
      DocumentMetadataFieldLabels.workStatementTitle,
    };
    return canonicalClaims.any(claims.contains);
  }

  static bool _hasPropertyClaims(Set<String> canonicalClaims) {
    const claims = <String>{
      DocumentMetadataFieldLabels.propertyId,
      DocumentMetadataFieldLabels.propertyName,
      DocumentMetadataFieldLabels.propertyRecordType,
      DocumentMetadataFieldLabels.propertyType,
      DocumentMetadataFieldLabels.propertyOwnershipStatus,
      DocumentMetadataFieldLabels.propertyFullAddress,
    };
    return canonicalClaims.any(claims.contains);
  }

  static String _firstMatch(DocumentDetailEntity detail, List<String> labels) {
    for (final target in labels) {
      final normalizedTarget = target.trim().toLowerCase();
      for (final field in detail.structuredFields) {
        final label = field.label.trim();
        final canonical = DocumentMetadataFieldLabels.toCanonicalClaimKey(
          label,
        );
        final normalizedLabel = label.toLowerCase();
        if (normalizedLabel == normalizedTarget ||
            canonical == normalizedTarget) {
          final value = field.value.trim();
          if (value.isNotEmpty) {
            return value;
          }
        }
      }
    }
    return '';
  }

  static PropertyVaultEntity _propertyFromDetail(DocumentDetailEntity detail) {
    final propertyName = _firstMatch(detail, const [
      DocumentMetadataFieldLabels.propertyName,
    ]);
    final propertyId = _firstMatch(detail, const [
      DocumentMetadataFieldLabels.propertyId,
    ]);
    final propertyType = _firstMatch(detail, const [
      DocumentMetadataFieldLabels.propertyType,
    ]);
    final ownership = _firstMatch(detail, const [
      DocumentMetadataFieldLabels.propertyOwnershipStatus,
    ]);
    final address = _firstMatch(detail, const [
      DocumentMetadataFieldLabels.propertyFullAddress,
    ]);
    final addressSuggestionJson = _firstMatch(detail, const [
      DocumentMetadataFieldLabels.propertyAddressSuggestionJson,
    ]);
    return PropertyVaultEntity(
      propertyId: propertyId.trim().isEmpty ? detail.id : propertyId,
      propertyName: propertyName.trim().isEmpty ? detail.issuer : propertyName,
      propertyTypeLabel: propertyType,
      ownershipStatusLabel: ownership,
      fullAddress: address,
      addressSuggestionJson: addressSuggestionJson,
      lastUpdatedAt: detail.updatedAt,
      documentsCount: 0,
      profileDocumentId: detail.id,
    );
  }

  static String _propertyIdFromDetail(DocumentDetailEntity detail) {
    final propertyId = _firstMatch(detail, const [
      DocumentMetadataFieldLabels.propertyId,
    ]);
    return propertyId.trim().isEmpty ? detail.id : propertyId;
  }

  static String _propertyNameFromDetail(DocumentDetailEntity detail) {
    final propertyName = _firstMatch(detail, const [
      DocumentMetadataFieldLabels.propertyName,
    ]);
    return propertyName.trim().isEmpty ? detail.issuer : propertyName;
  }

  static bool _isPropertyProfile(DocumentDetailEntity detail) {
    final recordType = _firstMatch(detail, const [
      DocumentMetadataFieldLabels.propertyRecordType,
    ]).trim().toLowerCase();
    return recordType == 'property_profile' || recordType == 'profile';
  }
}

enum _DocumentEditFlow {
  work,
  workPayslip,
  propertyProfile,
  propertyDocument,
  identity,
  fallback,
}
