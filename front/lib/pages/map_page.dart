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
          SnackBar(content: Text("Impossible d'obtenir la position exacte: $e")),
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

    final response = await http.post(
      Uri.parse('https://ton-backend.com/api/itineraire'), // DEBUG
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(request.toJson()),
    );

    // succes / error handling
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // TODO: traiter la réponse (itinéraire, polyline, instructions)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Itinéraire reçu du backend")), // DEBUG
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Erreur serveur")));
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
        ],
      ),

      // ================================= floating buttons ===========================================
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // .............. recenter button ..........................
          FloatingActionButton(
            heroTag: "gps",
            onPressed: _determinePosition,
            child: const Icon(Icons.gps_fixed),
          ),
          const SizedBox(height: 10),
          // .............. let's go button ...........................
          FloatingActionButton(
            heroTag: "route",
            onPressed: _sendRouteRequest,
            child: const Icon(Icons.directions),
          ),
        ],
      ),
    );
  }
}
