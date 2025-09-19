import 'package:assgn1/main.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final supabase = Supabase.instance.client;

  final _idctrl = TextEditingController();
  final _pwdctrl = TextEditingController();

  Future<void> _loginvalidation(String id,String pwd) async{
    try{
      final response = await supabase.from('Staff')
          .select()
          .eq('StaffID', id).eq('Password', pwd)
          .maybeSingle();

      if(response == null){
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Invalid ID or Password!"))
        );
        _idctrl.clear();
        _pwdctrl.clear();
      }
      else{
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Login Successfully!")),
        );
        Navigator.pushReplacement(context,
            MaterialPageRoute(
                builder: (context) => const MyHomePage())
        );
      }
    }catch(e){
      ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error:$e"))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Align(
                  alignment: Alignment(0, -0.5),
                  child: Text(
                    "GPT Car Workshop"
                        "\nService Hub  ",
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Padding(padding: EdgeInsets.only(top: 30),
                    child: Text(
                      "Login Page",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    )
                ),
                SizedBox(height: 100,),
                Padding(padding: EdgeInsets.all(20),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Enter your staff ID and password",
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500
                          ),
                        ),
                        SizedBox(height: 10,),
                        TextField(
                          controller: _idctrl,
                          decoration: InputDecoration(
                            labelText: "Staff ID",
                            border: OutlineInputBorder(),
                          ),
                        ),
                        SizedBox(height: 14,),
                        TextField(
                          controller: _pwdctrl,
                          decoration: InputDecoration(
                            labelText: "Password",
                            border: OutlineInputBorder(),
                          ),
                        ),
                        SizedBox(height: 25,),
                        ElevatedButton(onPressed: () {
                          _loginvalidation(
                              _idctrl.text.trim(),
                              _pwdctrl.text.trim());
                        }, style: ElevatedButton.styleFrom(
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

