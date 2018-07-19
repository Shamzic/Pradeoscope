import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:pradeoscope/api.dart';

class LoginPage extends StatelessWidget {
  Future<bool> _loginUser() async {
    final api = await FBApi.signInWithGoogle();
    if (api != null) {
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
