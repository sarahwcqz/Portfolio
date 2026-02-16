import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../services/location_service.dart';

class LocationController extends ChangeNotifier {
  final LocationService _locationService = LocationService();

  LatLng _currentPosition = const LatLng(48.8566, 2.3522);
  LatLng get currentPosition => _currentPosition;


// ---------------------------------- get position when arriving on main page -------
  Future<bool> determinePosition() async {
    bool hasPermission = await _locationService.checkPermissions();
    if (!hasPermission) {
      return false;
    }

    // to avoid big latencies, first try to get a last know position when arriving to main page
    final lastKnown = await _locationService.getLastKnownPosition();
    if (lastKnown != null) {
      _currentPosition = lastKnown;
      notifyListeners();
    }

    // then get the current position
    try {
      final current = await _locationService.getCurrentPosition();
      _currentPosition = current;
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

// ---------------------------------- update position -----------------------------
  Future<void> updatePosition() async {
    try {
      final position = await _locationService.getCurrentPosition();
      _currentPosition = position;
      notifyListeners();
    } catch (e) {
      debugPrint("Erreur GPS: $e");
    }
  }
}