import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
// GPS
import 'package:geolocator/geolocator.dart';

//--------------------------------------- MAP WIDGET ----------------------------------
class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  // controller to manipulate map through code
  final MapController _mapController = MapController();
  // Default position (Paris)
  LatLng _currentPosition = const LatLng(48.8566, 2.3522);

// when starting, calls determinePosition function
  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

// ======================================= FUNCTIONS ======================================

  /// Asks for permission + get location
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
        const SnackBar(content: Text("Veuillez activer le GPS"))
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
          const SnackBar(content: Text("Permission GPS refusée"))
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
  // if no current position available, display msg
  } catch (e) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Impossible d'obtenir la position exact: $e"))
        );
      });
  }
}

// ======================================================= UI ====================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FlutterMap(
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
          MarkerLayer(
            markers: [
              // User on the map (blue marker)
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
      // Recenter button
      floatingActionButton: FloatingActionButton(
        // calls determinePosition function when clicked
        onPressed: _determinePosition,
        child: const Icon(Icons.gps_fixed),
      ),
    );
  }
}