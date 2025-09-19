import 'package:flutter/material.dart';
import 'pages/home.dart';
import 'pages/vehicle.dart';
import 'pages/workscheduler.dart';
import 'pages/customer.dart';
import 'pages/inventory.dart';
import 'pages/invoice.dart';
import 'pages/login.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget{
  const MyApp({super.key});

  @override
  Widget build(BuildContext context){
    return MaterialApp(
      title: 'GPT app',
      home: Loginpage(),
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
    WorkSchedulerPage(),
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
