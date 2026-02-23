import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/route_request_model.dart';
import '../models/route_model.dart';

class RoutingService {
  // change for environement
  // false = émulateur Android
  // true  = téléphone réel (ngrok)
  static const bool _isPhysicalDevice = false;

  String get _baseUrl => _isPhysicalDevice
      ? (dotenv.env['NGROK_URL'] ??
            'http://10.0.2.2:8000/api/v1') // adress for test with ngrok
      : 'http://10.0.2.2:8000/api/v1'; // adress for test with emulator

  Map<String, String> get _headers => _isPhysicalDevice
      ? {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true', // OBLIGATOIRE pour ngrok
        }
      : {
          'Content-Type': 'application/json', // for emulator
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
