import 'package:ardi/screens/login.dart';
import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Section 1 : Image du profil et bouton se connecter
            Stack(
              children: [
                Container(
                  height: 200,
                  color:
                      const Color.fromRGBO(204, 20, 205, 100).withOpacity(0.1),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundImage:
                              const AssetImage('assets/images/profile.png'),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Utilisateur',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
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
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const LoginPage()),
                      );
                    },
                    icon: const Icon(Icons.login),
                    label: const Text('Se connecter'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromRGBO(204, 20, 205, 100),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Section 2 : Options de profil
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  const Text(
                    'Options de Profil',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildOptionItem(
                    context,
                    icon: Icons.edit,
                    text: 'Modifier le profil',
                    onTap: () {
                      // Logique pour modifier le profil
                      print('Modifier le profil');
                    },
                  ),
                  _buildOptionItem(
                    context,
                    icon: Icons.settings,
                    text: 'Paramètres',
                    onTap: () {
                      // Logique pour ouvrir les paramètres
                      print('Paramètres');
                    },
                  ),
                  _buildOptionItem(
                    context,
                    icon: Icons.lock,
                    text: 'Confidentialité',
                    onTap: () {
                      // Logique pour gérer la confidentialité
                      print('Confidentialité');
                    },
                  ),
                  _buildOptionItem(
                    context,
                    icon: Icons.policy,
                    text: 'Politique de confidentialité',
                    onTap: () {
                      // Logique pour consulter la politique
                      print('Politique de confidentialité');
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Section 3 : Déconnexion
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  const Divider(color: Colors.grey),
                  _buildOptionItem(
                    context,
                    icon: Icons.logout,
                    text: 'Se déconnecter',
                    onTap: () {
                      // Logique pour se déconnecter
                      print('Se déconnecter');
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

  Widget _buildOptionItem(
    BuildContext context, {
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
              color: isLogout
                  ? Colors.red
                  : const Color.fromRGBO(204, 20, 205, 100),
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
