import 'package:flutter/material.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final int _totalUsers = 150;
  final int _registeredUsers = 120;
  final int _totalDoctors = 30;

  void _navigateToAddDoctorPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddDoctorPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    int unregisteredUsers = _totalUsers - _registeredUsers;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de Bord Admin'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Statistiques Générales',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Statistiques
            _buildStatCard('Utilisateurs Inscrits', _registeredUsers, Colors.green),
            _buildStatCard('Utilisateurs Non Inscrits', unregisteredUsers, Colors.red),
            _buildStatCard('Médecins Disponibles', _totalDoctors, Colors.blue),

            const SizedBox(height: 30),

            // Bouton Ajouter Médecin
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

// Page pour ajouter un médecin
class AddDoctorPage extends StatefulWidget {
  const AddDoctorPage({super.key});

  @override
  State<AddDoctorPage> createState() => _AddDoctorPageState();
}

class _AddDoctorPageState extends State<AddDoctorPage> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _specialtyController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final List<String> _daysOfWeek = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
  final List<String> _selectedDays = [];

  void _submitDoctor() {
    String firstName = _firstNameController.text.trim();
    String lastName = _lastNameController.text.trim();
    String specialty = _specialtyController.text.trim();
    String category = _categoryController.text.trim();

    if (firstName.isEmpty || lastName.isEmpty || specialty.isEmpty || category.isEmpty || _selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs')),
      );
      return;
    }

    // Afficher confirmation
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Médecin Ajouté'),
        content: Text('Médecin : $firstName $lastName\nSpécialité : $specialty\nCatégorie : $category\nJours : ${_selectedDays.join(", ")}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );

    // Réinitialiser les champs
    _firstNameController.clear();
    _lastNameController.clear();
    _specialtyController.clear();
    _categoryController.clear();
    setState(() {
      _selectedDays.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajouter un Médecin'), backgroundColor: Colors.deepPurple),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildTextField(_firstNameController, 'Nom'),
            _buildTextField(_lastNameController, 'Prénom'),
            _buildTextField(_specialtyController, 'Spécialité'),
            _buildTextField(_categoryController, 'Catégorie'),

            const SizedBox(height: 20),

            // Jours de travail
            const Text('Jours de Travail', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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

            // Bouton de soumission
            ElevatedButton(
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
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}
