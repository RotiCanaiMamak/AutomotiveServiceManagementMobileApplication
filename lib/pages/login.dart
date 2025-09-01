import 'package:assgn1/main.dart';
import 'package:flutter/material.dart';

class Loginpage extends StatelessWidget {
  const Loginpage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home:Scaffold(
        backgroundColor: Colors.white,
          body: Center(
            child:Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                  Align(
                  alignment: Alignment(0, -0.5),
                  child: Text(
                      "GPT Car Workshop"
                          "\nService Hub  ",
                    style:TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w700,
                      ),
                    textAlign: TextAlign.center,
                    ),
                ),
                Padding(padding: EdgeInsets.only(top:30),
                    child:Text(
                      "Login Page",
                    style: TextStyle(
                      fontSize:16,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                ),
                SizedBox(height: 100,),
                Padding(padding: EdgeInsets.all(20),
                child:Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                    children:[
                      Text(
                      "Enter your staff ID and password",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500
                      ),
                    ),
                    SizedBox(height: 10,),
                    TextField(
                      decoration: InputDecoration(
                        labelText: "Staff ID",
                        border: OutlineInputBorder(),
                      ),
                    ),
                      SizedBox(height: 14,),
                    TextField(
                      decoration: InputDecoration(
                        labelText: "Password",
                        border: OutlineInputBorder(),
                      ),
                    ),
                      SizedBox(height: 25,),
                    ElevatedButton(onPressed: () {
                      Navigator.pushReplacement(context,
                      MaterialPageRoute(builder: (context) => const MyHomePage())
                      );
                    },style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      minimumSize: Size(double.infinity, 45)
                    ), child: const Text('Login'))
                    ]
                  ),
                )
              ],
            )
          ),
        ),
      );
  }
}
