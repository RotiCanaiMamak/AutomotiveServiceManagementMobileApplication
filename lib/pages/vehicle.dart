import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'add vehicle.dart';

/*class Vehiclepage2 extends StatelessWidget {
  const Vehiclepage2({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Vehicle List"),

      ),
      body: ElevatedButton(onPressed: (){
        Navigator .push(
      context,MaterialPageRoute(builder: (context) => AddVehiclepage())
        );
      }, child: const Text("Add")),
    );
  }
}*/

class Vehiclepage extends StatefulWidget {
  const Vehiclepage({super.key});

  @override
  State<Vehiclepage> createState() => _VehiclepageState();
}

class _VehiclepageState extends State<Vehiclepage> {
  final supabase = Supabase.instance.client;
  
  Future<List<Map<String, dynamic>>> fetchVehicle() async{
    final response = await supabase.from('Vehicle').select();
    return response as List<Map<String, dynamic>>;
  }

  String getImageURL(String path){
    return supabase.storage.from('Vehicles').getPublicUrl(path);
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Vehicle List"),),
      body: FutureBuilder<List<Map<String, dynamic>>>(
          future: fetchVehicle(),
          builder: (context, snapshot){
            if (!snapshot.hasData){
              return const Center(child: CircularProgressIndicator());
            }
            final vehicles = snapshot.data!;
            return ListView.builder(
                itemCount: vehicles.length,
                itemBuilder: (context, index){
                  final vehicle = vehicles[index];
                  final imageURL = vehicle['ImageURL'];
                  return Card(
                    margin: const EdgeInsets.all(10),
                    child: ListTile(
                      leading: SizedBox(
                        width: 160,
                        height: 160,
                        child: Image.network(
                          imageURL,
                          fit: BoxFit.cover,)
                      ),
                      title: Text("${vehicle['Plate No']}"),
                      subtitle: Text(
                          "Make: ${vehicle['Make']} \n"
                          "Model: ${vehicle['Model']} \n"
                          "Color: ${vehicle['Color']} \n"
                          "Year: ${vehicle['Year']} \n",
                      ),
                    )
                  );
                });
          })
    );
  }
}
