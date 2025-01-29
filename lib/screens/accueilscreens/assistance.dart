import 'package:flutter/material.dart';

class AssistancePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assistance ARDI 🩺'),
        backgroundColor: Colors.purple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Besoin d’aide ? Nous sommes là pour vous !',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            const Text(
              'Notre service d’assistance vous accompagne dans l’utilisation de la plateforme ARDI. Que ce soit pour des questions sur votre dossier médical, la prise de rendez-vous ou toute autre demande, nous vous apportons une réponse rapide et adaptée.',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.justify,
            ),
            const SizedBox(height: 24),

            // Bouton de contact
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  // Logique pour contacter l'assistance
                },
                icon: const Icon(Icons.headset_mic),
                label: const Text('Contacter l’assistance'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Infos complémentaires
            const Text(
              '📧 Email : support@ardi.africa\n📞 Téléphone : +XX XX XX XX XX\n🌍 Disponible 24h/24 et 7j/7',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
