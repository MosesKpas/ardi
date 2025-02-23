import 'dart:io';
import 'package:ardi/screens/accueil.dart';
import 'package:ardi/screens/admin/admin.dart';
import 'package:ardi/screens/docteurs/docta.dart';
import 'package:flutter/material.dart';
import 'package:ardi/utils/auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  bool _isSignUp = false;
  bool _isLoading = false;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _prenomController = TextEditingController();
  final _nomController = TextEditingController();

  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _prenomController.dispose();
    _nomController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _navigateBasedOnRole(BuildContext context) async{
    String? role = await AuthService().getUserRole();
    if(role=='admin'){
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context)=>const AdminDashboardPage()),(Route<dynamic> route)=>false);
    }else if(role =='docta'){
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context)=>const DoctorDashboardPage()),(Route<dynamic> route)=>false);
    }else{
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context)=> AccueilPage()),(Route<dynamic> route)=>false);
    }
  }

  Future<void> _handleGoogleSignIn(BuildContext context) async {
    setState(() => _isLoading = true);
    AuthResult result = await AuthService().signInWithGoogle();
    setState(() => _isLoading = false);

    if (result.patient != null) {
      // Vérification du rôle
      switch (result.patient!.role) {
        case 'admin':
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const AdminDashboardPage()),(Route<dynamic> route)=>false
          );
          break;
        case 'docta':
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const DoctorDashboardPage()),(Route<dynamic> route)=>false
          );
          break;
        default:
          Navigator.pop(context);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error ?? "Erreur inconnue")),
      );
    }
  }

  Future<void> _handleGoogleSignUp(BuildContext context) async {
    setState(() => _isLoading = true);
    AuthResult result = await AuthService().createWithGoogle();
    setState(() => _isLoading = false);

    if (result.patient != null) {
      await _navigateBasedOnRole(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error ?? "Erreur inconnue")),
      );
    }
  }

  Future<void> _handleEmailSignIn(BuildContext context) async {
    setState(() => _isLoading = true);

    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    AuthResult result = await AuthService().signInWithEmailAndPassword(email, password);
    setState(() => _isLoading = false);

    if (result.patient != null) {
      // Vérification du rôle
      switch (result.patient!.role) {
        case 'admin':
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const AdminDashboardPage()),(Route<dynamic> route)=>false
          );
          break;
        case 'docta':
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const DoctorDashboardPage()),(Route<dynamic> route)=>false
          );
          break;
        default:
          Navigator.pop(context);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error ?? "Erreur inconnue")),
      );
    }
  }

  Future<void> _handleEmailSignUp(BuildContext context) async {
    setState(() => _isLoading = true);

    String? photoURL;
    if (_selectedImage != null) {
      final storageRef = FirebaseStorage.instance.ref().child('profile_pics/${DateTime.now().millisecondsSinceEpoch}.jpg');
      await storageRef.putFile(_selectedImage!);
      photoURL = await storageRef.getDownloadURL();
    }

    AuthResult result = await AuthService().createWithEmailAndPassword(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      prenom: _prenomController.text.trim(),
      nom: _nomController.text.trim(),
      photoURL: photoURL,
    );
    setState(() => _isLoading = false);

    if (result.patient != null) {
     await _navigateBasedOnRole(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error ?? "Erreur inconnue")),
      );
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Widget _buildGoogleButton({required String label, required VoidCallback onPressed}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: Colors.grey),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        icon: Image.asset('assets/images/google.jpg', width: 24, height: 24, semanticLabel: "Logo Google"),
        label: Text(label, style: const TextStyle(fontSize: 16, color: Colors.black)),
      ),
    );
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
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
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
                const SizedBox(height: 40),

                if (_isLoading)
                  const CircularProgressIndicator()
                else ...[
                  if (!_isSignUp) ...[
                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: "Email",
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      decoration: const InputDecoration(
                        labelText: "Mot de passe",
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _handleEmailSignIn(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromRGBO(204, 20, 205, 100),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text("Se connecter", style: TextStyle(color: Colors.white)),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  _buildGoogleButton(
                    label: _isSignUp ? "Créer avec Google" : "Se connecter avec Google",
                    onPressed: () => _isSignUp ? _handleGoogleSignUp(context) : _handleGoogleSignIn(context),
                  ),

                  if (_isSignUp) ...[
                    const SizedBox(height: 20),
                    FadeTransition(
                      opacity: _animation,
                      child: Column(
                        children: [
                          TextField(
                            controller: _prenomController,
                            decoration: const InputDecoration(
                              labelText: "Prénom",
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _nomController,
                            decoration: const InputDecoration(
                              labelText: "Nom",
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _emailController,
                            decoration: const InputDecoration(
                              labelText: "Email",
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _passwordController,
                            decoration: const InputDecoration(
                              labelText: "Mot de passe",
                              border: OutlineInputBorder(),
                            ),
                            obscureText: true,
                          ),
                          const SizedBox(height: 16),
                          if (_selectedImage != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: Image.file(_selectedImage!, height: 100),
                            ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton(
                                onPressed: () => _pickImage(ImageSource.gallery),
                                child: const Text("Galerie"),
                              ),
                              ElevatedButton(
                                onPressed: () => _pickImage(ImageSource.camera),
                                child: const Text("Caméra"),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => _handleEmailSignUp(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color.fromRGBO(204, 20, 205, 100),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: const Text("Créer le compte", style: TextStyle(color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],

                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isSignUp = !_isSignUp;
                      if (_isSignUp) {
                        _animationController.forward();
                      } else {
                        _animationController.reverse();
                      }
                    });
                  },
                  child: Text(
                    _isSignUp ? 'Déjà un compte ? Se connecter' : 'Nouveau ? Créer un compte',
                    style: const TextStyle(fontSize: 16, color: Colors.blue),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}