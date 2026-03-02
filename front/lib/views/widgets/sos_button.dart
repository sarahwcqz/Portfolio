import 'package:flutter/material.dart';
import 'sos_dialog.dart';

class SosButton extends StatelessWidget {
  const SosButton({super.key});

  @override
  Widget build(BuildContext context) {    // DEBUG to be changed
    return Positioned(
      top: 120,
      right: 16,
      child: FloatingActionButton(
        heroTag: "sos",
        onPressed: () => _showSosDialog(context),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        child: const Icon(Icons.warning, size: 30),
      ),
    );
  }

  void _showSosDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const SosDialog(),
    );
  }
}