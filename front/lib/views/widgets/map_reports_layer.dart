import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../models/reports_model.dart';

class MapReportLayer extends StatelessWidget {
  final List<ReportModel> reports;

  const MapReportLayer({
    super.key,
    required this.reports,
  });

  @override
  Widget build(BuildContext context) {
    return MarkerLayer(
      markers: reports.map((s) {
        return Marker(
          point: LatLng(s.lat, s.lng),
          width: 40,
          height: 40,
          child: _buildIcon(s.type),
        );
      }).toList(),
    );
  }

  Widget _buildIcon(String type) {
    switch (type.toLowerCase()) {
      case 'accident':
        return const Icon(Icons.warning, color: Colors.red, size: 30);
      case 'travaux':
        return const Icon(Icons.construction, color: Colors.orange, size: 30);
      case 'danger':
        return const Icon(Icons.dangerous, color: Colors.red, size: 30);
      case 'test':
        return const Icon(Icons.bug_report, color: Colors.purple, size: 30);
      default:
        return const Icon(Icons.info, color: Colors.blue, size: 30);
    }
  }
}