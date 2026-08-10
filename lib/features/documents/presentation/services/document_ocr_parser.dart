import 'dart:math';

import 'package:intl/intl.dart';
import 'package:pass_doc_manager/domain/documents/entities/document_type.dart';
import 'package:pass_doc_manager/domain/documents/entities/identity_document_type_labels.dart';

enum ScannedIdType {
  passport,
  driversLicense,
  idCard,
  proofOfAgeCard,
  residencePermit,
  studentId,
  disabilityCard,
  unknown,
}

extension ScannedIdTypeX on ScannedIdType {
  String get rawTypeKey {
    return switch (this) {
      ScannedIdType.passport => IdentityDocumentTypeLabels.passport,
      ScannedIdType.driversLicense => IdentityDocumentTypeLabels.driversLicense,
      ScannedIdType.idCard => IdentityDocumentTypeLabels.idCard,
      ScannedIdType.proofOfAgeCard => IdentityDocumentTypeLabels.proofOfAgeCard,
      ScannedIdType.residencePermit =>
        IdentityDocumentTypeLabels.residencePermit,
      ScannedIdType.studentId => IdentityDocumentTypeLabels.studentId,
      ScannedIdType.disabilityCard => IdentityDocumentTypeLabels.disabilityCard,
      ScannedIdType.unknown => IdentityDocumentTypeLabels.unknown,
    };
  }

  String get label {
    return IdentityDocumentTypeLabels.labelFromRawType(rawTypeKey);
  }
}

class DocumentAutoFillSuggestion {
  const DocumentAutoFillSuggestion({
    required this.issuer,
    required this.identifierLabel,
    required this.identifierValue,
    required this.expiryDate,
    required this.birthDate,
    required this.structuredFields,
    required this.tags,
    required this.rawText,
    required this.detectedIdType,
    required this.confidence,
  });

  final String issuer;
  final String identifierLabel;
  final String identifierValue;
  final DateTime? expiryDate;
  final DateTime? birthDate;
  final List<Map<String, String>> structuredFields;
  final List<String> tags;
  final String rawText;
  final ScannedIdType detectedIdType;
  final double confidence;
}

class DocumentOcrParser {
  const DocumentOcrParser();

  static const _countryAliases = <String, String>{
    'usa': 'United States',
    'us': 'United States',
    'united states america': 'United States',
    'united states': 'United States',
    'united states of america': 'United States',
    'gbr': 'United Kingdom',
    'uk': 'United Kingdom',
    'gb': 'United Kingdom',
    'united kingdom': 'United Kingdom',
    'great britain': 'United Kingdom',
    'fra': 'France',
    'france': 'France',
    'esp': 'Spain',
    'spain': 'Spain',
    'tur': 'Turkey',
    'turkey': 'Turkey',
    'turkiye': 'Turkey',
    'tun': 'Tunisia',
    'tunisia': 'Tunisia',
    'are': 'United Arab Emirates',
    'united arab emirates': 'United Arab Emirates',
    'uae': 'United Arab Emirates',
    'deu': 'Germany',
    'germany': 'Germany',
    'ita': 'Italy',
    'italy': 'Italy',
    'can': 'Canada',
    'canada': 'Canada',
    'che': 'Switzerland',
    'switzerland': 'Switzerland',
    'european union': 'European Union',
  };

  static const _dobLabels = <String>[
    'date of birth',
    'birth date',
    'birthdate',
    'dob',
    'date birth',
    'geburtsdatum',
    'fecha de nacimiento',
    'date de naissance',
    'data di nascita',
    'data de nascimento',
    'geboortedatum',
    'fødselsdato',
    'födelsedatum',
    '생년월일',
    '生年月日',
    '出生日期',
  ];

  static const _expiryLabels = <String>[
    'expiry date',
    'expiration date',
    'expires',
    'expire',
    'expiration',
    'valid until',
    'date of expiry',
    'date d expiration',
    'valable jusqu',
    'valable jusqu au',
    'valid until',
    'ablaufdatum',
    'fecha de expiracion',
    'expiry',
  ];

  static const _dobBlacklist = <String>[
    'expiry',
    'expire',
    'expiration',
    'issue',
    'issued',
    'valid until',
    'date of issue',
  ];

  static const _idTypeKeywords = <ScannedIdType, List<String>>{
    ScannedIdType.passport: [
      'passport',
      'travel document',
      'passeport',
      'pasaporte',
      'reisepass',
      'passaporto',
      'passaporte',
      'paspoort',
    ],
    ScannedIdType.driversLicense: [
      'driver',
      'license',
      'driving',
      'permis',
      'licencia',
      'führerschein',
      'patente',
      'rijbewijs',
    ],
    ScannedIdType.idCard: [
      'national id',
      'identity card',
      'identification card',
      'carte d identité',
      'personalausweis',
      'citizen card',
      'personal identity',
    ],
    ScannedIdType.proofOfAgeCard: ['proof of age card'],
    ScannedIdType.residencePermit: [
      'residence permit',
      'residency permit',
      'residence card',
      'permesso di soggiorno',
      'aufenthaltstitel',
      'titre de sejour',
      'titre de séjour',
    ],
    ScannedIdType.studentId: [
      'student id',
      'student card',
      'student identity',
      'carte etudiante',
      'studentenausweis',
    ],
    ScannedIdType.disabilityCard: [
      'disability card',
      'disability id',
      'disability permit',
      'carte d invalidite',
      'tarjeta de discapacidad',
    ],
  };

  static const _monthLookup = <String, int>{
    'jan': 1,
    'january': 1,
    'janv': 1,
    'ene': 1,
    'feb': 2,
    'february': 2,
    'fev': 2,
    'fév': 2,
    'mar': 3,
    'march': 3,
    'apr': 4,
    'april': 4,
    'avr': 4,
    'may': 5,
    'mai': 5,
    'mag': 5,
    'jun': 6,
    'june': 6,
    'juin': 6,
    'jul': 7,
    'july': 7,
    'juil': 7,
    'aug': 8,
    'august': 8,
    'ago': 8,
    'aoû': 8,
    'sep': 9,
    'sept': 9,
    'september': 9,
    'set': 9,
    'oct': 10,
    'october': 10,
    'okt': 10,
    'nov': 11,
    'november': 11,
    'dec': 12,
    'december': 12,
    'dez': 12,
    'dic': 12,
    'déc': 12,
  };

  static final _dateTokenPattern = RegExp(
    r'(\d{1,2}[\/\-.]\d{1,2}[\/\-.]\d{2,4})|'
    r'(\d{4}[\/\-.]\d{1,2}[\/\-.]\d{1,2})|'
    r'(\d{1,2}\s+\d{1,2}\s+\d{2,4})|'
    r'(\d{1,2}\s+[A-Za-zÀ-ÿ]{3,10}\s+\d{2,4})|'
    r'(\d{1,2}\s*[A-Za-zÀ-ÿ]{3,10}\s*\d{2})|'
    r'(\d{8})',
    caseSensitive: false,
  );

  DocumentAutoFillSuggestion parse({
    required DocumentType type,
    required String recognizedText,
  }) {
    final text = recognizedText.replaceAll('\r', '\n');
    final lines = text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList(growable: false);

    final detectedIdType = detectIdType(text);
    final allDates = _extractAllDates(text);
    final country = _extractCountry(lines) ?? _extractCountry([text]) ?? '';
    final birthDate = _findDateByLabels(
      lines: lines,
      labels: _dobLabels,
      blockedKeywords: _dobBlacklist,
      fallbackDates: allDates,
      preferPast: true,
    );
    final expiryDate = _findDateByLabels(
      lines: lines,
      labels: _expiryLabels,
      blockedKeywords: const [],
      fallbackDates: allDates,
      preferPast: false,
    );

    return switch (type) {
      DocumentType.passport => _buildPassport(
        lines: lines,
        text: text,
        country: country,
        birthDate: birthDate,
        expiryDate: expiryDate,
        detectedIdType: detectedIdType,
      ),
      DocumentType.idCard => _buildIdCard(
        lines: lines,
        text: text,
        country: country,
        birthDate: birthDate,
        expiryDate: expiryDate,
        detectedIdType: detectedIdType,
      ),
      DocumentType.driversLicense => _buildDriver(
        lines: lines,
        text: text,
        country: country,
        birthDate: birthDate,
        expiryDate: expiryDate,
        detectedIdType: detectedIdType,
      ),
      DocumentType.other => _buildOther(
        lines: lines,
        text: text,
        country: country,
        birthDate: birthDate,
        expiryDate: expiryDate,
        detectedIdType: detectedIdType,
      ),
    };
  }

  ScannedIdType detectIdType(String text) {
    final lowerLines = text
        .toLowerCase()
        .replaceAll("'", ' ')
        .replaceAll(RegExp(r'[^a-z0-9À-ÿ\s\n]'), ' ')
        .split('\n');

    var bestType = ScannedIdType.unknown;
    var bestScore = 0;

    for (final line in lowerLines) {
      final compact = line.trim();
      if (compact.isEmpty) {
        continue;
      }
      for (final entry in _idTypeKeywords.entries) {
        for (final keyword in entry.value) {
          final normalizedKeyword = keyword.toLowerCase();
          if (compact.contains(normalizedKeyword)) {
            final score = normalizedKeyword.length;
            if (score > bestScore) {
              bestScore = score;
              bestType = entry.key;
            }
          }
        }
      }
    }

    return bestType;
  }

  DocumentAutoFillSuggestion _buildPassport({
    required List<String> lines,
    required String text,
    required String country,
    required DateTime? birthDate,
    required DateTime? expiryDate,
    required ScannedIdType detectedIdType,
  }) {
    final number =
        _extractByLabels(lines, const [
          'passport number',
          'document number',
          'passport no',
        ]) ??
        _extractDocumentToken(text);

    final nationality =
        _extractByLabels(lines, const ['nationality', 'country']) ?? country;
    final sex = _extractSex(lines);

    final fields = <Map<String, String>>[
      {'label': 'Passport Number', 'value': number ?? ''},
      if (nationality.isNotEmpty)
        {'label': 'Nationality', 'value': nationality},
      if ((sex ?? '').trim().isNotEmpty) {'label': 'Sex', 'value': sex!},
      if (birthDate != null)
        {'label': 'Birth Date', 'value': _formatDate(birthDate)},
      if (expiryDate != null)
        {'label': 'Expiry Date', 'value': _formatDate(expiryDate)},
      if (country.isNotEmpty) {'label': 'Issuing Country', 'value': country},
    ];

    final confidence = _scoreConfidence(
      detectedIdType: detectedIdType,
      expected: DocumentType.passport,
      tokens: <String?>[number, nationality],
      dates: <DateTime?>[birthDate, expiryDate],
    );

    return DocumentAutoFillSuggestion(
      issuer: country.isNotEmpty ? country : 'Passport',
      identifierLabel: 'Passport Number',
      identifierValue: number ?? '',
      expiryDate: expiryDate,
      birthDate: birthDate,
      structuredFields: fields.where(_isNonEmptyField).toList(growable: false),
      tags: const ['Travel', 'ID', 'Personal'],
      rawText: text,
      detectedIdType: detectedIdType,
      confidence: confidence,
    );
  }

  DocumentAutoFillSuggestion _buildIdCard({
    required List<String> lines,
    required String text,
    required String country,
    required DateTime? birthDate,
    required DateTime? expiryDate,
    required ScannedIdType detectedIdType,
  }) {
    final idValue =
        _extractByLabels(lines, const [
          'id number',
          'identity number',
          'identity id',
          'document number',
          'national id',
          'personal number',
          'numero personnel',
          'numéro personnel',
          'numero national',
          'numéro national',
        ]) ??
        _extractNumericIdentifierNearLabels(lines) ??
        _extractDocumentToken(text);
    final fullName =
        _extractNameFromResidencePermit(lines) ??
        _extractByLabels(lines, const [
          'full name',
          'forenames',
          'surname',
          'surnames',
          'noms prenoms',
        ]) ??
        _extractLikelyName(lines);
    final nationality =
        _extractCountryNearLabels(lines, const [
          'nationality',
          'nationalite',
          'nat',
        ]) ??
        _resolveCountryFromRawValue(
          _extractByLabels(lines, const [
            'nationality',
            'nationalite',
            'nat',
            'country',
          ]),
        ) ??
        _extractCountry(
          lines
              .where((line) {
                final normalized = _normalizeWords(line);
                return normalized.contains('nationalite') ||
                    normalized.contains('nationality') ||
                    normalized.contains(' nat ') ||
                    normalized.startsWith('nat ') ||
                    normalized.endsWith(' nat');
              })
              .toList(growable: false),
        ) ??
        country;
    final sex = _extractSex(lines);

    final fields = <Map<String, String>>[
      {'label': 'ID Number', 'value': idValue ?? ''},
      if ((fullName ?? '').trim().isNotEmpty)
        {'label': 'Full Name', 'value': fullName!.trim()},
      if (nationality.isNotEmpty)
        {'label': 'Nationality', 'value': nationality},
      if ((sex ?? '').trim().isNotEmpty) {'label': 'Sex', 'value': sex!},
      if (birthDate != null)
        {'label': 'Birth Date', 'value': _formatDate(birthDate)},
      if (expiryDate != null)
        {'label': 'Expiry Date', 'value': _formatDate(expiryDate)},
    ];

    final confidence = _scoreConfidence(
      detectedIdType: detectedIdType,
      expected: DocumentType.idCard,
      tokens: <String?>[idValue, fullName, nationality],
      dates: <DateTime?>[birthDate, expiryDate],
    );

    return DocumentAutoFillSuggestion(
      issuer: country.isNotEmpty ? country : 'ID Card',
      identifierLabel: 'ID Number',
      identifierValue: idValue ?? '',
      expiryDate: expiryDate,
      birthDate: birthDate,
      structuredFields: fields.where(_isNonEmptyField).toList(growable: false),
      tags: const ['ID', 'Personal'],
      rawText: text,
      detectedIdType: detectedIdType,
      confidence: confidence,
    );
  }

  DocumentAutoFillSuggestion _buildDriver({
    required List<String> lines,
    required String text,
    required String country,
    required DateTime? birthDate,
    required DateTime? expiryDate,
    required ScannedIdType detectedIdType,
  }) {
    final number =
        _extractByLabels(lines, const [
          'license number',
          'license no',
          'licence number',
        ]) ??
        _extractDocumentToken(text);
    final authority =
        _extractByLabels(lines, const ['issuing authority', 'authority']) ??
        country;
    final issueDate = _findDateByLabels(
      lines: lines,
      labels: const ['issue date', 'issued', 'date of issue'],
      blockedKeywords: const [],
      fallbackDates: const [],
      preferPast: true,
    );
    final categories = _extractByLabels(lines, const [
      'categories',
      'class',
      'vehicle class',
    ]);

    final fields = <Map<String, String>>[
      {'label': 'License Number', 'value': number ?? ''},
      if ((categories ?? '').trim().isNotEmpty)
        {'label': 'Categories', 'value': categories!.trim()},
      if (authority.isNotEmpty)
        {'label': 'Issuing Authority', 'value': authority},
      if (issueDate != null)
        {'label': 'Issue Date', 'value': _formatDate(issueDate)},
      if (expiryDate != null)
        {'label': 'Expiry Date', 'value': _formatDate(expiryDate)},
      if (birthDate != null)
        {'label': 'Birth Date', 'value': _formatDate(birthDate)},
    ];

    final confidence = _scoreConfidence(
      detectedIdType: detectedIdType,
      expected: DocumentType.driversLicense,
      tokens: <String?>[number, authority, categories],
      dates: <DateTime?>[issueDate, expiryDate],
    );

    return DocumentAutoFillSuggestion(
      issuer: authority.isNotEmpty ? authority : "Driver's License",
      identifierLabel: 'License Number',
      identifierValue: number ?? '',
      expiryDate: expiryDate,
      birthDate: birthDate,
      structuredFields: fields.where(_isNonEmptyField).toList(growable: false),
      tags: const ['Driving', 'ID', 'Essential'],
      rawText: text,
      detectedIdType: detectedIdType,
      confidence: confidence,
    );
  }

  DocumentAutoFillSuggestion _buildOther({
    required List<String> lines,
    required String text,
    required String country,
    required DateTime? birthDate,
    required DateTime? expiryDate,
    required ScannedIdType detectedIdType,
  }) {
    final idValue =
        _extractByLabels(lines, const [
          'document id',
          'reference',
          'id number',
          'number',
        ]) ??
        _extractDocumentToken(text);

    final fields = <Map<String, String>>[
      {'label': 'Document ID', 'value': idValue ?? ''},
      if (country.isNotEmpty) {'label': 'Country', 'value': country},
      if (birthDate != null)
        {'label': 'Birth Date', 'value': _formatDate(birthDate)},
      if (expiryDate != null)
        {'label': 'Expiry Date', 'value': _formatDate(expiryDate)},
    ];

    final confidence = _scoreConfidence(
      detectedIdType: detectedIdType,
      expected: DocumentType.other,
      tokens: <String?>[idValue, country],
      dates: <DateTime?>[birthDate, expiryDate],
    );

    return DocumentAutoFillSuggestion(
      issuer: country.isNotEmpty ? country : 'Document',
      identifierLabel: 'Document ID',
      identifierValue: idValue ?? '',
      expiryDate: expiryDate,
      birthDate: birthDate,
      structuredFields: fields.where(_isNonEmptyField).toList(growable: false),
      tags: const ['Document'],
      rawText: text,
      detectedIdType: detectedIdType,
      confidence: confidence,
    );
  }

  String? _extractCountry(List<String> lines) {
    for (final line in lines) {
      final resolved = _resolveCountryFromRawValue(line);
      if (resolved != null) {
        return resolved;
      }
    }
    return null;
  }

  String? _resolveCountryFromRawValue(String? rawValue) {
    final normalized = _normalizeWords(rawValue ?? '');
    if (normalized.isEmpty) {
      return null;
    }

    final exact = _countryAliases[normalized];
    if (exact != null) {
      return exact;
    }

    final tokens = normalized
        .split(' ')
        .map((token) => token.trim())
        .where((token) => token.isNotEmpty)
        .toList(growable: false);
    for (final token in tokens) {
      final directToken = _countryAliases[token];
      if (directToken != null) {
        return directToken;
      }
    }

    for (final entry in _countryAliases.entries) {
      final alias = _normalizeWords(entry.key);
      if (_containsLabelToken(normalized, alias)) {
        return entry.value;
      }
    }
    return null;
  }

  String? _extractCountryNearLabels(List<String> lines, List<String> labels) {
    for (var index = 0; index < lines.length; index++) {
      final normalizedLine = _normalizeWords(lines[index]);
      if (!_lineHasAnyLabel(normalizedLine, labels)) {
        continue;
      }

      final candidateIndexes = <int>[index, index + 1, index + 2, index - 1];
      for (final candidateIndex in candidateIndexes) {
        if (candidateIndex < 0 || candidateIndex >= lines.length) {
          continue;
        }
        final resolved = _resolveCountryFromRawValue(lines[candidateIndex]);
        if (resolved != null) {
          return resolved;
        }
      }
    }
    return null;
  }

  String? _extractSex(List<String> lines) {
    final explicit = _extractByLabels(lines, const ['sex', 'gender']);
    final normalizedExplicit = (explicit ?? '').trim().toLowerCase();
    if (normalizedExplicit == 'm' || normalizedExplicit == 'male') {
      return 'M';
    }
    if (normalizedExplicit == 'f' || normalizedExplicit == 'female') {
      return 'F';
    }

    for (final line in lines) {
      final normalized = _normalizeWords(line);
      if (!normalized.contains('sex') && !normalized.contains('gender')) {
        continue;
      }
      final tokenMatch = RegExp(
        r'\b(m|f|male|female)\b',
      ).firstMatch(normalized);
      if (tokenMatch == null) {
        continue;
      }
      final token = tokenMatch.group(1) ?? '';
      if (token == 'm' || token == 'male') {
        return 'M';
      }
      if (token == 'f' || token == 'female') {
        return 'F';
      }
    }
    return null;
  }

  String? _extractByLabels(List<String> lines, List<String> labels) {
    for (var index = 0; index < lines.length; index++) {
      final line = lines[index];
      final normalizedLine = _normalizeWords(line);
      if (!_lineHasAnyLabel(normalizedLine, labels)) {
        continue;
      }

      final valueFromLine = _extractValueFromLabelLine(
        line: line,
        labels: labels,
      );
      if ((valueFromLine ?? '').trim().isNotEmpty) {
        return valueFromLine;
      }

      if (index + 1 < lines.length) {
        final nextLine = lines[index + 1];
        final normalizedNext = _normalizeWords(nextLine);
        if (!_lineHasAnyLabel(normalizedNext, labels)) {
          final nextValue = _safeValue(nextLine);
          if (nextValue.isNotEmpty && !_looksLikeLabelOnlyLine(nextValue)) {
            return nextValue;
          }
        }
      }
    }
    return null;
  }

  String? _extractValueFromLabelLine({
    required String line,
    required List<String> labels,
  }) {
    final separatorMatch = RegExp(r'[:\-]\s*(.+)$').firstMatch(line);
    if (separatorMatch != null) {
      final value = _safeValue(separatorMatch.group(1) ?? '');
      if (value.isNotEmpty && !_looksLikeLabelOnlyLine(value)) {
        return value;
      }
    }

    var normalized = _normalizeWords(line);
    if (normalized.isEmpty) {
      return null;
    }

    for (final label in labels) {
      final normalizedLabel = _normalizeWords(label);
      if (normalizedLabel.isEmpty) {
        continue;
      }
      final pattern = RegExp(
        r'(^|\s)' + RegExp.escape(normalizedLabel) + r'(\s|$)',
      );
      normalized = normalized.replaceAll(pattern, ' ');
    }

    final candidate = _safeValue(normalized);
    if (candidate.isEmpty || _looksLikeLabelOnlyLine(candidate)) {
      return null;
    }
    return candidate;
  }

  bool _looksLikeLabelOnlyLine(String value) {
    final normalized = _normalizeWords(value);
    if (normalized.isEmpty) {
      return true;
    }
    return normalized.startsWith('date de') ||
        normalized.startsWith('date of') ||
        normalized.contains('birth date') ||
        normalized.contains('nationality') ||
        normalized.contains('nationalite') ||
        normalized.contains('number');
  }

  String? _extractNumericIdentifierNearLabels(List<String> lines) {
    const labels = <String>[
      'personal number',
      'numero personnel',
      'numéro personnel',
      'numero national',
      'numéro national',
      'id number',
      'identity number',
      'document number',
    ];

    for (var index = 0; index < lines.length; index++) {
      final normalizedLine = _normalizeWords(lines[index]);
      if (!_lineHasAnyLabel(normalizedLine, labels)) {
        continue;
      }

      final windowIndexes = <int>[index, index + 1, index + 2, index - 1];
      for (final candidateIndex in windowIndexes) {
        if (candidateIndex < 0 || candidateIndex >= lines.length) {
          continue;
        }
        final value = _extractBestIdentifierFromText(
          lines[candidateIndex],
          preferNumeric: true,
        );
        if ((value ?? '').isNotEmpty) {
          return value;
        }
      }
    }
    return null;
  }

  String? _extractNameFromResidencePermit(List<String> lines) {
    const residenceNameLabels = <String>[
      'noms prenoms',
      'surnames forenames',
      'surname forenames',
      'full name',
      'name',
    ];

    for (var index = 0; index < lines.length; index++) {
      final normalizedLine = _normalizeWords(lines[index]);
      if (!_lineHasAnyLabel(normalizedLine, residenceNameLabels)) {
        continue;
      }

      final names = <String>[];
      for (
        var candidateIndex = index + 1;
        candidateIndex < lines.length && candidateIndex <= index + 4;
        candidateIndex++
      ) {
        final candidate = _safeValue(
          lines[candidateIndex].replaceAll('*', ' '),
        );
        if (!_looksLikeNameLine(candidate)) {
          continue;
        }
        names.add(_normalizePersonName(candidate));
        if (names.length >= 2) {
          break;
        }
      }

      if (names.isNotEmpty) {
        return names.join(' ').trim();
      }
    }
    return null;
  }

  bool _looksLikeNameLine(String value) {
    final normalized = _normalizeWords(value);
    if (normalized.isEmpty) {
      return false;
    }
    if (RegExp(r'\d').hasMatch(normalized)) {
      return false;
    }
    if (normalized.length < 2 || normalized.length > 40) {
      return false;
    }
    if (normalized.contains('residence permit') ||
        normalized.contains('titre de sejour') ||
        normalized.contains('carte de sejour') ||
        normalized.contains('birth date') ||
        normalized.contains('nationalite') ||
        normalized.contains('nationality') ||
        normalized.contains('numero personnel') ||
        normalized.contains('personal number')) {
      return false;
    }
    final words = normalized.split(' ').where((word) => word.isNotEmpty);
    return words.isNotEmpty && words.length <= 4;
  }

  String _normalizePersonName(String value) {
    final cleaned = value
        .replaceAll('*', ' ')
        .replaceAll(RegExp(r'[^A-Za-zÀ-ÿ\-\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (cleaned.isEmpty) {
      return '';
    }

    final words = cleaned.split(' ').where((word) => word.isNotEmpty).map((
      word,
    ) {
      final lower = word.toLowerCase();
      return lower[0].toUpperCase() + lower.substring(1);
    });
    return words.join(' ');
  }

  String? _extractLikelyName(List<String> lines) {
    for (final line in lines) {
      final value = line.trim();
      if (value.length < 6 || value.length > 42) {
        continue;
      }
      if (value.contains(':')) {
        continue;
      }
      if (RegExp(r'\d').hasMatch(value)) {
        continue;
      }
      final normalized = _normalizeWords(value);
      if (normalized.contains('residence permit') ||
          normalized.contains('titre de sejour') ||
          normalized.contains('carte de sejour') ||
          normalized.contains('passport') ||
          normalized.contains('identity card') ||
          normalized.contains('id card')) {
        continue;
      }
      final words = value.split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
      if (words.length < 2 || words.length > 4) {
        continue;
      }
      return _normalizePersonName(value);
    }
    return null;
  }

  String? _extractBestIdentifierFromText(
    String text, {
    bool preferNumeric = false,
  }) {
    final candidates = RegExp(r'\b[A-Z0-9][A-Z0-9\-]{5,24}\b')
        .allMatches(text.toUpperCase())
        .map((match) => match.group(0) ?? '')
        .where((value) => value.isNotEmpty)
        .where((value) => RegExp(r'\d').hasMatch(value))
        .where((value) => parseLooseDate(value) == null)
        .toList(growable: false);
    if (candidates.isEmpty) {
      return null;
    }

    final sorted = [...candidates]
      ..sort((a, b) {
        var aScore = _identifierScore(a);
        var bScore = _identifierScore(b);
        if (preferNumeric) {
          if (RegExp(r'^\d+$').hasMatch(a)) {
            aScore += 12;
          }
          if (RegExp(r'^\d+$').hasMatch(b)) {
            bScore += 12;
          }
        }
        return bScore.compareTo(aScore);
      });
    return sorted.first;
  }

  String? _extractDocumentToken(String text) {
    return _extractBestIdentifierFromText(text);
  }

  int _identifierScore(String value) {
    final hasDash = value.contains('-') ? 2 : 0;
    final alphaCount = RegExp(r'[A-Z]').allMatches(value).length;
    final digitCount = RegExp(r'\d').allMatches(value).length;
    final isPureNumeric = RegExp(r'^\d+$').hasMatch(value);
    final parsedAsDate = isPureNumeric ? parseLooseDate(value) : null;
    final datePenalty = parsedAsDate != null ? -18 : 0;
    final pureNumericBoost = isPureNumeric ? 4 : 0;
    return hasDash + alphaCount + digitCount + pureNumericBoost + datePenalty;
  }

  DateTime? _findDateByLabels({
    required List<String> lines,
    required List<String> labels,
    required List<String> blockedKeywords,
    required List<DateTime> fallbackDates,
    required bool preferPast,
    int maxLineOffset = 4,
  }) {
    final now = DateTime.now();
    DateTime? bestDate;
    double bestScore = -1;

    bool hasBlockedKeyword(String line) {
      final lower = line.toLowerCase();
      return blockedKeywords.any(lower.contains);
    }

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final normalizedLine = _normalizeWords(line);
      final foundLabel = _lineHasAnyLabel(normalizedLine, labels);
      if (!foundLabel || hasBlockedKeyword(normalizedLine)) {
        continue;
      }

      void considerLine(String candidateLine, double score) {
        final candidates = _extractDatesFromText(candidateLine)
            .where((date) => _isDateValidForContext(date, now, preferPast))
            .toList(growable: false);
        if (candidates.isEmpty) {
          return;
        }

        candidates.sort((a, b) => a.compareTo(b));
        final selected = preferPast ? candidates.first : candidates.last;
        final weighted = score + _dateContextBonus(selected, now, preferPast);
        if (weighted > bestScore) {
          bestScore = weighted;
          bestDate = selected;
        }
      }

      considerLine(line, 1.0);
      for (var offset = 1; offset <= maxLineOffset; offset++) {
        final next = i + offset;
        final prev = i - offset;
        final score = 1.0 - (offset * 0.18);
        if (next < lines.length) {
          considerLine(lines[next], score);
        }
        if (prev >= 0) {
          considerLine(lines[prev], score);
        }
      }
    }

    if (bestDate != null) {
      return bestDate;
    }

    if (fallbackDates.isEmpty) {
      return null;
    }

    if (preferPast) {
      final pastDates = fallbackDates.where((d) => d.isBefore(now)).toList();
      if (pastDates.isNotEmpty) {
        pastDates.sort((a, b) => a.compareTo(b));
        return pastDates.first;
      }
      fallbackDates.sort((a, b) => a.compareTo(b));
      return fallbackDates.first;
    }

    final futureDates = fallbackDates.where((d) => !d.isBefore(now)).toList();
    if (futureDates.isNotEmpty) {
      futureDates.sort((a, b) => a.compareTo(b));
      return futureDates.first;
    }

    fallbackDates.sort((a, b) => a.compareTo(b));
    return fallbackDates.last;
  }

  bool _isDateValidForContext(DateTime date, DateTime now, bool preferPast) {
    if (date.year < 1900 || date.isAfter(now.add(const Duration(days: 3650)))) {
      return false;
    }
    if (preferPast) {
      return date.isBefore(now.subtract(const Duration(days: 365 * 8)));
    }
    return date.isAfter(now.subtract(const Duration(days: 365 * 30)));
  }

  double _dateContextBonus(DateTime date, DateTime now, bool preferPast) {
    if (preferPast) {
      final ageYears = now.year - date.year;
      if (ageYears >= 12 && ageYears <= 110) {
        return min(ageYears / 200.0, 0.18);
      }
      return 0;
    }

    final yearDelta = date.year - now.year;
    if (yearDelta >= 0) {
      return min(yearDelta / 20.0 + 0.06, 0.2);
    }
    if (yearDelta >= -15) {
      return 0.05;
    }
    return -0.05;
  }

  List<DateTime> _extractAllDates(String text) {
    final values = <DateTime>[];
    final seen = <String>{};
    for (final line in text.split('\n')) {
      for (final date in _extractDatesFromText(line)) {
        final key = DateFormat('yyyy-MM-dd').format(date);
        if (seen.add(key)) {
          values.add(date);
        }
      }
    }
    return values;
  }

  List<DateTime> _extractDatesFromText(String line) {
    final values = <DateTime>[];
    final seen = <String>{};

    for (final match in _dateTokenPattern.allMatches(line)) {
      final token = match.group(0) ?? '';
      if (token.trim().isEmpty) {
        continue;
      }
      final parsed = parseLooseDate(token);
      if (parsed == null) {
        continue;
      }
      final key = DateFormat('yyyy-MM-dd').format(parsed);
      if (seen.add(key)) {
        values.add(parsed);
      }
    }

    final wholeLineDate = parseLooseDate(line);
    if (wholeLineDate != null) {
      final key = DateFormat('yyyy-MM-dd').format(wholeLineDate);
      if (seen.add(key)) {
        values.add(wholeLineDate);
      }
    }

    return values;
  }

  bool _lineHasAnyLabel(String normalizedLine, List<String> labels) {
    for (final label in labels) {
      if (_lineHasLabel(normalizedLine, label)) {
        return true;
      }
    }
    return false;
  }

  bool _lineHasLabel(String normalizedLine, String label) {
    final normalizedLabel = _normalizeWords(label);
    if (normalizedLabel.isEmpty) {
      return false;
    }
    return _containsLabelToken(normalizedLine, normalizedLabel) ||
        _fuzzyContainsLabel(normalizedLine, normalizedLabel);
  }

  bool _containsLabelToken(String normalizedLine, String normalizedLabel) {
    if (normalizedLine.isEmpty || normalizedLabel.isEmpty) {
      return false;
    }
    final pattern = RegExp(
      r'(^|\s)' + RegExp.escape(normalizedLabel) + r'(\s|$)',
    );
    return pattern.hasMatch(normalizedLine);
  }

  bool _fuzzyContainsLabel(
    String normalizedLine,
    String normalizedLabel, {
    int maxDistance = 2,
  }) {
    if (normalizedLabel.isEmpty ||
        normalizedLine.length < normalizedLabel.length) {
      return false;
    }

    for (
      var start = 0;
      start <= normalizedLine.length - normalizedLabel.length;
      start++
    ) {
      final segment = normalizedLine.substring(
        start,
        start + normalizedLabel.length,
      );
      final distance = _levenshteinDistance(segment, normalizedLabel);
      if (normalizedLabel.length <= 3 && distance != 0) {
        continue;
      }
      if (distance <= maxDistance) {
        final hasLeftBoundary =
            start == 0 || !RegExp(r'[a-z]').hasMatch(normalizedLine[start - 1]);
        final rightIndex = start + normalizedLabel.length;
        final hasRightBoundary =
            rightIndex == normalizedLine.length ||
            !RegExp(r'[a-z]').hasMatch(normalizedLine[rightIndex]);
        if (hasLeftBoundary && hasRightBoundary) {
          return true;
        }
      }
    }
    return false;
  }

  int _levenshteinDistance(String a, String b) {
    final rows = a.length + 1;
    final cols = b.length + 1;
    final dp = List<List<int>>.generate(rows, (_) => List<int>.filled(cols, 0));

    for (var i = 0; i < rows; i++) {
      dp[i][0] = i;
    }
    for (var j = 0; j < cols; j++) {
      dp[0][j] = j;
    }

    for (var i = 1; i < rows; i++) {
      for (var j = 1; j < cols; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        dp[i][j] = min(
          dp[i - 1][j] + 1,
          min(dp[i][j - 1] + 1, dp[i - 1][j - 1] + cost),
        );
      }
    }

    return dp[a.length][b.length];
  }

  double _scoreConfidence({
    required ScannedIdType detectedIdType,
    required DocumentType expected,
    required List<String?> tokens,
    required List<DateTime?> dates,
  }) {
    var score = 0.15;
    for (final token in tokens) {
      if ((token ?? '').trim().isNotEmpty) {
        score += 0.16;
      }
    }
    for (final date in dates) {
      if (date != null) {
        score += 0.14;
      }
    }
    if (_matchesType(detectedIdType, expected)) {
      score += 0.2;
    } else if (detectedIdType != ScannedIdType.unknown) {
      score += 0.06;
    }

    if (score > 1) {
      return 1;
    }
    return score;
  }

  bool _matchesType(ScannedIdType scanned, DocumentType expected) {
    return switch (expected) {
      DocumentType.passport => scanned == ScannedIdType.passport,
      DocumentType.idCard =>
        scanned == ScannedIdType.idCard ||
            scanned == ScannedIdType.residencePermit ||
            scanned == ScannedIdType.studentId ||
            scanned == ScannedIdType.disabilityCard ||
            scanned == ScannedIdType.proofOfAgeCard,
      DocumentType.driversLicense => scanned == ScannedIdType.driversLicense,
      DocumentType.other => true,
    };
  }

  bool _isNonEmptyField(Map<String, String> field) {
    return (field['label'] ?? '').trim().isNotEmpty &&
        (field['value'] ?? '').trim().isNotEmpty;
  }

  String _formatDate(DateTime value) {
    return DateFormat('dd MMM yyyy').format(value);
  }

  String _normalizeWords(String value) {
    return value
        .toLowerCase()
        .replaceAll("'", ' ')
        .replaceAll(RegExp(r'[^a-z0-9À-ÿ\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _safeValue(String value) {
    return value
        .replaceAll(RegExp(r'[^A-Za-z0-9À-ÿ\-/\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static DateTime? parseLooseDate(String raw, {DateTime? now}) {
    final current = now ?? DateTime.now();
    final text = raw.trim();
    if (text.isEmpty) {
      return null;
    }

    final special = _extractSpecialFormatDate(text, current);
    if (special != null) {
      return special;
    }

    final direct = _parseDateToken(text, current);
    if (direct != null) {
      return direct;
    }

    for (final match in _dateTokenPattern.allMatches(text)) {
      final token = match.group(0) ?? '';
      final parsed = _parseDateToken(token, current);
      if (parsed != null) {
        return parsed;
      }
    }

    return null;
  }

  static DateTime? _extractSpecialFormatDate(String text, DateTime now) {
    final pattern = RegExp(
      r'(\d{1,2})[\s\/\-]*([A-Za-zÀ-ÿ]{3,6})(?:[\s\/\-]*([A-Za-zÀ-ÿ]{3,6}))?[\s\/\-]*(\d{2})\b',
      caseSensitive: false,
    );
    final match = pattern.firstMatch(text);
    if (match == null) {
      return null;
    }

    final day = int.tryParse(match.group(1) ?? '');
    final monthToken = (match.group(2) ?? '').toLowerCase();
    final extraMonthToken = (match.group(3) ?? '').toLowerCase();
    final yearSuffix = int.tryParse(match.group(4) ?? '');
    if (day == null || yearSuffix == null) {
      return null;
    }

    final month = _monthFromToken(monthToken);
    if (month == null) {
      return null;
    }

    if (extraMonthToken.isNotEmpty) {
      final secondMonth = _monthFromToken(extraMonthToken);
      if (secondMonth == null || secondMonth != month) {
        return null;
      }
    }

    final year = yearSuffix < 50 ? 2000 + yearSuffix : 1900 + yearSuffix;
    final parsed = _safeDate(year: year, month: month, day: day);
    if (parsed == null) {
      return null;
    }
    if (parsed.isAfter(now.add(const Duration(days: 3650)))) {
      return null;
    }
    return parsed;
  }

  static int? _monthFromToken(String token) {
    final normalized = token.trim().toLowerCase();
    if (normalized.isEmpty) {
      return null;
    }
    if (normalized.length == 6) {
      final left = normalized.substring(0, 3);
      final right = normalized.substring(3);
      final leftMonth = _monthLookup[left];
      final rightMonth = _monthLookup[right];
      if (leftMonth != null && leftMonth == rightMonth) {
        return leftMonth;
      }
    }
    return _monthLookup[normalized];
  }

  static DateTime? _parseDateToken(String token, DateTime now) {
    final value = token
        .trim()
        .replaceAll(RegExp(r'[^A-Za-z0-9/.\-\sÀ-ÿ]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ');
    if (value.isEmpty) {
      return null;
    }

    final yearFirst = RegExp(
      r'^(\d{4})[\/\-.](\d{1,2})[\/\-.](\d{1,2})$',
    ).firstMatch(value);
    if (yearFirst != null) {
      final year = int.tryParse(yearFirst.group(1) ?? '');
      final month = int.tryParse(yearFirst.group(2) ?? '');
      final day = int.tryParse(yearFirst.group(3) ?? '');
      final parsed = _safeDate(year: year, month: month, day: day);
      if (_isReasonableDate(parsed, now)) {
        return parsed;
      }
    }

    final dayFirst = RegExp(
      r'^(\d{1,2})[\/\-.](\d{1,2})[\/\-.](\d{2,4})$',
    ).firstMatch(value);
    if (dayFirst != null) {
      var year = int.tryParse(dayFirst.group(3) ?? '');
      final first = int.tryParse(dayFirst.group(1) ?? '');
      final second = int.tryParse(dayFirst.group(2) ?? '');
      if (year != null && year < 100) {
        year = year < 50 ? 2000 + year : 1900 + year;
      }
      if (year != null && first != null && second != null) {
        final asDayFirst = _safeDate(year: year, month: second, day: first);
        if (_isReasonableDate(asDayFirst, now)) {
          return asDayFirst;
        }
        final asMonthFirst = _safeDate(year: year, month: first, day: second);
        if (_isReasonableDate(asMonthFirst, now)) {
          return asMonthFirst;
        }
      }
    }

    final spacedNumeric = RegExp(
      r'^(\d{1,2})\s+(\d{1,2})\s+(\d{2,4})$',
    ).firstMatch(value);
    if (spacedNumeric != null) {
      var year = int.tryParse(spacedNumeric.group(3) ?? '');
      final day = int.tryParse(spacedNumeric.group(1) ?? '');
      final month = int.tryParse(spacedNumeric.group(2) ?? '');
      if (year != null && year < 100) {
        year = year < 50 ? 2000 + year : 1900 + year;
      }
      final parsed = _safeDate(year: year, month: month, day: day);
      if (_isReasonableDate(parsed, now)) {
        return parsed;
      }
    }

    final monthWord = RegExp(
      r'^(\d{1,2})\s+([A-Za-zÀ-ÿ]{3,10})\s+(\d{2,4})$',
      caseSensitive: false,
    ).firstMatch(value);
    if (monthWord != null) {
      final day = int.tryParse(monthWord.group(1) ?? '');
      final month = _monthFromToken(monthWord.group(2) ?? '');
      var year = int.tryParse(monthWord.group(3) ?? '');
      if (year != null && year < 100) {
        year = year < 50 ? 2000 + year : 1900 + year;
      }
      final parsed = _safeDate(year: year, month: month, day: day);
      if (_isReasonableDate(parsed, now)) {
        return parsed;
      }
    }

    final compact = RegExp(r'^(\d{2})(\d{2})(\d{4})$').firstMatch(value);
    if (compact != null) {
      final day = int.tryParse(compact.group(1) ?? '');
      final month = int.tryParse(compact.group(2) ?? '');
      final year = int.tryParse(compact.group(3) ?? '');
      final parsed = _safeDate(year: year, month: month, day: day);
      if (_isReasonableDate(parsed, now)) {
        return parsed;
      }
    }

    const formatterPatterns = <String>[
      'dd/MM/yyyy',
      'dd-MM-yyyy',
      'dd.MM.yyyy',
      'yyyy/MM/dd',
      'yyyy-MM-dd',
      'dd/MM/yy',
      'dd-MM-yy',
      'dd MMM yyyy',
      'dd MMM yy',
      'dd MMMM yyyy',
    ];

    for (final pattern in formatterPatterns) {
      try {
        final parsed = DateFormat(pattern).parseStrict(value);
        if (_isReasonableDate(parsed, now)) {
          return parsed;
        }
      } catch (_) {
        // Expected: trying multiple date formats — move to next pattern.
      }
    }

    return null;
  }

  static bool _isReasonableDate(DateTime? date, DateTime now) {
    if (date == null) {
      return false;
    }
    if (date.year < 1900) {
      return false;
    }
    if (date.isAfter(now.add(const Duration(days: 3650)))) {
      return false;
    }
    return true;
  }

  static DateTime? _safeDate({
    required int? year,
    required int? month,
    required int? day,
  }) {
    if (year == null || month == null || day == null) {
      return null;
    }
    try {
      final parsed = DateTime(year, month, day);
      if (parsed.year != year || parsed.month != month || parsed.day != day) {
        return null;
      }
      return parsed;
    } catch (_) {
      return null;
    }
  }
}
