import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
// GPS
import 'package:geolocator/geolocator.dart';
// conversion JSON <-> dart object
import 'dart:convert';
// http requests
import 'package:http/http.dart' as http;

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

  // --------------------------- INIT ------------------------------
  // when starting, calls determinePosition function
  @override
  void initState() {
    super.initState();
    _determinePosition();
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
          _startPoint = result.latLng; // <- to send to back for GraphH routing
          _startAddress = result.isCurrentPosition
              ? "Ma position actuelle"
              : result.address;
        } else {
          _destinationPoint =
              result.latLng; // <- to send to back for GraphH routing
          _destinationAddress = result.isCurrentPosition
              ? "Ma position actuelle"
              : result.address;
        }
      });
      // Centers on result <------------------------ change it later?
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
        Uri.parse(
          'http://10.0.2.2:8000/api/v1/routes/',
        ), // <---- will change when testing app
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
          _selectedRouteIndex = null; // Aucune route sélectionnée par défaut
        });
        // TO DO: traiter la réponse (itinéraire, polyline, instructions)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Itinéraire reçu du backend")), // DEBUG
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur serveur ${response.statusCode}")),
        );
      }
    } catch (e) {
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
            //binding controller
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentPosition,
              initialZoom: 13.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                // identity of project for api call to OSM
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
                    ).withOpacity(isSelected ? 1.0 : 0.6),
                  );
                }).toList(),
              ),

              // ..............................markers.........................
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

                  // current position(user on the map)
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
          Positioned(
            top: 50,
            left: 16,
            right: 16,
            child: Column(
              children: [
                // ------------ start point ------------------
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
                // ------------- destination point ------------
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

          // =================================== route selection cards ======================================
          // =================================== route selection cards + buttons ======================================
          if (_availableRoutes.isNotEmpty)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // ========== CARTES DE SÉLECTION (À GAUCHE) ==========
                  Expanded(
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
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Nom de la route
                                Row(
                                  children: [
                                    Container(
                                      width: 4,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: _getColorFromString(
                                          route['color'],
                                        ),
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
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.grey,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                // Description
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
                                // Distance et durée
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

                  const SizedBox(width: 12),

                  // ========== BOUTONS (À DROITE) ==========
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Bouton GPS
                      FloatingActionButton(
                        heroTag: "gps",
                        onPressed: _determinePosition,
                        child: const Icon(Icons.gps_fixed),
                      ),
                      const SizedBox(height: 10),
                      // Bouton Itinéraire
                      FloatingActionButton(
                        heroTag: "route",
                        onPressed: _sendRouteRequest,
                        child: const Icon(Icons.directions),
                      ),
                    ],
                  ),
                ],
              ),
            )
          else
            // ========== BOUTONS SEULS (SI PAS DE ROUTES) ==========
            Positioned(
              bottom: 16,
              right: 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FloatingActionButton(
                    heroTag: "gps",
                    onPressed: _determinePosition,
                    child: const Icon(Icons.gps_fixed),
                  ),
                  const SizedBox(height: 10),
                  FloatingActionButton(
                    heroTag: "route",
                    onPressed: _sendRouteRequest,
                    child: const Icon(Icons.directions),
                  ), // ← Ferme FloatingActionButton route
                ], // ← Ferme children de Column
              ), // ← Ferme child (Column)
            ), // ← Ferme Positioned (else)
        ], // ← Ferme children de Stack
      ), // ← Ferme body (Stack)
    ); // ← Ferme Scaffold
  } // ← Ferme Widget build()
} // ← Ferme class _MapPageState
