import 'package:ardi/screens/admin/admin.dart';
import 'package:ardi/screens/docteurs/docta.dart';
import 'package:ardi/utils/auth.dart';
import 'package:ardi/utils/navigation.dart';
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
import 'package:ardi/screens/login.dart';

class AccueilPage extends StatefulWidget {
  const AccueilPage({Key? key}) : super(key: key);

  @override
  State<AccueilPage> createState() => _AccueilPageState();
}

class _AccueilPageState extends State<AccueilPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _checkRoleAndRedirect();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..forward();
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
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

  Future<void> _signOut() async {
    await AuthService().signOut();
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (context) => const LoginPage()));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _salutation() {
    final hour = DateTime.now().hour;
    return hour < 12 ? 'Bonjour' : 'Bonsoir';
  }

  Widget _buildAnimatedText() {
    return Shimmer.fromColors(
      baseColor: Colors.white,
      highlightColor: Colors.black54,
      period: const Duration(seconds: 2),
      child: const Text(
        'Prenez soin de votre santé',
        style: TextStyle(
            fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, authSnapshot) {
            if (authSnapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox.shrink();
            }
            User? user = authSnapshot.data;
            if (user == null) {
              return const Text('Accueil',
                  style: TextStyle(color: Colors.black));
            }
            return StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .snapshots(),
              builder: (context, firestoreSnapshot) {
                if (!firestoreSnapshot.hasData ||
                    !firestoreSnapshot.data!.exists) {
                  return const Text('Accueil',
                      style: TextStyle(color: Colors.black));
                }
                Patient patient = Patient.fromMap(
                    firestoreSnapshot.data!.data() as Map<String, dynamic>);
                return GestureDetector(
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              const NavigationPage(initialIndex: 4))),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundImage: patient.photoURL != null
                            ? NetworkImage(patient.photoURL!)
                            : const AssetImage('assets/images/profile.png')
                                as ImageProvider,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${patient.prenom} ${patient.nom}',
                        style:
                            const TextStyle(color: Colors.black, fontSize: 18),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color.fromRGBO(204, 20, 205, 0.8),
                        Colors.purpleAccent
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: StreamBuilder<User?>(
                    stream: FirebaseAuth.instance.authStateChanges(),
                    builder: (context, authSnapshot) {
                      if (authSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                            child: CircularProgressIndicator(
                                valueColor:
                                    AlwaysStoppedAnimation(Colors.white)));
                      }
                      User? user = authSnapshot.data;
                      if (user == null) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_salutation()}',
                              style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                            const SizedBox(height: 12),
                            _buildAnimatedText(),
                          ],
                        );
                      }
                      return StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .doc(user.uid)
                            .snapshots(),
                        builder: (context, firestoreSnapshot) {
                          if (!firestoreSnapshot.hasData ||
                              !firestoreSnapshot.data!.exists) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${_salutation()}, Utilisateur',
                                  style: const TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white),
                                ),
                                const SizedBox(height: 12),
                                _buildAnimatedText(),
                              ],
                            );
                          }
                          Patient patient = Patient.fromMap(
                              firestoreSnapshot.data!.data()
                                  as Map<String, dynamic>);
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_salutation()}, ${patient.prenom} ${patient.nom}',
                                style: const TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                              ),
                              const SizedBox(height: 12),
                              _buildAnimatedText(),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1,
                ),
                itemCount: 4,
                itemBuilder: (context, index) {
                  final services = [
                    {
                      'name': 'Rendez-vous',
                      'icon': Icons.calendar_today,
                      'page': const RendezVousPage(),
                      'color': Colors.teal
                    },
                    {
                      'name': 'Dossiers',
                      'icon': Icons.folder_open,
                      'page': DossierMedicalPage(),
                      'color': Colors.blue
                    },
                    {
                      'name': 'Contactez-nous',
                      'icon': Icons.phone,
                      'page': AssistancePage(),
                      'color': Colors.orange
                    },
                    {
                      'name': 'Informations utiles',
                      'icon': Icons.rocket_launch,
                      'page': FormationPage(),
                      'color': Colors.red
                    },
                  ];
                  return GestureDetector(
                    onTap: () => _showServiceModal(
                        context, services[index]['page'] as Widget),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
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
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            services[index]['icon'] as IconData,
                            size: 40,
                            color: services[index]['color'] as Color,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            services[index]['name'] as String,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: services[index]['color'] as Color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Qui sommes-nous ?',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87),
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        'assets/images/fond.jpg',
                        width: double.infinity,
                        height: 120,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Nous sommes une initiative dédiée à l’amélioration du diagnostic et de la prise en charge des maladies rares en Afrique. En combinant la médecine génomique et les technologies numériques, nous développons un réseau de collaboration multidisciplinaire pour mieux comprendre ces pathologies et faciliter l’accès aux soins pour les patients.",
                      style: TextStyle(
                          fontSize: 14, color: Colors.black54, height: 1.5),
                      textAlign: TextAlign.justify,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Notre mission',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.favorite, color: Colors.red, size: 30),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "Accélérer le diagnostic des maladies rares grâce à l’innovation en médecine génomique et aux solutions numériques, tout en renforçant les capacités des professionnels de santé et en connectant les patients aux soins de manière efficace et inclusive.",
                            style: TextStyle(
                                fontSize: 14,
                                color: Colors.black54,
                                height: 1.5),
                            textAlign: TextAlign.justify,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
