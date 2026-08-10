import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:pass_doc_manager/data/credentials/datasources/local/credential_local_data_source.dart';
import 'package:pass_doc_manager/data/documents/datasources/local/document_local_data_source.dart';
import 'package:pass_doc_manager/domain/vault_health/entities/vault_health_grade.dart';
import 'package:pass_doc_manager/domain/vault_health/entities/vault_health_issue_entity.dart';
import 'package:pass_doc_manager/domain/vault_health/entities/vault_health_issue_severity.dart';
import 'package:pass_doc_manager/domain/vault_health/entities/vault_health_issue_type.dart';
import 'package:pass_doc_manager/domain/vault_health/entities/vault_health_report_entity.dart';
import 'package:pass_doc_manager/domain/vault_health/repositories/vault_health_repository.dart';

class VaultHealthRepositoryImpl implements VaultHealthRepository {
  VaultHealthRepositoryImpl({
    required CredentialLocalDataSource credentialDataSource,
    required DocumentLocalDataSource documentDataSource,
  })  : _credentialDataSource = credentialDataSource,
        _documentDataSource = documentDataSource,
        _dio = Dio();

  final CredentialLocalDataSource _credentialDataSource;
  final DocumentLocalDataSource _documentDataSource;
  final Dio _dio;

  @override
  Future<VaultHealthReportEntity> evaluateVaultHealth() async {
    final credentials = await _credentialDataSource.getCredentialSummaries();
    final documents = await _documentDataSource.getDocuments();

    var score = 100;
    final issues = <VaultHealthIssueEntity>[];

    int weakPasswordCount = 0;
    int reusedPasswordCount = 0;
    int noMfaCount = 0;
    int breachedCount = 0;
    int expiringDocuments30 = 0;
    int expiringDocuments60 = 0;
    int expiringDocuments90 = 0;
    int expiredDocuments = 0;

    final allPasswords = <String>[];
    for (final credential in credentials) {
      final detailDto = await _credentialDataSource.getCredentialDetailById(
        id: credential.id,
      );
      allPasswords.add(detailDto.password);
    }

    for (final credential in credentials) {
      final detailDto = await _credentialDataSource.getCredentialDetailById(
        id: credential.id,
      );

      if (!detailDto.isSecure) {
        weakPasswordCount++;
        issues.add(
          VaultHealthIssueEntity(
            type: VaultHealthIssueType.weakPassword,
            severity: VaultHealthIssueSeverity.high,
            title: 'Weak Password',
            description:
                'The password for ${detailDto.serviceName} is weak and should be updated.',
            itemId: detailDto.id,
            itemName: detailDto.serviceName,
          ),
        );
        score -= 5;
      }

      final passwordCount =
          allPasswords.where((p) => p == detailDto.password).length;
      if (passwordCount > 1) {
        reusedPasswordCount++;
        issues.add(
          VaultHealthIssueEntity(
            type: VaultHealthIssueType.reusedPassword,
            severity: VaultHealthIssueSeverity.high,
            title: 'Reused Password',
            description:
                'The password for ${detailDto.serviceName} is reused across multiple accounts.',
            itemId: detailDto.id,
            itemName: detailDto.serviceName,
          ),
        );
        score -= 5;
      }

      if (detailDto.mfaRecovery.trim().isEmpty ||
          detailDto.mfaRecovery.trim() == 'Not set') {
        noMfaCount++;
        issues.add(
          VaultHealthIssueEntity(
            type: VaultHealthIssueType.noMfa,
            severity: VaultHealthIssueSeverity.medium,
            title: 'No MFA Recovery Set',
            description:
                'Multi-factor authentication recovery codes are not set for ${detailDto.serviceName}.',
            itemId: detailDto.id,
            itemName: detailDto.serviceName,
          ),
        );
        score -= 2;
      }

      if (detailDto.breachedCount > 0) {
        breachedCount++;
        issues.add(
          VaultHealthIssueEntity(
            type: VaultHealthIssueType.breachedCredential,
            severity: VaultHealthIssueSeverity.critical,
            title: 'Breached Credential',
            description:
                'The password for ${detailDto.serviceName} has been found in ${detailDto.breachedCount} data breach(es). Change it immediately.',
            itemId: detailDto.id,
            itemName: detailDto.serviceName,
          ),
        );
        score -= 10;
      } else {
        final hibpBreachCount = await _checkHibpBreach(detailDto.password);
        if (hibpBreachCount > 0) {
          breachedCount++;
          issues.add(
            VaultHealthIssueEntity(
              type: VaultHealthIssueType.breachedCredential,
              severity: VaultHealthIssueSeverity.critical,
              title: 'Breached Credential',
              description:
                  'The password for ${detailDto.serviceName} has been found in $hibpBreachCount data breach(es). Change it immediately.',
              itemId: detailDto.id,
              itemName: detailDto.serviceName,
            ),
          );
          score -= 10;
        }
      }
    }

    final now = DateTime.now();
    final thirtyDaysFromNow = now.add(const Duration(days: 30));
    final sixtyDaysFromNow = now.add(const Duration(days: 60));
    final ninetyDaysFromNow = now.add(const Duration(days: 90));

    for (final document in documents) {
      final expiryDate = DateTime.tryParse(document.expiryAtIso);
      if (expiryDate == null || expiryDate.year == 1900) {
        continue;
      }

      if (expiryDate.isBefore(now)) {
        expiredDocuments++;
        issues.add(
          VaultHealthIssueEntity(
            type: VaultHealthIssueType.expiredDocument,
            severity: VaultHealthIssueSeverity.critical,
            title: 'Expired Document',
            description: 'The document "${document.title}" has expired.',
            itemId: document.id,
            itemName: document.title,
          ),
        );
        score -= 3;
      } else if (expiryDate.isBefore(thirtyDaysFromNow)) {
        expiringDocuments30++;
        issues.add(
          VaultHealthIssueEntity(
            type: VaultHealthIssueType.expiringDocument,
            severity: VaultHealthIssueSeverity.high,
            title: 'Expires Soon (30 days)',
            description:
                'The document "${document.title}" expires in less than 30 days.',
            itemId: document.id,
            itemName: document.title,
          ),
        );
        score -= 1;
      } else if (expiryDate.isBefore(sixtyDaysFromNow)) {
        expiringDocuments60++;
        issues.add(
          VaultHealthIssueEntity(
            type: VaultHealthIssueType.expiringDocument,
            severity: VaultHealthIssueSeverity.medium,
            title: 'Expires Soon (60 days)',
            description:
                'The document "${document.title}" expires in less than 60 days.',
            itemId: document.id,
            itemName: document.title,
          ),
        );
        score -= 1;
      } else if (expiryDate.isBefore(ninetyDaysFromNow)) {
        expiringDocuments90++;
      }
    }

    score = score.clamp(0, 100);

    final grade = _calculateGrade(score);

    issues.sort((a, b) {
      final severityOrder = {
        VaultHealthIssueSeverity.critical: 0,
        VaultHealthIssueSeverity.high: 1,
        VaultHealthIssueSeverity.medium: 2,
        VaultHealthIssueSeverity.low: 3,
      };
      return (severityOrder[a.severity] ?? 4)
          .compareTo(severityOrder[b.severity] ?? 4);
    });

    return VaultHealthReportEntity(
      overallScore: score,
      grade: grade,
      issues: issues,
      totalCredentials: credentials.length,
      weakPasswordCount: weakPasswordCount,
      reusedPasswordCount: reusedPasswordCount,
      noMfaCount: noMfaCount,
      breachedCount: breachedCount,
      expiringDocuments30: expiringDocuments30,
      expiringDocuments60: expiringDocuments60,
      expiringDocuments90: expiringDocuments90,
      expiredDocuments: expiredDocuments,
      checkedAt: DateTime.now(),
    );
  }

  Future<int> _checkHibpBreach(String password) async {
    try {
      final bytes = utf8.encode(password);
      final digest = _sha1(bytes);
      final hashHex = digest.toUpperCase();
      final prefix = hashHex.substring(0, 5);
      final suffix = hashHex.substring(5);

      final response = await _dio.get(
        'https://api.pwnedpasswords.com/range/$prefix',
        options: Options(
          receiveTimeout: const Duration(seconds: 10),
          sendTimeout: const Duration(seconds: 10),
          connectTimeout: const Duration(seconds: 10),
        ),
      );

      if (response.statusCode == 200) {
        final body = response.data as String;
        final lines = body.split('\n');

        for (final line in lines) {
          final parts = line.trim().split(':');
          if (parts.isNotEmpty) {
            final hashSuffix = parts[0].toUpperCase();
            if (hashSuffix == suffix) {
              final count = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
              return count;
            }
          }
        }
      }
    } catch (e) {
      return 0;
    }

    return 0;
  }

  VaultHealthGrade _calculateGrade(int score) {
    if (score >= 80) {
      return VaultHealthGrade.excellent;
    } else if (score >= 60) {
      return VaultHealthGrade.good;
    } else if (score >= 40) {
      return VaultHealthGrade.fair;
    } else {
      return VaultHealthGrade.poor;
    }
  }

  String _sha1(List<int> bytes) {
    const String table = '0123456789abcdef';
    var acc = StringBuffer();
    for (final byte in _sha1Digest(bytes)) {
      acc.write('${table[(byte >> 4) & 0xf]}${table[byte & 0xf]}');
    }
    return acc.toString();
  }

  List<int> _sha1Digest(List<int> input) {
    final h0 = 0x67452301;
    final h1 = 0xEFCDAB89;
    final h2 = 0x98BADCFE;
    final h3 = 0x10325476;
    final h4 = 0xC3D2E1F0;

    final msg = _preprocessMessage(input);

    var a = h0;
    var b = h1;
    var c = h2;
    var d = h3;
    var e = h4;

    for (var i = 0; i < msg.length; i += 16) {
      final w = List<int>.filled(80, 0);

      for (var j = 0; j < 16; j++) {
        w[j] = (msg[i + j * 4] << 24) |
            (msg[i + j * 4 + 1] << 16) |
            (msg[i + j * 4 + 2] << 8) |
            msg[i + j * 4 + 3];
      }

      for (var j = 16; j < 80; j++) {
        w[j] = _leftrotate(
            w[j - 3] ^ w[j - 8] ^ w[j - 14] ^ w[j - 16], 1);
      }

      var aa = a;
      var bb = b;
      var cc = c;
      var dd = d;
      var ee = e;

      for (var j = 0; j < 80; j++) {
        final f = j < 20
            ? (bb & cc) | ((~bb) & dd)
            : j < 40
                ? bb ^ cc ^ dd
                : j < 60
                    ? (bb & cc) | (bb & dd) | (cc & dd)
                    : bb ^ cc ^ dd;

        final k = j < 20
            ? 0x5A827999
            : j < 40
                ? 0x6ED9EBA1
                : j < 60
                    ? 0x8F1BBCDC
                    : 0xCA62C1D6;

        final temp = (_leftrotate(aa, 5) + f + ee + k + w[j]) & 0xffffffff;
        ee = dd;
        dd = cc;
        cc = _leftrotate(bb, 30);
        bb = aa;
        aa = temp;
      }

      a = (a + aa) & 0xffffffff;
      b = (b + bb) & 0xffffffff;
      c = (c + cc) & 0xffffffff;
      d = (d + dd) & 0xffffffff;
      e = (e + ee) & 0xffffffff;
    }

    return [
      (a >> 24) & 0xff,
      (a >> 16) & 0xff,
      (a >> 8) & 0xff,
      a & 0xff,
      (b >> 24) & 0xff,
      (b >> 16) & 0xff,
      (b >> 8) & 0xff,
      b & 0xff,
      (c >> 24) & 0xff,
      (c >> 16) & 0xff,
      (c >> 8) & 0xff,
      c & 0xff,
      (d >> 24) & 0xff,
      (d >> 16) & 0xff,
      (d >> 8) & 0xff,
      d & 0xff,
      (e >> 24) & 0xff,
      (e >> 16) & 0xff,
      (e >> 8) & 0xff,
      e & 0xff,
    ];
  }

  List<int> _preprocessMessage(List<int> input) {
    final msgLen = input.length;
    final msg = <int>[...input];
    msg.add(0x80);

    while ((msg.length % 64) != 56) {
      msg.add(0x00);
    }

    final lengthInBits = msgLen * 8;
    for (var i = 7; i >= 0; i--) {
      msg.add((lengthInBits >> (i * 8)) & 0xff);
    }

    return msg;
  }

  int _leftrotate(int value, int count) {
    return ((value << count) | (value >> (32 - count))) & 0xffffffff;
  }
}
