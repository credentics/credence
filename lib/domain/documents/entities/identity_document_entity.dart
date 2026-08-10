import 'package:pass_doc_manager/domain/documents/entities/document_country.dart';
import 'package:pass_doc_manager/domain/documents/entities/identity_document_holder_relation.dart';
import 'package:pass_doc_manager/domain/documents/entities/identity_document_group.dart';
import 'package:pass_doc_manager/domain/documents/entities/identity_document_status.dart';

class IdentityDocumentEntity {
  const IdentityDocumentEntity({
    required this.id,
    required this.typeLabel,
    required this.issuer,
    required this.country,
    required this.countryName,
    required this.identifierLabel,
    required this.identifierValue,
    required this.expiryDate,
    required this.addedDate,
    this.lastUpdatedAt,
    required this.status,
    required this.group,
    required this.isPrimary,
    required this.holderRelation,
  });

  final String id;
  final String typeLabel;
  final String issuer;
  final DocumentCountry country;
  final String countryName;
  final String identifierLabel;
  final String identifierValue;
  final DateTime expiryDate;
  final DateTime addedDate;
  final DateTime? lastUpdatedAt;
  final IdentityDocumentStatus status;
  final IdentityDocumentGroup group;
  final bool isPrimary;
  final IdentityDocumentHolderRelation holderRelation;
}
