import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class VehicleDetailsPage extends StatelessWidget {
  final Map<String, dynamic> vehicle;

  const VehicleDetailsPage({Key? key, required this.vehicle}) : super(key: key);

  Future<List<Map<String, dynamic>>> fetchServiceHistory() async {
    final response = await Supabase.instance.client
        .from('Service_History')
        .select()
        .eq('VehicleID', vehicle['Plate No'])
        .order('Service Date', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Vehicle Details",
          style: TextStyle(fontSize: 30,fontWeight: FontWeight.w600)),
      centerTitle:true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(
              vehicle['ImageURL'],
              height: 300,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
            const SizedBox(height: 20),
            Text("Plate No: ${vehicle['Plate No']}",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text("Make: ${vehicle['Make']}"),
            Text("Model: ${vehicle['Model']}"),
            Text("Color: ${vehicle['Color']}"),
            Text("Year: ${vehicle['Year']}"),

            const SizedBox(height: 30),
            Text("Service History",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),

            FutureBuilder<List<Map<String, dynamic>>>(
              future: fetchServiceHistory(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Text("Error: ${snapshot.error}");
                }
                final data = snapshot.data ?? [];
                if (data.isEmpty) {
                  return Text("No service history available.",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w200));
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: data.length,
                  itemBuilder: (context, index) {
                    final history = data[index];
                    final date = DateTime.parse(history['Service Date'].toString());
                    final formatted = DateFormat('dd-MM-yyyy').format(date);

                    return ListTile(
                      leading: Icon(Icons.build),
                      title: Text(history['Description']),
                      subtitle: Text("Date: $formatted"),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}