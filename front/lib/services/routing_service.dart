import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/route_request_model.dart';
import '../models/route_model.dart';

class RoutingService {
  final String _baseUrl = 'http://10.0.2.2:8000/api/v1';


// --------------------------- send route to back -----------------------------
  Future<List<RouteModel>> calculateRoutes(RouteRequest request) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/routes/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(request.toJson()),
    );

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
    final response = await http.post(
      Uri.parse('$_baseUrl/routes/$routeId/instructions'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['instructions'] as List<dynamic>;
    } else {
      throw Exception('Erreur serveur ${response.statusCode}');
    }
  }
}