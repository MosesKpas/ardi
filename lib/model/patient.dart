class Patient {
  final String uid;
  final String prenom;
  final String nom;
  final String email;
  final String? photoURL;

  Patient({
    required this.uid,
    required this.prenom,
    required this.nom,
    required this.email,
    this.photoURL,
  });

  // Convertir un objet Patient en un map pour stocker dans Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'firstName': prenom,
      'lastName': nom,
      'email': email,
      'photoURL': photoURL,
    };
  }

  // Convertir un map Firestore en un objet Patient
  factory Patient.fromMap(Map<String, dynamic> map) {
    return Patient(
      uid: map['uid'],
      prenom: map['prenom'],
      nom: map['nom'],
      email: map['email'],
      photoURL: map['photoURL'],
    );
  }
}
