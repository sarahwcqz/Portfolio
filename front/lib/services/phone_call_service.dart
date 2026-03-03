import 'package:url_launcher/url_launcher.dart';

class PhoneCallService {
  static const String SAMU = '112';

  // ----------------------- makeCall ------------------------------
  // either SAMU or contact
  Future<void> makeCall(String phoneNumber) async {
    final uri = Uri.parse('tel:$phoneNumber');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw Exception('Impossible de lancer l\'appel vers $phoneNumber');
    }
  }

  // ------------ SAMU --------------
  Future<void> callSAMU() async {
    await makeCall(SAMU);
  }

  // ------------ contact ----------
  Future<void> callEmergencyContact(String phone) async {
    await makeCall(phone);
  }
}