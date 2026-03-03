import 'package:shared_preferences/shared_preferences.dart';
import '../models/emergency_contact_model.dart';

class EmergencyContactService {
  static const String _keyName = 'emergency_contact_name';
  static const String _keyPhone = 'emergency_contact_phone';
  static const String _keyOnboardingSeen = 'has_seen_emergency_onboarding';

  // --------------------------- hasSeenOnboarding? -------------------------
  // used to display emergency contact question only on first connexion
  Future<bool> hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyOnboardingSeen) ?? false;
  }

  // --------------------------- markOnboardingSeen -------------------------
  Future<void> markOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyOnboardingSeen, true);
  }

  // ---------------------------- saveContact ------------------------------- 
  Future<void> saveContact(String name, String phone) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyName, name);
    await prefs.setString(_keyPhone, phone);
  }

  // --------------------------- getContact --------------------------------
  Future<EmergencyContactModel?> getContact() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_keyName);
    final phone = prefs.getString(_keyPhone);

    if (name != null && phone != null) {
      return EmergencyContactModel(name: name, phone: phone);
    }
    return null;
  }

  // --------------------------- deleteContact -----------------------------
  // for later use, when implementing profil page
  Future<void> deleteContact() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyName);
    await prefs.remove(_keyPhone);
  }
}