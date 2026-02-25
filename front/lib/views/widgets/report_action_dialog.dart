import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/reports_controller.dart';
import '../../models/reports_model.dart';

class ReportConfirmationDialog extends StatefulWidget {
  final ReportModel report;

  const ReportConfirmationDialog({
    super.key,
    required this.report,
  });

  @override
  State<ReportConfirmationDialog> createState() =>
      _ReportConfirmationDialogState();
}

class _ReportConfirmationDialogState extends State<ReportConfirmationDialog> {
  bool _isLoading = false;

  // -------------------------------- ✅ button ---------------------------
  Future<void> _handleConfirm() async {
    setState(() => _isLoading = true);

    final controller = context.read<ReportController>();
    final message = await controller.confirmReport(widget.report.id);

    if (!mounted) return;

    setState(() => _isLoading = false);

    // close dialog
    Navigator.of(context).pop();

    // error message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: message.contains("Erreur") ||
                message.contains("déjà voté")
            ? Colors.red
            : Colors.green,
      ),
    );
  }

  // ------------------------------------- ❌ button ------------------------------
  Future<void> _handleInfirm() async {
    setState(() => _isLoading = true);

    final controller = context.read<ReportController>();
    final message = await controller.infirmReport(widget.report.id);

    if (!mounted) return;

    setState(() => _isLoading = false);

    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: message.contains("Erreur") ||
                message.contains("déjà voté")
            ? Colors.red
            : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ................................. icon......................
            _buildIcon(widget.report.type),
            const SizedBox(height: 16),

            // ................................. title .....................
            Text(
              _getTitle(widget.report.type),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            // ................................ toujours là? ..............
            const Text(
              "Ce signalement est-il toujours présent ?",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 32),

            // ................................. Y/N buttons .............
            if (_isLoading)
              const CircularProgressIndicator()
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // ...................................✅
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _handleConfirm,
                      icon: const Icon(Icons.check_circle, size: 24),
                      label: const Text("Oui"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // ....................................❌
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _handleInfirm,
                      icon: const Icon(Icons.cancel, size: 24),
                      label: const Text("Non"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  // DEBUG a changer en fonction des types

  // ------------------------------------ icons -------------------------------
  Widget _buildIcon(String type) {
    IconData iconData;
    Color color;

    switch (type.toLowerCase()) {
      case 'accident':
        iconData = Icons.warning;
        color = Colors.red;
        break;
      case 'travaux':
        iconData = Icons.construction;
        color = Colors.orange;
        break;
      case 'danger':
        iconData = Icons.dangerous;
        color = Colors.red;
        break;
      case 'test':
        iconData = Icons.bug_report;
        color = Colors.purple;
        break;
      default:
        iconData = Icons.info;
        color = Colors.blue;
    }

    return Icon(iconData, size: 60, color: color);
  }

  // ----------------------------------- title -------------------------------
  String _getTitle(String type) {
    switch (type.toLowerCase()) {
      case 'accident':
        return "Accident";
      case 'travaux':
        return "Travaux";
      case 'danger':
        return "Danger";
      case 'test':
        return "Test";
      default:
        return "Signalement";
    }
  }
}