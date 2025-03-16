import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';

class MedicalProfilePage extends StatefulWidget {
  const MedicalProfilePage({Key? key}) : super(key: key);

  @override
  _MedicalProfilePageState createState() => _MedicalProfilePageState();
}

class _MedicalProfilePageState extends State<MedicalProfilePage>
    with SingleTickerProviderStateMixin {
  // Contrôleurs pour les champs
  TextEditingController _ageController = TextEditingController();
  TextEditingController _professionController = TextEditingController();
  TextEditingController _heightWeightController = TextEditingController();
  TextEditingController _bloodPressureController = TextEditingController();
  TextEditingController _familyHistoryDetailsController =
      TextEditingController();
  TextEditingController _geneticDisordersDetailsController =
      TextEditingController();
  TextEditingController _chronicIllnessesDetailsController =
      TextEditingController();
  TextEditingController _previousDiagnosesDetailsController =
      TextEditingController();
  TextEditingController _surgeriesDetailsController = TextEditingController();
  TextEditingController _allergiesDetailsController = TextEditingController();
  TextEditingController _dietDetailsController = TextEditingController();
  TextEditingController _activityDetailsController = TextEditingController();
  TextEditingController _alcoholDetailsController = TextEditingController();
  TextEditingController _tobaccoDetailsController = TextEditingController();
  TextEditingController _drugsDetailsController = TextEditingController();
  TextEditingController _pollutantsDetailsController = TextEditingController();
  TextEditingController _householdPeopleController = TextEditingController();
  TextEditingController _sleepingRoomsController = TextEditingController();

  // Variables pour les sélections
  bool _useDateOfBirth = true;
  DateTime? _dateOfBirth;
  int? _calculatedAge;
  String? _sex;
  String? _ethnicity;
  String? _lifestyleExposure;
  bool _hasFamilyHistory = false;
  bool _hasGeneticDisorders = false;
  bool _hasChronicIllnesses = false;
  bool _hasPreviousDiagnoses = false;
  bool _hasSurgeries = false;
  bool _hasAllergies = false;
  bool _hasDietIssues = false;
  bool _hasActivityIssues = false;
  bool _hasAlcoholConsumption = false;
  String? _tobaccoConsumption;
  String? _drugsConsumption;
  bool _hasPollutantsExposure = false;

  // Statut socioéconomique
  Map<String, bool> _socioeconomicItems = {
    'electricity': false,
    'radio': false,
    'television': false,
    'refrigerator': false,
    'cellPhone': false,
    'personalComputerOrLaptop': false,
    'farmAnimals': false,
    'agriculturalLand': false,
    'bicycle': false,
    'motorcycleScooter': false,
    'carTruck': false,
  };

  bool _isLoading = false;
  bool _isProfileSaved = false;

  // Données récupérées pour l'export PDF
  Map<String, dynamic>? _profileData;

  // Animation
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Options pour les listes déroulantes
  final List<String> _sexOptions = ['Homme', 'Femme'];
  final List<String> _ethnicityOptions = [
    'Caucasien',
    'Africain',
    'Asiatique',
    'Hispanique',
    'Autre'
  ];
  final List<String> _lifestyleExposureOptions = ['Urbain', 'Rural'];
  final List<String> _consumptionOptions = [
    'Nulle',
    'Occasionnelle',
    'Fréquente',
    'Régulière'
  ];

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
    _loadProfile();
  }

  @override
  void dispose() {
    _ageController.dispose();
    _professionController.dispose();
    _heightWeightController.dispose();
    _bloodPressureController.dispose();
    _familyHistoryDetailsController.dispose();
    _geneticDisordersDetailsController.dispose();
    _chronicIllnessesDetailsController.dispose();
    _previousDiagnosesDetailsController.dispose();
    _surgeriesDetailsController.dispose();
    _allergiesDetailsController.dispose();
    _dietDetailsController.dispose();
    _activityDetailsController.dispose();
    _alcoholDetailsController.dispose();
    _tobaccoDetailsController.dispose();
    _drugsDetailsController.dispose();
    _pollutantsDetailsController.dispose();
    _householdPeopleController.dispose();
    _sleepingRoomsController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('medicalProfile')
        .doc('profile')
        .get();

    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      setState(() {
        _profileData = data;
        _calculatedAge = data['age'];
        _ageController.text = data['age']?.toString() ?? '';
        _sex = data['sex'];
        _ethnicity = data['ethnicity'];
        _professionController.text = data['profession'] ?? '';
        _lifestyleExposure =
            data['environmentalExposures']?['lifestyleExposures'];

        // Historique médical familial
        _hasFamilyHistory = data['familyMedicalHistory'] != null;
        _familyHistoryDetailsController.text =
            data['familyMedicalHistory'] ?? '';

        // Historique médical personnel
        _hasGeneticDisorders =
            data['personalMedicalHistory']?['geneticDisorders'] != null;
        _geneticDisordersDetailsController.text =
            data['personalMedicalHistory']?['geneticDisorders'] ?? '';
        _hasChronicIllnesses =
            data['personalMedicalHistory']?['chronicIllnesses'] != null;
        _chronicIllnessesDetailsController.text =
            data['personalMedicalHistory']?['chronicIllnesses'] ?? '';
        _hasPreviousDiagnoses =
            data['personalMedicalHistory']?['previousDiagnoses'] != null;
        _previousDiagnosesDetailsController.text =
            data['personalMedicalHistory']?['previousDiagnoses'] ?? '';
        _hasSurgeries = data['personalMedicalHistory']?['surgeries'] != null;
        _surgeriesDetailsController.text =
            data['personalMedicalHistory']?['surgeries'] ?? '';
        _hasAllergies = data['personalMedicalHistory']?['allergies'] != null;
        _allergiesDetailsController.text =
            data['personalMedicalHistory']?['allergies'] ?? '';

        // Facteurs de mode de vie
        _hasDietIssues = data['lifestyleFactors']?['dietAndNutrition'] != null;
        _dietDetailsController.text =
            data['lifestyleFactors']?['dietAndNutrition'] ?? '';
        _hasActivityIssues =
            data['lifestyleFactors']?['physicalActivity'] != null;
        _activityDetailsController.text =
            data['lifestyleFactors']?['physicalActivity'] ?? '';
        _hasAlcoholConsumption =
            data['lifestyleFactors']?['alcoholConsumption'] != null;
        _alcoholDetailsController.text =
            data['lifestyleFactors']?['alcoholConsumption'] ?? '';
        _tobaccoConsumption =
            data['lifestyleFactors']?['tobaccoConsumption'] ?? 'Nulle';
        _tobaccoDetailsController.text =
            data['lifestyleFactors']?['tobaccoDetails'] ?? '';
        _drugsConsumption =
            data['lifestyleFactors']?['drugsConsumption'] ?? 'Nulle';
        _drugsDetailsController.text =
            data['lifestyleFactors']?['drugsDetails'] ?? '';

        // Biométrie
        _heightWeightController.text =
            data['clinicalMeasurements']?['heightAndWeight'] ?? '';
        _bloodPressureController.text =
            data['clinicalMeasurements']?['bloodPressure'] ?? '';

        // Expositions environnementales
        _hasPollutantsExposure =
            data['environmentalExposures']?['occupationalPollutants'] != null;
        _pollutantsDetailsController.text =
            data['environmentalExposures']?['occupationalPollutants'] ?? '';

        // Statut socioéconomique
        final socioeconomicStatus = data['socioeconomicStatus'];
        if (socioeconomicStatus is Map) {
          _socioeconomicItems.forEach((key, _) {
            final value = socioeconomicStatus[key];
            _socioeconomicItems[key] = value is bool ? value : false;
          });
          _householdPeopleController.text =
              socioeconomicStatus['householdPeople']?.toString() ?? '';
          _sleepingRoomsController.text =
              socioeconomicStatus['sleepingRooms']?.toString() ?? '';
        } else {
          // Si socioeconomicStatus n'est pas un Map, réinitialiser les valeurs
          _socioeconomicItems
              .forEach((key, _) => _socioeconomicItems[key] = false);
          _householdPeopleController.text = '';
          _sleepingRoomsController.text = '';
        }

        _isProfileSaved = true;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDateOfBirth(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color.fromRGBO(204, 20, 205, 100),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _dateOfBirth) {
      setState(() {
        _dateOfBirth = picked;
        _calculatedAge = DateTime.now().year - picked.year;
        if (DateTime.now().month < picked.month ||
            (DateTime.now().month == picked.month &&
                DateTime.now().day < picked.day)) {
          _calculatedAge = _calculatedAge! - 1;
        }
      });
    }
  }

  Future<void> _saveProfile() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (_calculatedAge == null && _ageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 8),
              Text('Veuillez indiquer votre âge.'),
            ],
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (_sex == null || _ethnicity == null || _lifestyleExposure == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 8),
              Text('Veuillez remplir tous les champs démographiques.'),
            ],
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (_heightWeightController.text.isEmpty ||
        _bloodPressureController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 8),
              Text('Veuillez remplir les données de biométrie.'),
            ],
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final profileData = {
      'age': _calculatedAge ?? int.parse(_ageController.text),
      'sex': _sex,
      'ethnicity': _ethnicity,
      'profession': _professionController.text.trim(),
      'socioeconomicStatus': {
        ..._socioeconomicItems,
        'householdPeople': _householdPeopleController.text.isNotEmpty
            ? int.tryParse(_householdPeopleController.text)
            : null,
        'sleepingRooms': _sleepingRoomsController.text.isNotEmpty
            ? int.tryParse(_sleepingRoomsController.text)
            : null,
      },
      'familyMedicalHistory': _hasFamilyHistory
          ? _familyHistoryDetailsController.text.trim()
          : null,
      'personalMedicalHistory': {
        'geneticDisorders': _hasGeneticDisorders
            ? _geneticDisordersDetailsController.text.trim()
            : null,
        'chronicIllnesses': _hasChronicIllnesses
            ? _chronicIllnessesDetailsController.text.trim()
            : null,
        'previousDiagnoses': _hasPreviousDiagnoses
            ? _previousDiagnosesDetailsController.text.trim()
            : null,
        'surgeries':
            _hasSurgeries ? _surgeriesDetailsController.text.trim() : null,
        'allergies':
            _hasAllergies ? _allergiesDetailsController.text.trim() : null,
      },
      'lifestyleFactors': {
        'dietAndNutrition':
            _hasDietIssues ? _dietDetailsController.text.trim() : null,
        'physicalActivity':
            _hasActivityIssues ? _activityDetailsController.text.trim() : null,
        'alcoholConsumption': _hasAlcoholConsumption
            ? _alcoholDetailsController.text.trim()
            : null,
        'tobaccoConsumption': _tobaccoConsumption,
        'tobaccoDetails': _tobaccoConsumption != 'Nulle'
            ? _tobaccoDetailsController.text.trim()
            : null,
        'drugsConsumption': _drugsConsumption,
        'drugsDetails': _drugsConsumption != 'Nulle'
            ? _drugsDetailsController.text.trim()
            : null,
      },
      'clinicalMeasurements': {
        'heightAndWeight': _heightWeightController.text.trim(),
        'bloodPressure': _bloodPressureController.text.trim(),
      },
      'environmentalExposures': {
        'occupationalPollutants': _hasPollutantsExposure
            ? _pollutantsDetailsController.text.trim()
            : null,
        'lifestyleExposures': _lifestyleExposure,
      },
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('medicalProfile')
        .doc('profile')
        .set(profileData);

    setState(() {
      _isLoading = false;
      _isProfileSaved = true;
      _profileData = profileData;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text('Profil médical sauvegardé avec succès !'),
          ],
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _exportToPDF() async {
    if (_profileData == null) return;

    final pdf = pw.Document();

    pdf.addPage(pw.Page(
      build: (pw.Context context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Profil Médical',
              style:
                  pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 20),
          pw.Text('Démographie',
              style:
                  pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          pw.Text('Âge: ${_profileData!['age']} ans'),
          pw.Text('Sexe: ${_profileData!['sex'] ?? 'Non spécifié'}'),
          pw.Text('Ethnicité: ${_profileData!['ethnicity'] ?? 'Non spécifié'}'),
          pw.SizedBox(height: 20),
          pw.Text('Statut socioéconomique',
              style:
                  pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          pw.Text(
              'Profession: ${_profileData!['profession'] ?? 'Non spécifié'}'),
          pw.Text('Avez-vous :',
              style:
                  pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          // Vérification que socioeconomicStatus est un Map avant d'accéder aux clés
          if (_profileData!['socioeconomicStatus'] is Map) ...[
            pw.Bullet(
              text:
                  'Électricité: ${(_profileData!['socioeconomicStatus'] as Map)['electricity'] ?? false ? 'Oui' : 'Non'}',
            ),
            pw.Bullet(
              text:
                  'Radio: ${(_profileData!['socioeconomicStatus'] as Map)['radio'] ?? false ? 'Oui' : 'Non'}',
            ),
            pw.Bullet(
              text:
                  'Télévision: ${(_profileData!['socioeconomicStatus'] as Map)['television'] ?? false ? 'Oui' : 'Non'}',
            ),
            pw.Bullet(
              text:
                  'Réfrigérateur: ${(_profileData!['socioeconomicStatus'] as Map)['refrigerator'] ?? false ? 'Oui' : 'Non'}',
            ),
            pw.Bullet(
              text:
                  'Téléphone portable: ${(_profileData!['socioeconomicStatus'] as Map)['cellPhone'] ?? false ? 'Oui' : 'Non'}',
            ),
            pw.Bullet(
              text:
                  'Ordinateur personnel ou portable: ${(_profileData!['socioeconomicStatus'] as Map)['personalComputerOrLaptop'] ?? false ? 'Oui' : 'Non'}',
            ),
            pw.Bullet(
              text:
                  'Animaux de ferme: ${(_profileData!['socioeconomicStatus'] as Map)['farmAnimals'] ?? false ? 'Oui' : 'Non'}',
            ),
            pw.Bullet(
              text:
                  'Terre agricole: ${(_profileData!['socioeconomicStatus'] as Map)['agriculturalLand'] ?? false ? 'Oui' : 'Non'}',
            ),
            pw.Bullet(
              text:
                  'Bicyclette: ${(_profileData!['socioeconomicStatus'] as Map)['bicycle'] ?? false ? 'Oui' : 'Non'}',
            ),
            pw.Bullet(
              text:
                  'Moto/Scooter: ${(_profileData!['socioeconomicStatus'] as Map)['motorcycleScooter'] ?? false ? 'Oui' : 'Non'}',
            ),
            pw.Bullet(
              text:
                  'Voiture/Camion: ${(_profileData!['socioeconomicStatus'] as Map)['carTruck'] ?? false ? 'Oui' : 'Non'}',
            ),
            pw.Text(
              'Personnes dans le ménage: ${(_profileData!['socioeconomicStatus'] as Map)['householdPeople']?.toString() ?? 'Non spécifié'}',
            ),
            pw.Text(
              'Pièces pour dormir: ${(_profileData!['socioeconomicStatus'] as Map)['sleepingRooms']?.toString() ?? 'Non spécifié'}',
            ),
          ] else
            pw.Text('Statut socioéconomique non disponible',
                style: pw.TextStyle(fontSize: 14)),
          pw.SizedBox(height: 20),
          pw.Text('Biométrie',
              style:
                  pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          pw.Text(
              'Taille et poids: ${_profileData!['clinicalMeasurements']?['heightAndWeight'] ?? 'Non spécifié'}'),
          pw.Text(
              'Pression artérielle: ${_profileData!['clinicalMeasurements']?['bloodPressure'] ?? 'Non spécifié'}'),
          pw.SizedBox(height: 20),
          pw.Text('Historique médical familial',
              style:
                  pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          pw.Text(
              'Antécédents familiaux: ${_profileData!['familyMedicalHistory'] ?? 'Aucun'}'),
          pw.SizedBox(height: 20),
          pw.Text('Historique médical personnel',
              style:
                  pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          pw.Text(
              'Troubles génétiques: ${_profileData!['personalMedicalHistory']?['geneticDisorders'] ?? 'Aucun'}'),
          pw.Text(
              'Maladies chroniques: ${_profileData!['personalMedicalHistory']?['chronicIllnesses'] ?? 'Aucun'}'),
          pw.Text(
              'Diagnostics précédents: ${_profileData!['personalMedicalHistory']?['previousDiagnoses'] ?? 'Aucun'}'),
          pw.Text(
              'Chirurgies: ${_profileData!['personalMedicalHistory']?['surgeries'] ?? 'Aucune'}'),
          pw.Text(
              'Allergies: ${_profileData!['personalMedicalHistory']?['allergies'] ?? 'Aucune'}'),
          pw.SizedBox(height: 20),
          pw.Text('Facteurs de mode de vie',
              style:
                  pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          pw.Text(
              'Régime alimentaire: ${_profileData!['lifestyleFactors']?['dietAndNutrition'] ?? 'Aucun'}'),
          pw.Text(
              'Activité physique: ${_profileData!['lifestyleFactors']?['physicalActivity'] ?? 'Aucune'}'),
          pw.Text(
              'Consommation d’alcool: ${_profileData!['lifestyleFactors']?['alcoholConsumption'] ?? 'Aucune'}'),
          pw.Text(
              'Consommation de tabac: ${_profileData!['lifestyleFactors']?['tobaccoConsumption'] ?? 'Nulle'}'),
          if (_profileData!['lifestyleFactors']?['tobaccoDetails'] != null)
            pw.Text(
                'Détails tabac: ${_profileData!['lifestyleFactors']?['tobaccoDetails']}'),
          pw.Text(
              'Consommation de drogues: ${_profileData!['lifestyleFactors']?['drugsConsumption'] ?? 'Nulle'}'),
          if (_profileData!['lifestyleFactors']?['drugsDetails'] != null)
            pw.Text(
                'Détails drogues: ${_profileData!['lifestyleFactors']?['drugsDetails']}'),
          pw.SizedBox(height: 20),
          pw.Text('Expositions environnementales',
              style:
                  pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          pw.Text(
              'Polluants occupationnels: ${_profileData!['environmentalExposures']?['occupationalPollutants'] ?? 'Aucun'}'),
          pw.Text(
              'Mode de vie: ${_profileData!['environmentalExposures']?['lifestyleExposures'] ?? 'Non spécifié'}'),
        ],
      ),
    ));

    final output = await getTemporaryDirectory();
    final file = File('${output.path}/profil_medical.pdf');
    await file.writeAsBytes(await pdf.save());

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Voici mon profil médical en PDF',
    );
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
        title: Row(
          children: const [
            Icon(Icons.person, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Profil médical',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
          ],
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
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionCard(
                  title: 'Démographie',
                  icon: Icons.people,
                  child: Column(
                    children: [
                      _buildAgeSection(),
                      const SizedBox(height: 16),
                      _buildDropdownField('Sexe', _sex, _sexOptions,
                          (value) => setState(() => _sex = value)),
                      const SizedBox(height: 16),
                      _buildDropdownField(
                          'Ethnicité',
                          _ethnicity,
                          _ethnicityOptions,
                          (value) => setState(() => _ethnicity = value)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionCard(
                  title: 'Biométrie',
                  icon: Icons.health_and_safety,
                  child: Column(
                    children: [
                      _buildTextField('Taille et poids (ex. 1.75m, 70kg)',
                          _heightWeightController),
                      const SizedBox(height: 16),
                      _buildTextField('Pression artérielle (ex. 120/80 mmHg)',
                          _bloodPressureController),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionCard(
                  title: 'Statut socioéconomique',
                  icon: Icons.work,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTextField('Profession', _professionController),
                      const SizedBox(height: 16),
                      const Text(
                        'Avez-vous :',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color.fromRGBO(204, 20, 205, 100)),
                      ),
                      const SizedBox(height: 12),
                      ..._socioeconomicItems.keys.map((key) => CheckboxListTile(
                            title: Text('${_getItemLabel(key)} ?'),
                            value: _socioeconomicItems[key],
                            onChanged: (value) => setState(
                                () => _socioeconomicItems[key] = value!),
                            activeColor:
                                const Color.fromRGBO(204, 20, 205, 100),
                          )),
                      _buildTextField('Combien de personnes vivent avec vous ?',
                          _householdPeopleController),
                      _buildTextField(
                          'Combien de pièces sont utilisées pour dormir ?',
                          _sleepingRoomsController),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionCard(
                  title: 'Historique méd. familial',
                  icon: Icons.family_restroom,
                  child: _buildYesNoQuestion(
                    'Avez-vous des antécédents familiaux de maladies ?',
                    _hasFamilyHistory,
                    (value) => setState(() => _hasFamilyHistory = value!),
                    _familyHistoryDetailsController,
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionCard(
                  title: 'Historique méd. personnel',
                  icon: Icons.local_hospital,
                  child: Column(
                    children: [
                      _buildYesNoQuestion(
                        'Avez-vous des troubles génétiques ?',
                        _hasGeneticDisorders,
                        (value) =>
                            setState(() => _hasGeneticDisorders = value!),
                        _geneticDisordersDetailsController,
                      ),
                      const SizedBox(height: 16),
                      _buildYesNoQuestion(
                        'Avez-vous des maladies chroniques ?',
                        _hasChronicIllnesses,
                        (value) =>
                            setState(() => _hasChronicIllnesses = value!),
                        _chronicIllnessesDetailsController,
                      ),
                      const SizedBox(height: 16),
                      _buildYesNoQuestion(
                        'Avez-vous eu des diagnostics précédents ?',
                        _hasPreviousDiagnoses,
                        (value) =>
                            setState(() => _hasPreviousDiagnoses = value!),
                        _previousDiagnosesDetailsController,
                      ),
                      const SizedBox(height: 16),
                      _buildYesNoQuestion(
                        'Avez-vous subi des chirurgies ?',
                        _hasSurgeries,
                        (value) => setState(() => _hasSurgeries = value!),
                        _surgeriesDetailsController,
                      ),
                      const SizedBox(height: 16),
                      _buildYesNoQuestion(
                        'Avez-vous des allergies ?',
                        _hasAllergies,
                        (value) => setState(() => _hasAllergies = value!),
                        _allergiesDetailsController,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionCard(
                  title: 'Facteurs de mode de vie',
                  icon: Icons.fitness_center,
                  child: Column(
                    children: [
                      _buildYesNoQuestion(
                        'Suivez-vous un régime alimentaire particulier ?',
                        _hasDietIssues,
                        (value) => setState(() => _hasDietIssues = value!),
                        _dietDetailsController,
                      ),
                      const SizedBox(height: 16),
                      _buildYesNoQuestion(
                        'Pratiquez-vous une activité physique régulière ?',
                        _hasActivityIssues,
                        (value) => setState(() => _hasActivityIssues = value!),
                        _activityDetailsController,
                      ),
                      const SizedBox(height: 16),
                      _buildYesNoQuestion(
                        'Consommez-vous de l’alcool ?',
                        _hasAlcoholConsumption,
                        (value) =>
                            setState(() => _hasAlcoholConsumption = value!),
                        _alcoholDetailsController,
                      ),
                      const SizedBox(height: 16),
                      _buildConsumptionQuestion(
                        'Consommez-vous du tabac ?',
                        _tobaccoConsumption,
                        (value) => setState(() => _tobaccoConsumption = value),
                        _tobaccoDetailsController,
                      ),
                      const SizedBox(height: 16),
                      _buildConsumptionQuestion(
                        'Consommez-vous des drogues ?',
                        _drugsConsumption,
                        (value) => setState(() => _drugsConsumption = value),
                        _drugsDetailsController,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionCard(
                  title: 'Expo. environnementales',
                  icon: Icons.eco,
                  child: Column(
                    children: [
                      _buildYesNoQuestion(
                        'Êtes-vous exposé à des polluants occupationnels ?',
                        _hasPollutantsExposure,
                        (value) =>
                            setState(() => _hasPollutantsExposure = value!),
                        _pollutantsDetailsController,
                      ),
                      const SizedBox(height: 16),
                      _buildDropdownField(
                          'Mode de vie (Urbain/Rural)',
                          _lifestyleExposure,
                          _lifestyleExposureOptions,
                          (value) =>
                              setState(() => _lifestyleExposure = value)),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Center(
                  child: Column(
                    children: [
                      if (_isProfileSaved)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          child: ElevatedButton.icon(
                            onPressed: _exportToPDF,
                            icon: const Icon(Icons.picture_as_pdf, size: 20),
                            label: const Text('Exporter en PDF',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 32, vertical: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              elevation: 5,
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      _isLoading
                          ? const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation(
                                  Color.fromRGBO(204, 20, 205, 100)),
                            )
                          : AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              child: ElevatedButton.icon(
                                onPressed: _saveProfile,
                                icon: const Icon(Icons.save, size: 20),
                                label: const Text('Enregistrer',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      const Color.fromRGBO(204, 20, 205, 100),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 32, vertical: 16),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  elevation: 5,
                                ),
                              ),
                            ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard(
      {required String title, required IconData icon, required Widget child}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon,
                    color: const Color.fromRGBO(204, 20, 205, 100), size: 28),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color.fromRGBO(204, 20, 205, 100),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(color: Colors.grey, thickness: 0.5),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildAgeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Âge',
          style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildToggleButton(
              text: 'Date de naissance',
              isSelected: _useDateOfBirth,
              onTap: () => setState(() => _useDateOfBirth = true),
            ),
            _buildToggleButton(
              text: 'Saisir l’âge',
              isSelected: !_useDateOfBirth,
              onTap: () => setState(() => _useDateOfBirth = false),
            ),
          ],
        ),
        const SizedBox(height: 12),
        AnimatedCrossFade(
          firstChild: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _selectDateOfBirth(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      border:
                          Border.all(color: Colors.grey.shade300, width: 1.5),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.white,
                    ),
                    child: Text(
                      _dateOfBirth == null
                          ? 'Sélectionnez votre date de naissance'
                          : 'Date de naissance : ${DateFormat('dd/MM/yyyy').format(_dateOfBirth!)}',
                      style: TextStyle(
                          fontSize: 16,
                          color: _dateOfBirth == null
                              ? Colors.grey
                              : Colors.black87),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.calendar_today,
                    color: Color.fromRGBO(204, 20, 205, 100)),
                onPressed: () => _selectDateOfBirth(context),
                constraints: const BoxConstraints(maxWidth: 48),
              ),
            ],
          ),
          secondChild: TextField(
            controller: _ageController,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 16, color: Colors.black87),
            decoration: InputDecoration(
              labelText: 'Âge (en années)',
              labelStyle: const TextStyle(color: Colors.grey),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.grey, width: 1.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.grey, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                    color: Color.fromRGBO(204, 20, 205, 100), width: 2),
              ),
            ),
          ),
          crossFadeState: _useDateOfBirth
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          duration: const Duration(milliseconds: 300),
        ),
        if (_calculatedAge != null && _useDateOfBirth)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              'Âge calculé : $_calculatedAge ans',
              style: const TextStyle(fontSize: 14, color: Colors.black54),
            ),
          ),
      ],
    );
  }

  Widget _buildToggleButton(
      {required String text,
      required bool isSelected,
      required VoidCallback onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color.fromRGBO(204, 20, 205, 100)
                : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownField(String label, String? value, List<String> options,
      Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          isExpanded: true,
          value: value,
          items: options.map((option) {
            return DropdownMenuItem<String>(
              value: option,
              child: Text(
                option,
                style: const TextStyle(fontSize: 16, color: Colors.black87),
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.grey, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.grey, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                  color: Color.fromRGBO(204, 20, 205, 100), width: 2),
            ),
            hintText: 'Sélectionnez $label',
            hintStyle: const TextStyle(color: Colors.grey),
            prefixIcon: const Icon(Icons.arrow_drop_down,
                color: Color.fromRGBO(204, 20, 205, 100)),
          ),
        ),
      ],
    );
  }

  Widget _buildYesNoQuestion(String question, bool value,
      Function(bool?) onChanged, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question,
          style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildToggleButton(
              text: 'Oui',
              isSelected: value,
              onTap: () => onChanged(true),
            ),
            const SizedBox(width: 8),
            _buildToggleButton(
              text: 'Non',
              isSelected: !value,
              onTap: () => onChanged(false),
            ),
          ],
        ),
        if (value)
          Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: TextField(
              controller: controller,
              maxLines: 3,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
              decoration: InputDecoration(
                labelText: 'Précisez',
                labelStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.grey, width: 1.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.grey, width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                      color: Color.fromRGBO(204, 20, 205, 100), width: 2),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildConsumptionQuestion(String question, String? value,
      Function(String?) onChanged, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question,
          style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        _buildDropdownField('', value, _consumptionOptions, onChanged),
        if (value != 'Nulle')
          Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: TextField(
              controller: controller,
              maxLines: 3,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
              decoration: InputDecoration(
                labelText: 'Précisez la substance',
                labelStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.grey, width: 1.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.grey, width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                      color: Color.fromRGBO(204, 20, 205, 100), width: 2),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87),
          ),
          const SizedBox(height: 4),
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 16, color: Colors.black87),
            decoration: InputDecoration(
              labelText: label,
              labelStyle: const TextStyle(color: Colors.grey),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.grey, width: 1.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.grey, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                    color: Color.fromRGBO(204, 20, 205, 100), width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getItemLabel(String key) {
    switch (key) {
      case 'electricity':
        return 'Électricité';
      case 'radio':
        return 'Radio';
      case 'television':
        return 'Télévision';
      case 'refrigerator':
        return 'Réfrigérateur';
      case 'cellPhone':
        return 'Téléphone portable';
      case 'personalComputerOrLaptop':
        return 'Ordinateur personnel ou portable';
      case 'farmAnimals':
        return 'Animaux de ferme';
      case 'agriculturalLand':
        return 'Terre agricole';
      case 'bicycle':
        return 'Bicyclette';
      case 'motorcycleScooter':
        return 'Moto/Scooter';
      case 'carTruck':
        return 'Voiture/Camion';
      default:
        return key;
    }
  }
}
