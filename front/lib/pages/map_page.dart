import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
// GPS
import 'package:geolocator/geolocator.dart';
// conversion JSON <-> dart object
import 'dart:convert';
// http requests
import 'package:http/http.dart' as http;
// Timer pour le suivi GPS
import 'dart:async';

// others pages
import 'address_search_page.dart';

//============================================================================================================================
//========================================================== CLASSES =========================================================
//============================================================================================================================

//============================================ ROUTE REQUEST  ==============================================
class RouteRequest {
  final double startLat, startLng, destLat, destLng;

  RouteRequest({
    required this.startLat,
    required this.startLng,
    required this.destLat,
    required this.destLng,
  });

  Map<String, dynamic> toJson() => {
    'start_lat': startLat,
    'start_lng': startLng,
    'dest_lat': destLat,
    'dest_lng': destLng,
  };
}

//============================================ MAP  ==============================================
class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  // --------------------- VAR ----------------------------
  // controller to manipulate map through code
  final MapController _mapController = MapController();
  // Default position (Paris)
  LatLng _currentPosition = const LatLng(48.8566, 2.3522);
  // POINT DEPART
  LatLng? _startPoint;
  String _startAddress = "Position actuelle";

  // DESTINATION
  LatLng? _destinationPoint;
  String _destinationAddress = "Choisir la destination";

  //select route
  List<Map<String, dynamic>> _availableRoutes = [];
  int? _selectedRouteIndex;

  // ✅ NOUVELLES VARIABLES : Navigation GPS
  List<dynamic> _currentInstructions = [];
  int _currentStepIndex = 0;
  Timer? _gpsTimer;
  bool _isNavigating = false;
  double _distanceToNextStep = 0.0;

  // ======================================================= startNavigation =================================================
  // Récupère les instructions de guidage pour la route sélectionnée

  Future<void> _startNavigation() async {
    if (_selectedRouteIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez sélectionner un itinéraire")),
      );
      return;
    }

    // Récupère les infos de la route sélectionnée
    final selectedRoute = _availableRoutes[_selectedRouteIndex!];
    final routeId = selectedRoute['route_id'];

    // Affiche un loader
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(width: 16),
            Text("Chargement du guidage..."),
          ],
        ),
        duration: Duration(seconds: 30),
      ),
    );

    try {
      // ========== REQUÊTE POUR OBTENIR LES INSTRUCTIONS ==========
      final request = RouteRequest(
        startLat: _startPoint!.latitude,
        startLng: _startPoint!.longitude,
        destLat: _destinationPoint!.latitude,
        destLng: _destinationPoint!.longitude,
      );

      final response = await http.post(
        Uri.parse('http://10.0.2.2:8000/api/v1/routes/$routeId/instructions'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(request.toJson()),
      );

      // Ferme le loader
      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // ACTIVE LA NAVIGATION GPS
        setState(() {
          _currentInstructions = data['instructions'];
          _currentStepIndex = 0;
          _isNavigating = true;
        });

        // DÉMARRE LE SUIVI GPS
        _startGPSTracking();

        if (!mounted) return;

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Navigation démarrée")));
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur ${response.statusCode}")),
        );
      }
      if (!mounted) return;
    } catch (e) {
      ScaffoldMessenger.of(context).clearSnackBars();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erreur : $e")));
    }
  }

  // ======================================================= startGPSTracking =================================================
  // Suit la position GPS toutes les 2 secondes

  void _startGPSTracking() {
    _gpsTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      try {
        // Récupère la position actuelle
        Position position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        );

        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
        });

        // Recentre la carte sur ta position
        _mapController.move(_currentPosition, 17.0);

        // Calcule la distance à la prochaine instruction
        _updateDistanceToNextStep(position);

        // Vérifie si on a atteint l'étape
        _checkIfStepReached();
      } catch (e) {
        debugPrint("Erreur GPS: $e");
      }
    });
  }

  // ======================================================= updateDistanceToNextStep =================================================
  // Calcule la distance jusqu'à la prochaine instruction

  void _updateDistanceToNextStep(Position currentPosition) {
    if (_currentStepIndex >= _currentInstructions.length) {
      // Navigation terminée
      _stopNavigation();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Vous êtes arrivé à destination !"),
          backgroundColor: Colors.green,
        ),
      );
      return;
    }

    // Récupère les coordonnées de la route sélectionnée
    final routePoints =
        _availableRoutes[_selectedRouteIndex!]['points'] as List<LatLng>;

    // Trouve le point le plus proche correspondant à l'instruction actuelle
    // (Simplifié : on prend un point vers le milieu de la route pour cette étape)
    int pointIndex =
        (_currentStepIndex * routePoints.length / _currentInstructions.length)
            .floor();
    if (pointIndex >= routePoints.length) pointIndex = routePoints.length - 1;

    final targetPoint = routePoints[pointIndex];

    // Calcul de distance (en mètres)
    double distance = Geolocator.distanceBetween(
      currentPosition.latitude,
      currentPosition.longitude,
      targetPoint.latitude,
      targetPoint.longitude,
    );

    setState(() {
      _distanceToNextStep = distance;
    });
  }

  // ======================================================= checkIfStepReached =================================================
  // Vérifie si on a atteint l'étape actuelle

  void _checkIfStepReached() {
    // Si on est à moins de 30m de la prochaine étape
    if (_distanceToNextStep < 30) {
      setState(() {
        _currentStepIndex++;
      });

      // Message de confirmation
      if (_currentStepIndex < _currentInstructions.length) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Étape $_currentStepIndex/${_currentInstructions.length}",
            ),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    }
  }

  // ======================================================= stopNavigation =================================================
  // Arrête la navigation GPS

  void _stopNavigation() {
    _gpsTimer?.cancel();
    setState(() {
      _isNavigating = false;
      _currentStepIndex = 0;
      _currentInstructions = [];
      _distanceToNextStep = 0.0;
    });
  }

  // --------------------------- INIT ------------------------------
  // when starting, calls determinePosition function
  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  @override
  void dispose() {
    _gpsTimer?.cancel(); // Important : nettoie le timer
    super.dispose();
  }

  // =============================================================================================================================
  // ============================================================ FUNCTIONS ======================================================
  // =============================================================================================================================

  // ======================================================= determinePosition =================================================
  // Asks for permission + get location

  Future<void> _determinePosition() async {
    // GPS activation (T/F)
    bool serviceEnabled;

    LocationPermission permission;

    //----------------------------------- permissions -------------------------------------

    // checks GPS unabled, if not displays msg
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Veuillez activer le GPS")),
        );
      });
      return;
    }

    // Checks GPS permission, if not, asks GPS perm, if denied, displays msg
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Permission GPS refusée")),
          );
        });
        return;
      }
    }

    // ---------------------------------- get location ----------------------------------------

    // First, sets position to last know position (avoid big latency when clicking 'recenter')
    Position? position = await Geolocator.getLastKnownPosition();

    // sets currentPosition to LastKnowPosition and moves map to currentPosition (while waiting for current position to be found)
    if (position != null) {
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
      });
      _mapController.move(_currentPosition, 15.0);
    }

    // get real current position with high accuracy (while displaying LastKnowPosition)
    try {
      Position current = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      // If LastKnow not same than current, update and move map to current
      if (_currentPosition.latitude != current.latitude ||
          _currentPosition.longitude != current.longitude) {
        setState(() {
          _currentPosition = LatLng(current.latitude, current.longitude);
        });
        _mapController.move(_currentPosition, 15.0);
      }

      // if no starting point selected by user, default on geoloc
      if (_startPoint == null) {
        setState(() {
          _startPoint = _currentPosition;
        });
      }

      // if no current position available, display msg
    } catch (e) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Impossible d'obtenir la position exacte: $e"),
          ),
        );
      });
    }
  }

  // ======================================================= openAddressSearch =================================================
  // opens a search address bar, calls address search page, gets what search page returns (PickedLocation),
  // transforms it to start/dest point + address, and zooms on result (start + dest)

  Future<void> _openAddressSearch({required bool isStart}) async {
    final result = await Navigator.push<PickedLocation>(
      context,
      MaterialPageRoute(
        builder: (_) => AddressSearchPage(currentPosition: _currentPosition),
      ),
    );

    if (result != null) {
      setState(() {
        if (isStart) {
          _startPoint = result.latLng;
          _startAddress = result.isCurrentPosition
              ? "Ma position actuelle"
              : result.address;
        } else {
          _destinationPoint = result.latLng;
          _destinationAddress = result.isCurrentPosition
              ? "Ma position actuelle"
              : result.address;
        }
      });
      _mapController.move(result.latLng, 15.0);
    }
  }

  // ======================================================= sendRouteRequest =================================================
  // shapes the request that will be sent to back when user presses "let's go" button

  Future<void> _sendRouteRequest() async {
    // if no start + dest was chosen
    if (_startPoint == null || _destinationPoint == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez définir départ et destination")),
      );
      return;
    }

    // request sent to back for routing
    final request = RouteRequest(
      startLat: _startPoint!.latitude,
      startLng: _startPoint!.longitude,
      destLat: _destinationPoint!.latitude,
      destLng: _destinationPoint!.longitude,
    );

    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:8000/api/v1/routes/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(request.toJson()),
      );

      // succes / error handling
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          _availableRoutes = List<Map<String, dynamic>>.from(
            (data['routes'] as List).map(
              (route) => {
                'route_id': route['route_id'],
                'name': route['name'],
                'description': route['description'] ?? '',
                'distance': route['distance'],
                'duration': route['duration'],
                'color': route['color'],
                'points': (route['coordinates'] as List)
                    .map((point) => LatLng(point['lat'], point['lng']))
                    .toList(),
              },
            ),
          );
          _selectedRouteIndex = null;
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${_availableRoutes.length} itinéraires trouvés !"),
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur serveur ${response.statusCode}")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erreur de connexion: $e")));
    }
  }

  Color _getColorFromString(String colorName) {
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

  // ==================================================================================================================
  // ======================================================= UI =======================================================
  // ==================================================================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ---------------------------------------- FLUTTER MAP ----------------------------------
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentPosition,
              initialZoom: 13.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.front',
              ),

              PolylineLayer(
                polylines: _availableRoutes.asMap().entries.map((entry) {
                  int index = entry.key;
                  var route = entry.value;
                  bool isSelected = _selectedRouteIndex == index;

                  return Polyline(
                    points: route['points'],
                    strokeWidth: isSelected ? 6.0 : 4.0,
                    color: _getColorFromString(
                      route['color'],
                    ).withValues(alpha: isSelected ? 1.0 : 0.6),
                  );
                }).toList(),
              ),

              // markers
              MarkerLayer(
                markers: [
                  // start
                  if (_startPoint != null)
                    Marker(
                      point: _startPoint!,
                      width: 60,
                      height: 60,
                      child: const Icon(
                        Icons.location_pin,
                        color: Colors.red,
                        size: 40,
                      ),
                    ),

                  // destination
                  if (_destinationPoint != null)
                    Marker(
                      point: _destinationPoint!,
                      width: 60,
                      height: 60,
                      child: const Icon(
                        Icons.flag,
                        color: Colors.green,
                        size: 40,
                      ),
                    ),

                  // current position
                  Marker(
                    point: _currentPosition,
                    width: 60,
                    height: 60,
                    child: const Icon(
                      Icons.my_location,
                      color: Colors.blue,
                      size: 40,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // =================================== start + dest fields ======================================
          if (!_isNavigating) // Cache les champs pendant la navigation
            Positioned(
              top: 50,
              left: 16,
              right: 16,
              child: Column(
                children: [
                  // start point
                  GestureDetector(
                    onTap: () => _openAddressSearch(isStart: true),
                    child: Material(
                      elevation: 4,
                      borderRadius: BorderRadius.circular(8),
                      child: TextFormField(
                        enabled: false,
                        decoration: InputDecoration(
                          hintText: _startAddress,
                          prefixIcon: const Icon(Icons.trip_origin),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // destination point
                  GestureDetector(
                    onTap: () => _openAddressSearch(isStart: false),
                    child: Material(
                      elevation: 4,
                      borderRadius: BorderRadius.circular(8),
                      child: TextFormField(
                        enabled: false,
                        decoration: InputDecoration(
                          hintText: _destinationAddress,
                          prefixIcon: const Icon(Icons.flag),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          //  =================================== BANNIÈRE DE NAVIGATION ======================================
          if (_isNavigating && _currentInstructions.isNotEmpty)
            Positioned(
              top: 50,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade700, Colors.blue.shade500],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Distance
                    Row(
                      children: [
                        const Icon(
                          Icons.straighten,
                          color: Colors.white,
                          size: 28,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _distanceToNextStep < 1000
                              ? "Dans ${_distanceToNextStep.toInt()} m"
                              : "Dans ${(_distanceToNextStep / 1000).toStringAsFixed(1)} km",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Instruction actuelle
                    Text(
                      _currentStepIndex < _currentInstructions.length
                          ? _currentInstructions[_currentStepIndex]['instruction']
                          : "Vous êtes arrivé !",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Progression
                    Text(
                      "Étape ${_currentStepIndex + 1}/${_currentInstructions.length}",
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // =================================== CARTES DE SÉLECTION ======================================
          if (_availableRoutes.isNotEmpty && !_isNavigating)
            Positioned(
              bottom: 16,
              left: 16,
              right: 80,
              child: Column(
                children: _availableRoutes.asMap().entries.map((entry) {
                  int index = entry.key;
                  var route = entry.value;
                  bool isSelected = _selectedRouteIndex == index;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedRouteIndex = index;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blue : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? Colors.blue
                              : Colors.grey.shade300,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 4,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: _getColorFromString(route['color']),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  route['name'],
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ),
                              ),
                              Icon(
                                isSelected
                                    ? Icons.check_circle
                                    : Icons.circle_outlined,
                                size: 20,
                                color: isSelected ? Colors.white : Colors.grey,
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          if (route['description'].toString().isNotEmpty)
                            Text(
                              route['description'],
                              style: TextStyle(
                                fontSize: 11,
                                color: isSelected
                                    ? Colors.white70
                                    : Colors.grey,
                              ),
                            ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                '${(route['distance'] / 1000).toStringAsFixed(1)} km',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.black,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${(route['duration'] / 60).toStringAsFixed(0)} min',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isSelected
                                      ? Colors.white70
                                      : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

          // =================================== BOUTONS GPS + CALCULER ======================================
          Positioned(
            bottom: 16,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Bouton GPS (si pas en navigation)
                if (!_isNavigating)
                  FloatingActionButton(
                    heroTag: "gps",
                    onPressed: _determinePosition,
                    child: const Icon(Icons.gps_fixed),
                  ),

                if (!_isNavigating) const SizedBox(height: 10),

                //  Bouton ARRÊTER (si en navigation)
                if (_isNavigating)
                  FloatingActionButton.extended(
                    heroTag: "stop_navigation",
                    onPressed: _stopNavigation,
                    backgroundColor: Colors.red,
                    icon: const Icon(Icons.stop),
                    label: const Text("Arrêter"),
                  )
                // Bouton Démarrer (si route sélectionnée)
                else if (_selectedRouteIndex != null)
                  FloatingActionButton.extended(
                    heroTag: "start_navigation",
                    onPressed: _startNavigation,
                    backgroundColor: Colors.green,
                    icon: const Icon(Icons.navigation),
                    label: const Text("Démarrer"),
                  )
                // Bouton Calculer (si départ + destination définis)
                else if (_startPoint != null && _destinationPoint != null)
                  FloatingActionButton(
                    heroTag: "route",
                    onPressed: _sendRouteRequest,
                    child: const Icon(Icons.directions),
                  ),
              ],
            ),
          ),
        ], // ← Ferme children du Stack
      ), // ← Ferme body (Stack)
    ); // ← Ferme Scaffold
  } // ← Ferme build()
} // ← Ferme _MapPageState
