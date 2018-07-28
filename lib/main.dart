import 'package:flutter/material.dart';
import 'package:pradeoscope/flux.dart';
import 'package:pradeoscope/login.dart';

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pradeoscope',
      theme: ThemeData(
        primaryColor: Colors.red,
        accentColor: Colors.red,
        
      ),
      routes: {
        "flux-page": (context) => FluxPage(),
        "login-page": (context) => LoginPage(),
      },
      //home: LoginPage(),
      home: LoginPage(),
    );
  }
}
