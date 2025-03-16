import 'package:ardi/screens/profile/editer.dart';
import 'package:ardi/screens/profile/privacy.dart';
import 'package:ardi/screens/profile/settings.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ardi/screens/login.dart';
import 'package:ardi/utils/auth.dart';
import 'package:ardi/model/patient.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
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

  void _showBottomSheet(Widget page) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.85,
        child: page,
      ),
    );
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
          'Mon Profil',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Section du profil
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.purple.shade50.withOpacity(0.5), // Fond clair et subtil
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32.0),
                child: StreamBuilder<User?>(
                  stream: FirebaseAuth.instance.authStateChanges(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Color.fromRGBO(204, 20, 205, 100))));
                    }

                    User? user = snapshot.data;

                    if (user == null) {
                      return FadeTransition(
                        opacity: _fadeAnimation,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CircleAvatar(
                              radius: 60, // Taille agrandie
                              backgroundImage: AssetImage('assets/images/profile.png'),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Utilisateur',
                              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
                            ),
                            const SizedBox(height: 16),
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
                      );
                    }

                    return StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
                      builder: (context, firestoreSnapshot) {
                        if (firestoreSnapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Color.fromRGBO(204, 20, 205, 100))));
                        }

                        if (!firestoreSnapshot.hasData || !firestoreSnapshot.data!.exists) {
                          return FadeTransition(
                            opacity: _fadeAnimation,
                            child: const Center(
                              child: Text(
                                "Données utilisateur non trouvées",
                                style: TextStyle(fontSize: 18, color: Colors.black87),
                              ),
                            ),
                          );
                        }

                        Patient patient = Patient.fromMap(firestoreSnapshot.data!.data() as Map<String, dynamic>);

                        return FadeTransition(
                          opacity: _fadeAnimation,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                radius: 60, // Taille agrandie
                                backgroundImage: patient.photoURL != null
                                    ? NetworkImage(patient.photoURL!)
                                    : const AssetImage('assets/images/profile.png') as ImageProvider,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                '${patient.prenom} ${patient.nom}'.trim(),
                                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Options
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
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
                    children: [
                      _buildOptionItem(
                        icon: Icons.edit,
                        text: 'Modifier le profil',
                        onTap: () => _showBottomSheet(EditProfilePage()),
                      ),
                      const Divider(height: 1, color: Colors.grey),
                      _buildOptionItem(
                        icon: Icons.settings,
                        text: 'Paramètres',
                        onTap: () => _showBottomSheet(const SettingsPage()),
                      ),
                      const Divider(height: 1, color: Colors.grey),
                      _buildOptionItem(
                        icon: Icons.lock,
                        text: 'Confidentialité',
                        onTap: () => _showBottomSheet(const PrivacyPage()),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Bouton de déconnexion (visible uniquement si connecté)
            StreamBuilder<User?>(
              stream: FirebaseAuth.instance.authStateChanges(),
              builder: (context, snapshot) {
                if (snapshot.data != null) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            await AuthService().signOut();
                            setState(() {});
                          },
                          icon: const Icon(Icons.logout, size: 20),
                          label: const Text('Se déconnecter'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 5,
                            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionItem({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
        child: Row(
          children: [
            Icon(
              icon,
              color: isLogout ? Colors.red : const Color.fromRGBO(204, 20, 205, 100),
              size: 24,
            ),
            const SizedBox(width: 16),
            Text(
              text,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isLogout ? FontWeight.bold : FontWeight.w500,
                color: isLogout ? Colors.red : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}