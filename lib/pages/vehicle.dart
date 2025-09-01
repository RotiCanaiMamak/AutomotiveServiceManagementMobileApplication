import 'package:flutter/material.dart';
import 'add vehicle.dart';

class Vehiclepage extends StatelessWidget {
  const Vehiclepage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Vehicle Page"),
        backgroundColor: Colors.grey,
      ),
      body: ElevatedButton(onPressed: (){
        Navigator .push(
      context,MaterialPageRoute(builder: (context) => AddVehiclepage())
        );
      }, child: const Text("Add")),
    );
  }
}
