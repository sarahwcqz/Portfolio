import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_compass/flutter_compass.dart';

class LocationService {
  Stream<double>? getCompassStream() {
    return FlutterCompass.events?.map((event) => event.heading ?? 0.0);
  }

  // ------------------------------------ check permissions ------------------------------
  /// checks GPS permissions
  Future<bool> checkPermissions() async {
    // checks if GPS is unabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    // Checks GPS permission, if not, asks GPS perm
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  // ------------------------------------------- get last know position ----------------------
  /// sets position to last know position (avoid big latency when clicking 'recenter')
  Future<LatLng?> getLastKnownPosition() async {
    Position? position = await Geolocator.getLastKnownPosition();
    if (position != null) {
      return LatLng(position.latitude, position.longitude);
    }
    return null;
  }

  // ------------------------------------------ get current position --------------------------
  /// get real current position with high accuracy
  Future<LatLng> getCurrentPosition() async {
    Position position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
    return LatLng(position.latitude, position.longitude);
  }

  // ------------------------------------------ ?????????? -------------------------------------
  double calculateDistance(LatLng from, LatLng to) {
    return Geolocator.distanceBetween(
      from.latitude,
      from.longitude,
      to.latitude,
      to.longitude,
    );
  }

  //..............................Calculate point mini betwen point and polyline...........
  double distanceToPolyline(LatLng point, List<LatLng> polyline) {
    if (polyline.isEmpty) return double.infinity;

    double minDistance = double.infinity;

    // Calcule la distance à chaque segment de la polyline
    for (int i = 0; i < polyline.length - 1; i++) {
      final segmentStart = polyline[i];
      final segmentEnd = polyline[i + 1];

      final distance = _distanceToSegment(point, segmentStart, segmentEnd);
      if (distance < minDistance) {
        minDistance = distance;
      }
    }

    return minDistance;
  }

  /// Calcule la distance d'un point à un segment de ligne
  double _distanceToSegment(LatLng point, LatLng start, LatLng end) {
    // Distance directe aux extrémités
    final distToStart = calculateDistance(point, start);
    final distToEnd = calculateDistance(point, end);

    return distToStart < distToEnd ? distToStart : distToEnd;
  }
}
