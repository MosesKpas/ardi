import 'package:ardi/model/patient.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Classe pour gérer les résultats d'authentification
class AuthResult {
  final Patient? patient;
  final String? error;
  AuthResult({this.patient, this.error});
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  //Methode pour obtenir le role de l'utilisateur connecte
  Future<String?> getUserRole() async{
    User? user = _auth.currentUser;
    if(user == null) return null;

    DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();
    if(doc.exists){
      return (doc.data() as Map<String, dynamic>)['role']as String?;
    }
    return null;
  }

  // Connexion avec Google
  Future<AuthResult> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return AuthResult(error: "Connexion annulée");

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await _auth.signInWithCredential(credential);
      User? user = userCredential.user;

      if (user != null) {
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          return AuthResult(patient: Patient.fromMap(userDoc.data() as Map<String, dynamic>));
        } else {
          return AuthResult(error: "Compte inexistant. Veuillez créer un compte.");
        }
      }
      return AuthResult(error: "Utilisateur non trouvé");
    } catch (e) {
      return AuthResult(error: "Erreur de connexion Google : $e");
    }
  }

  /// Création de compte avec Google
  Future<AuthResult> createWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return AuthResult(error: "Création annulée");

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await _auth.signInWithCredential(credential);
      User? user = userCredential.user;

      if (user != null) {
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
        if (!userDoc.exists) {
          List<String> nameParts = (user.displayName ?? "").split(' ');
          String prenom = nameParts.isNotEmpty ? nameParts.first : "";
          String nom = nameParts.length > 1 ? nameParts.last : "";

          Map<String, dynamic> userData = {
            'uid': user.uid,
            'prenom': prenom,
            'nom': nom,
            'email': user.email,
            'photoURL': user.photoURL,
            'role':'patient',
            'dateCreation': FieldValue.serverTimestamp(),
          };
          await _firestore.collection('users').doc(user.uid).set(userData);
          return AuthResult(patient: Patient.fromMap(userData));
        }
        return AuthResult(patient: Patient.fromMap(userDoc.data() as Map<String, dynamic>));
      }
      return AuthResult(error: "Utilisateur non trouvé");
    } catch (e) {
      return AuthResult(error: "Erreur lors de la création du compte Google : $e");
    }
  }

  /// Connexion avec email et mot de passe
  Future<AuthResult> signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = userCredential.user;

      if (user != null) {
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          return AuthResult(patient: Patient.fromMap(userDoc.data() as Map<String, dynamic>));
        } else {
          return AuthResult(error: "Compte inexistant. Veuillez créer un compte.");
        }
      }
      return AuthResult(error: "Utilisateur non trouvé");
    } catch (e) {
      return AuthResult(error: "Erreur de connexion : $e");
    }
  }

  /// Création de compte avec email et mot de passe
  Future<AuthResult> createWithEmailAndPassword({
    required String email,
    required String password,
    required String prenom,
    required String nom,
    String? photoURL,
  }) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = userCredential.user;

      if (user != null) {
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
        if (!userDoc.exists) {
          Map<String, dynamic> userData = {
            'uid': user.uid,
            'prenom': prenom,
            'nom': nom,
            'email': email,
            'photoURL': photoURL,
            'role':'patient',
            'dateCreation': FieldValue.serverTimestamp(),
          };
          await _firestore.collection('users').doc(user.uid).set(userData);
          return AuthResult(patient: Patient.fromMap(userData));
        }
        return AuthResult(patient: Patient.fromMap(userDoc.data() as Map<String, dynamic>));
      }
      return AuthResult(error: "Utilisateur non créé");
    } catch (e) {
      return AuthResult(error: "Erreur lors de la création du compte : $e");
    }
  }

  /// Déconnexion
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}