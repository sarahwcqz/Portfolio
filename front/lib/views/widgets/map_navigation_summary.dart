import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/navigation_state_model.dart';

class MapNavigationSummary extends StatelessWidget {
  final NavigationState navState;
  final VoidCallback onStop;
  final bool showRecenter;
  final VoidCallback? onRecenter;
  final String arrivalTime;

  const MapNavigationSummary({
    super.key,
    required this.navState,
    required this.onStop,
    required this.arrivalTime,
    this.showRecenter = false,
    this.onRecenter,
  });

  @override
  Widget build(BuildContext context) {
    int minutesRemaining = navState.durationRemaining;
    double totalDist = navState.totalDistanceRemaining;
    String distDisplay = totalDist >= 1000
        ? "${(totalDist / 1000).toStringAsFixed(1)} km"
        : "${totalDist.toInt()} m";

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onStop,
            icon: const Icon(Icons.close, color: Colors.redAccent, size: 28),
            style: IconButton.styleFrom(backgroundColor: Colors.grey[100]),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "$minutesRemaining min",
                  style: const TextStyle(
                    color: Colors.green,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "$distDisplay • $arrivalTime",
                  style: const TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ],
            ),
          ),
          if (showRecenter)
            FloatingActionButton(
              heroTag: "recenter_summary",
              onPressed: onRecenter,
              backgroundColor: const Color(0xFF512DA8),
              elevation: 4,
              mini: true,
              child: const Icon(Icons.my_location, color: Colors.white),
            )
          else
            const Icon(Icons.keyboard_arrow_up, color: Colors.black26),
        ],
      ),
    );
  }
}
