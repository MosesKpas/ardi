import 'package:ardi/screens/admin/admin.dart';
import 'package:ardi/screens/docteurs/docta.dart';
import 'package:ardi/utils/auth.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ardi/screens/accueilscreens/assistance.dart';
import 'package:ardi/screens/accueilscreens/consultation.dart';
import 'package:ardi/screens/accueilscreens/dossier.dart';
import 'package:ardi/screens/accueilscreens/sequencage.dart';
import 'package:ardi/screens/accueilscreens/rdvaccueil.dart';
import 'package:ardi/screens/accueilscreens/formation.dart';
import 'package:ardi/model/patient.dart';

class AccueilPage extends StatefulWidget {
  const AccueilPage({Key? key}) : super(key: key);

  @override
  State<AccueilPage> createState() => _AccueilPageState();
}

class _AccueilPageState extends State<AccueilPage> {
  @override
  void initState(){
    super.initState();
    _checkRoleAndRedirect();
  }
  Future<void> _checkRoleAndRedirect() async {
    String? role = await AuthService().getUserRole();
    if (role == 'admin') {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AdminDashboardPage()));
    } else if (role == 'docta') {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const DoctorDashboardPage()));
    }
  }


  String _salutation() {
    final hour = DateTime.now().hour;
    return hour < 12 ? 'Bonjour' : 'Bonsoir';
  }

  Widget _buildAnimatedText() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade500,
      highlightColor: Colors.grey.shade300,
      child: const Text(
        'Prenez soin de votre santé',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w400,
          color: Colors.black,
        ),
      ),
    );
  }

  void _showServiceModal(BuildContext context, Widget page) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.85,
        child: page,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Section 1: Salutation et message animé
              StreamBuilder<User?>(
                stream: FirebaseAuth.instance.authStateChanges(),
                builder: (context, authSnapshot) {
                  if (authSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  User? user = authSnapshot.data;

                  if (user == null) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircleAvatar(
                          radius: 40,
                          backgroundImage: AssetImage('assets/images/profile.png'),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _salutation(),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Utilisateur',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildAnimatedText(),
                          ],
                        ),
                      ],
                    );
                  }

                  // Charger les données du patient depuis Firestore
                  return StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
                    builder: (context, firestoreSnapshot) {
                      if (firestoreSnapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (!firestoreSnapshot.hasData || !firestoreSnapshot.data!.exists) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CircleAvatar(
                              radius: 40,
                              backgroundImage: AssetImage('assets/images/profile.png'),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _salutation(),
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Utilisateur',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _buildAnimatedText(),
                              ],
                            ),
                          ],
                        );
                      }

                      Patient patient = Patient.fromMap(firestoreSnapshot.data!.data() as Map<String, dynamic>);

                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundImage: patient.photoURL != null
                                ? NetworkImage(patient.photoURL!)
                                : const AssetImage('assets/images/profile.png') as ImageProvider,
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _salutation(),
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${patient.prenom} ${patient.nom}'.trim(),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildAnimatedText(),
                            ],
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 32),

              // Section 2: Services disponibles avec recherche
              TextField(
                decoration: InputDecoration(
                  hintText: 'Rechercher un service',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.pink),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Services disponibles',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Grille des services
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 3 / 2,
                ),
                itemCount: 6,
                itemBuilder: (context, index) {
                  final services = [
                    {'name': 'Consultation', 'icon': Icons.medical_services, 'page': ConsultationPage()},
                    {'name': 'Rendez-vous', 'icon': Icons.calendar_today, 'page': RendezVousPage()},
                    {'name': 'Dossiers médicaux', 'icon': Icons.folder_open, 'page': DossierMedicalPage()},
                    {'name': 'Séquençage', 'icon': Icons.schema, 'page': SequencagePage()},
                    {'name': 'Assistance', 'icon': Icons.headset_mic, 'page': AssistancePage()},
                    {'name': 'Formation', 'icon': Icons.rocket_launch, 'page': FormationPage()},
                  ];
                  return GestureDetector(
                    onTap: () => _showServiceModal(context, services[index]['page'] as Widget),
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 5,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            services[index]['icon'] as IconData,
                            size: 50,
                            color: const Color.fromRGBO(204, 20, 205, 100),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            services[index]['name'] as String,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.purple,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),

              // Section: Qui sommes-nous ?
              const Text(
                'Qui sommes-nous ?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                ),
              ),
              const SizedBox(height: 16),
              const Center(
                child: Image(
                  image: AssetImage('assets/images/fond.jpg'),
                  width: double.infinity,
                  height: 150,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Nous sommes une initiative dédiée à l’amélioration du diagnostic et de la prise en charge des maladies rares en Afrique. En combinant la médecine génomique et les technologies numériques, nous développons un réseau de collaboration multidisciplinaire pour mieux comprendre ces pathologies et faciliter l’accès aux soins pour les patients.",
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.justify,
              ),
              const SizedBox(height: 32),

              // Section: Notre mission
              const Text(
                'Notre mission',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Notre mission est d’accélérer le diagnostic des maladies rares grâce à l’innovation en médecine génomique et à la mise en place de solutions de santé numériques. En renforçant les capacités des professionnels de santé et en développant des outils comme les dossiers électroniques et les applications mobiles, nous visons à connecter les patients aux systèmes de soins de manière plus efficace et inclusive.",
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.justify,
              ),
            ],
          ),
        ),
      ),
    );
  }
}