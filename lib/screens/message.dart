import 'package:ardi/screens/chat.dart';
import 'package:flutter/material.dart';

class MessagesPage extends StatelessWidget {
  const MessagesPage({Key? key}) : super(key: key);

  // Liste des correspondants
  final List<Map<String, String>> correspondents = const [
    {
      'name': 'Dr. Paul Kalamba',
      'specialization': 'Cardiologue',
      'lastMessage': 'Bonjour, comment allez-vous ?',
      'image': 'assets/images/docteur1.png',
      'time': '10:30 AM',
    },
    {
      'name': 'Dr. Olivier Durand',
      'specialization': 'Dermatologue',
      'lastMessage': 'Vos résultats sont prêts.',
      'image': 'assets/images/docteur2.png',
      'time': '09:15 AM',
    },
    {
      'name': 'Dr. Emma Roux',
      'specialization': 'Pédiatre',
      'lastMessage': 'Rendez-vous confirmé pour demain.',
      'image': 'assets/images/docteur3.jpg',
      'time': '08:00 AM',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(
        itemCount: correspondents.length,
        itemBuilder: (context, index) {
          final correspondent = correspondents[index];
          return ListTile(
            leading: CircleAvatar(
              radius: 25,
              backgroundImage: AssetImage(correspondent['image']!),
            ),
            title: Text(
              correspondent['name']!,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              correspondent['lastMessage']!,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.grey),
            ),
            trailing: Text(
              correspondent['time']!,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatPage(
                    name: correspondent['name']!,
                    specialization: correspondent['specialization']!,
                    image: correspondent['image']!,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
