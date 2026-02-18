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
  bool _isRecalculating = false;

  // Callbacks pour la navigation
  VoidCallback? _onStepReached;
  VoidCallback? _onArrival;
  Function(LatLng)? _onPositionUpdate;
  VoidCallback? _onRecalculating;

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
    VoidCallback? onRecalculating,
  }) async {
    if (_selectedRouteIndex == null) {
      throw Exception("Veuillez sélectionner un itinéraire");
    }

    _onStepReached = onStepReached;
    _onArrival = onArrival;
    _onRecalculating = onRecalculating;

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
      distanceFromRoute: 0.0,
      deviationCounter: 0,
    );

    _startCompassTracking();

    notifyListeners();
  }

  void _startCompassTracking() {
    final compassStream = _locationService.getCompassStream();
    if (compassStream == null) {
      debugPrint("Boussole non disponible sur cet appareil");
      return;
    }

    double lastHeading = 0.0;
    DateTime lastUpdate = DateTime.now();

    _compassSubscription = compassStream.listen((heading) {
      final now = DateTime.now();

      if (now.difference(lastUpdate).inMilliseconds < 50) {
        return;
      }

      if ((heading - lastHeading).abs() < 1) {
        return;
      }

      lastHeading = heading;
      lastUpdate = now;

      _navigationState = _navigationState.copyWith(currentHeading: heading);

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

        _onPositionUpdate?.call(position);

        if (_navigationState.isNavigating) {
          _updateNavigation(position);
        }
      } catch (e) {
        onError?.call("Erreur GPS: $e");
      }
    });
  }

  // MODIFIÉ : Mettre à jour la navigation avec détection de déviation
  void _updateNavigation(LatLng currentPosition) {
    if (!_navigationState.isNavigating ||
        _selectedRouteIndex == null ||
        _navigationState.currentStepIndex >=
            _navigationState.instructions.length) {
      return;
    }

    final routePoints = _availableRoutes[_selectedRouteIndex!].points;

    // NOUVEAU : Calcule la distance à la route
    final distanceFromRoute = _locationService.distanceToPolyline(
      currentPosition,
      routePoints,
    );

    // NOUVEAU : Détecte les déviations
    int newDeviationCounter = _navigationState.deviationCounter;

    if (distanceFromRoute > 50) {
      // Plus de 50m de la route
      newDeviationCounter++;

      // Après 5 détections (5 × 2s = 10 secondes)
      if (newDeviationCounter >= 5 && !_isRecalculating) {
        debugPrint("Déviation détectée ! Recalcul automatique...");
        _recalculateRouteAutomatically(currentPosition);
        return; // Sort de la fonction pour ne pas continuer la mise à jour
      }
    } else {
      newDeviationCounter = 0; // Reset si on revient sur la route
    }

    // Calcul de la distance à la prochaine étape
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
        distanceFromRoute: distanceFromRoute,
        deviationCounter: newDeviationCounter,
      );
      _onStepReached?.call();
    } else {
      _navigationState = _navigationState.copyWith(
        distanceToNextStep: distance,
        distanceFromRoute: distanceFromRoute,
        deviationCounter: newDeviationCounter,
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

  //FONCTION : Recalcul automatique
  Future<void> _recalculateRouteAutomatically(LatLng currentPosition) async {
    if (_isRecalculating || _destinationPoint == null) return;

    _isRecalculating = true;
    _onRecalculating?.call(); // Notifie la vue

    try {
      debugPrint("Recalcul de l'itinéraire...");

      // Utilise la position actuelle comme nouveau départ
      _startPoint = currentPosition;

      // Recalcule les routes
      final request = RouteRequest(
        startLat: _startPoint!.latitude,
        startLng: _startPoint!.longitude,
        destLat: _destinationPoint!.latitude,
        destLng: _destinationPoint!.longitude,
      );

      _availableRoutes = await _routingService.calculateRoutes(request);

      // Garde la même sélection (même type de route)
      final wasAvoidRoute = _selectedRouteIndex == 1;
      _selectedRouteIndex = wasAvoidRoute && _availableRoutes.length > 1
          ? 1
          : 0;

      final selectedRoute = _availableRoutes[_selectedRouteIndex!];

      // Récupère les nouvelles instructions
      final instructions = await _routingService.getInstructions(
        selectedRoute.routeId,
        request,
      );

      // Réinitialise la navigation avec le nouvel itinéraire
      _navigationState = NavigationState(
        isNavigating: true,
        instructions: instructions,
        currentStepIndex: 0,
        distanceToNextStep: 0.0,
        currentHeading: _navigationState.currentHeading,
        distanceFromRoute: 0.0,
        deviationCounter: 0,
      );

      notifyListeners();
      debugPrint("Itinéraire recalculé !");
    } catch (e) {
      debugPrint("Erreur recalcul : $e");
    } finally {
      _isRecalculating = false;
    }
  }

  // Arrêter la navigation
  void stopNavigation() {
    _gpsTimer?.cancel();
    _stopCompassTracking();
    _navigationState = NavigationState.initial();
    _onStepReached = null;
    _onArrival = null;
    _onRecalculating = null;
    _isRecalculating = false;
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
