import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:pass_doc_manager/core/config/brandfetch_config.dart';
import 'package:pass_doc_manager/data/branding/apis/brandfetch_search_api.dart';
import 'package:pass_doc_manager/data/branding/dtos/brandfetch_search_item_dto.dart';

class BrandfetchSearchRemoteDataSource {
  const BrandfetchSearchRemoteDataSource({required this.api});

  final BrandfetchSearchApi api;

  Future<List<BrandfetchSearchItemDto>> searchCompanies({
    required String query,
  }) async {
    final cleaned = query.trim();
    if (kDebugMode) {
      debugPrint('[Brandfetch] search query="$cleaned"');
    }
    if (cleaned.length < 2) {
      return const [];
    }

    try {
      final response = await api
          .searchCompanies(query: cleaned, clientId: brandfetchClientId)
          .timeout(const Duration(seconds: 6));

      final rows = response
          .where((it) => (it.domain ?? '').trim().isNotEmpty)
          .take(8)
          .toList(growable: false);
      if (kDebugMode) {
        debugPrint('[Brandfetch] search results=${rows.length}');
      }
      return rows;
    } catch (_) {
      if (kDebugMode) {
        debugPrint('[Brandfetch] search failed for query="$cleaned"');
      }
      return const [];
    }
  }
}
