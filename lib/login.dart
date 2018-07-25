import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pradeoscope/api.dart';

class LoginPage extends StatelessWidget {
  Future<bool> _loginUser() async {
    final api = await FBApi.signInWithGoogle();
    if (api != null) {
      Firestore.instance.runTransaction((transaction) async {
        FirebaseUser currentUser = await FirebaseAuth.instance.currentUser();
        CollectionReference reference = Firestore.instance.collection('connected_users');
        QuerySnapshot querySnapshot = await Firestore.instance.collection("connected_users")
          .getDocuments();
        var list = querySnapshot.documents;
        var alreadyREgistered = false;
        list.forEach((doc) {
          if (doc.data['userID'] == currentUser.uid) {
            doc.reference.updateData({'connected': true});
            alreadyREgistered = true;
          }
        });
        if (!alreadyREgistered) {
          await reference.add({
            "userID": currentUser.uid,
            "userName": currentUser.displayName,
            "connected": true,
            "photoURL": currentUser.photoUrl,
          });
        }
      });
      return true;
    } else {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Sign In'),
      ),
      body: Center(
        child: Stack(
          children: <Widget>[
            Center(
              child: ConstrainedBox(
                constraints: BoxConstraints.expand(
                  width: 250.0,
                  height: 250.0,
                ),
                child: Container(
                  color: Colors.red,
                ),
              ),
            ),
            Center(
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: 4.0,
                  sigmaY: 4.0,
                ),
                child: Container(
                  width: 250.0,
                  height: 250.0,
                  color: Colors.red.withOpacity(0.1),
                  padding: EdgeInsets.only(top: 15.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: <Widget>[
                      Text(
                        "Login to Pradeoscope!",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22.0,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      FlatButton(
                        color: Colors.black54,
                        onPressed: () async {
                          bool b = await _loginUser();

                          b
                              ? Navigator.of(context).pushNamed('flux-page')
                              : Scaffold.of(context).showSnackBar(
                                    SnackBar(content: Text("Wrong email !")),
                                  );
                        },
                        textColor: Colors.white.withOpacity(0.9),
                        child: Text('Sign in'),
                      ),
                      FlatButton(
                        color: Colors.black54,
                        onPressed: () async {
                          FBApi.logout();
                        },
                        textColor: Colors.white.withOpacity(0.9),
                        child: Text('Disconnect'),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
