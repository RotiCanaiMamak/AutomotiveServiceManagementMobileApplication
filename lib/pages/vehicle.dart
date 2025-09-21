import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'add vehicle.dart';
import 'vehicledetails.dart';

class Vehiclepage extends StatefulWidget {
  const Vehiclepage({super.key});

  @override
  State<Vehiclepage> createState() => _VehiclepageState();
}

class _VehiclepageState extends State<Vehiclepage> {
  final supabase = Supabase.instance.client;
  String searchQuery = "";

  Future<List<Map<String, dynamic>>> fetchVehicle() async{
    final response = await supabase.from('Vehicle').select();
    return response;
  }

  Future<void> deleteVehicle(String vehicleId) async {
    try {
      await Supabase.instance.client
          .from('vehicles')
          .delete()
          .eq('id', vehicleId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Vehicle deleted successfully"),
          backgroundColor: Colors.black,
        ),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Delete failed: $error"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void didchangedependency(){
    super.didChangeDependencies();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Vehicle List",
      style: TextStyle(fontSize: 32,fontWeight: FontWeight.w800),),
          centerTitle:true,),
      body:Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
              padding: EdgeInsets.all(12.0),
            child: Align(
              alignment: Alignment.center,
              child:Text(
                "Serviced Vehicles",
                style: TextStyle(fontSize: 24,fontWeight: FontWeight.w400),),
            ),
          ),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search by Plate No / Make / Model",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value){
                setState(() {
                  searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          const SizedBox(height: 10,),
          Expanded(
              child:FutureBuilder<List<Map<String, dynamic>>>(
                future: fetchVehicle(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final vehicles = snapshot.data!;

                  final filteredVehicles = vehicles.where((vehicle) {
                    final plate = vehicle['Plate No']
                        ?.toString()
                        .toLowerCase() ?? "";
                    final make = vehicle['Make']?.toString().toLowerCase() ??
                        "";
                    final model = vehicle['Model']?.toString().toLowerCase() ??
                        "";
                    return plate.contains(searchQuery) ||
                        make.contains(searchQuery) ||
                        model.contains(searchQuery);
                  }).toList();

                  if(filteredVehicles.isEmpty){
                    return const Center(
                      child: Text(
                        "No Vehicles found",
                        style: TextStyle(fontSize: 20,fontWeight: FontWeight.w300),
                      ),
                    );
                  }

                  return ListView.builder(
                      itemCount: filteredVehicles.length,
                      itemBuilder: (context, index) {
                        final vehicle = filteredVehicles[index];
                        final imageURL = vehicle['ImageURL'];
                        return InkWell(
                          onDoubleTap: (){
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:(context)=>
                                    VehicleDetailsPage(vehicle:vehicle),
                              )
                            );
                          },
                          child: Card(
                            margin: const EdgeInsets.all(10),
                            child: Padding(
                                padding: const EdgeInsets.all(10),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                        width: 200,
                                        height: 160,
                                        child: Image.network(
                                          imageURL,
                                          fit: BoxFit.cover,)),
                                    const SizedBox(width: 10,),
                                    Expanded(child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text("${vehicle['Plate No']}",
                                              style: const TextStyle(
                                                fontSize: 23,
                                                fontWeight: FontWeight.bold,
                                              ),),
                                            IconButton(
                                                icon: const Icon(Icons.delete),
                                              onPressed:(){
                                                  showDialog(context: context,
                                                      builder:(context) => AlertDialog(
                                                        title: const Text("Delete Vehicle"),
                                                        content: Text("Are you sure you want to delete ${vehicle['Plate No']}?"),
                                                        actions: [
                                                          TextButton(onPressed: () => Navigator.pop(context),
                                                              child: const Text("Cancel")),
                                                          TextButton(onPressed: () async{
                                                            Navigator.pop(context);

                                                            await deleteVehicle(vehicle['Plate No']);

                                                            setState(() {});
                                                          }, child: const Text(
                                                            "Delete",style: TextStyle(color: Colors.red),
                                                          ))
                                                        ],
                                                      ));
                                              },)
                                          ],
                                        ),
                                        Text("Make: ${vehicle['Make']} "),
                                        Text("Model: ${vehicle['Model']} "),
                                        Text("Color: ${vehicle['Color']} "),
                                        Text("Year: ${vehicle['Year']} ",),
                                      ],
                                    )
                                    )
                                  ],
                                )
                            ),
                          ),
                        );
                      });
                })
            )
          ],
        ),
      floatingActionButton: FloatingActionButton(
          onPressed: (){
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context)=> const AddVehiclepage(),),
            );
          },
          backgroundColor: const Color(0xB6D1FFFF),
          child: const Icon(Icons.add, size:32, color: Colors.black),
        ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      );
  }
}
