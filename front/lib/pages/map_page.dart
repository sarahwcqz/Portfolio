import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapPage extends StatelessWidget {
  const MapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FlutterMap(
        options: MapOptions(
          initialCenter: LatLng(48.8566, 2.3522), // Coordonnées de Paris
          initialZoom: 13.0,
        ),
        children: [
          TileLayer( // C'est ici qu'on appelle OpenStreetMap
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.votreprojet.app', // Important pour OSM
          ),
        ],
      ),
    );
  }
}