import 'package:ardi/screens/admin/admin.dart';
import 'package:ardi/screens/docteurs/docta.dart';
import 'package:ardi/utils/auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ardi/screens/chat.dart';
import 'package:ardi/screens/login.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({Key? key}) : super(key: key);

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _checkRoleAndRedirect();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkRoleAndRedirect() async {
    String? role = await AuthService().getUserRole();
    if (role == 'admin') {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AdminDashboardPage()));
    } else if (role == 'docta') {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const DoctorDashboardPage()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color.fromRGBO(204, 20, 205, 100), Colors.purpleAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Text(
          'Messages 💬',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        elevation: 0,
      ),
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Color.fromRGBO(204, 20, 205, 100))));
          }

          bool isLoggedIn = snapshot.hasData;

          if (!isLoggedIn) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.lock, size: 40, color: Color.fromRGBO(204, 20, 205, 100)),
                      const SizedBox(height: 16),
                      const Text(
                        'Veuillez vous connecter pour envoyer des messages.',
                        style: TextStyle(fontSize: 18, color: Colors.black87, fontWeight: FontWeight.w500),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginPage()));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromRGBO(204, 20, 205, 100),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 5,
                        ),
                        child: const Text('Se connecter', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          // Liste des docteurs pour un patient connecté
          final patientUid = snapshot.data!.uid;

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'docta').where('isActive', isEqualTo: true).snapshots(),
            builder: (context, doctorSnapshot) {
              if (!doctorSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Color.fromRGBO(204, 20, 205, 100))));
              }

              final doctors = doctorSnapshot.data!.docs;

              if (doctors.isEmpty) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.message, size: 40, color: Color.fromRGBO(204, 20, 205, 100)),
                          SizedBox(height: 16),
                          Text(
                            'Aucun docteur disponible pour le moment.',
                            style: TextStyle(fontSize: 18, color: Colors.black87, fontWeight: FontWeight.w500),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              return ListView.builder(
                itemCount: doctors.length,
                itemBuilder: (context, index) {
                  final doctorData = doctors[index].data() as Map<String, dynamic>;
                  final doctorId = doctors[index].id;
                  final doctorName = '${doctorData['prenom']} ${doctorData['nom']}';
                  final specialization = doctorData['specialty'] ?? 'Médecin';
                  final image = doctorData['photoURL'] ?? 'assets/images/profile.png';

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

                      return FadeTransition(
                        opacity: _fadeAnimation,
                        child: Card(
                          elevation: 3,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              radius: 25,
                              backgroundImage: image.startsWith('http') ? NetworkImage(image) : AssetImage(image) as ImageProvider,
                            ),
                            title: Text(
                              doctorName,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                            ),
                            subtitle: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    specialization,
                                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    lastMessage,
                                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            trailing: const Icon(Icons.message, color: Color.fromRGBO(204, 20, 205, 100)),
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
      ),
    );
  }
}