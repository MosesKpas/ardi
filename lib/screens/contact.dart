import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';

class ContactPage extends StatelessWidget {
  const ContactPage({Key? key}) : super(key: key);

  // Membres du personnel pour le carrousel
  final List<Map<String, String>> staffMembers = const [
    {
      'name': 'Dr. Paul Kalamba',
      'role': 'Directeur Médical',
      'image': 'assets/images/docteur1.png',
    },
    {
      'name': 'Jean-Pierre Martin',
      'role': 'Responsable Administratif',
      'image': 'assets/images/docteur2.png',
    },
    {
      'name': 'Marie Lefevre',
      'role': 'Infirmière en Chef',
      'image': 'assets/images/docteur3.jpg',
    },
  ];

  // Liste des médecins avec leurs spécialisations
  final List<Map<String, String>> doctors = const [
    {
      'name': 'Dr. Camille Bernard',
      'specialization': 'Cardiologue',
    },
    {
      'name': 'Dr. Olivier Durand',
      'specialization': 'Dermatologue',
    },
    {
      'name': 'Dr. Emma Roux',
      'specialization': 'Pédiatre',
    },
    {
      'name': 'Dr. Thomas Laurent',
      'specialization': 'Neurologue',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section Carrousel : Membres du personnel
              const Text(
                'Contactez-Nous',
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
              ),
              const SizedBox(
                height: 10,
              ),
              const Text(
                'Membres du Personnel',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              CarouselSlider(
                options: CarouselOptions(
                  height: 200,
                  autoPlay: true,
                  enlargeCenterPage: true,
                  enableInfiniteScroll: true,
                ),
                items: staffMembers.map((member) {
                  return Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: AssetImage(member['image']!),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        member['name']!,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        member['role']!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),

              // Section Liste des médecins
              const Text(
                'Liste des Médecins',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  final doctor = doctors[index];
                  return ListTile(
                    leading: const Icon(Icons.person, color: Colors.pinkAccent),
                    title: Text(
                      doctor['name']!,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      doctor['specialization']!,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    trailing: const Icon(Icons.phone,
                        color: Colors.grey), // Icône statique sans action
                  );
                },
                separatorBuilder: (context, index) => const Divider(),
                itemCount: doctors.length,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
