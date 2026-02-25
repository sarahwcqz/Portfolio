import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import '../models/reports_model.dart';
import '../models/bounding_box_model.dart';
import '../services/reports_service.dart';
import '../services/report_action_service.dart';

class ReportController extends ChangeNotifier {
  final ReportService _service = ReportService();
  final ReportActionService _actionService = ReportActionService();

  List<ReportModel> _reports = [];
  bool _isLoading = false;
  BoundingBox? _lastBoundingBox;
  Timer? _debounceTimer;

  List<ReportModel> get reports => _reports;
  bool get isLoading => _isLoading;


  // ============================================== get reports to be visible on map ==========================
  // ==========================================================================================================


  // ------------------------------ when map moved -------------------------------
  void onMapMoved(MapCamera camera) {
    debugPrint('onMapMoved appelé'); // DEBUG

    final bbox = _getBoundingBoxFromCamera(camera);
    debugPrint(
      'bbox: ${bbox.minLat}, ${bbox.maxLat}, ${bbox.minLng}, ${bbox.maxLng}',
    ); // DEBUG

    // if mvmt too small, ignore
    if (!bbox.hasSignificantlyChangedFrom(_lastBoundingBox)) {
      debugPrint('Changement ignoré car trop insignifiant'); // DEBUG
      return;
    }

    // Reset timer when mvmt
    _debounceTimer?.cancel();

    // request after 500 ms
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _loadReports(bbox);
    });
  }

  // ------------------------------ load reports visible ---------------------------------
  Future<void> _loadReports(BoundingBox bbox) async {
    _isLoading = true;
    _lastBoundingBox = bbox;
    notifyListeners();

    try {
      final allReports = await _service.getReportsInBoundingBox(bbox);

      // making sure to return reports that aren't expired // DEBUG, to be removed?
      final nowUtc = DateTime.now().toUtc();

      _reports = allReports.where((r) {
        final isValid = r.expiresAt.isAfter(nowUtc);

        if (!isValid) {
          debugPrint('DEBUG: Signalement ${r.type} ignoré car expiré (UTC)');
        } //DEBUG
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

  // ------------------------------- get visible bounding box from Flutter Map ----------------
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



  // =================================== confirm / infirm report =======================================
  // ====================================================================================================

  // -------------------------------------- CONFIRM ----------------------------------------------------

  Future<String> confirmReport(String reportId) async {
    try {
      await _actionService.confirmReport(reportId);
      
      // Reload reports  // DEBUG ; interet?
      if (_lastBoundingBox != null) {
        await _loadReports(_lastBoundingBox!);
      }
      
      return "Merci pour votre contribution !";
    } catch (e) {
      if (e.toString().contains('400')) {
        return "Vous avez déjà voté pour ce signalement, merci.";
      } else if (e.toString().contains('404')) {
        return "Signalement introuvable";
      } else if (e.toString().contains('401')) {
        return "Session expirée, reconnectez-vous";   // DEBUG : possible?
      } else {
        return "Erreur : ${e.toString()}";
      }
    }
  }

  // -------------------------------------- INFIRM -----------------------------------------------------

  Future<String> infirmReport(String reportId) async {
    try {
      await _actionService.infirmReport(reportId);
      
      // Reload reports // DEBUG
      if (_lastBoundingBox != null) {
        await _loadReports(_lastBoundingBox!);
      }
      
      return "Merci pour votre contribution !";
    } catch (e) {
      if (e.toString().contains('400')) {
        return "Vous avez déjà voté pour ce signalement";
      } else if (e.toString().contains('404')) {
        return "Signalement introuvable";
      } else if (e.toString().contains('401')) {
        return "Session expirée, reconnectez-vous";   // DEBUG
      } else {
        return "Erreur : ${e.toString()}";
      }
    }
  }

}


