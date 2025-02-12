import 'package:flutter/material.dart';
import 'package:ardi/utils/auth.dart'; // Ton service Auth
import 'package:ardi/model/patient.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isSignUp = false;
  bool _isLoading = false;

  /// Connexion avec Google
  Future<void> _handleGoogleSignIn(BuildContext context) async {
    setState(() => _isLoading = true);

    Patient? user = await AuthService().signInWithGoogle();

    setState(() => _isLoading = false);

    if (user != null) {
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Compte introuvable. Veuillez créer un compte.")),
      );
    }
  }

  /// Création de compte avec Google
  Future<void> _handleGoogleSignUp(BuildContext context) async {
    setState(() => _isLoading = true);

    Patient? user = await AuthService().createWithGoogle();

    setState(() => _isLoading = false);

    if (user != null) {
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erreur lors de la création du compte.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isSignUp ? "Créer un compte" : "Connexion"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircleAvatar(
                radius: 50,
                backgroundImage: AssetImage('assets/images/path33.png'),
              ),
              const SizedBox(height: 20),

              Text(
                _isSignUp ? 'Créer un compte' : 'Bienvenue !',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color.fromRGBO(204, 20, 205, 100),
                ),
              ),
              const SizedBox(height: 70),

              if (_isLoading)
                const CircularProgressIndicator()
              else ...[
                // Bouton Connexion avec Google
                if (!_isSignUp)
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
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: Image.asset('assets/images/google.jpg', width: 24, height: 24),
                      label: const Text(
                        "Se connecter avec Google",
                        style: TextStyle(fontSize: 16, color: Colors.black),
                      ),
                    ),
                  ),

                // Bouton Création de compte avec Google
                if (_isSignUp)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _handleGoogleSignUp(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: const BorderSide(color: Colors.grey),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: Image.asset('assets/images/google.jpg', width: 24, height: 24),
                      label: const Text(
                        "Créer avec Google",
                        style: TextStyle(fontSize: 16, color: Colors.black),
                      ),
                    ),
                  ),
              ],

              const SizedBox(height: 20),

              GestureDetector(
                onTap: () {
                  setState(() {
                    _isSignUp = !_isSignUp;
                  });
                },
                child: Text(
                  _isSignUp ? 'Déjà un compte ? Se connecter' : 'Nouveau ? Créer un compte',
                  style: const TextStyle(fontSize: 16, color: Colors.blue),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
