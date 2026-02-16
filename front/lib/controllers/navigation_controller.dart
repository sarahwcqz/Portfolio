import 'dart:async';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import '../models/route_request_model.dart';
import '../models/route_model.dart';
import '../models/navigation_state_model.dart';
import '../services/routing_service.dart';
import '../services/location_service.dart';

class NavigationController extends ChangeNotifier {
  final RoutingService _routingService = RoutingService();
  final LocationService _locationService = LocationService();

  // État
  LatLng? _startPoint;
  String _startAddress = "Position actuelle";
  LatLng? _destinationPoint;
  String _destinationAddress = "Choisir la destination";
  List<RouteModel> _availableRoutes = [];
  int? _selectedRouteIndex;
  NavigationState _navigationState = NavigationState.initial();
  Timer? _gpsTimer;
  StreamSubscription<double>? _compassSubscription;
  MapController? _mapController;

  // Callbacks pour la navigation
  VoidCallback? _onStepReached;
  VoidCallback? _onArrival;
  Function(LatLng)? _onPositionUpdate;

  // Getters
  LatLng? get startPoint => _startPoint;
  String get startAddress => _startAddress;
  LatLng? get destinationPoint => _destinationPoint;
  String get destinationAddress => _destinationAddress;
  List<RouteModel> get availableRoutes => _availableRoutes;
  int? get selectedRouteIndex => _selectedRouteIndex;
  NavigationState get navigationState => _navigationState;

  void setMapController(MapController controller) {
    _mapController = controller;
  }

  // Setters
  void setStartPoint(LatLng point, String address) {
    _startPoint = point;
    _startAddress = address;
    notifyListeners();
  }

  void setDestinationPoint(LatLng point, String address) {
    _destinationPoint = point;
    _destinationAddress = address;
    notifyListeners();
  }

  void selectRoute(int index) {
    _selectedRouteIndex = index;
    notifyListeners();
  }

  // Calculer les routes
  Future<void> calculateRoutes() async {
    if (_startPoint == null || _destinationPoint == null) {
      throw Exception("Départ et destination requis");
    }

    final request = RouteRequest(
      startLat: _startPoint!.latitude,
      startLng: _startPoint!.longitude,
      destLat: _destinationPoint!.latitude,
      destLng: _destinationPoint!.longitude,
    );

    _availableRoutes = await _routingService.calculateRoutes(request);
    _selectedRouteIndex = null;
    notifyListeners();
  }

  // Démarrer la navigation
  Future<void> startNavigation({
    VoidCallback? onStepReached,
    VoidCallback? onArrival,
  }) async {
    if (_selectedRouteIndex == null) {
      throw Exception("Veuillez sélectionner un itinéraire");
    }

    _onStepReached = onStepReached;
    _onArrival = onArrival;

    final selectedRoute = _availableRoutes[_selectedRouteIndex!];

    final request = RouteRequest(
      startLat: _startPoint!.latitude,
      startLng: _startPoint!.longitude,
      destLat: _destinationPoint!.latitude,
      destLng: _destinationPoint!.longitude,
    );

    final instructions = await _routingService.getInstructions(
      selectedRoute.routeId,
      request,
    );

    _navigationState = NavigationState(
      isNavigating: true,
      instructions: instructions,
      currentStepIndex: 0,
      distanceToNextStep: 0.0,
      currentHeading: 0.0,
    );

    _startCompassTracking();

    notifyListeners();
  }

  void _startCompassTracking() {
    final compassStream = _locationService.getCompassStream();
    if (compassStream == null) {
      debugPrint("⚠️ Boussole non disponible sur cet appareil");
      return;
    }

    _compassSubscription = compassStream.listen((heading) {
      _navigationState = _navigationState.copyWith(currentHeading: heading);

      // Faire tourner la carte selon l'orientation
      if (_mapController != null) {
        _mapController!.moveAndRotate(
          _mapController!.camera.center,
          _mapController!.camera.zoom,
          -heading,
        );
      }

      notifyListeners();
    });
  }

  void _stopCompassTracking() {
    _compassSubscription?.cancel();
    _compassSubscription = null;

    // Remettre la carte à plat
    if (_mapController != null) {
      _mapController!.moveAndRotate(
        _mapController!.camera.center,
        _mapController!.camera.zoom,
        0.0,
      );
    }
  }

  // Démarrer le suivi GPS
  void startGPSTracking({
    required Function(LatLng) onPositionUpdate,
    Function(String)? onError,
  }) {
    _onPositionUpdate = onPositionUpdate;

    _gpsTimer?.cancel();
    _gpsTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      try {
        final position = await _locationService.getCurrentPosition();

        // Notifier la view de la nouvelle position
        _onPositionUpdate?.call(position);

        // Si en navigation, mettre à jour
        if (_navigationState.isNavigating) {
          _updateNavigation(position);
        }
      } catch (e) {
        onError?.call("Erreur GPS: $e");
      }
    });
  }

  // Mettre à jour la navigation
  void _updateNavigation(LatLng currentPosition) {
    if (!_navigationState.isNavigating ||
        _selectedRouteIndex == null ||
        _navigationState.currentStepIndex >=
            _navigationState.instructions.length) {
      return;
    }

    final routePoints = _availableRoutes[_selectedRouteIndex!].points;

    int pointIndex =
        (_navigationState.currentStepIndex *
                routePoints.length /
                _navigationState.instructions.length)
            .floor();

    if (pointIndex >= routePoints.length) {
      pointIndex = routePoints.length - 1;
    }

    final targetPoint = routePoints[pointIndex];

    double distance = _locationService.calculateDistance(
      currentPosition,
      targetPoint,
    );

    // Vérifier si on a atteint l'étape
    if (distance < 30 &&
        _navigationState.currentStepIndex <
            _navigationState.instructions.length - 1) {
      _navigationState = _navigationState.copyWith(
        currentStepIndex: _navigationState.currentStepIndex + 1,
        distanceToNextStep: distance,
      );
      _onStepReached?.call();
    } else {
      _navigationState = _navigationState.copyWith(
        distanceToNextStep: distance,
      );
    }

    // Vérifier si arrivé
    if (_navigationState.currentStepIndex >=
        _navigationState.instructions.length) {
      _onArrival?.call();
      stopNavigation();
    }

    notifyListeners();
  }

  // Arrêter la navigation
  void stopNavigation() {
    _gpsTimer?.cancel();
    _stopCompassTracking();
    _navigationState = NavigationState.initial();
    _onStepReached = null;
    _onArrival = null;
    notifyListeners();
  }

  // Helper : Couleur depuis string
  Color getRouteColor(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'blue':
        return Colors.blue;
      case 'green':
        return Colors.green;
      case 'red':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  @override
  void dispose() {
    _gpsTimer?.cancel();
    _compassSubscription?.cancel();
    super.dispose();
  }
}
