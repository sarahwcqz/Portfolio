import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
// import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../controllers/location_controller.dart';
import '../controllers/navigation_controller.dart';
import '../controllers/reports_controller.dart';
import '../models/picked_location_model.dart';
import 'address_search_page.dart';
import 'widgets/map_address_fields.dart';
import 'widgets/map_navigation_banner.dart';
import 'widgets/map_route_cards.dart';
import 'widgets/map_floating_buttons.dart';
import 'widgets/map_reports_layer.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final MapController _mapController = MapController();

  final supabase = Supabase.instance.client;

  void _handleReportButtonPressed() {
    final user = supabase.auth.currentUser;

    if (user != null) {
      // Étape 3 : On ouvre l'interface (UI)
      _showReportModal(user.id);
    } else {
      // Petit message d'erreur si pas connecté
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Connectez-vous pour signaler un incident !"),
        ),
      );
    }
  }

  Map<String, dynamic> _createReportData({
    required String userId,
    required String type,
  }) {
    final locationController = context.read<LocationController>();

    final double lat = locationController.currentPosition.latitude;
    final double lng = locationController.currentPosition.longitude;

    return {
      "user_id": userId,
      "type": type.toLowerCase(),
      "lat": lat,
      "lng": lng,
      "expires_at": DateTime.now()
          .add(const Duration(minutes: 15))
          .toUtc()
          .toIso8601String(),
    };
  }

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  @override
  void dispose() {
    super.dispose();
  }

  bool _isFollowMode = true;

  Future<void> _initializeMap() async {
    final locationController = context.read<LocationController>();
    final navController = context.read<NavigationController>();

    navController.setMapController(_mapController);

    final success = await locationController.determinePosition();
    if (!success) {
      _showError("Erreur GPS - Vérifiez les permissions");
      return;
    }

    navController.setStartPoint(
      locationController.currentPosition,
      "Ma position actuelle",
    );

    _mapController.move(locationController.currentPosition, 15.0);

    navController.startGPSTracking(
      onPositionUpdate: (position) {
        if (navController.navigationState.isNavigating && _isFollowMode) {
          _mapController.move(position, 17.0);
        }
        if (mounted) setState(() {});
      },
      onError: (message) => _showError(message),
    );

    // initial loading of reports when map is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReportController>().onMapMoved(_mapController.camera);
    });
  }

  Future<void> _onRecenterPressed() async {
    setState(() {
      _isFollowMode = true;
    });
    final controller = context.read<LocationController>();
    final navController = context.read<NavigationController>();
    await controller.determinePosition();
    double targetZoom = navController.navigationState.isNavigating
        ? 17.0
        : 15.0;
    _mapController.move(controller.currentPosition, targetZoom);

    // call function to get reports from Db in visible bounding box
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReportController>().onMapMoved(_mapController.camera);
    });
  }

  Future<void> _onCalculateRoutesPressed() async {
    final navController = context.read<NavigationController>();
    _showMessage("Calcul en cours...");
    try {
      await navController.calculateRoutes();
      _showMessage(
        "${navController.availableRoutes.length} itinéraires trouvés !",
      );
    } catch (e) {
      _showError(e.toString());
    }
  }

  Future<void> _onStartNavigationPressed() async {
    final navController = context.read<NavigationController>();
    final locationController = context.read<LocationController>();

    _showLoader("Chargement du guidage...");

    try {
      await navController.startNavigation(
        onStepReached: () => _showMessage("Étape suivante"),
        onArrival: () => _showSuccess("Vous êtes arrivé !"),
        onRecalculating: () => _showMessage("Recalcul de l'itinéraire..."),
      );
      _hideLoader();
      _mapController.move(locationController.currentPosition, 17.0);
      _showMessage("Navigation démarrée");
    } catch (e) {
      _hideLoader();
      _showError(e.toString());
    }
  }

  Future<void> _onAddressSearchPressed({required bool isStart}) async {
    final locationController = context.read<LocationController>();
    final navController = context.read<NavigationController>();

    final result = await Navigator.push<PickedLocation>(
      context,
      MaterialPageRoute(
        builder: (_) => AddressSearchPage(
          currentPosition: locationController.currentPosition,
        ),
      ),
    );

    if (result != null) {
      final address = result.isCurrentPosition
          ? "Ma position actuelle"
          : result.address;
      if (isStart) {
        navController.setStartPoint(result.latLng, address);
      } else {
        navController.setDestinationPoint(result.latLng, address);
      }
      _mapController.move(result.latLng, 15.0);

      // call function to get reports from Db in visible bounding box
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<ReportController>().onMapMoved(_mapController.camera);
      });
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _showLoader(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 16),
            Text(message),
          ],
        ),
        duration: const Duration(seconds: 30),
      ),
    );
  }

  void _hideLoader() => ScaffoldMessenger.of(context).clearSnackBars();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer2<LocationController, NavigationController>(
        builder: (context, locationController, navController, child) {
          return Stack(
            children: [
              _buildMap(locationController, navController),
              if (!navController.navigationState.isNavigating)
                MapAddressFields(
                  navController: navController,
                  onStartTap: () => _onAddressSearchPressed(isStart: true),
                  onDestinationTap: () =>
                      _onAddressSearchPressed(isStart: false),
                ),
              if (navController.navigationState.isNavigating)
                MapNavigationBanner(navState: navController.navigationState),
              if (navController.availableRoutes.isNotEmpty &&
                  !navController.navigationState.isNavigating)
                MapRouteCards(navController: navController),

              if (!_isFollowMode && navController.navigationState.isNavigating)
                Positioned(
                  bottom: 147,
                  right: 16,
                  child: FloatingActionButton(
                    onPressed: _onRecenterPressed,
                    backgroundColor: const Color(0xFF512DA8),
                    elevation: 4,
                    child: const Icon(Icons.my_location, color: Colors.white),
                  ),
                ),
              MapFloatingButtons(
                navState: navController.navigationState,
                navController: navController,
                onRecenter: _onRecenterPressed,
                onCalculateRoutes: _onCalculateRoutesPressed,
                onStartNavigation: _onStartNavigationPressed,
                onReportIncident: _handleReportButtonPressed,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMap(
    LocationController locationController,
    NavigationController navController,
  ) {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: locationController.currentPosition,
        initialZoom: 13.0,
        minZoom: 10.0,
        maxZoom: 18.0,
        // --------------------------- if mouvement on map -----------------
        onMapEvent: (event) {
          if (event.source == MapEventSource.onDrag ||
              event.source == MapEventSource.onMultiFinger ||
              event.source == MapEventSource.scrollWheel) {
            if (_isFollowMode) {
              setState(() {
                _isFollowMode = false;
              });
            }
          }
          if (event is MapEventMoveEnd || event is MapEventScrollWheelZoom) {
            context.read<ReportController>().onMapMoved(event.camera);
          }
        },
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.front',
        ),
        PolylineLayer(
          polylines: navController.availableRoutes.asMap().entries.map((entry) {
            int index = entry.key;
            var route = entry.value;
            bool isSelected = navController.selectedRouteIndex == index;
            return Polyline(
              points: route.points,
              strokeWidth: isSelected ? 6.0 : 4.0,
              color: navController
                  .getRouteColor(route.color)
                  .withValues(alpha: isSelected ? 1.0 : 0.6),
            );
          }).toList(),
        ),
        Consumer<ReportController>(
          builder: (context, controller, child) {
            return MapReportLayer(reports: controller.reports);
          },
        ),
        MarkerLayer(
          markers: [
            if (navController.startPoint != null &&
                !navController.navigationState.isNavigating &&
                const Distance().as(
                      LengthUnit.Meter,
                      navController.startPoint!,
                      locationController.currentPosition,
                    ) >
                    10)
              Marker(
                point: navController.startPoint!,
                width: 60,
                height: 60,
                child: const Icon(
                  Icons.location_pin,
                  color: Colors.red,
                  size: 40,
                ),
              ),
            if (navController.destinationPoint != null)
              Marker(
                point: navController.destinationPoint!,
                width: 60,
                height: 60,
                child: const Icon(Icons.flag, color: Colors.green, size: 40),
              ),
            Marker(
              // Si on navigue, on utilise la position "live", sinon la position fixe
              point:
                  (navController.navigationState.isNavigating &&
                      navController.currentLivePosition != null)
                  ? navController.currentLivePosition!
                  : locationController.currentPosition,
              width: 60,
              height: 60,
              child: Transform.rotate(
                angle:
                    navController.navigationState.currentHeading *
                    (3.14159 / 180),
                child: Icon(
                  navController.navigationState.isNavigating
                      ? Icons.navigation
                      : Icons.my_location,
                  color: Colors.blue,
                  size: 40,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _sendReportToBackend(Map<String, dynamic> data) async {
    _showLoader("Envoi du signalement...");
    try {
      // final baseUrl =
      // dotenv.env['NGROK_URL'] ?? 'https://default-url.ngrok-free.app';
      final String baseUrl = 'http://10.0.2.2:8000/api/v1';
      final finalUri = Uri.parse('$baseUrl/reports/');
      final response = await http.post(
        finalUri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(data),
      );

      _hideLoader();

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSuccess("Signalement enregistré !");
        // On rafraîchit la carte pour voir le point immédiatement
        if (mounted) {
          context.read<ReportController>().onMapMoved(_mapController.camera);
        }
      } else {
        _showError("Erreur serveur : ${response.statusCode}");
      }
    } catch (e) {
      _hideLoader();
      _showError("Impossible de contacter le serveur");
    }
  }

  void _showReportModal(String userId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          top: 15,
          left: 20,
          right: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Quel incident voulez-vous signaler ?",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 25),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 2,
              mainAxisSpacing: 15,
              crossAxisSpacing: 15,
              childAspectRatio: 1.5,
              children: [
                _buildReportOption(
                  userId,
                  'travaux',
                  Icons.construction,
                  Colors.orange,
                ),
                _buildReportOption(
                  userId,
                  'accident',
                  Icons.warning,
                  Colors.red,
                ),
                _buildReportOption(
                  userId,
                  'danger',
                  Icons.dangerous,
                  Colors.redAccent,
                ),
                _buildReportOption(
                  userId,
                  'test',
                  Icons.bug_report,
                  Colors.purple,
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildReportOption(
    String userId,
    String type,
    IconData icon,
    Color color,
  ) {
    return InkWell(
      onTap: () {
        final data = _createReportData(userId: userId, type: type);
        Navigator.pop(context);
        _sendReportToBackend(data);
      },
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 35),
            const SizedBox(height: 8),
            Text(
              type.toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
