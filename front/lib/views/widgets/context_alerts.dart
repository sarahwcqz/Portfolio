import 'package:flutter/material.dart';

extension UIHelpers on BuildContext {
  void showMessage(String message) {
    // On vérifie si l'écran est toujours affiché pour éviter les crashs
    if (!Navigator.of(this).mounted) return;

    ScaffoldMessenger.of(this).showSnackBar(SnackBar(content: Text(message)));
  }

  void showError(String message) {
    if (!Navigator.of(this).mounted) return;

    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void showSuccess(String message) {
    if (!Navigator.of(this).mounted) return;

    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void showLoader(String message) {
    if (!Navigator.of(this).mounted) return;

    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 16),
            Text(message),
          ],
        ),
        duration: const Duration(seconds: 30),
      ),
    );
  }

  void hideLoader() {
    ScaffoldMessenger.of(this).clearSnackBars();
  }
}
