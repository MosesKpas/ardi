import 'package:flutter/material.dart';

class ConsultationPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Consultations Médicales 🩺'),
        backgroundColor: Colors.purple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Consultez un médecin facilement !',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            const Text(
              'Avec ARDI, vous pouvez prendre rendez-vous avec un médecin en quelques clics. Que ce soit pour une consultation générale ou un suivi spécialisé, notre plateforme vous connecte avec des professionnels de santé qualifiés.',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.justify,
            ),
            const SizedBox(height: 24),

            // Bouton pour prendre rendez-vous
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  // Logique pour prendre un rendez-vous
                },
                icon: const Icon(Icons.calendar_today),
                label: const Text('Prendre un rendez-vous'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
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
              '📅 Disponibilité 24h/24 et 7j/7\n📍 Téléconsultation et rendez-vous en présentiel\n👨‍⚕️ Accès à plusieurs spécialités médicales',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
