import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ardi/utils/auth.dart';
import 'package:ardi/model/patient.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _signOut() async {
    await AuthService().signOut();
    if (mounted) {
      Navigator.pop(context);
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Text('Admin');
            return StreamBuilder<DocumentSnapshot>(
              stream: _firestore.collection('users').doc(snapshot.data!.uid).snapshots(),
              builder: (context, docSnapshot) {
                if (!docSnapshot.hasData || !docSnapshot.data!.exists) {
                  return const Text('Admin');
                }
                Patient admin = Patient.fromMap(docSnapshot.data!.data() as Map<String, dynamic>);
                return Text('- Admin');
              },
            );
          },
        ),
        backgroundColor: Colors.deepPurple,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
            tooltip: 'Déconnexion',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Statistiques Générales',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('users').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final users = snapshot.data!.docs;
                  int totalPatients = users.where((user) => user['role'] == 'patient').length;
                  int totalDoctors = users.where((user) => user['role'] == 'docta').length;

                  return Column(
                    children: [
                      _buildStatCard('Patients', totalPatients, Colors.green),
                      _buildStatCard('Médecins', totalDoctors, Colors.blue),
                    ],
                  );
                },
              ),
              const SizedBox(height: 30),
              const Text(
                'Gestion des Patients',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('users').where('role', isEqualTo: 'patient').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final patients = snapshot.data!.docs;

                  return ListView.builder(
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
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundImage: patient.photoURL != null
                                ? NetworkImage(patient.photoURL!)
                                : const AssetImage('assets/images/profile.png') as ImageProvider,
                          ),
                          title: Text('${patient.prenom} ${patient.nom}'),
                          subtitle: Text(patient.email),
                          trailing: Switch(
                            value: isActive,
                            onChanged: (value) => _toggleUserStatus(patients[index].id, isActive),
                            activeColor: Colors.green,
                            inactiveThumbColor: Colors.red,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 30),
              const Text(
                'Gestion des Médecins',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('users').where('role', isEqualTo: 'docta').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final doctors = snapshot.data!.docs;

                  return ListView.builder(
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
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundImage: doctor.photoURL != null
                                ? NetworkImage(doctor.photoURL!)
                                : const AssetImage('assets/images/profile.png') as ImageProvider,
                          ),
                          title: Text('${doctor.prenom} ${doctor.nom}'),
                          subtitle: Text(doctor.email),
                          trailing: Switch(
                            value: isActive,
                            onChanged: (value) => _toggleUserStatus(doctors[index].id, isActive),
                            activeColor: Colors.green,
                            inactiveThumbColor: Colors.red,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 30),
              Center(
                child: ElevatedButton(
                  onPressed: _navigateToAddDoctorPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  ),
                  child: const Text('Ajouter un Médecin', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, int value, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      child: ListTile(
        leading: Icon(Icons.bar_chart, color: color, size: 40),
        title: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        trailing: Text(
          value.toString(),
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
        ),
      ),
    );
  }
}

class AddDoctorPage extends StatefulWidget {
  const AddDoctorPage({super.key});

  @override
  State<AddDoctorPage> createState() => _AddDoctorPageState();
}

class _AddDoctorPageState extends State<AddDoctorPage> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _specialtyController = TextEditingController();
  final List<String> _daysOfWeek = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
  final List<String> _selectedDays = [];
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false; // État pour le loader

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitDoctor() async {
    String firstName = _firstNameController.text.trim();
    String lastName = _lastNameController.text.trim();
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();
    String specialty = _specialtyController.text.trim();

    if (firstName.isEmpty || lastName.isEmpty || email.isEmpty || password.isEmpty || specialty.isEmpty || _selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = userCredential.user;

      if (user != null) {
        String? photoURL;
        if (_selectedImage != null) {
          final storageRef = FirebaseStorage.instance.ref().child('profile_pics/${user.uid}.jpg');
          await storageRef.putFile(_selectedImage!);
          photoURL = await storageRef.getDownloadURL();
        }

        Map<String, dynamic> doctorData = {
          'uid': user.uid,
          'prenom': firstName,
          'nom': lastName,
          'email': email,
          'photoURL': photoURL,
          'role': 'docta',
          'specialty': specialty,
          'workingDays': _selectedDays,
          'isActive': true,
          'dateCreation': FieldValue.serverTimestamp(),
        };

        await FirebaseFirestore.instance.collection('users').doc(user.uid).set(doctorData);

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Médecin Ajouté'),
            content: Text('Médecin : $firstName $lastName\nEmail : $email\nSpécialité : $specialty\nJours : ${_selectedDays.join(", ")}'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );

        _firstNameController.clear();
        _lastNameController.clear();
        _emailController.clear();
        _passwordController.clear();
        _specialtyController.clear();
        setState(() {
          _selectedDays.clear();
          _selectedImage = null;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l’ajout : $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter un Médecin'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildTextField(_firstNameController, 'Prénom'),
              _buildTextField(_lastNameController, 'Nom'),
              _buildTextField(_emailController, 'Email'),
              _buildTextField(_passwordController, 'Mot de passe', obscureText: true),
              _buildTextField(_specialtyController, 'Spécialité'),
              const SizedBox(height: 20),
              if (_selectedImage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Image.file(_selectedImage!, height: 100),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    child: const Text('Galerie'),
                  ),
                  ElevatedButton(
                    onPressed: () => _pickImage(ImageSource.camera),
                    child: const Text('Caméra'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Jours de Travail',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Wrap(
                spacing: 10,
                children: _daysOfWeek.map((day) {
                  bool isSelected = _selectedDays.contains(day);
                  return ChoiceChip(
                    label: Text(day),
                    selected: isSelected,
                    selectedColor: Colors.deepPurple,
                    onSelected: (selected) {
                      setState(() {
                        isSelected ? _selectedDays.remove(day) : _selectedDays.add(day);
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                onPressed: _submitDoctor,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
                child: const Text('Ajouter', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {bool obscureText = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}