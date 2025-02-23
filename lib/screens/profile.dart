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

class _ProfilePageState extends State<ProfilePage> {
  void _showBottomSheet(Widget page) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => page,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            StreamBuilder<User?>(
              stream: FirebaseAuth.instance.authStateChanges(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                User? user = snapshot.data;

                if (user == null) {
                  return Stack(
                    children: [
                      Container(
                        height: 200,
                        color: const Color.fromRGBO(204, 20, 205, 100).withOpacity(0.1),
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                radius: 50,
                                backgroundImage: AssetImage('assets/images/profile.png'),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Utilisateur',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 16,
                        top: 16,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginPage()));
                          },
                          icon: const Icon(Icons.login),
                          label: const Text('Se connecter'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromRGBO(204, 20, 205, 100),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  );
                }

                return StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
                  builder: (context, firestoreSnapshot) {
                    if (firestoreSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!firestoreSnapshot.hasData || !firestoreSnapshot.data!.exists) {
                      return const Center(child: Text("Données utilisateur non trouvées"));
                    }

                    Patient patient = Patient.fromMap(firestoreSnapshot.data!.data() as Map<String, dynamic>);

                    return Stack(
                      children: [
                        Container(
                          height: 200,
                          color: const Color.fromRGBO(204, 20, 205, 100).withOpacity(0.1),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircleAvatar(
                                  radius: 50,
                                  backgroundImage: patient.photoURL != null
                                      ? NetworkImage(patient.photoURL!)
                                      : const AssetImage('assets/images/profile.png') as ImageProvider,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${patient.prenom} ${patient.nom}'.trim(),
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  _buildOptionItem(
                    icon: Icons.edit,
                    text: 'Modifier le profil',
                    onTap: () => _showBottomSheet(EditProfilePage()),
                  ),
                  _buildOptionItem(
                    icon: Icons.settings,
                    text: 'Paramètres',
                    onTap: () => _showBottomSheet(const SettingsPage()),
                  ),
                  _buildOptionItem(
                    icon: Icons.lock,
                    text: 'Confidentialité',
                    onTap: () => _showBottomSheet(const PrivacyPage()),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            StreamBuilder<User?>(
              stream: FirebaseAuth.instance.authStateChanges(),
              builder: (context, snapshot) {
                if (snapshot.data != null) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      children: [
                        const Divider(color: Colors.grey),
                        _buildOptionItem(
                          icon: Icons.logout,
                          text: 'Se déconnecter',
                          onTap: () async {
                            await AuthService().signOut();
                            setState(() {});
                          },
                          isLogout: true,
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
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
        padding: const EdgeInsets.symmetric(vertical: 12.0),
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
                fontWeight: isLogout ? FontWeight.bold : FontWeight.normal,
                color: isLogout ? Colors.red : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}