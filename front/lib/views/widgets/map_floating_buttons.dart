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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (navController.selectedRouteIndex != null)
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
    );
  }
}
