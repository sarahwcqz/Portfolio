import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/reports_model.dart';
import '../models/bounding_box_model.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ReportService {
  //final String _baseUrl = 'http://10.0.2.2:8000/api/v1';
  final String _baseUrl = dotenv.env['NGROK_URL'] ?? '';

  Future<List<ReportModel>> getReportsInBoundingBox(BoundingBox bbox) async {
    final uri = Uri.parse('$_baseUrl/reports/').replace(
      queryParameters: {
        'min_lat': bbox.minLat.toString(),
        'max_lat': bbox.maxLat.toString(),
        'min_lng': bbox.minLng.toString(),
        'max_lng': bbox.maxLng.toString(),
      },
    );

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data
          .cast<Map<String, dynamic>>()
          .map((json) => ReportModel.fromJson(json))
          .toList();
    } else {
      throw Exception('Erreur serveur ${response.statusCode}');
    }
  }
}
