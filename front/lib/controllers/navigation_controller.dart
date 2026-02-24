import 'dart:async';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import '../models/route_request_model.dart';
import '../models/route_model.dart';
import '../models/navigation_state_model.dart';
import '../services/routing_service.dart';
import '../services/location_service.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

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

  // REMPLACÉ : Timer par StreamSubscription
  StreamSubscription<LatLng>? _gpsSubscription;
  StreamSubscription<double>? _compassSubscription;

  MapController? _mapController;
  bool _isRecalculating = false;

  // Callbacks
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

  LatLng? _currentLivePosition;
  LatLng? get currentLivePosition => _currentLivePosition;

  void setMapController(MapController controller) {
    _mapController = controller;
  }

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

  // --- NAVIGATION ---

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

    // ACTIVER Wakelock
    WakelockPlus.enable();

    _startCompassTracking();
    notifyListeners();
  }

  void stopNavigation() {
    // NETTOYAGE complet
    //_gpsSubscription?.cancel();
    // _gpsSubscription = null;
    _stopCompassTracking();

    // DÉSACTIVER Wakelock
    WakelockPlus.disable();

    _navigationState = NavigationState.initial();
    _onStepReached = null;
    _onArrival = null;
    _onRecalculating = null;
    _isRecalculating = false;
    notifyListeners();
  }

  // --- TRACKING GPS (STREAM) ---

  void startGPSTracking({
    required Function(LatLng) onPositionUpdate,
    Function(String)? onError,
  }) {
    _onPositionUpdate = onPositionUpdate;

    _gpsSubscription?.cancel();

    _gpsSubscription = _locationService.getPositionStream().listen((
      newPosition,
    ) {
      _currentLivePosition = newPosition;

      notifyListeners();

      _onPositionUpdate?.call(newPosition);

      if (_navigationState.isNavigating) {
        _updateNavigation(newPosition);
      }
    }, onError: (e) => onError?.call("Erreur GPS: $e"));
  }

  // --- LOGIQUE INTERNE ---

  void _updateNavigation(LatLng currentPosition) {
    if (!_navigationState.isNavigating ||
        _selectedRouteIndex == null ||
        _navigationState.currentStepIndex >=
            _navigationState.instructions.length) {
      return;
    }

    final routePoints = _availableRoutes[_selectedRouteIndex!].points;
    final distanceFromRoute = _locationService.distanceToPolyline(
      currentPosition,
      routePoints,
    );

    int newDeviationCounter = _navigationState.deviationCounter;

    if (distanceFromRoute > 30) {
      newDeviationCounter++;
      if (newDeviationCounter >= 16 && !_isRecalculating) {
        _recalculateRouteAutomatically(currentPosition);
        return;
      }
    } else {
      newDeviationCounter = 0;
    }

    // Utilise le way_point exact fourni par ORS
    int pointIndex;
    try {
      final currentInstruction =
          _navigationState.instructions[_navigationState.currentStepIndex];
      final wayPoints = currentInstruction['way_points'] as List<dynamic>;
      pointIndex = wayPoints[1] as int; // way_points[1] = fin de l'étape

      // Sécurité : vérifie que l'index est valide
      if (pointIndex >= routePoints.length) {
        pointIndex = routePoints.length - 1;
      }
    } catch (e) {
      // Fallback sur l'ancienne méthode si way_points n'existe pas
      debugPrint("way_points non disponible, utilisation approximation");
      pointIndex =
          (_navigationState.currentStepIndex *
          routePoints.length ~/
          _navigationState.instructions.length);
      if (pointIndex >= routePoints.length) pointIndex = routePoints.length - 1;
    }

    final targetPoint = routePoints[pointIndex];
    double distance = _locationService.calculateDistance(
      currentPosition,
      targetPoint,
    );

    // --- SECTION MODIFIÉE POUR L'ARRIVÉE ---

    if (distance < 25) {
      // Est-ce qu'on est sur la dernière instruction ?
      bool isLastInstruction =
          _navigationState.currentStepIndex >=
          _navigationState.instructions.length - 1;

      if (isLastInstruction) {
        // CAS 1 : ARRIVÉE FINALE
        _navigationState = _navigationState.copyWith(
          distanceToNextStep: 0,
          distanceFromRoute: distanceFromRoute,
          deviationCounter: 0,
        );
        notifyListeners();

        _onArrival?.call();
        stopNavigation(); // On arrête tout proprement
        return;
      } else {
        // CAS 2 : ÉTAPE FRANCHIE (MAIS PAS LA DERNIÈRE)
        _navigationState = _navigationState.copyWith(
          currentStepIndex: _navigationState.currentStepIndex + 1,
          distanceToNextStep: distance,
          distanceFromRoute: distanceFromRoute,
          deviationCounter: newDeviationCounter,
        );
        _onStepReached?.call();
      }
    } else {
      // CAS 3 : ON AVANCE JUSTE SUR LE CHEMIN
      _navigationState = _navigationState.copyWith(
        distanceToNextStep: distance,
        distanceFromRoute: distanceFromRoute,
        deviationCounter: newDeviationCounter,
      );
    }

    notifyListeners();
  }

  Future<void> _recalculateRouteAutomatically(LatLng currentPosition) async {
    if (_isRecalculating || _destinationPoint == null) return;
    _isRecalculating = true;
    _onRecalculating?.call();

    try {
      _startPoint = currentPosition;
      final request = RouteRequest(
        startLat: _startPoint!.latitude,
        startLng: _startPoint!.longitude,
        destLat: _destinationPoint!.latitude,
        destLng: _destinationPoint!.longitude,
      );

      _availableRoutes = await _routingService.calculateRoutes(request);
      _selectedRouteIndex = 0;
      final selectedRoute = _availableRoutes[0];

      final instructions = await _routingService.getInstructions(
        selectedRoute.routeId,
        request,
      );

      _navigationState = _navigationState.copyWith(
        instructions: instructions,
        currentStepIndex: 0,
        distanceFromRoute: 0.0,
        deviationCounter: 0,
      );
      notifyListeners();
    } catch (e) {
      debugPrint("Erreur recalcul : $e");
    } finally {
      _isRecalculating = false;
    }
  }

  void _startCompassTracking() {
    final compassStream = _locationService.getCompassStream();
    if (compassStream == null) return;

    double lastHeading = 0.0;
    _compassSubscription = compassStream.listen((heading) {
      if ((heading - lastHeading).abs() < 1.5) return;
      lastHeading = heading;
      _navigationState = _navigationState.copyWith(currentHeading: heading);

      if (_mapController != null) {
        _mapController!.rotate(-heading);
      }
      notifyListeners();
    });
  }

  void _stopCompassTracking() {
    _compassSubscription?.cancel();
    _compassSubscription = null;
    _mapController?.rotate(0.0);
  }

  @override
  void dispose() {
    _gpsSubscription?.cancel();
    _compassSubscription?.cancel();
    WakelockPlus.disable();
    super.dispose();
  }

  // Helper pour convertir le nom de la couleur (String) en objet Color Flutter
  Color getRouteColor(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'blue':
        return Colors.blue;
      case 'green':
        return Colors.green;
      case 'red':
        return Colors.red;
      case 'purple':
        return Colors.purple;
      case 'orange':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }
}
