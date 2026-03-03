import 'package:flutter/material.dart';
import '../../models/navigation_state_model.dart';
import '../../controllers/navigation_controller.dart';

class MapFloatingButtons extends StatelessWidget {
  final NavigationState navState;
  final NavigationController navController;
  final VoidCallback onRecenter;
  final VoidCallback onCalculateRoutes;
  final VoidCallback onStartNavigation;
  final VoidCallback onReportIncident;

  const MapFloatingButtons({
    super.key,
    required this.navState,
    required this.navController,
    required this.onRecenter,
    required this.onCalculateRoutes,
    required this.onStartNavigation,
    required this.onReportIncident,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 16,
      right: 16,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: "report",
            onPressed: onReportIncident,
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            child: const Icon(Icons.warning_amber_rounded),
          ),
          const SizedBox(height: 10),
          if (!navState.isNavigating) ...[
            FloatingActionButton(
              heroTag: "gps",
              onPressed: onRecenter,
              backgroundColor: const Color(0xFF5E35B1),
              foregroundColor: Colors.white,
              child: const Icon(Icons.gps_fixed),
            ),
            const SizedBox(height: 10),
          ],
          if (navState.isNavigating)
            FloatingActionButton(
              heroTag: "stop",
              onPressed: () => navController.stopNavigation(),
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              child: const Icon(Icons.stop),
            )
          else if (navController.selectedRouteIndex != null)
            FloatingActionButton(
              heroTag: "start",
              onPressed: onStartNavigation,
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              child: const Icon(Icons.navigation),
            )
          else if (navController.startPoint != null &&
              navController.destinationPoint != null)
            FloatingActionButton(
              heroTag: "calculate",
              onPressed: onCalculateRoutes,
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              child: const Icon(Icons.directions),
            ),
        ],
      ),
    );
  }
}
