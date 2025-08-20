import 'package:flutter/material.dart';

class Loginpage extends StatelessWidget {
  const Loginpage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home:Scaffold(
        backgroundColor: Colors.white,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "GPT",
                style:TextStyle(
                  fontSize: 72,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  ),
                textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
      )
    );
  }
}
