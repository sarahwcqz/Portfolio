import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';
import '../../models/reports_model.dart';
import 'report_validation_dialog.dart';

class MapReportLayer extends StatelessWidget {
  final List<ReportModel> reports;

  const MapReportLayer({super.key, required this.reports});

  @override
  Widget build(BuildContext context) {
    final List<Marker> markers = reports.map((report) {
      return Marker(
        point: LatLng(report.lat, report.lng),
        width: 40,
        height: 40,
        child: GestureDetector(      // <------------------------ onTAP -> open dialog
            onTap: () => _showConfirmationDialog(
              context,
              report,
            ),
          child: _buildIcon(report.type),
        ),
      );
    }).toList();

    return MarkerClusterLayerWidget(
      options: MarkerClusterLayerOptions(
        maxClusterRadius: 45,
        size: const Size(40, 40),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(5),
        markers: markers,
        builder: (context, clusterMarkers) {
          return Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.orange.withValues(alpha: 0.9), // DEBUG to change
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                clusterMarkers.length.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // --------------------------------- open dialog -----------------------------
  void _showConfirmationDialog(BuildContext context, ReportModel report) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ReportConfirmationDialog(report: report);
      },
    );
  } 

  Widget _buildIcon(String type) {
    switch (type.toLowerCase()) {
      // DEBUG (a changer en fct du choix de Leo)
      case 'permanent':
        return const Icon(Icons.stairs, color: Colors.purple, size: 30);
      case 'travaux':
        return const Icon(Icons.construction, color: Colors.orange, size: 30);
      case 'dégradation':
        return const Icon(Icons.warning, color: Colors.blue, size: 30);
      case 'obstruction':
        return const Icon(Icons.block, color: Colors.red, size: 30);  // accessible | block | accessible_forward
      default:
        return const Icon(Icons.info, color: Colors.yellow, size: 30);
    }
  }
}
