import 'package:ardi/model/patient.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Connexion avec Google
  Future<Patient?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await _auth.signInWithCredential(credential);
      User? user = userCredential.user;

      if (user != null) {
        // Vérifier si l'utilisateur existe dans Firestore
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          return Patient.fromMap(userDoc.data() as Map<String, dynamic>);
        } else {
          print("Compte inexistant. Demande de création requise.");
          return null;
        }
      }
      return null;
    } catch (e) {
      print("Erreur de connexion Google : $e");
      return null;
    }
  }
//creer un compte avec google
  Future<Patient?> createWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

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
          // Création du profil utilisateur
          await _firestore.collection('users').doc(user.uid).set({
            'uid': user.uid,
            'prenom': user.displayName?.split(' ').first ?? '',
            'nom': user.displayName?.split(' ').last ?? '',
            'email': user.email,
            'photoURL': user.photoURL,
            'dateCreation': FieldValue.serverTimestamp(),
          });
        }

        return Patient.fromMap((await _firestore.collection('users').doc(user.uid).get()).data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print("Erreur lors de la création du compte Google : $e");
      return null;
    }
  }

  // Connexion avec email et mot de passe
  Future<Patient?> signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = userCredential.user;

      if (user != null) {
        // Récupérer les données de l'utilisateur depuis Firestore
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();

        // Créer et retourner l'objet Patient
        return Patient.fromMap(userDoc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print("Erreur de connexion avec email et mot de passe : $e");
      return null;
    }
  }

  // Déconnexion
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}

