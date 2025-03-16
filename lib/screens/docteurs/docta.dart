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

class _DoctorDashboardPageState extends State<DoctorDashboardPage> with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late String _doctorUid;
  String _doctorName = 'Docteur';
  bool _isLoading = true;
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
    _initializeSession();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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

    DocumentSnapshot doc = await _firestore.collection('users').doc(_doctorUid).get();
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      _doctorName = '${data['prenom']} ${data['nom']}';
    }

    setState(() => _isLoading = false);
  }

  Future<void> _signOut() async {
    await AuthService().signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
          (Route<dynamic> route) => false,
    );
  }

  Future<void> _updateAppointmentStatus(String appointmentId, String newStatus) async {
    await _firestore.collection('rdv').doc(appointmentId).update({'status': newStatus});
  }

  Future<void> _savePrescription(String patientUid, String prescription) async {
    await _firestore.collection('prescriptions').add({
      'doctorUid': _doctorUid,
      'patientUid': patientUid,
      'prescription': prescription,
      'timestamp': FieldValue.serverTimestamp(),
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Prescription envoyée au dossier du patient')),
    );
  }

  void _showPrescriptionDialog(String patientUid) {
    final TextEditingController prescriptionController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Ajouter une Prescription', style: TextStyle(color: Color.fromRGBO(204, 20, 205, 100))),
        content: TextField(
          controller: prescriptionController,
          maxLines: 5,
          decoration: InputDecoration(
            hintText: 'Entrez la prescription ici...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            filled: true,
            fillColor: Colors.grey.shade100,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              if (prescriptionController.text.trim().isNotEmpty) {
                await _savePrescription(patientUid, prescriptionController.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text('Envoyer', style: TextStyle(color: Color.fromRGBO(204, 20, 205, 100))),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Color.fromRGBO(204, 20, 205, 100),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Color.fromRGBO(204, 20, 205, 100)))),
      );
    }

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
        title: Text(
          'Bonjour Dr. $_doctorName',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Se déconnecter',
            onPressed: _signOut,
          ),
        ],
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('Rendez-vous soumis'),
                _buildPendingAppointmentsSection(),
                const SizedBox(height: 20),
                _buildSectionTitle('Messages des patients'),
                _buildMessagesSection(),
                const SizedBox(height: 20),
                _buildSectionTitle('Rendez-vous à venir'),
                _buildUpcomingAppointmentsSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPendingAppointmentsSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('rdv').where('doctorUid', isEqualTo: _doctorUid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Color.fromRGBO(204, 20, 205, 100))));
        }
        final appointments = snapshot.data!.docs;

        if (appointments.isEmpty) {
          return const Text('Aucun rendez-vous soumis.', style: TextStyle(color: Colors.grey));
        }

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          child: ListView.builder(
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
                      leading: const Icon(Icons.pending_actions, color: Color.fromRGBO(204, 20, 205, 100)),
                      title: Text(patientName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Date : $formattedDate | Statut : $status', style: const TextStyle(color: Colors.grey)),
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
          ),
        );
      },
    );
  }

  Widget _buildMessagesSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('msg').where('doctorUid', isEqualTo: _doctorUid).orderBy('timestamp', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Color.fromRGBO(204, 20, 205, 100))));
        }
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

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          child: ListView.builder(
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
                        icon: const Icon(Icons.reply, color: Color.fromRGBO(204, 20, 205, 100)),
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
          ),
        );
      },
    );
  }

  Widget _buildUpcomingAppointmentsSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('rdv').where('doctorUid', isEqualTo: _doctorUid).where('status', isEqualTo: 'confirmé').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Color.fromRGBO(204, 20, 205, 100))));
        }
        final appointments = snapshot.data!.docs;

        if (appointments.isEmpty) {
          return const Text('Aucun rendez-vous confirmé.', style: TextStyle(color: Colors.grey));
        }

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          child: ListView.builder(
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
                      leading: const Icon(Icons.event, color: Color.fromRGBO(204, 20, 205, 100)),
                      title: Text(patientName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Date : $formattedDate | Statut : Confirmé', style: const TextStyle(color: Colors.grey)),
                      trailing: IconButton(
                        icon: const Icon(Icons.medical_services, color: Color.fromRGBO(204, 20, 205, 100)),
                        onPressed: () => _showPrescriptionDialog(patientUid),
                        tooltip: 'Ajouter une prescription',
                      ),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}