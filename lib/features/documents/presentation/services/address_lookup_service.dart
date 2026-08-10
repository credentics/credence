import 'dart:convert';

import 'package:dio/dio.dart';

class AddressSuggestion {
  const AddressSuggestion({
    required this.displayName,
    required this.latitude,
    required this.longitude,
  });

  final String displayName;
  final double latitude;
  final double longitude;
}

class AddressLookupService {
  AddressLookupService({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  Future<List<AddressSuggestion>> search({
    required String query,
    int limit = 6,
  }) async {
    final cleaned = query.trim();
    if (cleaned.length < 3) {
      return const <AddressSuggestion>[];
    }

    final response = await _dio.get<List<dynamic>>(
      'https://nominatim.openstreetmap.org/search',
      queryParameters: <String, Object>{
        'q': cleaned,
        'format': 'jsonv2',
        'addressdetails': 1,
        'limit': limit,
      },
      options: Options(
        headers: const <String, String>{
          'User-Agent': 'Credence/1.0 (address-lookup)',
          'Accept': 'application/json',
        },
        sendTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 8),
      ),
    );

    final rows = response.data ?? const <dynamic>[];
    final suggestions = <AddressSuggestion>[];
    for (final row in rows) {
      if (row is! Map<String, dynamic>) {
        continue;
      }
      final display = (row['display_name'] ?? '').toString().trim();
      final lat = double.tryParse((row['lat'] ?? '').toString().trim());
      final lon = double.tryParse((row['lon'] ?? '').toString().trim());
      if (display.isEmpty || lat == null || lon == null) {
        continue;
      }
      suggestions.add(
        AddressSuggestion(
          displayName: display,
          latitude: lat,
          longitude: lon,
        ),
      );
    }
    return suggestions;
  }

  Future<AddressSuggestion?> resolveSingle({
    required String query,
  }) async {
    final results = await search(query: query, limit: 1);
    if (results.isEmpty) {
      return null;
    }
    return results.first;
  }

  String staticMapUrl({
    required double latitude,
    required double longitude,
    int zoom = 15,
    int width = 860,
    int height = 280,
  }) {
    // Use OSM static map API
    final uri = Uri.https(
      'staticmap.openstreetmap.de',
      '/staticmap.php',
      <String, String>{
        'center': '${latitude.toStringAsFixed(6)},${longitude.toStringAsFixed(6)}',
        'zoom': '$zoom',
        'size': '${width}x$height',
        'markers':
            '${latitude.toStringAsFixed(6)},${longitude.toStringAsFixed(6)},red-pushpin',
      },
    );
    return uri.toString();
  }


  String encodeSearchForMap(String address) {
    return Uri.encodeComponent(address.trim());
  }
}

String encodeAddressSuggestion(AddressSuggestion suggestion) {
  final map = <String, Object>{
    'display_name': suggestion.displayName,
    'lat': suggestion.latitude,
    'lon': suggestion.longitude,
  };
  return jsonEncode(map);
}

AddressSuggestion? decodeAddressSuggestion(String rawJson) {
  try {
    final decoded = jsonDecode(rawJson);
    if (decoded is! Map<String, dynamic>) {
      return null;
    }
    final display = (decoded['display_name'] ?? '').toString().trim();
    final lat = (decoded['lat'] as num?)?.toDouble();
    final lon = (decoded['lon'] as num?)?.toDouble();
    if (display.isEmpty || lat == null || lon == null) {
      return null;
    }
    return AddressSuggestion(
      displayName: display,
      latitude: lat,
      longitude: lon,
    );
  } catch (_) {
    return null;
  }
}
