class VaultDocumentRecordDto {
  const VaultDocumentRecordDto({
    required this.id,
    required this.title,
    required this.category,
    required this.updatedAtIso,
    this.fileName = '',
    this.documentType = '',
    this.identityGroup = '',
    this.identifierLabel = '',
    this.identifierValue = '',
    this.expiryAtIso = '',
    this.requiresAttention = false,
    this.structuredFields = const [],
    this.tags = const [],
    this.uploadDateIso = '',
    this.fileSizeLabel = '1.8 MB',
    this.isVerifiedScan = true,
    this.isFavorite = false,
    this.isPrimary = false,
    this.captureSource = 'camera',
    this.scanPagesCount = 1,
  });

  final String id;
  final String title;
  final String category;
  final String updatedAtIso;
  final String fileName;
  final String documentType;
  final String identityGroup;
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
  final String captureSource;
  final int scanPagesCount;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'fileName': fileName,
      'category': category,
      'updatedAtIso': updatedAtIso,
      'documentType': documentType,
      'identityGroup': identityGroup,
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
      'captureSource': captureSource,
      'scanPagesCount': scanPagesCount,
    };
  }

  factory VaultDocumentRecordDto.fromMap(Map<String, dynamic> map) {
    return VaultDocumentRecordDto(
      id: map['id'] as String,
      title: map['title'] as String,
      category: map['category'] as String,
      updatedAtIso: map['updatedAtIso'] as String,
      fileName: map['fileName'] as String? ?? '',
      documentType: map['documentType'] as String? ?? '',
      identityGroup: map['identityGroup'] as String? ?? '',
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
      captureSource: map['captureSource'] as String? ?? 'camera',
      scanPagesCount: map['scanPagesCount'] as int? ?? 1,
    );
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
