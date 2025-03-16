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

class _RendezVousPageState extends State<RendezVousPage> with SingleTickerProviderStateMixin {
  DateTime _selectedDate = DateTime.now();
  TextEditingController _nomController = TextEditingController();
  TextEditingController _prenomController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _adresseController = TextEditingController();
  TextEditingController _telephoneController = TextEditingController();
  TextEditingController _otherDescriptionController = TextEditingController();
  List<String> _selectedConsultationTypes = [];
  bool _isLoading = false;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  final List<String> _consultationTypes = [
    'Comportement autistique/autisme',
    'Trouble du langage',
    'Trouble de la marche',
    'Difficulté ou déficit intellectuel',
    'Trouble du comportement',
    'Épilepsie',
    'Malformations',
    'Faiblesse musculaire',
    'Hospitalisation en néonatologie',
    'Hospitalisation soins intensifs de pédiatrie',
    'Maladie rénale',
    'Maladie cardiaque',
    'Diabète',
    'Hypertension artérielle',
    'Autre',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _checkRoleAndRedirect();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
  }

  Future<void> _checkRoleAndRedirect() async {
    String? role = await AuthService().getUserRole();
    if (role == 'admin') {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AdminDashboardPage()));
    } else if (role == 'docta') {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const DoctorDashboardPage()));
    }
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    _adresseController.dispose();
    _telephoneController.dispose();
    _otherDescriptionController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
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

  Future<void> _sendEmailToDefault(String nom, String prenom, String email, String date, String consultationTypes, String? otherDescription) async {
    String username = 'moisekapend80@gmail.com';
    String password = 'kvhgrjyixtbjpjvq';

    final smtpServer = gmail(username, password);

    final message = Message()
      ..from = Address(username, 'Service Rendez-Vous')
      ..recipients.add('force.onelib@gmail.com')
      ..subject = 'Nouveau rendez-vous - $date'
      ..text = 'Nouveau rendez-vous :\n\nNom : $nom $prenom\nEmail : $email\nDate : $date\nTypes de consultation : $consultationTypes${otherDescription != null ? '\nAutre : $otherDescription' : ''}';

    try {
      await send(message, smtpServer);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l’envoi de l’email : $e')),
        );
      }
    }
  }

  Future<void> _addAppointmentForPatient(String patientUid) async {
    if (_selectedConsultationTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner au moins un type de consultation.')),
      );
      return;
    }

    final appointmentData = {
      'patientUid': patientUid,
      'doctorUid': null,
      'date': _selectedDate,
      'consultationTypes': _selectedConsultationTypes,
      'otherDescription': _selectedConsultationTypes.contains('Autre') ? _otherDescriptionController.text.trim() : null,
      'status': 'en attente',
      'createdAt': FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance.collection('rdv').add(appointmentData);
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
          'Prise de Rendez-vous 📅',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
          child: StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              bool isLoggedIn = snapshot.hasData;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Text(
                      isLoggedIn ? 'Planifiez votre rendez-vous' : 'Réservez anonymement',
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Formulaire
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Informations personnelles',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color.fromRGBO(204, 20, 205, 100)),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _nomController,
                            decoration: InputDecoration(
                              labelText: 'Nom',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                            enabled: !isLoggedIn,
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _prenomController,
                            decoration: InputDecoration(
                              labelText: 'Prénom',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                            enabled: !isLoggedIn,
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                            enabled: !isLoggedIn,
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _adresseController,
                            decoration: InputDecoration(
                              labelText: 'Adresse',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _telephoneController,
                            decoration: InputDecoration(
                              labelText: 'Numéro de téléphone',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                            keyboardType: TextInputType.phone,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Type de consultation
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Motif de consultation',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color.fromRGBO(204, 20, 205, 100)),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            isExpanded: true, // Ajouté pour éviter l'overflow
                            decoration: InputDecoration(
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                            hint: const Text('Choisir un type de consultation'),
                            items: _consultationTypes.map((type) {
                              return DropdownMenuItem<String>(
                                value: type,
                                child: Text(
                                  type,
                                  overflow: TextOverflow.ellipsis, // Tronque le texte si trop long
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null && !_selectedConsultationTypes.contains(value)) {
                                setState(() {
                                  _selectedConsultationTypes.add(value);
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 12),
                          if (_selectedConsultationTypes.isNotEmpty) ...[
                            const Text(
                              'Mes choix de consultation :',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                            ),
                            const SizedBox(height: 8),
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _selectedConsultationTypes.length,
                              itemBuilder: (context, index) {
                                final type = _selectedConsultationTypes[index];
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(type, style: const TextStyle(fontSize: 14)),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.remove_circle, color: Colors.red),
                                    onPressed: () {
                                      setState(() {
                                        _selectedConsultationTypes.removeAt(index);
                                      });
                                    },
                                  ),
                                );
                              },
                            ),
                          ],
                          if (_selectedConsultationTypes.contains('Autre')) ...[
                            const SizedBox(height: 12),
                            TextField(
                              controller: _otherDescriptionController,
                              maxLines: 3,
                              decoration: InputDecoration(
                                labelText: 'Décrivez "Autre"',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Calendrier
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Sélectionnez une date',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color.fromRGBO(204, 20, 205, 100)),
                          ),
                          const SizedBox(height: 12),
                          TableCalendar(
                            focusedDay: _selectedDate,
                            firstDay: DateTime.now(),
                            lastDay: DateTime.now().add(const Duration(days: 365)),
                            calendarFormat: CalendarFormat.month,
                            selectedDayPredicate: (day) => isSameDay(day, _selectedDate),
                            onDaySelected: _onDateSelected,
                            headerStyle: const HeaderStyle(
                              formatButtonVisible: false,
                              titleCentered: true,
                              titleTextStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color.fromRGBO(204, 20, 205, 100)),
                            ),
                            calendarStyle: CalendarStyle(
                              isTodayHighlighted: true,
                              selectedDecoration: BoxDecoration(
                                color: const Color.fromRGBO(204, 20, 205, 100).withOpacity(0.8),
                                shape: BoxShape.circle,
                              ),
                              todayDecoration: BoxDecoration(
                                color: const Color.fromRGBO(204, 20, 205, 100).withOpacity(0.3),
                                shape: BoxShape.circle,
                              ),
                              defaultTextStyle: const TextStyle(fontSize: 14, color: Colors.black87),
                              weekendTextStyle: const TextStyle(fontSize: 14, color: Colors.black54),
                            ),
                            daysOfWeekStyle: const DaysOfWeekStyle(
                              weekdayStyle: TextStyle(color: Color.fromRGBO(204, 20, 205, 100)),
                              weekendStyle: TextStyle(color: Color.fromRGBO(204, 20, 205, 100)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Bouton de confirmation
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Center(
                      child: _isLoading
                          ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Color.fromRGBO(204, 20, 205, 100)))
                          : AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              child: ElevatedButton(
                                onPressed: () async {
                                  final nom = _nomController.text.trim();
                                  final prenom = _prenomController.text.trim();
                                  final email = _emailController.text.trim();
                                  final adresse = _adresseController.text.trim();
                                  final telephone = _telephoneController.text.trim();
                                  final otherDescription = _selectedConsultationTypes.contains('Autre') ? _otherDescriptionController.text.trim() : null;

                                  if (nom.isEmpty ||
                                      prenom.isEmpty ||
                                      email.isEmpty ||
                                      adresse.isEmpty ||
                                      telephone.isEmpty ||
                                      _selectedConsultationTypes.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Veuillez remplir tous les champs et sélectionner au moins un type de consultation.')),
                                    );
                                    return;
                                  }

                                  if (_selectedConsultationTypes.contains('Autre') && (otherDescription == null || otherDescription.isEmpty)) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Veuillez décrire "Autre" si sélectionné.')),
                                    );
                                    return;
                                  }

                                  setState(() => _isLoading = true);

                                  final formattedDate = '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}';
                                  final consultationTypesString = _selectedConsultationTypes.join(', ');

                                  if (isLoggedIn) {
                                    await _addAppointmentForPatient(snapshot.data!.uid);
                                  } else {
                                    await _sendEmailToDefault(nom, prenom, email, formattedDate, consultationTypesString, otherDescription);
                                  }

                                  if (!isLoggedIn) {
                                    _nomController.clear();
                                    _prenomController.clear();
                                    _emailController.clear();
                                  }
                                  _adresseController.clear();
                                  _telephoneController.clear();
                                  _otherDescriptionController.clear();
                                  setState(() => _selectedConsultationTypes.clear());

                                  setState(() => _isLoading = false);

                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      title: const Text('Confirmation', style: TextStyle(color: Color.fromRGBO(204, 20, 205, 100))),
                                      content: Text('Rendez-vous fixé pour le $formattedDate.'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.of(context).pop(),
                                          child: const Text('OK', style: TextStyle(color: Color.fromRGBO(204, 20, 205, 100))),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color.fromRGBO(204, 20, 205, 100),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 5,
                                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                child: const Text('Confirmer le rendez-vous'),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Historique
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Historique des rendez-vous',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color.fromRGBO(204, 20, 205, 100)),
                          ),
                          const SizedBox(height: 12),
                          if (!isLoggedIn)
                            Column(
                              children: [
                                const Text(
                                  'Aucun rendez-vous sauvegardé.',
                                  style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.black54),
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginPage()));
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color.fromRGBO(204, 20, 205, 100),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: const Text('Se connecter pour sauvegarder vos rendez-vous'),
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
                                if (!snapshot.hasData) return const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Color.fromRGBO(204, 20, 205, 100)));

                                final appointments = snapshot.data!.docs;

                                if (appointments.isEmpty) {
                                  return const Text(
                                    'Aucun rendez-vous pour le moment.',
                                    style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.black54),
                                  );
                                }

                                return Table(
                                  border: TableBorder.all(color: Colors.grey.shade300),
                                  columnWidths: const {0: FlexColumnWidth(2), 1: FlexColumnWidth(4), 2: FlexColumnWidth(2)},
                                  children: [
                                    TableRow(
                                      decoration: BoxDecoration(color: const Color.fromRGBO(204, 20, 205, 100).withOpacity(0.1)),
                                      children: const [
                                        Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: Text('Date', style: TextStyle(fontWeight: FontWeight.bold, color: Color.fromRGBO(204, 20, 205, 100)), textAlign: TextAlign.center),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: Text('Types de consultation', style: TextStyle(fontWeight: FontWeight.bold, color: Color.fromRGBO(204, 20, 205, 100)), textAlign: TextAlign.center),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: Text('Statut', style: TextStyle(fontWeight: FontWeight.bold, color: Color.fromRGBO(204, 20, 205, 100)), textAlign: TextAlign.center),
                                        ),
                                      ],
                                    ),
                                    ...appointments.map((doc) {
                                      final data = doc.data() as Map<String, dynamic>;
                                      final date = (data['date'] as Timestamp).toDate();
                                      final formattedDate = '${date.day}/${date.month}/${date.year}';
                                      final consultationTypesList = data['consultationTypes'] as List<dynamic>? ?? [];
                                      final consultationTypes = consultationTypesList.isNotEmpty ? consultationTypesList.join(', ') : 'Non spécifié';
                                      return TableRow(
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text(formattedDate, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14)),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text(consultationTypes, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14)),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text(
                                              data['status'] ?? 'Inconnu',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(fontSize: 14, color: data['status'] == 'en attente' ? Colors.orange : Colors.green),
                                            ),
                                          ),
                                        ],
                                      );
                                    }),
                                  ],
                                );
                              },
                            ),
                        ],
                      ),
                    ),
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