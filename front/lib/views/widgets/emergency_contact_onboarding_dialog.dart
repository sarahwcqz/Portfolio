import 'package:flutter/material.dart';
import '../../services/emergency_contact_service.dart';
import '../../services/contact_selector_service.dart';

class EmergencyContactOnboardingDialog extends StatefulWidget {
  const EmergencyContactOnboardingDialog({super.key});

  @override
  State<EmergencyContactOnboardingDialog> createState() =>
      _EmergencyContactOnboardingDialogState();
}

class _EmergencyContactOnboardingDialogState
    extends State<EmergencyContactOnboardingDialog> {
  final EmergencyContactService _contactService = EmergencyContactService();
  final ContactPickerService _pickerService = ContactPickerService();

  bool _isLoading = false;

  // ===================================================================
  // do you want to add an emergency contact? 
  // ===================================================================

  // ---------------------------------- YES ----------------------
  Future<void> _handleYes() async {
    setState(() => _isLoading = true);

    try {
      // opens selector
      final contact = await _pickerService.pickContact();

      if (contact != null) {
        // calls saveContact
        await _contactService.saveContact(contact.name, contact.phone);

        if (!mounted) return;
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Contact d\'urgence enregistré : ${contact.name}'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // user cancels
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur : $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      // set onbaording as seen
      await _contactService.markOnboardingSeen();
    }
  }

 // ------------------------------------ NO ------------------------
  Future<void> _handleNo() async {
    // set onboarding as seen
    await _contactService.markOnboardingSeen();

    if (!mounted) return;
    Navigator.of(context).pop();
  }



// ==========================================================================
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.contact_phone,
              size: 60,
              color: Colors.blue,
            ),
            const SizedBox(height: 16),
            const Text(
              "Contact d'urgence",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Voulez-vous enregistrer un contact d'urgence ?\n\n"
              "Ce contact sera accessible via le bouton SOS en cas de besoin.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 24),

            if (_isLoading)
              const CircularProgressIndicator()
            else
              Column(
                children: [
                  // ----------------------- YES button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _handleYes,
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Choisir un contact'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ---------------------------------- NO button
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: _handleNo,
                      child: const Text('Non, pas maintenant'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey,
                        padding: const EdgeInsets.symmetric(vertical: 14),
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
}