import 'package:flutter/material.dart';
import 'pages/home.dart';
import 'pages/vehicle.dart';
import 'pages/workscheduler.dart';
import 'pages/customer.dart';
import 'pages/inventory.dart';
import 'pages/invoice.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyApp> {
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
