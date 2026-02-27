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

  Future<bool> addReport(Map<String, dynamic> data) async {
    _isLoading = true;
    notifyListeners(); // On prévient l'UI qu'on travaille

    try {
      // On demande au service de faire la requête HTTP
      final success = await _service.createReport(data);
      return success;
    } catch (e) {
      debugPrint('Erreur Controller addReport: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners(); // On a fini
    }
  }

  // ─── Appelé à chaque mouvement de carte ───────────────────────
  void onMapMoved(MapCamera camera) {
    debugPrint('onMapMoved appelé'); // DEBUG

    final bbox = _getBoundingBoxFromCamera(camera);
    debugPrint(
      'bbox: ${bbox.minLat}, ${bbox.maxLat}, ${bbox.minLng}, ${bbox.maxLng}',
    ); // DEBUG

    // Ignore si le mouvement est trop petit
    if (!bbox.hasSignificantlyChangedFrom(_lastBoundingBox)) {
      debugPrint('Changement ignoré car trop insignifiant'); //
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
      // On récupère tous les rapports via le service
      final allReports = await _service.getReportsInBoundingBox(bbox);

      // MODIFICATION : FILTRAGE PAR DATE UTC
      final nowUtc = DateTime.now().toUtc();

      _reports = allReports.where((r) {
        // On vérifie si l'expiration est bien dans le futur par rapport à l'UTC
        final isValid = r.expiresAt.isAfter(nowUtc);

        if (!isValid) {
          debugPrint('DEBUG: Signalement ${r.type} ignoré car expiré (UTC)');
        }
        return isValid;
      }).toList();

      debugPrint('${_reports.length} reports valides chargés et affichés');
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
