import 'package:latlong2/latlong.dart';

class RouteModel {
  final String routeId;
  final String name;
  final double distance;
  final double duration;
  final String color;
  final List<LatLng> points;

  RouteModel({
    required this.routeId,
    required this.name,
    required this.distance,
    required this.duration,
    required this.color,
    required this.points,
  });

  factory RouteModel.fromJson(Map<String, dynamic> json) {
    return RouteModel(
      routeId: json['route_id'],
      name: json['name'],
      distance: json['distance'].toDouble(),
      duration: json['duration'].toDouble(),
      color: json['color'],
      points: (json['coordinates'] as List)
          .map((point) => LatLng(point['lat'], point['lng']))
          .toList(),
    );
  }
}
