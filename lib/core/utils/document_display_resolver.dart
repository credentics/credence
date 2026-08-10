import 'package:pass_doc_manager/data/documents/dtos/document_record_dto.dart';
import 'package:pass_doc_manager/domain/documents/entities/document_metadata_field_labels.dart';

/// Semantic icon key for a document row. The widget layer maps these
/// strings to actual `IconData` + accent colour so the resolver stays
/// UI-framework-free.
class DocumentIconKey {
  const DocumentIconKey._();

  static const payslip = 'payslip';
  static const contract = 'contract';
  static const workRecord = 'work_record';
  static const identityCard = 'identity_card';
  static const passport = 'passport';
  static const driverLicense = 'driver_license';
  static const residencePermit = 'residence_permit';
  static const travelTicket = 'travel_ticket';
  static const travelTripProfile = 'travel_trip_profile';
  static const travelBudget = 'travel_budget';
  static const travelEvent = 'travel_event';
  static const travelExpense = 'travel_expense';
  static const propertyRecord = 'property_record';
  static const propertyAsset = 'property_asset';
  static const finance = 'finance';
  static const genericDocument = 'document';
}

/// Everything the UI layer needs to render a single document row, plus
/// optional aggregation metadata.
///
/// When [aggregateKey] is non-null, consumers may bucket items that share
/// the same key under a single expandable parent row. [aggregateLabel]
/// and [aggregateHint] describe how the parent row should look when that
/// bucket contains ≥ 2 items.
class DocumentDisplaySpec {
  const DocumentDisplaySpec({
    required this.title,
    required this.subtitle,
    required this.iconKey,
    this.dateLabel,
    this.aggregateKey,
    this.aggregateLabel,
    this.aggregateHint,
    this.aggregateIconKey,
  });

  final String title;
  final String subtitle;
  final String iconKey;
  final String? dateLabel;
  final String? aggregateKey;
  final String? aggregateLabel;
  final String? aggregateHint;
  final String? aggregateIconKey;
}

/// Resolves human-friendly display metadata for a document stored in the
/// vault. All logic is driven by `DocumentMetadataFieldLabels` constants
/// plus the top-level DTO fields — no free-text label matching.
class DocumentDisplayResolver {
  const DocumentDisplayResolver._();

  static DocumentDisplaySpec resolve(DocumentRecordDto dto) {
    final fields = _fieldMap(dto);
    final category = dto.categoryKey.trim().toLowerCase();

    switch (category) {
      case 'work':
      case 'employment':
        return _resolveWork(dto, fields);
      case 'identity':
      case 'government':
        return _resolveIdentity(dto, fields);
      case 'travel':
        return _resolveTravel(dto, fields);
      case 'property':
        return _resolveProperty(dto, fields);
      case 'finance':
      case 'banking':
      case 'insurance':
        return _resolveFinance(dto, fields);
      default:
        return _resolveGeneric(dto);
    }
  }

  // ---------------------------------------------------------------------------
  // Per-category resolvers

  static DocumentDisplaySpec _resolveWork(
    DocumentRecordDto dto,
    Map<String, String> fields,
  ) {
    final statementTitle = fields[DocumentMetadataFieldLabels.workStatementTitle];
    final statementDate = fields[DocumentMetadataFieldLabels.workStatementDate];
    final company = fields[DocumentMetadataFieldLabels.workCompanyName];
    final folderType = fields[DocumentMetadataFieldLabels.workFolderType];
    final role = fields[DocumentMetadataFieldLabels.workRole];

    final isPayslip = folderType?.toLowerCase().contains('payslip') == true ||
        (statementTitle?.toLowerCase().contains('payslip') == true);
    final iconKey = isPayslip
        ? DocumentIconKey.payslip
        : (folderType?.toLowerCase().contains('contract') == true
            ? DocumentIconKey.contract
            : DocumentIconKey.workRecord);

    final title = _firstNonEmpty([
      statementTitle,
      dto.identifierValue,
      dto.title,
      dto.fileName,
    ]);
    final subtitleParts = <String>[
      if (company != null && company.isNotEmpty) company,
      if (folderType != null && folderType.isNotEmpty) _humanize(folderType),
      if (role != null && role.isNotEmpty) role,
    ];
    final subtitle = subtitleParts.isEmpty
        ? _humanize(dto.documentType)
        : subtitleParts.join(' \u2022 ');

    final aggregateKey = (company != null &&
            company.isNotEmpty &&
            folderType != null &&
            folderType.isNotEmpty)
        ? 'work:${company.toLowerCase()}:${folderType.toLowerCase()}'
        : null;

    return DocumentDisplaySpec(
      title: title,
      subtitle: subtitle,
      iconKey: iconKey,
      dateLabel: statementDate,
      aggregateKey: aggregateKey,
      aggregateLabel: aggregateKey != null ? company : null,
      aggregateHint: aggregateKey != null ? _humanizePlural(folderType!) : null,
      aggregateIconKey: aggregateKey != null ? iconKey : null,
    );
  }

  static DocumentDisplaySpec _resolveIdentity(
    DocumentRecordDto dto,
    Map<String, String> fields,
  ) {
    final docType = dto.documentType.toLowerCase();
    final iconKey = docType.contains('passport')
        ? DocumentIconKey.passport
        : docType.contains('driver')
            ? DocumentIconKey.driverLicense
            : docType.contains('residence') || docType.contains('permit')
                ? DocumentIconKey.residencePermit
                : DocumentIconKey.identityCard;

    final given = fields[DocumentMetadataFieldLabels.givenName];
    final family = fields[DocumentMetadataFieldLabels.familyName];
    final fullName = [
      if (given != null && given.isNotEmpty) given,
      if (family != null && family.isNotEmpty) family,
    ].join(' ').trim();
    final docNumber = fields[DocumentMetadataFieldLabels.documentNumber];

    final title = _firstNonEmpty([
      dto.title,
      fullName.isEmpty ? null : fullName,
      docNumber,
      dto.fileName,
    ]);
    final subtitleParts = <String>[
      _humanize(dto.documentType),
      if (docNumber != null && docNumber.isNotEmpty) docNumber,
    ];

    // Identity docs don't aggregate — each should stand alone.
    return DocumentDisplaySpec(
      title: title,
      subtitle: subtitleParts.join(' \u2022 '),
      iconKey: iconKey,
    );
  }

  static DocumentDisplaySpec _resolveTravel(
    DocumentRecordDto dto,
    Map<String, String> fields,
  ) {
    final recordType = fields[DocumentMetadataFieldLabels.travelRecordType];
    final tripTitle = fields[DocumentMetadataFieldLabels.travelTripTitle];
    final destination = fields[DocumentMetadataFieldLabels.travelDestination];
    final eventCategory = fields[DocumentMetadataFieldLabels.travelEventCategory];
    final startDate = fields[DocumentMetadataFieldLabels.travelStartDate];

    String iconKey;
    switch (recordType?.toLowerCase()) {
      case 'trip_profile':
        iconKey = DocumentIconKey.travelTripProfile;
      case 'budget':
        iconKey = DocumentIconKey.travelBudget;
      case 'event':
        iconKey = DocumentIconKey.travelEvent;
      case 'expense':
        iconKey = DocumentIconKey.travelExpense;
      case 'wallet_document':
        iconKey = DocumentIconKey.travelTicket;
      default:
        iconKey = DocumentIconKey.travelTicket;
    }

    final title = _firstNonEmpty([
      dto.title,
      tripTitle,
      destination,
      dto.fileName,
    ]);
    final subtitleParts = <String>[
      if (recordType != null) _humanize(recordType),
      if (destination != null && destination.isNotEmpty) destination,
      if (eventCategory != null && eventCategory.isNotEmpty)
        _humanize(eventCategory),
    ];

    final aggregateKey = (tripTitle != null && tripTitle.isNotEmpty)
        ? 'travel:${tripTitle.toLowerCase()}'
        : null;

    return DocumentDisplaySpec(
      title: title,
      subtitle: subtitleParts.isEmpty
          ? _humanize(dto.documentType)
          : subtitleParts.join(' \u2022 '),
      iconKey: iconKey,
      dateLabel: startDate,
      aggregateKey: aggregateKey,
      aggregateLabel: tripTitle,
      aggregateHint: destination,
      aggregateIconKey:
          aggregateKey != null ? DocumentIconKey.travelTripProfile : null,
    );
  }

  static DocumentDisplaySpec _resolveProperty(
    DocumentRecordDto dto,
    Map<String, String> fields,
  ) {
    final propertyName = fields[DocumentMetadataFieldLabels.propertyName];
    final propertyType = fields[DocumentMetadataFieldLabels.propertyType];
    final recordType = fields[DocumentMetadataFieldLabels.propertyRecordType];
    final assetType = fields[DocumentMetadataFieldLabels.propertyAssetType];

    final iconKey = assetType != null && assetType.isNotEmpty
        ? DocumentIconKey.propertyAsset
        : DocumentIconKey.propertyRecord;

    final title = _firstNonEmpty([
      dto.title,
      propertyName,
      dto.fileName,
    ]);
    final subtitleParts = <String>[
      if (propertyName != null && propertyName.isNotEmpty) propertyName,
      if (propertyType != null && propertyType.isNotEmpty)
        _humanize(propertyType),
      if (recordType != null && recordType.isNotEmpty) _humanize(recordType),
    ];

    final aggregateKey = (propertyName != null && propertyName.isNotEmpty)
        ? 'property:${propertyName.toLowerCase()}'
        : null;

    return DocumentDisplaySpec(
      title: title,
      subtitle: subtitleParts.isEmpty
          ? _humanize(dto.documentType)
          : subtitleParts.join(' \u2022 '),
      iconKey: iconKey,
      aggregateKey: aggregateKey,
      aggregateLabel: propertyName,
      aggregateHint: propertyType == null ? null : _humanize(propertyType),
      aggregateIconKey:
          aggregateKey != null ? DocumentIconKey.propertyRecord : null,
    );
  }

  static DocumentDisplaySpec _resolveFinance(
    DocumentRecordDto dto,
    Map<String, String> fields,
  ) {
    final title = _firstNonEmpty([
      dto.title,
      dto.identifierValue,
      dto.fileName,
    ]);
    final subtitleParts = <String>[
      _humanize(dto.documentType),
      if (dto.identifierLabel.trim().isNotEmpty &&
          dto.identifierValue.trim().isNotEmpty)
        dto.identifierLabel,
    ];
    return DocumentDisplaySpec(
      title: title,
      subtitle: subtitleParts.join(' \u2022 '),
      iconKey: DocumentIconKey.finance,
    );
  }

  static DocumentDisplaySpec _resolveGeneric(DocumentRecordDto dto) {
    final title = _firstNonEmpty([
      dto.title,
      dto.identifierValue,
      dto.fileName,
    ]);
    final subtitle = _humanize(dto.documentType);
    return DocumentDisplaySpec(
      title: title,
      subtitle: subtitle.isEmpty ? dto.fileName : subtitle,
      iconKey: DocumentIconKey.genericDocument,
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers

  static Map<String, String> _fieldMap(DocumentRecordDto dto) {
    final out = <String, String>{};
    for (final field in dto.structuredFields) {
      final key = (field['label'] ?? '').trim();
      final value = (field['value'] ?? '').trim();
      if (key.isEmpty || value.isEmpty) continue;
      out[key] = value;
    }
    return out;
  }

  static String _firstNonEmpty(List<String?> candidates) {
    for (final candidate in candidates) {
      if (candidate == null) continue;
      final trimmed = candidate.trim();
      if (trimmed.isNotEmpty) return trimmed;
    }
    return '';
  }

  static String _humanize(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '';
    return trimmed
        .replaceAll('_', ' ')
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  static String _humanizePlural(String raw) {
    final label = _humanize(raw);
    if (label.isEmpty) return '';
    if (label.endsWith('s')) return label;
    return '${label}s';
  }
}
