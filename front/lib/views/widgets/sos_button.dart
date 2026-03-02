import 'package:flutter/material.dart';
import 'sos_dialog.dart';

class SosButton extends StatelessWidget {
  const SosButton({super.key});

  @override
  Widget build(BuildContext context) {    // DEBUG to be changed
    return Positioned(
      right: 16,
      top: MediaQuery.of(context).size.height / 2 - 28,
      child: FloatingActionButton(
        heroTag: "sos",
        onPressed: () => _showSosDialog(context),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        child: const Text(
          'SOS',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
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