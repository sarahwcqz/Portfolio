import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';

class AuthController extends ChangeNotifier {
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  
  bool get isLoading => _isLoading;

// -------------------- sign in ---------------------------
  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.signIn(email, password);
      await _authService.saveEmail(email);
      
      _isLoading = false;
      notifyListeners();
      return true;
      
    } on AuthException catch (error) {
      _isLoading = false;
      notifyListeners();
      throw error;
    }
  }

// -------------------- sign up ----------------------------
  Future<bool> signUp(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.signUp(email, password);
      
      _isLoading = false;
      notifyListeners();
      return true;
      
    } on AuthException catch (error) {
      _isLoading = false;
      notifyListeners();
      throw error;
    }
  }

  // ----------------------- load saved email ------------------
  Future<String?> loadSavedEmail() async {
    return await _authService.loadSavedEmail();
  }


}