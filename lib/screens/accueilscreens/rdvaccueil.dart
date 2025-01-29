import 'package:flutter/material.dart';

class RendezVousPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prise de Rendez-vous 📅'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Prenez vos rendez-vous médicaux en ligne 🏥',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            const Text(
              'Avec ARDI, vous pouvez prendre vos rendez-vous directement en ligne avec les médecins de votre choix. Plus besoin de téléphoner !',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.justify,
            ),
            const SizedBox(height: 24),

            // Bouton pour prendre un rendez-vous
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  // Logique pour rediriger vers la prise de rendez-vous
                },
                icon: const Icon(Icons.calendar_today),
                label: const Text('Prendre un rendez-vous'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Infos complémentaires
            const Text(
              '🔹 Réservez à tout moment\n🔹 Choix parmi plusieurs médecins\n🔹 Confirmation instantanée',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
