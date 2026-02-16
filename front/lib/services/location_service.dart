import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class LocationService {
  

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
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
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
}