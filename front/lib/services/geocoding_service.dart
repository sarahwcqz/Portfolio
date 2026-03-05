import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import '../models/address_suggestion_model.dart';

final logger = Logger();

class GeocodingService {
  // Headers for all requests
  final Map<String, String> _headers = {'User-Agent': 'com.example.front'};

  // ------------------------------------ Search address ---------------------------------
  /// returns a suggestion of adresses to the user
  Future<List<AddressSuggestion>> searchAddresses(String query) async {
    if (query.length < 3) return [];
    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
        'q': query,
        'format': 'json',
        'addressdetails': '0',
        'limit': '3',
        'countrycodes': 'fr',
      });
      final response = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data
            .cast<Map<String, dynamic>>()
            .map((json) => AddressSuggestion.fromJson(json))
            .toList();
      }

      return [];
    } catch (e) {
      logger.e('Erreur de recherche', error: e);
      return [];
    }
  }
}
