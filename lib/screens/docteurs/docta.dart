import 'package:ardi/screens/login.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ardi/screens/chat.dart';
import 'package:ardi/utils/auth.dart';
import 'package:ardi/screens/accueil.dart';
import 'package:ardi/screens/admin/admin.dart';

class DoctorDashboardPage extends StatefulWidget {
  const DoctorDashboardPage({super.key});

  @override
  State<DoctorDashboardPage> createState() => _DoctorDashboardPageState();
}

class _DoctorDashboardPageState extends State<DoctorDashboardPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late String _doctorUid;
  String _doctorName = 'Docteur'; 
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeSession();
  }

  Future<void> _initializeSession() async {
    _doctorUid = FirebaseAuth.instance.currentUser!.uid;
    String? role = await AuthService().getUserRole();

    if (role != 'docta') {
      if (role == 'admin') {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AdminDashboardPage()));
      } else {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AccueilPage()));
      }
      return;
    }

    // Charger le nom du docteur
    DocumentSnapshot doc = await _firestore.collection('users').doc(_doctorUid).get();
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      _doctorName = '${data['prenom']} ${data['nom']}';
    }

    setState(() => _isLoading = false);
  }

  Future<void> _signOut() async {
    await AuthService().signOut();
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginPage()));
  }

  Future<void> _updateAppointmentStatus(String appointmentId, String newStatus) async {
    await _firestore.collection('rdv').doc(appointmentId).update({'status': newStatus});
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Bonjour Docteur $_doctorName',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.teal,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Se déconnecter',
            onPressed: _signOut,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Rendez-vous soumis'),
            StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('rdv').where('doctorUid', isEqualTo: _doctorUid).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final appointments = snapshot.data!.docs;

                if (appointments.isEmpty) {
                  return const Text('Aucun rendez-vous soumis.', style: TextStyle(color: Colors.grey));
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: appointments.length,
                  itemBuilder: (context, index) {
                    final appointment = appointments[index].data() as Map<String, dynamic>;
                    final appointmentId = appointments[index].id;
                    final date = (appointment['date'] as Timestamp).toDate();
                    final formattedDate = '${date.day}/${date.month}/${date.year}';
                    final status = appointment['status'];
                    final patientUid = appointment['patientUid'];

                    return FutureBuilder<DocumentSnapshot>(
                      future: _firestore.collection('users').doc(patientUid).get(),
                      builder: (context, patientSnapshot) {
                        if (!patientSnapshot.hasData) return const SizedBox.shrink();
                        final patientData = patientSnapshot.data!.data() as Map<String, dynamic>;
                        final patientName = '${patientData['prenom']} ${patientData['nom']}';
                        bool isPending = status == 'en attente';

                        return Card(
                          elevation: 4,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            title: Text('$patientName', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('Date : $formattedDate | Statut : $status'),
                            trailing: isPending
                                ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.check_circle, color: Colors.green),
                                  onPressed: () => _updateAppointmentStatus(appointmentId, 'confirmé'),
                                  tooltip: 'Confirmer',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.cancel, color: Colors.red),
                                  onPressed: () => _updateAppointmentStatus(appointmentId, 'annulé'),
                                  tooltip: 'Annuler',
                                ),
                              ],
                            )
                                : null,
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 20),

            _buildSectionTitle('Messages des patients'),
            StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('msg').where('doctorUid', isEqualTo: _doctorUid).orderBy('timestamp', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final messages = snapshot.data!.docs;

                if (messages.isEmpty) {
                  return const Text('Aucun message reçu.', style: TextStyle(color: Colors.grey));
                }

                Map<String, Map<String, dynamic>> latestMessages = {};
                for (var msg in messages) {
                  final messageData = msg.data() as Map<String, dynamic>;
                  final patientUid = messageData['patientUid'];
                  if (!latestMessages.containsKey(patientUid)) {
                    latestMessages[patientUid] = messageData;
                  }
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: latestMessages.length,
                  itemBuilder: (context, index) {
                    final patientUid = latestMessages.keys.elementAt(index);
                    final messageData = latestMessages[patientUid]!;
                    final timestamp = (messageData['timestamp'] as Timestamp?)?.toDate();
                    final formattedDate = timestamp != null ? '${timestamp.day}/${timestamp.month}/${timestamp.year}' : 'N/A';

                    return FutureBuilder<DocumentSnapshot>(
                      future: _firestore.collection('users').doc(patientUid).get(),
                      builder: (context, patientSnapshot) {
                        if (!patientSnapshot.hasData) return const SizedBox.shrink();
                        final patientData = patientSnapshot.data!.data() as Map<String, dynamic>;
                        final patientName = '${patientData['prenom']} ${patientData['nom']}';

                        return Card(
                          elevation: 4,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            leading: CircleAvatar(
                              radius: 20,
                              backgroundImage: patientData['photoURL'] != null
                                  ? NetworkImage(patientData['photoURL'])
                                  : const AssetImage('assets/images/profile.png') as ImageProvider,
                            ),
                            title: Text(patientName, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(messageData['message'], overflow: TextOverflow.ellipsis),
                                Text('Reçu le : $formattedDate', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.reply, color: Colors.teal),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ChatPage(
                                      doctorId: patientUid,
                                      name: patientName,
                                      specialization: 'Patient',
                                      image: patientData['photoURL'] ?? 'assets/images/profile.png',
                                    ),
                                  ),
                                );
                              },
                              tooltip: 'Répondre',
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 20),

            _buildSectionTitle('Rendez-vous à venir'),
            StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('rdv').where('doctorUid', isEqualTo: _doctorUid).where('status', isEqualTo: 'confirmé').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final appointments = snapshot.data!.docs;

                if (appointments.isEmpty) {
                  return const Text('Aucun rendez-vous confirmé.', style: TextStyle(color: Colors.grey));
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: appointments.length,
                  itemBuilder: (context, index) {
                    final appointment = appointments[index].data() as Map<String, dynamic>;
                    final date = (appointment['date'] as Timestamp).toDate();
                    final formattedDate = '${date.day}/${date.month}/${date.year}';
                    final patientUid = appointment['patientUid'];

                    return FutureBuilder<DocumentSnapshot>(
                      future: _firestore.collection('users').doc(patientUid).get(),
                      builder: (context, patientSnapshot) {
                        if (!patientSnapshot.hasData) return const SizedBox.shrink();
                        final patientData = patientSnapshot.data!.data() as Map<String, dynamic>;
                        final patientName = '${patientData['prenom']} ${patientData['nom']}';

                        return Card(
                          elevation: 4,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            title: Text('$patientName', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('Date : $formattedDate | Statut : Confirmé'),
                            leading: const Icon(Icons.event, color: Colors.teal),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}