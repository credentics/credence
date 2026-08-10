import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pass_doc_manager/data/vault_sync/mirror/dropbox_mirror_data_source.dart';
import 'package:pass_doc_manager/domain/vault_sync/entities/vault_sync_head_entity.dart';

/// Drives DropboxMirrorDataSource.readHead against a scripted HTTP layer — no
/// network, fully deterministic in CI. This is where the live "409 →
/// could-not-verify" incident lived, so the head/manifest fallback, the
/// not-found-as-null contract, and auth-error propagation all get pinned here.
void main() {
  const directory = '/Credence';
  const headPath = '/Credence/.credence/head.json';
  const manifestPath = '/Credence/.credence/manifest.json';

  DropboxMirrorDataSource sourceThatServes(
    Map<String, _CannedResponse> byPath,
  ) {
    final dio = Dio()..httpClientAdapter = _ScriptedDropboxAdapter(byPath);
    return DropboxMirrorDataSource(dio: dio);
  }

  test('reads head.json when it is present', () async {
    final head = const VaultSyncHeadEntity(
      revision: 7,
      deviceId: 'device-a',
      manifestHash: 'checksum-7',
      generatedAtIso: '2026-02-01T00:00:00.000Z',
      provider: 'dropbox',
      fileCount: 3,
      directoryCount: 2,
    );
    final source = sourceThatServes({
      headPath: _CannedResponse(200, head.toJsonText()),
    });

    final result = await source.readHead(
      accessToken: 'token',
      directoryPath: directory,
    );

    expect(result, isNotNull);
    expect(result!.revision, 7);
    expect(result.deviceId, 'device-a');
  });

  test(
    'falls back to manifest.json when head.json is 409 (not found)',
    () async {
      const manifestJson =
          '{"revision":5,"device_id":"device-b","content_checksum":"cc-5",'
          '"files":[],"directories":[]}';
      final source = sourceThatServes({
        headPath: _CannedResponse(409, '{"error_summary":"path/not_found/.."}'),
        manifestPath: _CannedResponse(200, manifestJson),
      });

      final result = await source.readHead(
        accessToken: 'token',
        directoryPath: directory,
      );

      expect(result, isNotNull);
      expect(result!.revision, 5, reason: 'derived from the manifest fallback');
      expect(result.manifestHash, 'cc-5');
    },
  );

  test(
    'returns null when neither head nor manifest exist (both 409)',
    () async {
      final source = sourceThatServes({
        headPath: _CannedResponse(409, '{"error_summary":"path/not_found/.."}'),
        manifestPath: _CannedResponse(
          409,
          '{"error_summary":"path/not_found/.."}',
        ),
      });

      final result = await source.readHead(
        accessToken: 'token',
        directoryPath: directory,
      );

      expect(result, isNull);
    },
  );

  test('propagates an auth error (401) instead of swallowing it', () async {
    final source = sourceThatServes({
      headPath: _CannedResponse(
        401,
        '{"error_summary":"expired_access_token"}',
      ),
    });

    await expectLater(
      source.readHead(accessToken: 'expired', directoryPath: directory),
      throwsA(isA<DioException>()),
    );
  });
}

class _CannedResponse {
  const _CannedResponse(this.statusCode, this.body);
  final int statusCode;
  final String body;
}

/// A dio adapter that answers Dropbox `files/download` calls from a canned map
/// keyed by the requested remote path (read out of the `Dropbox-API-Arg`
/// header). Any unscripted path returns 409 (not found).
class _ScriptedDropboxAdapter implements HttpClientAdapter {
  _ScriptedDropboxAdapter(this.byPath);

  final Map<String, _CannedResponse> byPath;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<dynamic>? cancelFuture,
  ) async {
    final arg = '${options.headers['Dropbox-API-Arg'] ?? '{}'}';
    final path = '${(jsonDecode(arg) as Map)['path'] ?? ''}';
    final canned =
        byPath[path] ?? const _CannedResponse(409, '{"error":"not_found"}');
    return ResponseBody.fromBytes(
      utf8.encode(canned.body),
      canned.statusCode,
      headers: {
        Headers.contentTypeHeader: ['application/octet-stream'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
