import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import '../models/reports_model.dart';
import '../models/bounding_box_model.dart';
import '../services/reports_service.dart';

class ReportController extends ChangeNotifier {
  final ReportService _service = ReportService();

  List<ReportModel> _reports = [];
  bool _isLoading = false;
  BoundingBox? _lastBoundingBox;
  Timer? _debounceTimer;

  List<ReportModel> get reports => _reports;
  bool get isLoading => _isLoading;

  // ─── Appelé à chaque mouvement de carte ───────────────────────
  void onMapMoved(MapCamera camera) {
    debugPrint('onMapMoved appelé');  // DEBUG

    final bbox = _getBoundingBoxFromCamera(camera);
    debugPrint('bbox: ${bbox.minLat}, ${bbox.maxLat}, ${bbox.minLng}, ${bbox.maxLng}');  // DEBUG

    // Ignore si le mouvement est trop petit
    if (!bbox.hasSignificantlyChangedFrom(_lastBoundingBox)) {
      debugPrint('Changement ignoré car trop insignifiant');  //
      return;
      }

    // Reset le timer à chaque mouvement
    _debounceTimer?.cancel();

    // Lance la requête après 500ms d'inactivité
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _loadReports(bbox);
    });
  }

  // ─── Chargement depuis le back ─────────────────────────────────
  Future<void> _loadReports(BoundingBox bbox) async {
    _isLoading = true;
    _lastBoundingBox = bbox;
    notifyListeners();

    try {
      _reports = await _service.getReportsInBoundingBox(bbox);
      debugPrint('${_reports.length} reports chargés'); // DEBUG
      for (var r in _reports) {
      debugPrint('${r.type} at ${r.lat}, ${r.lng}');  // DEBUG
    }
    } catch (e) {
      debugPrint('Erreur chargement reports: $e');
      _reports = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── Extrait la bounding box depuis la caméra Flutter Map ──────
  BoundingBox _getBoundingBoxFromCamera(MapCamera camera) {
    final bounds = camera.visibleBounds;
    return BoundingBox(
      minLat: bounds.south,
      maxLat: bounds.north,
      minLng: bounds.west,
      maxLng: bounds.east,
    );
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}