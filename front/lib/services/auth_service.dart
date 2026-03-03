import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {


  // --------------------------- SIGN IN ----------------------------
  Future<void> signIn(String email, String password) async {
    await Supabase.instance.client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // ----------------------------- SIGN UP --------------------------
  Future<void> signUp(String email, String password) async {
    await Supabase.instance.client.auth.signUp(
      email: email,
      password: password,
    );
  }

  // ----------------------------- load saved email ------------------
  Future<String?> loadSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('saved_email');
  }

  // ---------------------------- save email -------------------------
  Future<void> saveEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_email', email);
  }

  
}