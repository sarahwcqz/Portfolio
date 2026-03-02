import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static String get baseUrl {
    final mode = dotenv.env['APP_MODE'] ?? 'emulator';

    if (mode == 'prod') {
      return dotenv.env['RENDER_URL'] ?? '';
    } else if (mode == 'device') {
      return dotenv.env['NGROK_URL'] ?? '';
    } else {
      return dotenv.env['API_URL_EMULATOR'] ?? 'http://10.0.2.2:8000/api/v1';
    }
  }

  // Pour savoir facilement si on est en débug/émulateur ailleurs dans l'app
  static bool get isEmulator =>
      (dotenv.env['APP_MODE'] ?? 'emulator') == 'emulator';
}
