import 'package:flutter/material.dart';

class DoctorDashboardPage extends StatefulWidget {
  const DoctorDashboardPage({super.key});

  @override
  State<DoctorDashboardPage> createState() => _DoctorDashboardPageState();
}

class _DoctorDashboardPageState extends State<DoctorDashboardPage> {
  final List<Map<String, dynamic>> _appointments = [
    {'id': 1, 'patient': 'Roger kalala', 'date': '06/02/2025', 'status': 'En attente'},
    {'id': 2, 'patient': 'Marie', 'date': '07/02/2025', 'status': 'Confirmé'},
  ];

  final List<Map<String, dynamic>> _prescriptions = [
    {'id': 1, 'patient': 'Roger kalala', 'medication': 'Paracétamol', 'date': '01/02/2025'},
    {'id': 2, 'patient': 'Marie', 'medication': 'Ibuprofène', 'date': '02/02/2025'},
  ];

  final List<Map<String, dynamic>> _messages = [
    {'id': 1, 'patient': 'Roger kalala', 'message': 'Docteur, j’ai encore des douleurs.', 'date': '05/02/2025'},
    {'id': 2, 'patient': 'Marie', 'message': 'Merci pour votre assistance.', 'date': '06/02/2025'},
  ];

  void _confirmAppointment(int index) {
    setState(() {
      _appointments[index]['status'] = 'Confirmé';
    });
  }

  void _cancelAppointment(int index) {
    setState(() {
      _appointments[index]['status'] = 'Annulé';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de Bord Docteur'),
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Rendez-vous soumis'),
            _appointments.isEmpty
                ? const Text('Aucun rendez-vous soumis.')
                : _buildAppointmentList(),

            const SizedBox(height: 20),

            _buildSectionTitle('Prescriptions données'),
            _prescriptions.isEmpty
                ? const Text('Aucune prescription enregistrée.')
                : _buildPrescriptionList(),

            const SizedBox(height: 20),

            _buildSectionTitle('Messages des patients'),
            _messages.isEmpty
                ? const Text('Aucun message reçu.')
                : _buildMessageList(),

            const SizedBox(height: 20),

            _buildSectionTitle('Rendez-vous à venir'),
            _buildUpcomingAppointments(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildAppointmentList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _appointments.length,
      itemBuilder: (context, index) {
        final appointment = _appointments[index];
        bool isPending = appointment['status'] == 'En attente';

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 5),
          child: ListTile(
            title: Text('${appointment['patient']} - ${appointment['date']}'),
            subtitle: Text('Statut : ${appointment['status']}'),
            trailing: isPending
                ? Wrap(
                    spacing: 8,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check_circle, color: Colors.green),
                        onPressed: () => _confirmAppointment(index),
                        tooltip: 'Confirmer',
                      ),
                      IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.red),
                        onPressed: () => _cancelAppointment(index),
                        tooltip: 'Annuler',
                      ),
                    ],
                  )
                : null,
          ),
        );
      },
    );
  }

  Widget _buildPrescriptionList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _prescriptions.length,
      itemBuilder: (context, index) {
        final prescription = _prescriptions[index];

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 5),
          child: ListTile(
            title: Text('${prescription['patient']} - ${prescription['medication']}'),
            subtitle: Text('Date : ${prescription['date']}'),
          ),
        );
      },
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 5),
          child: ListTile(
            title: Text('${message['patient']} - ${message['date']}'),
            subtitle: Text(message['message']),
          ),
        );
      },
    );
  }

  Widget _buildUpcomingAppointments() {
    final upcomingAppointments =
        _appointments.where((appointment) => appointment['status'] == 'Confirmé').toList();

    return upcomingAppointments.isEmpty
        ? const Text('Aucun rendez-vous confirmé.')
        : ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: upcomingAppointments.length,
            itemBuilder: (context, index) {
              final appointment = upcomingAppointments[index];

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 5),
                child: ListTile(
                  title: Text('${appointment['patient']} - ${appointment['date']}'),
                  subtitle: const Text('Statut : Confirmé'),
                ),
              );
            },
          );
  }
}
