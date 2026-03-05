import 'package:flutter/material.dart';
import '../../models/navigation_state_model.dart';

class MapInstructionBanner extends StatelessWidget {
  final NavigationState navState;

  const MapInstructionBanner({super.key, required this.navState});

  @override
  Widget build(BuildContext context) {
    return Positioned(
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
            Row(
              children: [
                const Icon(Icons.straighten, color: Colors.white, size: 28),
                const SizedBox(width: 8),
                Text(
                  _formatDistance(navState.distanceToNextStep),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              navState.currentStepIndex < navState.instructions.length
                  ? navState.instructions[navState
                            .currentStepIndex]['instruction'] ??
                        ''
                  : "Vous êtes arrivé !",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Étape ${navState.currentStepIndex + 1}/${navState.instructions.length}",
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDistance(double distance) {
    if (distance < 1000) {
      return "Dans ${distance.toInt()} m";
    } else {
      return "Dans ${(distance / 1000).toStringAsFixed(1)} km";
    }
  }
}
