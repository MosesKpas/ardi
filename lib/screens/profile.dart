import 'package:ardi/screens/profile/editer.dart';
import 'package:ardi/screens/profile/privacy.dart';
import 'package:ardi/screens/profile/settings.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ardi/screens/login.dart';
import 'package:ardi/utils/auth.dart';

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
            // Section 1 : Image du profil et bouton se connecter
            StreamBuilder<User?>(
              stream: FirebaseAuth.instance.authStateChanges(),
              builder: (context, snapshot) {
                User? user = snapshot.data;

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
                              backgroundImage: user != null && user.photoURL != null
                                  ? NetworkImage(user.photoURL!)
                                  : const AssetImage('assets/images/profile.png') as ImageProvider,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              user != null ? user.displayName ?? 'Utilisateur' : 'Utilisateur',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (user == null)
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
              },
            ),

            const SizedBox(height: 16),

            // Section 2 : Options de profil
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

            // Section 3 : Déconnexion
            if (mounted)
              Padding(
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
