import 'package:flutter/material.dart';

class DossierMedicalPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Suivi des Dossiers 🏥'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Gérez vos dossiers médicaux en ligne 📂',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            const Text(
              'Avec ARDI, accédez facilement à vos antécédents médicaux, vos consultations, vos analyses et vos prescriptions en ligne. Plus besoin de conserver des papiers, tout est disponible en un clic !',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.justify,
            ),
            const SizedBox(height: 24),

            // Bouton pour accéder aux dossiers médicaux
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  // Logique pour accéder aux dossiers médicaux
                },
                icon: const Icon(Icons.medical_services),
                label: const Text('Accéder à mes dossiers'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
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
              '🔹 Historique médical sécurisé\n🔹 Accès aux prescriptions et résultats d’analyses\n🔹 Partage facilité avec les professionnels de santé',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
