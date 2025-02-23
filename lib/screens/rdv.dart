import 'package:ardi/screens/admin/admin.dart';
import 'package:ardi/screens/docteurs/docta.dart';
import 'package:ardi/utils/auth.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ardi/model/patient.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:ardi/screens/login.dart';

class RendezVousPage extends StatefulWidget {
  const RendezVousPage({Key? key}) : super(key: key);

  @override
  State<RendezVousPage> createState() => _RendezVousPageState();
}

class _RendezVousPageState extends State<RendezVousPage> {
  DateTime _selectedDate = DateTime.now();
  TextEditingController _nomController = TextEditingController();
  TextEditingController _prenomController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _adresseController = TextEditingController();
  TextEditingController _telephoneController = TextEditingController();
  TextEditingController _descriptionController = TextEditingController();
  String? _selectedDoctorId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _checkRoleAndRedirect();
  }

  Future<void> _checkRoleAndRedirect() async {
    String? role = await AuthService().getUserRole();
    if (role == 'admin') {
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (context) => const AdminDashboardPage()));
    } else if (role == 'docta') {
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (context) => const DoctorDashboardPage()));
    }
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    _adresseController.dispose();
    _telephoneController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        Patient patient = Patient.fromMap(doc.data() as Map<String, dynamic>);
        setState(() {
          _nomController.text = patient.nom;
          _prenomController.text = patient.prenom;
          _emailController.text = patient.email;
        });
      }
    }
  }

  void _onDateSelected(DateTime day, DateTime focusedDay) {
    setState(() {
      _selectedDate = day;
    });
  }

  Future<void> _sendEmailToDefault(String nom, String prenom, String email,
      String date, String description) async {
    String username = 'moisekapend80@gmail.com';
    String password = 'kvhgrjyixtbjpjvq';

    final smtpServer = gmail(username, password);

    final message = Message()
      ..from = Address(username, 'Service Rendez-Vous')
      ..recipients.add('force.onelib@gmail.com')
      ..subject = 'Nouveau rendez-vous - $date'
      ..text =
          'Nouveau rendez-vous :\n\nNom : $nom $prenom\nEmail : $email\nDate : $date\nDescription : $description';

    try {
      await send(message, smtpServer);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l’envoi de l’email : $e')),
      );
    }
  }

  Future<void> _addAppointmentForPatient(String patientUid) async {
    if (_selectedDoctorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner un docteur.')),
      );
      return;
    }

    final appointmentData = {
      'patientUid': patientUid,
      'doctorUid': _selectedDoctorId,
      'date': _selectedDate,
      'description': _descriptionController.text.trim(),
      'status': 'en attente',
      'createdAt': FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance.collection('rdv').add(appointmentData);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              bool isLoggedIn = snapshot.hasData;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isLoggedIn
                        ? 'Prise de rendez-vous (Patient)'
                        : 'Prise de rendez-vous (Anonyme)',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // Formulaire
                  TextField(
                    controller: _nomController,
                    decoration: InputDecoration(
                      labelText: 'Nom',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    enabled: !isLoggedIn,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _prenomController,
                    decoration: InputDecoration(
                      labelText: 'Prénom',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    enabled: !isLoggedIn,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    enabled: !isLoggedIn,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _adresseController,
                    decoration: InputDecoration(
                      labelText: 'Adresse',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _telephoneController,
                    decoration: InputDecoration(
                      labelText: 'Numéro de téléphone',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 32),

                  // Sélection du docteur (patients connectés uniquement)
                  if (isLoggedIn) ...[
                    const Text(
                      'Sélectionnez un docteur',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .where('role', isEqualTo: 'docta')
                          .where('isActive', isEqualTo: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData)
                          return const CircularProgressIndicator();
                        final doctors = snapshot.data!.docs;

                        return DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          hint: const Text('Choisir un docteur'),
                          value: _selectedDoctorId,
                          items: doctors.map((doc) {
                            final doctorData =
                                doc.data() as Map<String, dynamic>;
                            final doctor = Patient.fromMap(doctorData);
                            return DropdownMenuItem<String>(
                              value: doc.id,
                              child: Text(
                                  '${doctor.prenom} ${doctor.nom} - ${doctorData['specialty']}'),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedDoctorId = value;
                            });
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 32),
                  ],

                  // Calendrier
                  const Text(
                    'Sélectionnez une date',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TableCalendar(
                    focusedDay: _selectedDate,
                    firstDay: DateTime.now(),
                    lastDay: DateTime.now().add(const Duration(days: 365)),
                    calendarFormat: CalendarFormat.month,
                    selectedDayPredicate: (day) =>
                        isSameDay(day, _selectedDate),
                    onDaySelected: _onDateSelected,
                    headerStyle: const HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                    ),
                    calendarStyle: CalendarStyle(
                      isTodayHighlighted: true,
                      selectedDecoration: const BoxDecoration(
                        color: Color.fromRGBO(204, 20, 205, 100),
                        shape: BoxShape.circle,
                      ),
                      todayDecoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Description
                  const Text(
                    'Description de la consultation',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _descriptionController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText:
                          'Décrivez brièvement la raison de votre consultation',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Bouton de confirmation
                  Center(
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : ElevatedButton(
                            onPressed: () async {
                              final nom = _nomController.text.trim();
                              final prenom = _prenomController.text.trim();
                              final email = _emailController.text.trim();
                              final adresse = _adresseController.text.trim();
                              final telephone =
                                  _telephoneController.text.trim();
                              final description =
                                  _descriptionController.text.trim();

                              if (nom.isEmpty ||
                                  prenom.isEmpty ||
                                  email.isEmpty ||
                                  adresse.isEmpty ||
                                  telephone.isEmpty ||
                                  description.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Veuillez remplir tous les champs.')),
                                );
                                return;
                              }

                              setState(() => _isLoading = true);

                              final formattedDate =
                                  '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}';

                              if (isLoggedIn) {
                                await _addAppointmentForPatient(
                                    snapshot.data!.uid);
                              } else {
                                await _sendEmailToDefault(nom, prenom, email,
                                    formattedDate, description);
                              }

                              // Réinitialiser les champs
                              if (!isLoggedIn) {
                                _nomController.clear();
                                _prenomController.clear();
                                _emailController.clear();
                              }
                              _adresseController.clear();
                              _telephoneController.clear();
                              _descriptionController.clear();
                              if (isLoggedIn)
                                setState(() => _selectedDoctorId = null);

                              setState(() => _isLoading = false);

                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Confirmation'),
                                  content: Text(
                                      'Rendez-vous fixé pour le $formattedDate.'),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(),
                                      child: const Text('OK'),
                                    ),
                                  ],
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color.fromRGBO(204, 20, 205, 100),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 32, vertical: 16),
                            ),
                            child: const Text('Confirmer le rendez-vous',
                                style: TextStyle(fontSize: 16)),
                          ),
                  ),

                  const SizedBox(height: 32),

                  // Historique
                  const Text(
                    'Historique des rendez-vous',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  if (!isLoggedIn)
                    Column(
                      children: [
                        const Text(
                          'Aucun rendez-vous sauvegardé.',
                          style: TextStyle(
                              fontSize: 16, fontStyle: FontStyle.italic),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const LoginPage()));
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color.fromRGBO(204, 20, 205, 100),
                          ),
                          child: const Text(
                              'Se connecter pour sauvegarder vos rendez-vous'),
                        ),
                      ],
                    )
                  else
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('rdv')
                          .where('patientUid', isEqualTo: snapshot.data!.uid)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData)
                          return const CircularProgressIndicator();

                        final appointments = snapshot.data!.docs;

                        if (appointments.isEmpty) {
                          return const Text(
                            'Aucun rendez-vous pour le moment.',
                            style: TextStyle(
                                fontSize: 16, fontStyle: FontStyle.italic),
                          );
                        }

                        return Table(
                          border: TableBorder.all(color: Colors.grey),
                          columnWidths: const {
                            0: FlexColumnWidth(2),
                            1: FlexColumnWidth(4),
                            2: FlexColumnWidth(2)
                          },
                          children: [
                            const TableRow(
                              decoration: BoxDecoration(
                                  color: Color.fromRGBO(204, 20, 205, 100)),
                              children: [
                                Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text('Date',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white),
                                      textAlign: TextAlign.center),
                                ),
                                Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text('Description',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white),
                                      textAlign: TextAlign.center),
                                ),
                                Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text('Statut',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white),
                                      textAlign: TextAlign.center),
                                ),
                              ],
                            ),
                            ...appointments.map((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              final date = (data['date'] as Timestamp).toDate();
                              final formattedDate =
                                  '${date.day}/${date.month}/${date.year}';
                              return TableRow(
                                children: [
                                  Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(formattedDate,
                                          textAlign: TextAlign.center)),
                                  Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(data['description'],
                                          textAlign: TextAlign.center)),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(data['status'],
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                            color: Colors.orange)),
                                  ),
                                ],
                              );
                            }),
                          ],
                        );
                      },
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
