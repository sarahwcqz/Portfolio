// views/map_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
// import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../controllers/location_controller.dart';
import '../controllers/navigation_controller.dart';
import '../models/picked_location_model.dart';
import 'address_search_page.dart';
import 'widgets/map_address_fields.dart';
import 'widgets/map_navigation_banner.dart';
import 'widgets/map_route_cards.dart';
import 'widgets/map_floating_buttons.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  @override
  void dispose() {
    super.dispose();
  }

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
        if (navController.navigationState.isNavigating) {
          _mapController.move(position, 17.0);
        }
        if (mounted) setState(() {});
      },
      onError: (message) => _showError(message),
    );
  }

  Future<void> _onRecenterPressed() async {
    final controller = context.read<LocationController>();
    await controller.determinePosition();
    _mapController.move(controller.currentPosition, 15.0);
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
              MapFloatingButtons(
                navState: navController.navigationState,
                navController: navController,
                onRecenter: _onRecenterPressed,
                onCalculateRoutes: _onCalculateRoutesPressed,
                onStartNavigation: _onStartNavigationPressed,
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
        MarkerLayer(
          markers: [
            if (navController.startPoint != null &&
                !navController.navigationState.isNavigating)
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
}
