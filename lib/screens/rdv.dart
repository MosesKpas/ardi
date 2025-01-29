import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

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
  List<Map<String, String>> _historique = []; // Liste pour l'historique des rendez-vous

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

  void _onDateSelected(DateTime day, DateTime focusedDay) {
    setState(() {
      _selectedDate = day;
    });
  }

  void _ajouterRendezVous(String date, String description) {
    setState(() {
      _historique.add({
        'date': date,
        'description': description,
        'statut': 'En attente',
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Prise de rendez-vous',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Formulaire de prise de rendez-vous
              TextField(
                controller: _nomController,
                decoration: InputDecoration(
                  labelText: 'Nom',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _prenomController,
                decoration: InputDecoration(
                  labelText: 'Prénom',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _adresseController,
                decoration: InputDecoration(
                  labelText: 'Adresse',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _telephoneController,
                decoration: InputDecoration(
                  labelText: 'Numéro de téléphone',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 32),

              // Sélection de la date
              const Text(
                'Sélectionnez une date',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Calendrier
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
                ),
                calendarStyle: CalendarStyle(
                  isTodayHighlighted: true,
                  selectedDecoration: BoxDecoration(
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

              // Description de la consultation
              const Text(
                'Description de la consultation',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Décrivez brièvement la raison de votre consultation',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Bouton de confirmation
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    final nom = _nomController.text.trim();
                    final prenom = _prenomController.text.trim();
                    final email = _emailController.text.trim();
                    final adresse = _adresseController.text.trim();
                    final telephone = _telephoneController.text.trim();
                    final description = _descriptionController.text.trim();

                    if (nom.isEmpty || prenom.isEmpty || email.isEmpty || adresse.isEmpty || telephone.isEmpty || description.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Veuillez remplir tous les champs.'),
                          backgroundColor: Color.fromRGBO(204, 20, 205, 100),
                        ),
                      );
                      return;
                    }

                    // Ajouter le rendez-vous à l'historique
                    final formattedDate =
                        '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}';
                    _ajouterRendezVous(formattedDate, description);

                    // Réinitialiser les champs du formulaire
                    _nomController.clear();
                    _prenomController.clear();
                    _emailController.clear();
                    _adresseController.clear();
                    _telephoneController.clear();
                    _descriptionController.clear();

                    // Afficher une confirmation
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Confirmation'),
                        content: Text(
                          'Votre rendez-vous est fixé pour le $formattedDate avec la description :\n\n"$description"',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromRGBO(204, 20, 205, 100),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                  child: const Text(
                    'Confirmer le rendez-vous',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Historique des rendez-vous
              const Text(
                'Historique des rendez-vous',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _historique.isEmpty
                  ? const Text(
                      'Aucun rendez-vous pour le moment.',
                      style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                    )
                  : Table(
                      border: TableBorder.all(color: Colors.grey),
                      columnWidths: const {
                        0: FlexColumnWidth(2),
                        1: FlexColumnWidth(4),
                        2: FlexColumnWidth(2),
                      },
                      children: [
                        // En-tête du tableau
                        const TableRow(
                          decoration: BoxDecoration(color: Color.fromRGBO(204, 20, 205, 100)),
                          children: [
                            Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                'Date',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                'Description',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                'Statut',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                        // Lignes du tableau
                        ..._historique.map(
                          (rendezVous) => TableRow(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  rendezVous['date']!,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  rendezVous['description']!,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  rendezVous['statut']!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.orange),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
