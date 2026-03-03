import 'package:flutter/material.dart';
import '../../controllers/navigation_controller.dart';
import '../../models/route_model.dart';

class MapRouteCards extends StatelessWidget {
  final NavigationController navController;

  const MapRouteCards({
    super.key,
    required this.navController,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 16,
      left: 16,
      right: 80,
      child: Column(
        children: navController.availableRoutes.asMap().entries.map((entry) {
          int index = entry.key;
          RouteModel route = entry.value;
          bool isSelected = navController.selectedRouteIndex == index;

          return GestureDetector(
            onTap: () => navController.selectRoute(index),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? Colors.blue : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? Colors.blue : Colors.grey.shade300,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 40,
                    decoration: BoxDecoration(
                      color: navController.getRouteColor(route.color),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          route.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: isSelected ? Colors.white : Colors.black,
                          ),
                        ),
                        if (route.description.isNotEmpty)
                          Text(
                            route.description,
                            style: TextStyle(
                              fontSize: 11,
                              color: isSelected ? Colors.white70 : Colors.grey,
                            ),
                          ),
                        const SizedBox(height: 4),
                        Text(
                          '${(route.distance / 1000).toStringAsFixed(1)} km · ${(route.duration / 60).toStringAsFixed(0)} min',
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected ? Colors.white70 : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isSelected ? Icons.check_circle : Icons.circle_outlined,
                    size: 20,
                    color: isSelected ? Colors.white : Colors.grey,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}