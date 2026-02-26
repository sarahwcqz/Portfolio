import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/route_request_model.dart';
import '../models/route_model.dart';
import '../config/app_config.dart';

class RoutingService {
  final String _baseUrl = AppConfig.baseUrl;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // --------------------------- send route to back -----------------------------
  Future<List<RouteModel>> calculateRoutes(RouteRequest request) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/routes/'),
          headers: _headers,
          body: jsonEncode(request.toJson()),
        )
        .timeout(const Duration(seconds: 30));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['routes'] as List)
          .map((route) => RouteModel.fromJson(route))
          .toList();
    } else {
      throw Exception('Erreur serveur ${response.statusCode}');
    }
  }

  // ------------------------------ get instruction for route selected -------------------
  Future<List<dynamic>> getInstructions(
    String routeId,
    RouteRequest request,
  ) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/routes/$routeId/instructions'),
          headers: _headers,
          body: jsonEncode(request.toJson()),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['instructions'] as List<dynamic>;
    } else {
      throw Exception('Erreur serveur ${response.statusCode}');
    }
  }
}
