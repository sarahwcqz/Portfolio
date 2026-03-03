import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/emergency_contact_model.dart';

class ContactPickerService {
  
  // --------------------- requestPermission --------------------------
  // access tel contacts
  Future<bool> requestPermission() async {
    final status = await Permission.contacts.request();
    return status.isGranted;
  }

  // -------------------------- pickContact ---------------------------
  Future<EmergencyContactModel?> pickContact() async {
    // calls requestPermission
    final hasPermission = await requestPermission();
    
    if (!hasPermission) {
      throw Exception('Permission d\'accès aux contacts refusée');
    }

    // opens contacts
    final contact = await FlutterContacts.openExternalPick();
    
    // if user quits
    if (contact == null) {
      return null;
    }

  // gets contact's details
    final fullContact = await FlutterContacts.getContact(contact.id);
    
    if (fullContact == null || fullContact.phones.isEmpty) {
      throw Exception('Ce contact n\'a pas de numéro de téléphone');
    }

    // Returns contacts' name + number
    return EmergencyContactModel(
      name: fullContact.displayName,
      phone: fullContact.phones.first.number,
    );
  }
}