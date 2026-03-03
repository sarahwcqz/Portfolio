import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class ReportActionService {
  final String _baseUrl = 'http://10.0.2.2:8000/api/v1';

  // ------------------------------ Get JWT --------------------------------
  String? _getAuthToken() {
    final session = Supabase.instance.client.auth.currentSession;
    return session?.accessToken;
  }

  // ------------------------------ CONFIRM REPORT -> patch /confirm + token --------------------------
  Future<void> confirmReport(String reportId) async {
    final token = _getAuthToken();

    if (token == null) {
      throw Exception("Utilisateur non connecté");
    }

    final response = await http.patch(
      Uri.parse('$_baseUrl/reports/$reportId/confirm'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Erreur: ${response.statusCode} - ${response.body}');
    }
  }

  // ---------------------------------- INFIRM REPORT -> patch /infirm + token ------------------------
  Future<void> infirmReport(String reportId) async {
    final token = _getAuthToken();

    if (token == null) {
      throw Exception("Utilisateur non connecté");
    }

    final response = await http.patch(
      Uri.parse('$_baseUrl/reports/$reportId/infirm'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Erreur: ${response.statusCode} - ${response.body}');
    }
  }
}