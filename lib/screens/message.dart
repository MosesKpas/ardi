import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ardi/utils/auth.dart';
import 'package:ardi/screens/chat.dart';
import 'package:ardi/screens/login.dart';
import 'package:ardi/screens/admin/admin.dart';
import 'package:ardi/screens/docteurs/docta.dart';

class MessagesPage extends StatelessWidget {
  const MessagesPage({Key? key}) : super(key: key);

  Future<void> _checkRoleAndRedirect(BuildContext context) async {
    String? role = await AuthService().getUserRole();
    if (role == 'admin') {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AdminDashboardPage()));
    } else if (role == 'docta') {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const DoctorDashboardPage()));
    }
  }

  @override
  Widget build(BuildContext context) {
    _checkRoleAndRedirect(context);
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          bool isLoggedIn = snapshot.hasData;

          if (!isLoggedIn) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Veuillez vous connecter pour envoyer des messages.',
                    style: TextStyle(fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginPage()));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromRGBO(204, 20, 205, 100),
                    ),
                    child: const Text('Se connecter'),
                  ),
                ],
              ),
            );
          }

          // Liste des docteurs pour un patient connecté
          final patientUid = snapshot.data!.uid;

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'docta').where('isActive', isEqualTo: true).snapshots(),
            builder: (context, doctorSnapshot) {
              if (!doctorSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final doctors = doctorSnapshot.data!.docs;

              return ListView.builder(
                itemCount: doctors.length,
                itemBuilder: (context, index) {
                  final doctorData = doctors[index].data() as Map<String, dynamic>;
                  final doctorId = doctors[index].id;
                  final doctorName = '${doctorData['prenom']} ${doctorData['nom']}';
                  final specialization = doctorData['specialty'] ?? 'Médecin';
                  final image = doctorData['photoURL'] ?? 'assets/images/profile.png';

                  // Récupérer le dernier message entre ce patient et ce docteur
                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('msg')
                        .where('patientUid', isEqualTo: patientUid)
                        .where('doctorUid', isEqualTo: doctorId)
                        .orderBy('timestamp', descending: true)
                        .limit(1)
                        .snapshots(),
                    builder: (context, messageSnapshot) {
                      String lastMessage = 'Aucun message';
                      if (messageSnapshot.hasData && messageSnapshot.data!.docs.isNotEmpty) {
                        final messageData = messageSnapshot.data!.docs.first.data() as Map<String, dynamic>;
                        lastMessage = messageData['message'];
                      }

                      return ListTile(
                        leading: CircleAvatar(
                          radius: 25,
                          backgroundImage: image.startsWith('http') ? NetworkImage(image) : AssetImage(image) as ImageProvider,
                        ),
                        title: Text(
                          '$doctorName - $specialization',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          lastMessage,
                          style: const TextStyle(color: Colors.grey),
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: const Icon(Icons.message, color: Colors.grey),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatPage(
                                doctorId: doctorId,
                                name: doctorName,
                                specialization: specialization,
                                image: image,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}