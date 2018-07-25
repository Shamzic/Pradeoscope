import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

// Classe d'authentification avec compte Google

class FBApi {
  static FirebaseAuth _auth = FirebaseAuth.instance;
  static GoogleSignIn _googleSignIn = GoogleSignIn();

  FirebaseUser firebaseUser;

  FBApi(FirebaseUser user) {
    // constructor
    this.firebaseUser = user;
  }

  static Future<FBApi> signInWithGoogle() async {
    final GoogleSignInAccount googleUser = await _googleSignIn.signIn();
    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

    final FirebaseUser user =
        await _auth.signInWithGoogle(idToken: googleAuth.idToken, accessToken: googleAuth.accessToken);

    // Tests pour vérifier les paramètres de l'utilisateur
    assert(user.email != null);
    assert(user.displayName != null);
    assert(await user.getIdToken() != null);

    final FirebaseUser currentUser = await _auth.currentUser();
    assert(user.uid == currentUser.uid);

    return FBApi(user);
  }

  static void handleSignOut() async {
    _googleSignIn.disconnect();
  }

  static void logout() {
    Firestore.instance.runTransaction((transaction) async {
      FirebaseUser currentUser = await FirebaseAuth.instance.currentUser();
      QuerySnapshot querySnapshot = await Firestore.instance.collection("connected_users")
        .getDocuments();
      var list = querySnapshot.documents;
      list.forEach((doc) {
        if (doc.data['userID'] == currentUser.uid) {
          print('disconnected :::: ');
          print(doc.data['userName']);
          doc.reference.updateData({'connected': false});
          handleSignOut();
          return;
        }
      });
    });
  }
}
