import 'dart:io';
import 'package:ardi/screens/accueil.dart';
import 'package:ardi/screens/admin/admin.dart';
import 'package:ardi/screens/docteurs/docta.dart';
import 'package:ardi/utils/navigation.dart';
import 'package:flutter/material.dart';
import 'package:ardi/utils/auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isSignUp = false;
  bool _isLoading = false;
  bool _obscurePassword = true; // Pour gérer la visibilité du mot de passe

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _prenomController = TextEditingController();
  final _nomController = TextEditingController();

  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _prenomController.dispose();
    _nomController.dispose();
    super.dispose();
  }

  Future<void> _navigateBasedOnRole(BuildContext context) async {
    String? role = await AuthService().getUserRole();
    if (role == 'admin') {
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const AdminDashboardPage()),
          (Route<dynamic> route) => false);
    } else if (role == 'docta') {
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const DoctorDashboardPage()),
          (Route<dynamic> route) => false);
    } else {
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const NavigationPage()),
          (Route<dynamic> route) => false);
    }
  }

  Future<void> _handleGoogleSignIn(BuildContext context) async {
    setState(() => _isLoading = true);
    AuthResult result = await AuthService().signInWithGoogle();
    setState(() => _isLoading = false);

    if (result.patient != null) {
      switch (result.patient!.role) {
        case 'admin':
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const AdminDashboardPage()),
            (Route<dynamic> route) => false,
          );
          break;
        case 'docta':
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
                builder: (context) => const DoctorDashboardPage()),
            (Route<dynamic> route) => false,
          );
          break;
        default:
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const NavigationPage()),
            (Route<dynamic> route) => false,
          );
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

    AuthResult result =
        await AuthService().signInWithEmailAndPassword(email, password);
    setState(() => _isLoading = false);

    if (result.patient != null) {
      switch (result.patient!.role) {
        case 'admin':
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const AdminDashboardPage()),
            (Route<dynamic> route) => false,
          );
          break;
        case 'docta':
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
                builder: (context) => const DoctorDashboardPage()),
            (Route<dynamic> route) => false,
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
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_pics/${DateTime.now().millisecondsSinceEpoch}.jpg');
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

  Widget _buildGoogleButton(
      {required String label, required VoidCallback onPressed}) {
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
        icon: Image.asset('assets/images/google.jpg',
            width: 24, height: 24, semanticLabel: "Logo Google"),
        label: Text(label,
            style: const TextStyle(fontSize: 16, color: Colors.black)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isSignUp ? "Créer un compte" : "Connexion"),
        backgroundColor: const Color.fromRGBO(204, 20, 205, 100),
        foregroundColor: Colors.white,
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
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation(
                        Color.fromRGBO(204, 20, 205, 100)),
                  )
                else ...[
                  if (!_isSignUp) ...[
                    TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: "Email",
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: "Mot de passe",
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: const Color.fromRGBO(204, 20, 205, 100),
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      obscureText: _obscurePassword,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _handleEmailSignIn(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color.fromRGBO(204, 20, 205, 100),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text("Se connecter",
                            style:
                                TextStyle(color: Colors.white, fontSize: 16)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                            child: Divider(
                                color: Colors.grey.shade400, thickness: 1)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            "Ou",
                            style: TextStyle(
                                fontSize: 16, color: Colors.grey.shade600),
                          ),
                        ),
                        Expanded(
                            child: Divider(
                                color: Colors.grey.shade400, thickness: 1)),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                  _buildGoogleButton(
                    label: _isSignUp
                        ? "Créer avec Google"
                        : "Se connecter avec Google",
                    onPressed: () => _isSignUp
                        ? _handleGoogleSignUp(context)
                        : _handleGoogleSignIn(context),
                  ),
                  if (_isSignUp) ...[
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                            child: Divider(
                                color: Colors.grey.shade400, thickness: 1)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            "Ou",
                            style: TextStyle(
                                fontSize: 16, color: Colors.grey.shade600),
                          ),
                        ),
                        Expanded(
                            child: Divider(
                                color: Colors.grey.shade400, thickness: 1)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _prenomController,
                      decoration: InputDecoration(
                        labelText: "Prénom",
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _nomController,
                      decoration: InputDecoration(
                        labelText: "Nom",
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: "Email",
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: "Mot de passe",
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: const Color.fromRGBO(204, 20, 205, 100),
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      obscureText: _obscurePassword,
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
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text("Galerie"),
                        ),
                        ElevatedButton(
                          onPressed: () => _pickImage(ImageSource.camera),
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
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
                          backgroundColor:
                              const Color.fromRGBO(204, 20, 205, 100),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text("Créer le compte",
                            style:
                                TextStyle(color: Colors.white, fontSize: 16)),
                      ),
                    ),
                  ],
                ],
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isSignUp = !_isSignUp;
                    });
                  },
                  child: Text(
                    _isSignUp
                        ? 'Déjà un compte ? Se connecter'
                        : 'Nouveau ? Créer un compte',
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
