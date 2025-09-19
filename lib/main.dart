import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'pages/home.dart';
import 'pages/vehicle.dart';
import 'pages/workscheduler.dart';
import 'pages/customer.dart';
import 'pages/inventory.dart';
import 'pages/invoice.dart';
import 'pages/login.dart';

const String databaseurl = "https://etwmuxytsycqvvvcfsak.supabase.co";
const String databasekey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImV0d211eHl0c3ljcXZ2dmNmc2FrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTgxMDUyODIsImV4cCI6MjA3MzY4MTI4Mn0.MBoKYIYCGEAyupokCgwAlgLFAD9O0M0_alxuAtvwr6k";

class Staff{
  final String id;
  final String pwd;
  Staff({required this.id, required this.pwd});

  factory Staff.fromJson(Map<String,dynamic>json){
    return Staff(
        id: json['StaffID'].toString(), pwd: json['Password'] as String);
  }
}

Future<void>main()async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: databaseurl, anonKey: databasekey);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget{
  const MyApp({super.key});

  @override
  Widget build(BuildContext context){
    return MaterialApp(
      title: 'GPT app',
      home: LoginPage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _currentpage = 0;

  final List<Widget> _pages = const [
    Homepage(),
    Vehiclepage(),
    Workschedulerpage(),
    Customerpage(),
    Inventorypage(),
    Invoicepage(),
  ];

  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      home: Scaffold(
      body: _pages[_currentpage],
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.black,
          currentIndex: _currentpage,
          onTap: (i) => setState(() => _currentpage = i),
          items: const[
            BottomNavigationBarItem(icon: Icon(Icons.home),label:"Home"),
            BottomNavigationBarItem(icon: Icon(Icons.directions_car),label:"Vehicles"),
            BottomNavigationBarItem(icon: Icon(Icons.work),label:"Jobs"),
            BottomNavigationBarItem(icon: Icon(Icons.person),label:"Customer"),
            BottomNavigationBarItem(icon: Icon(Icons.inventory),label:"Inventory"),
            BottomNavigationBarItem(icon: Icon(Icons.receipt),label:"Invoices")
          ]
      ),
    ),
    );
  }
}
