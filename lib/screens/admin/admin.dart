import 'package:ardi/screens/admin/ajout.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ardi/utils/auth.dart';
import 'package:ardi/model/patient.dart';
import 'package:ardi/screens/login.dart'; // Importer LoginPage

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
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
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _signOut() async {
    await AuthService().signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
            (Route<dynamic> route) => false, // Supprime toutes les routes précédentes
      );
    }
  }

  Future<void> _toggleUserStatus(String uid, bool currentStatus) async {
    await _firestore.collection('users').doc(uid).update({
      'isActive': !currentStatus,
    });
  }

  void _navigateToAddDoctorPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddDoctorPage()),
    ).then((_) => setState(() {}));
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
        title: StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Text('Admin', style: TextStyle(color: Colors.white));
            return StreamBuilder<DocumentSnapshot>(
              stream: _firestore.collection('users').doc(snapshot.data!.uid).snapshots(),
              builder: (context, docSnapshot) {
                if (!docSnapshot.hasData || !docSnapshot.data!.exists) {
                  return const Text('Admin', style: TextStyle(color: Colors.white));
                }
                Patient admin = Patient.fromMap(docSnapshot.data!.data() as Map<String, dynamic>);
                return Text('${admin.prenom} ${admin.nom} - Admin',
                    style: const TextStyle(fontSize: 20, color: Colors.white));
              },
            );
          },
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _signOut,
            tooltip: 'Déconnexion',
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
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  _buildStatsSection(),
                  const SizedBox(height: 30),
                  _buildSectionTitle('Gestion des Patients'),
                  _buildPatientsSection(),
                  const SizedBox(height: 30),
                  _buildSectionTitle('Gestion des Médecins'),
                  _buildDoctorsSection(),
                  const SizedBox(height: 30),
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: _navigateToAddDoctorPage,
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: const Text('Ajouter un Médecin'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromRGBO(204, 20, 205, 100),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 5,
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: Color.fromRGBO(204, 20, 205, 100),
      ),
    );
  }

  Widget _buildStatsSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Color.fromRGBO(204, 20, 205, 100))));
        }
        final users = snapshot.data!.docs;
        int totalPatients = users.where((user) => user['role'] == 'patient').length;
        int totalDoctors = users.where((user) => user['role'] == 'docta').length;

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStatCard('Patients', totalPatients, Colors.green),
            _buildStatCard('Médecins', totalDoctors, Colors.blue),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String title, int value, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, color.withOpacity(0.1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(Icons.bar_chart, color: color, size: 40),
            const SizedBox(height: 10),
            Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
            Text(
              value.toString(),
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientsSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('users').where('role', isEqualTo: 'patient').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Color.fromRGBO(204, 20, 205, 100))));
        }
        final patients = snapshot.data!.docs;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: patients.length,
            itemBuilder: (context, index) {
              final patientData = patients[index].data() as Map<String, dynamic>;
              final patient = Patient.fromMap(patientData);
              bool isActive = patientData['isActive'] ?? true;

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: patient.photoURL != null
                        ? NetworkImage(patient.photoURL!)
                        : const AssetImage('assets/images/profile.png') as ImageProvider,
                    radius: 20,
                  ),
                  title: Text('${patient.prenom} ${patient.nom}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(patient.email, style: const TextStyle(color: Colors.grey)),
                  trailing: Switch(
                    value: isActive,
                    onChanged: (value) => _toggleUserStatus(patients[index].id, isActive),
                    activeColor: Colors.green,
                    inactiveThumbColor: Colors.red,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildDoctorsSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('users').where('role', isEqualTo: 'docta').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Color.fromRGBO(204, 20, 205, 100))));
        }
        final doctors = snapshot.data!.docs;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: doctors.length,
            itemBuilder: (context, index) {
              final doctorData = doctors[index].data() as Map<String, dynamic>;
              final doctor = Patient.fromMap(doctorData);
              bool isActive = doctorData['isActive'] ?? true;

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: doctor.photoURL != null
                        ? NetworkImage(doctor.photoURL!)
                        : const AssetImage('assets/images/profile.png') as ImageProvider,
                    radius: 20,
                  ),
                  title: Text('${doctor.prenom} ${doctor.nom}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${doctor.email}\n${doctorData['specialty'] ?? 'Non spécifié'}',
                      style: const TextStyle(color: Colors.grey)),
                  trailing: Switch(
                    value: isActive,
                    onChanged: (value) => _toggleUserStatus(doctors[index].id, isActive),
                    activeColor: Colors.green,
                    inactiveThumbColor: Colors.red,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}