import 'package:flutter/material.dart';

class IncidentReportSheet extends StatelessWidget {
  // Le callback : c'est la fonction que MapPage va nous donner
  // pour savoir quel bouton a été cliqué.
  final Function(String type) onReportSelected;

  const IncidentReportSheet({super.key, required this.onReportSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        top: 15,
        left: 20,
        right: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // La petite barre grise en haut de la modale
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "Quel incident voulez-vous signaler ?",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 25),
          GridView.count(
            shrinkWrap: true,
            crossAxisCount: 2,
            mainAxisSpacing: 15,
            crossAxisSpacing: 15,
            childAspectRatio: 1.5,
            children: [
              _buildOption(context, 'Permanent', Icons.stairs, Colors.purple),
              _buildOption(
                context,
                'Travaux',
                Icons.construction,
                Colors.orange,
              ),
              _buildOption(context, 'Degradation', Icons.warning, Colors.blue),
              _buildOption(context, 'Obstruction', Icons.block, Colors.red),
            ],
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  // Petite fonction interne pour construire chaque bouton de la grille
  Widget _buildOption(
    BuildContext context,
    String type,
    IconData icon,
    Color color,
  ) {
    return InkWell(
      onTap: () => onReportSelected(type), // On renvoie le type au parent
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 35),
            const SizedBox(height: 8),
            Text(
              type.toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
