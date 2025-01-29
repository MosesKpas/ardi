import 'package:flutter/material.dart';

class SequencagePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Séquençage ADN 🧬'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Le séquençage ADN avec ARDI 🔬',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            const Text(
              'Notre service de séquençage ADN permet une analyse génétique avancée pour mieux comprendre les maladies héréditaires, personnaliser les traitements et approfondir la recherche scientifique.',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.justify,
            ),
            const SizedBox(height: 24),

            // Bouton pour en savoir plus
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  // Logique pour en savoir plus sur le séquençage
                },
                icon: const Icon(Icons.biotech),
                label: const Text('En savoir plus'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Infos complémentaires
            const Text(
              '🔍 Analyse ADN de haute précision\n🧑‍⚕️ Utilisation pour le diagnostic médical\n🧪 Outil essentiel pour la recherche génétique',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
