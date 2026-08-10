class DocumentRecordDto {
  const DocumentRecordDto({
    required this.id,
    required this.title,
    required this.fileName,
    required this.categoryKey,
    required this.updatedAtIso,
    required this.documentType,
    required this.identityGroupKey,
    required this.identifierLabel,
    required this.identifierValue,
    required this.expiryAtIso,
    required this.requiresAttention,
    this.structuredFields = const [],
    this.tags = const [],
    this.uploadDateIso = '',
    this.fileSizeLabel = '1.8 MB',
    this.isVerifiedScan = true,
    this.isFavorite = false,
    this.isPrimary = false,
    this.isArchived = false,
    this.archivedAtIso = '',
    this.captureSource = 'camera',
    this.scanPagesCount = 1,
  });

  final String id;
  final String title;
  final String fileName;
  final String categoryKey;
  final String updatedAtIso;
  final String documentType;
  final String identityGroupKey;
  final String identifierLabel;
  final String identifierValue;
  final String expiryAtIso;
  final bool requiresAttention;
  final List<Map<String, String>> structuredFields;
  final List<String> tags;
  final String uploadDateIso;
  final String fileSizeLabel;
  final bool isVerifiedScan;
  final bool isFavorite;
  final bool isPrimary;
  final bool isArchived;
  final String archivedAtIso;
  final String captureSource;
  final int scanPagesCount;

  factory DocumentRecordDto.fromMap(Map<String, dynamic> map) {
    return DocumentRecordDto(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      fileName: map['fileName'] as String? ?? (map['title'] as String? ?? ''),
      categoryKey: map['category'] as String? ?? '',
      updatedAtIso: map['updatedAtIso'] as String? ?? '',
      documentType: map['documentType'] as String? ?? '',
      identityGroupKey: map['identityGroup'] as String? ?? '',
      identifierLabel: map['identifierLabel'] as String? ?? '',
      identifierValue: map['identifierValue'] as String? ?? '',
      expiryAtIso: map['expiryAtIso'] as String? ?? '',
      requiresAttention: map['requiresAttention'] as bool? ?? false,
      structuredFields: _parseStructuredFields(map['structuredFields']),
      tags: _parseTags(map['tags']),
      uploadDateIso: map['uploadDateIso'] as String? ?? '',
      fileSizeLabel: map['fileSizeLabel'] as String? ?? '1.8 MB',
      isVerifiedScan: map['isVerifiedScan'] as bool? ?? true,
      isFavorite: map['isFavorite'] as bool? ?? false,
      isPrimary: map['isPrimary'] as bool? ?? false,
      isArchived: map['isArchived'] as bool? ?? false,
      archivedAtIso: map['archivedAtIso'] as String? ?? '',
      captureSource: map['captureSource'] as String? ?? 'camera',
      scanPagesCount: map['scanPagesCount'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'fileName': fileName,
      'category': categoryKey,
      'updatedAtIso': updatedAtIso,
      'documentType': documentType,
      'identityGroup': identityGroupKey,
      'identifierLabel': identifierLabel,
      'identifierValue': identifierValue,
      'expiryAtIso': expiryAtIso,
      'requiresAttention': requiresAttention,
      'structuredFields': structuredFields,
      'tags': tags,
      'uploadDateIso': uploadDateIso,
      'fileSizeLabel': fileSizeLabel,
      'isVerifiedScan': isVerifiedScan,
      'isFavorite': isFavorite,
      'isPrimary': isPrimary,
      'isArchived': isArchived,
      'archivedAtIso': archivedAtIso,
      'captureSource': captureSource,
      'scanPagesCount': scanPagesCount,
    };
  }

  static List<Map<String, String>> _parseStructuredFields(dynamic raw) {
    if (raw is! List) {
      return const [];
    }

    final values = <Map<String, String>>[];
    for (final item in raw) {
      if (item is Map) {
        final mapped = Map<String, dynamic>.from(item);
        final label = mapped['label']?.toString().trim() ?? '';
        final value = mapped['value']?.toString().trim() ?? '';
        if (label.isEmpty || value.isEmpty) {
          continue;
        }
        values.add({'label': label, 'value': value});
      }
    }
    return values;
  }

  static List<String> _parseTags(dynamic raw) {
    if (raw is! List) {
      return const [];
    }
    return raw
        .map((item) => item.toString())
        .where((it) => it.isNotEmpty)
        .toList(growable: false);
  }
}
