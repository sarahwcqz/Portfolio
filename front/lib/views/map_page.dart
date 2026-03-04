// views/map_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
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
import 'widgets/incident_report_sheet.dart';
import 'widgets/context_alerts.dart';
import 'widgets/sos_button.dart';
import 'widgets/emergency_contact_onboarding_dialog.dart';
import '../services/emergency_contact_service.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {


  // =========================================================================
  //                                    PROPERTIES
  // ========================================================================
  
  final MapController _mapController = MapController();
  final EmergencyContactService _emergencyService = EmergencyContactService();
  bool _isFollowMode = true;



  // =========================================================================
  //                                      EXECUTION
  // =========================================================================
  @override
  void initState() {
    super.initState();
    _initializeMap();
    _checkEmergencyOnboarding();
  }

  @override
  void dispose() {
    super.dispose();
  }


  // ====================================================================================
  // ========================================= FUNCTIONS ================================
  // ====================================================================================


  // =========================================================================
  //                                      INIT FUNCTIONS
  // =========================================================================

  Future<void> _initializeMap() async {
    final locationController = context.read<LocationController>();
    final navController = context.read<NavigationController>();

    navController.setMapController(_mapController);

    final success = await locationController.determinePosition();
    if (!mounted) return;
    
    if (!success) {
      context.showError("Erreur GPS - Vérifiez les permissions");
      return;
    }

    navController.setStartPoint(
      locationController.currentPosition,
      "Ma position actuelle",
    );
    _mapController.move(locationController.currentPosition, 15.0);

    navController.startGPSTracking(
      onPositionUpdate: (position) {
        if (_isFollowMode) {
          double targetZoom = navController.navigationState.isNavigating
              ? 17.0
              : _mapController.camera.zoom;
          _mapController.move(position, targetZoom);
        }
        if (mounted) setState(() {});
      },
      onError: (message) => context.showError(message),
    );

    _refreshReports();
  }

  Future<void> _checkEmergencyOnboarding() async {
    final hasSeenOnboarding = await _emergencyService.hasSeenOnboarding();

    if (!hasSeenOnboarding && mounted) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const EmergencyContactOnboardingDialog(),
          );
        }
      });
    }
  }

  // =========================================================================
  //                                      EVENT FUNCTIONS
  // =========================================================================

  Future<void> _onRecenterPressed() async {
    setState(() => _isFollowMode = true);

    final controller = context.read<LocationController>();
    final navController = context.read<NavigationController>();
    
    await controller.determinePosition();
    if (!mounted) return;

    double targetZoom = navController.navigationState.isNavigating ? 17.0 : 15.0;
    _mapController.move(controller.currentPosition, targetZoom);

    _refreshReports();
  }

  Future<void> _onCalculateRoutesPressed() async {
    final navController = context.read<NavigationController>();
    
    context.showMessage("Calcul en cours...");

    try {
      await navController.calculateRoutes();
      if (!mounted) return;
      
      context.showMessage(
        "${navController.availableRoutes.length} itinéraires trouvés !",
      );
    } catch (e) {
      if (!mounted) return;
      context.showError(e.toString());
    }
  }

  Future<void> _onStartNavigationPressed() async {
    final navController = context.read<NavigationController>();
    final locationController = context.read<LocationController>();

    context.showLoader("Chargement du guidage...");

    try {
      await navController.startNavigation(
        onStepReached: () => context.showMessage("Étape suivante"),
        onArrival: () => context.showSuccess("Vous êtes arrivé !"),
        onRecalculating: () => context.showMessage("Recalcul de l'itinéraire..."),
      );
      
      if (!mounted) return;
      
      context.hideLoader();
      _mapController.move(locationController.currentPosition, 17.0);
      context.showMessage("Navigation démarrée");
    } catch (e) {
      if (!mounted) return;
      context.hideLoader();
      context.showError(e.toString());
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
    
    if (!mounted || result == null) return;

    final address = result.isCurrentPosition
        ? "Ma position actuelle"
        : result.address;
    
    if (isStart) {
      navController.setStartPoint(result.latLng, address);
    } else {
      navController.setDestinationPoint(result.latLng, address);
    }

  // DEBUG : a tester
    setState(() {
      _isFollowMode = false;
    });
    
    _mapController.move(result.latLng, 15.0);
    _refreshReports();
  }

  void _handleReportButtonPressed() {
    final user = Supabase.instance.client.auth.currentUser;

    if (user != null) {
      _showReportModal(user.id);
    } else {
      context.showError("Connectez-vous pour signaler un incident !");
    }
  }

  Future<void> _sendReportToBackend(Map<String, dynamic> data) async {
    context.showLoader("Envoi du signalement...");

    try {
      final success = await context.read<ReportController>().addReport(data);

      if (!mounted) return;
      context.hideLoader();

      if (success) {
        context.showSuccess("Signalement enregistré !");
        _refreshReports();
      } else {
        context.showError("Erreur lors de l'envoi");
      }
    } catch (e) {
      if (!mounted) return;
      context.hideLoader();
      context.showError("Impossible de contacter le serveur");
    }
  }

  // =========================================================================
  //                                          HELPERS FUNCTIONS
  // =========================================================================

  void _refreshReports() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReportController>().onMapMoved(_mapController.camera);
    });
  }

  Map<String, dynamic> _createReportData({
    required String userId,
    required String type,
  }) {
    final navController = context.read<NavigationController>();
    final locationController = context.read<LocationController>();
    final position = navController.currentLivePosition ??
        locationController.currentPosition;

    return {
      "user_id": userId,
      "type": type.toLowerCase(),
      "lat": position.latitude,
      "lng": position.longitude,
    };
  }

  void _showReportModal(String userId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => IncidentReportSheet(
        onReportSelected: (type) {
          Navigator.pop(context);
          final data = _createReportData(userId: userId, type: type);
          _sendReportToBackend(data);
        },
      ),
    );
  }

  bool _shouldShowStartMarker(
    NavigationController navController,
    LocationController locationController,
  ) {
    if (navController.startPoint == null) return false;
    if (navController.navigationState.isNavigating) return false;
    if (navController.startAddress.toLowerCase().contains("position")) {
      return false;
    }

    final distance = const Distance().as(
      LengthUnit.Meter,
      navController.startPoint!,
      navController.currentLivePosition ?? locationController.currentPosition,
    );

    return distance > 30;
  }

  // =========================================================================
  //                                              BUILD
  // =========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer2<LocationController, NavigationController>(
        builder: (context, locationController, navController, child) {
          return Stack(
            children: [
              _buildMap(locationController, navController),
              
              // ----------------------------------- address fields (not navigating)
              if (!navController.navigationState.isNavigating)
                MapAddressFields(
                  navController: navController,
                  onStartTap: () => _onAddressSearchPressed(isStart: true),
                  onDestinationTap: () => _onAddressSearchPressed(isStart: false),
                ),
              
              // ------------------------------------ navigation banner
              if (navController.navigationState.isNavigating)
                MapNavigationBanner(navState: navController.navigationState),
              
              // --------------------------------------- route selection cards
              if (navController.availableRoutes.isNotEmpty &&
                  !navController.navigationState.isNavigating)
                MapRouteCards(navController: navController),

              // --------------------------------------- recenter button (when not following)
              if (!_isFollowMode && navController.navigationState.isNavigating)
                Positioned(
                  bottom: 147,
                  right: 16,
                  child: FloatingActionButton(
                    heroTag: "recenter",
                    onPressed: _onRecenterPressed,
                    backgroundColor: const Color(0xFF512DA8),
                    elevation: 4,
                    child: const Icon(Icons.my_location, color: Colors.white),
                  ),
                ),
              
              // ------------------------------------------- main floating buttons
              MapFloatingButtons(
                navState: navController.navigationState,
                navController: navController,
                onRecenter: _onRecenterPressed,
                onCalculateRoutes: _onCalculateRoutesPressed,
                onStartNavigation: _onStartNavigationPressed,
                onReportIncident: _handleReportButtonPressed,
              ),
              
              // --------------------------------------------- SOS button
              const SosButton(),
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
        onMapEvent: (event) {
          // disable follow mode on user interaction
          if (event.source == MapEventSource.onDrag ||
              event.source == MapEventSource.onMultiFinger ||
              event.source == MapEventSource.scrollWheel) {
            if (_isFollowMode) {
              setState(() => _isFollowMode = false);
            }
          }
          
          // refresh reports on map movement
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
        _buildPolylines(navController),
        _buildReportLayer(),
        _buildMarkers(locationController, navController),
      ],
    );
  }

  Widget _buildPolylines(NavigationController navController) {
    return PolylineLayer(
      polylines: navController.availableRoutes
          .asMap()
          .entries
          .where((entry) {
            // show only selected route when navigating
            if (navController.navigationState.isNavigating) {
              return entry.key == navController.selectedRouteIndex;
            }
            return true;
          })
          .map((entry) {
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
          })
          .toList(),
    );
  }

  Widget _buildReportLayer() {
    return Consumer<ReportController>(
      builder: (context, controller, child) {
        return MapReportLayer(reports: controller.reports);
      },
    );
  }

  Widget _buildMarkers(
    LocationController locationController,
    NavigationController navController,
  ) {
    return MarkerLayer(
      markers: [
        // ----------------------------- start marker
        if (_shouldShowStartMarker(navController, locationController))
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
        
        // ------------------------------- dest marker
        if (navController.destinationPoint != null)
          Marker(
            point: navController.destinationPoint!,
            width: 60,
            height: 60,
            child: const Icon(Icons.flag, color: Colors.green, size: 40),
          ),
        
        // ---------------------------------- current position marker
        Marker(
          point: navController.currentLivePosition ??
              locationController.currentPosition,
          width: 60,
          height: 60,
          child: Transform.rotate(
            angle: navController.navigationState.currentHeading * (3.14159 / 180),
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
    );
  }
}