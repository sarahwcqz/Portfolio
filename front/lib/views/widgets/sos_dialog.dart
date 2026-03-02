import 'package:flutter/material.dart';
import '../../services/emergency_contact_service.dart';
import '../../services/phone_call_service.dart';
import '../../models/emergency_contact_model.dart';

class SosDialog extends StatefulWidget {
  const SosDialog({super.key});

  @override
  State<SosDialog> createState() => _SosDialogState();
}

class _SosDialogState extends State<SosDialog> {
  final EmergencyContactService _contactService = EmergencyContactService();
  final PhoneCallService _phoneService = PhoneCallService();

  EmergencyContactModel? _emergencyContact;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContact();
  }

  Future<void> _loadContact() async {
    final contact = await _contactService.getContact();
    setState(() {
      _emergencyContact = contact;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_amber_rounded, size: 60, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              "URGENCE",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Qui souhaitez-vous appeler ?",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),

            if (_isLoading)
              const CircularProgressIndicator()
            else
              Column(
                children: [
                  // ----------------------- SAMU
                  _buildCallButton(
                    icon: Icons.local_hospital,
                    label: "SAMU (15)",
                    subtitle: "Urgence médicale",
                    color: Colors.red,
                    onPressed: () async {
                      Navigator.of(context).pop();
                      try {
                        await _phoneService.callSAMU();
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Erreur: $e')),
                          );
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // -------------------------- contact
                  _buildCallButton(
                    icon: Icons.contact_phone,
                    label: _emergencyContact != null
                        ? _emergencyContact!.name
                        : "Aucun contact",
                    subtitle: _emergencyContact?.phone ?? "Non configuré",
                    color: _emergencyContact != null
                        ? Colors.blue
                        : Colors.grey,
                    onPressed: _emergencyContact != null
                        ? () async {
                            Navigator.of(context).pop();
                            try {
                              await _phoneService.callEmergencyContact(
                                _emergencyContact!.phone,
                              );
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Erreur: $e')),
                                );
                              }
                            }
                          }
                        : null,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCallButton({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.phone, size: 24),
          ],
        ),
      ),
    );
  }
}