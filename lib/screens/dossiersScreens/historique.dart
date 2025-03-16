import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AppointmentsHistoryPage extends StatefulWidget {
  const AppointmentsHistoryPage({Key? key}) : super(key: key);

  @override
  _AppointmentsHistoryPageState createState() => _AppointmentsHistoryPageState();
}

class _AppointmentsHistoryPageState extends State<AppointmentsHistoryPage> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  List<Map<String, dynamic>> _appointments = [];
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
    _loadAppointments();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadAppointments() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (mounted) setState(() => _isLoading = true);

    QuerySnapshot appointmentsSnapshot = await FirebaseFirestore.instance
        .collection('rdv')
        .where('patientUid', isEqualTo: user.uid)
        .orderBy('date', descending: true)
        .get();

    List<Map<String, dynamic>> tempAppointments = [];
    for (var doc in appointmentsSnapshot.docs) {
      var data = doc.data() as Map<String, dynamic>;
      tempAppointments.add({
        'date': (data['date'] as Timestamp).toDate(),
        'consultationTypes': data['consultationTypes'] as List<dynamic>? ?? [],
        'status': data['status'] ?? 'Inconnu',
      });
    }

    if (mounted) {
      setState(() {
        _appointments = tempAppointments;
        _isLoading = false;
      });
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
          'Historique des rendez-vous',
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
                  child: _appointments.isEmpty
                      ? const Center(child: Text('Aucun rendez-vous trouvé.', style: TextStyle(color: Colors.grey)))
                      : Container(
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
                          child: Table(
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
                              ..._appointments.map((appointment) {
                                final formattedDate = '${appointment['date'].day}/${appointment['date'].month}/${appointment['date'].year}';
                                final consultationTypes = (appointment['consultationTypes'] as List<dynamic>? ?? []).join(', ') ?? 'Non spécifié';
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
                                        appointment['status'],
                                        textAlign: TextAlign.center,
                                        style: TextStyle(fontSize: 14, color: appointment['status'] == 'en attente' ? Colors.orange : Colors.green),
                                      ),
                                    ),
                                  ],
                                );
                              }),
                            ],
                          ),
                        ),
                ),
              ),
      ),
    );
  }
}