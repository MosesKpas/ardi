import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class MedicalReportsPage extends StatefulWidget {
  const MedicalReportsPage({Key? key}) : super(key: key);

  @override
  _MedicalReportsPageState createState() => _MedicalReportsPageState();
}

class _MedicalReportsPageState extends State<MedicalReportsPage> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  Map<String, List<Map<String, dynamic>>> _dossiersBySpecialty = {};
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _loadDossiers();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadDossiers() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (mounted) setState(() => _isLoading = true);

    QuerySnapshot messagesSnapshot = await FirebaseFirestore.instance
        .collection('msg')
        .where('patientUid', isEqualTo: user.uid)
        .where('type', whereIn: ['file', 'image'])
        .get();

    Map<String, List<Map<String, dynamic>>> tempDossiers = {};

    for (var doc in messagesSnapshot.docs) {
      var data = doc.data() as Map<String, dynamic>;
      String doctorUid = data['doctorUid'];

      DocumentSnapshot doctorDoc = await FirebaseFirestore.instance.collection('users').doc(doctorUid).get();
      if (doctorDoc.exists) {
        var doctorData = doctorDoc.data() as Map<String, dynamic>;
        String specialty = doctorData['specialty'] ?? 'Non spécifié';

        if (!tempDossiers.containsKey(specialty)) {
          tempDossiers[specialty] = [];
        }

        tempDossiers[specialty]!.add({
          'fileName': data['fileName'] ?? 'Image_${DateTime.now().millisecondsSinceEpoch}',
          'url': data['message'],
          'timestamp': (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
          'type': data['type'],
        });
      }
    }

    if (mounted) {
      setState(() {
        _dossiersBySpecialty = tempDossiers;
        _isLoading = false;
      });
    }
  }

  Future<void> _shareFile(String url, String fileName) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) throw Exception('Erreur lors du téléchargement du fichier');

      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);

      await Share.shareXFiles(
        [XFile(filePath)],
        text: 'Voici un fichier médical : $fileName',
      );

      await file.delete();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du partage : $e')),
        );
      }
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
          'Rapport médical',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.purple.shade50.withOpacity(0.5),
              Colors.white,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Color.fromRGBO(204, 20, 205, 100))))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: _dossiersBySpecialty.isEmpty
                      ? const Center(child: Text('Aucun rapport médical trouvé.', style: TextStyle(color: Colors.grey)))
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: _dossiersBySpecialty.entries.map((entry) {
                            String specialty = entry.key;
                            List<Map<String, dynamic>> files = entry.value;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  specialty,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color.fromRGBO(204, 20, 205, 100),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.2),
                                        spreadRadius: 2,
                                        blurRadius: 5,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: ListView.separated(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: files.length,
                                    itemBuilder: (context, index) {
                                      var file = files[index];
                                      IconData fileIcon = file['type'] == 'image' ? Icons.image : Icons.insert_drive_file;
                                      return ListTile(
                                        leading: Icon(fileIcon, color: const Color.fromRGBO(204, 20, 205, 100)),
                                        title: Text(
                                          file['fileName'],
                                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        subtitle: Text(
                                          file['timestamp'].toString().substring(0, 16),
                                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                                        ),
                                        trailing: IconButton(
                                          icon: const Icon(Icons.save_alt_rounded, color: Color.fromRGBO(204, 20, 205, 100)),
                                          onPressed: () => _shareFile(file['url'], file['fileName']),
                                          tooltip: 'Télécharger/Partager',
                                        ),
                                      );
                                    },
                                    separatorBuilder: (context, index) => const Divider(height: 1, color: Colors.grey),
                                  ),
                                ),
                                const SizedBox(height: 24),
                              ],
                            );
                          }).toList(),
                        ),
                ),
              ),
      ),
    );
  }
}