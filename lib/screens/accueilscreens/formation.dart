import 'package:flutter/material.dart';

class FormationPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Formations 🎓'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Formez-vous avec ARDI ! 🚀',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            const Text(
              'Nous proposons des formations adaptées aux professionnels de la santé et aux aidants pour améliorer la prise en charge des patients. Nos modules sont conçus par des experts et accessibles en ligne.',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.justify,
            ),
            const SizedBox(height: 24),

            // Bouton pour accéder aux formations
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  // Logique pour accéder aux formations
                },
                icon: const Icon(Icons.school),
                label: const Text('Découvrir les formations'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Infos complémentaires
            const Text(
              '🎯 Modules interactifs et accessibles à distance\n📚 Formations pour professionnels et aidants\n📅 Sessions régulières avec certification',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
