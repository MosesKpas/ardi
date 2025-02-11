import 'package:ardi/model/patient.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ardi/utils/auth.dart'; // Ton service Auth

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();
  bool _isSignUp = false;
  bool _isLoading = false;  // Indicateur de chargement

  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
  }

  Future<void> _handleGoogleSignIn(BuildContext context) async {
    setState(() {
      _isLoading = true;  // Démarrer le loader
    });

    Patient? user = await AuthService().signInWithGoogle();
    setState(() {
      _isLoading = false;  // Arrêter le loader
    });

    if (user != null) {
      print("Connexion réussie : ${user.prenom}");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Bienvenue, ${user.prenom}!")),
      );
      // Retourner à la page précédente après une connexion réussie
      Navigator.pop(context);
    } else {
      print("Connexion annulée");
    }
  }

  Future<void> _handleEmailSignIn(BuildContext context) async {
    setState(() {
      _isLoading = true;  // Démarrer le loader
    });

    try {
      Patient? patient = await AuthService().signInWithEmailAndPassword(
        _emailController.text,
        _passwordController.text,
      );
      setState(() {
        _isLoading = false;  // Arrêter le loader
      });

      if (patient != null) {
        print("Connexion réussie : ${patient.prenom} ${patient.nom}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Bienvenue, ${patient.prenom}!")),
        );
        // Retourner à la page précédente après une connexion réussie
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;  // Arrêter le loader en cas d'erreur
      });
      print("Erreur de connexion : $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Échec de la connexion")),
      );
    }
  }

  Future<void> _handleCreateAccount(BuildContext context) async {
    setState(() {
      _isLoading = true;  // Démarrer le loader
    });

    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      setState(() {
        _isLoading = false;  // Arrêter le loader
      });

      User? user = userCredential.user;
      if (user != null) {
        print("Compte créé avec succès : ${user.displayName}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Compte créé, bienvenue ${user.displayName}!")),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;  // Arrêter le loader en cas d'erreur
      });
      print("Erreur lors de la création du compte : $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Échec de la création du compte")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Connexion / Création compte"),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const CircleAvatar(
                radius: 50,
                backgroundImage: AssetImage('assets/images/fond.jpg'),
              ),
              const SizedBox(height: 16),
              Text(
                _isSignUp ? 'Créer un compte' : 'Bienvenue !',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color.fromRGBO(204, 20, 205, 100),
                ),
              ),
              const SizedBox(height: 32),

              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: const Icon(Icons.email, color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Mot de passe',
                  prefixIcon: const Icon(Icons.lock, color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Afficher un loader pendant que l'on attend la connexion
              if (_isLoading)
                const CircularProgressIndicator(),

              // Sinon afficher le bouton pour se connecter ou créer un compte
              if (!_isLoading)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_isSignUp) {
                        _handleCreateAccount(context);
                      } else {
                        _handleEmailSignIn(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromRGBO(204, 20, 205, 100),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      _isSignUp ? 'Créer un compte' : 'Se connecter',
                      style: const TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _handleGoogleSignIn(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: const BorderSide(color: Colors.grey),
                    ),
                  ),
                  icon: Image.asset(
                    'assets/images/google.jpg',
                    width: 20,
                    height: 20,
                  ),
                  label: Text(
                    _isSignUp ? 'Créer avec Google' : 'Se connecter avec Google',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              GestureDetector(
                onTap: () {
                  setState(() {
                    _isSignUp = !_isSignUp;
                  });
                },
                child: Text(
                  _isSignUp ? 'Déjà un compte ? Se connecter' : 'Nouveau ? Créer un compte',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.blue,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

