import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PrivacyPage extends StatefulWidget {
  const PrivacyPage({Key? key}) : super(key: key);

  @override
  _PrivacyPageState createState() => _PrivacyPageState();
}

class _PrivacyPageState extends State<PrivacyPage> {
  bool _profilePublic = true; // Valeur par défaut
  bool _shareLocation = false; // Valeur par défaut
  bool _shareHistory = false; // Valeur par défaut
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPrivacySettings();
  }

  Future<void> _loadPrivacySettings() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        var data = doc.data() as Map<String, dynamic>;
        setState(() {
          _profilePublic = data['profilePublic'] ?? true;
          _shareLocation = data['shareLocation'] ?? false;
          _shareHistory = data['shareHistory'] ?? false;
        });
      }
    }
  }

  Future<void> _savePrivacySettings() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'profilePublic': _profilePublic,
        'shareLocation': _shareLocation,
        'shareHistory': _shareHistory,
      }, SetOptions(merge: true));
    }
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'Politique de confidentialité',
          style: TextStyle(color: Color.fromRGBO(204, 20, 205, 100)),
        ),
        content: const SingleChildScrollView(
          child: Text(
            'Votre vie privée est importante pour nous. Voici comment nous protégeons vos données :\n\n'
                '- Nous ne partageons pas vos informations personnelles sans votre consentement.\n'
                '- Les données sont cryptées et stockées sécuritement.\n'
                '- Vous pouvez contrôler ce que vous partagez via ces paramètres.\n\n'
                'Pour plus de détails, contactez-nous à privacy@ardi.com.',
            style: TextStyle(color: Colors.black87),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer', style: TextStyle(color: Color.fromRGBO(204, 20, 205, 100))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            spreadRadius: 2,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Confidentialité",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color.fromRGBO(204, 20, 205, 100),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              "Gérez vos préférences de confidentialité",
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 24),
            _buildPrivacyItem(
              title: 'Profil public',
              subtitle: 'Rendre votre profil visible à tous les utilisateurs',
              trailing: Switch(
                value: _profilePublic,
                onChanged: (value) {
                  setState(() => _profilePublic = value);
                  _savePrivacySettings();
                },
                activeColor: const Color.fromRGBO(204, 20, 205, 100),
                inactiveTrackColor: Colors.grey.shade300,
              ),
            ),
            const Divider(height: 1, color: Colors.grey),
            _buildPrivacyItem(
              title: 'Partager la localisation',
              subtitle: 'Autoriser l\'application à partager votre position',
              trailing: Switch(
                value: _shareLocation,
                onChanged: (value) {
                  setState(() => _shareLocation = value);
                  _savePrivacySettings();
                },
                activeColor: const Color.fromRGBO(204, 20, 205, 100),
                inactiveTrackColor: Colors.grey.shade300,
              ),
            ),
            const Divider(height: 1, color: Colors.grey),
            _buildPrivacyItem(
              title: 'Partager l\'historique',
              subtitle: 'Autoriser l\'application à partager votre historique',
              trailing: Switch(
                value: _shareHistory,
                onChanged: (value) {
                  setState(() => _shareHistory = value);
                  _savePrivacySettings();
                },
                activeColor: const Color.fromRGBO(204, 20, 205, 100),
                inactiveTrackColor: Colors.grey.shade300,
              ),
            ),
            const Divider(height: 32, color: Colors.grey),
            _buildPrivacyItem(
              title: 'Politique de confidentialité',
              subtitle: 'Consultez notre politique de confidentialité',
              onTap: _showPrivacyPolicy,
            ),
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton(
                onPressed: _isLoading ? null : () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromRGBO(204, 20, 205, 100),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 5,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                )
                    : const Text(
                  'Fermer',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyItem({
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 14, color: Colors.black54),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                ],
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }
}