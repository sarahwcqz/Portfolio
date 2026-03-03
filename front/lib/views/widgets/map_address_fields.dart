import 'package:flutter/material.dart';
import '../../controllers/navigation_controller.dart';

class MapAddressFields extends StatelessWidget {
  final NavigationController navController;
  final VoidCallback onStartTap;
  final VoidCallback onDestinationTap;

  const MapAddressFields({
    super.key,
    required this.navController,
    required this.onStartTap,
    required this.onDestinationTap,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 50,
      left: 16,
      right: 16,
      child: Column(
        children: [
          _buildAddressField(
            hint: navController.startAddress,
            icon: Icons.trip_origin,
            onTap: onStartTap,
          ),
          const SizedBox(height: 10),
          _buildAddressField(
            hint: navController.destinationAddress,
            icon: Icons.flag,
            onTap: onDestinationTap,
          ),
        ],
      ),
    );
  }

  Widget _buildAddressField({
    required String hint,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(8),
        child: TextFormField(
          enabled: false,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
    );
  }
}