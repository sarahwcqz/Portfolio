import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/reports_model.dart';
import '../models/bounding_box_model.dart';
import '../config/app_config.dart';

class ReportService {
  final String _baseUrl = AppConfig.baseUrl;

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


  Future<bool> createReport(Map<String, dynamic> data) async {
    try {
      final supabase = Supabase.instance.client;
      final session = supabase.auth.currentSession;
      final String? token = session?.accessToken;

      if (token == null) return false;

      final response = await http.post(
        Uri.parse('$_baseUrl/reports/'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(data),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('Erreur Service createReport: $e');
      return false;
    }
  }
}
