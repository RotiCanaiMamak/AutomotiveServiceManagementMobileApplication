import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class VehicleDetailsPage extends StatefulWidget {
  final Map<String, dynamic> vehicle;

  const VehicleDetailsPage({Key? key, required this.vehicle}) : super(key: key);

  @override
  State<VehicleDetailsPage> createState() => _VehicleDetailsPageState();
}

class _VehicleDetailsPageState extends State<VehicleDetailsPage> {
  late Future<List<Map<String, dynamic>>> _serviceFuture;

  @override
  void initState() {
    super.initState();
    _serviceFuture = fetchServiceHistory();
  }

  Future<List<Map<String, dynamic>>> fetchServiceHistory() async {
    final response = await Supabase.instance.client
        .from('Service_History')
        .select()
        .eq('VehicleID', widget.vehicle['Plate No'])
        .order('Service Date', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  //auto generate Service id
  Future<String> _generateServiceID() async {
    final response = await Supabase.instance.client
        .from("Service_History")
        .select("ServiceID")
        .order("ServiceID", ascending: false)
        .limit(1);

    if (response.isEmpty) {
      return "S101";
    }

    final latestId = response[0]["ServiceID"] as String;

    final numberPart = int.parse(latestId.substring(1));

    final newId = "S${numberPart + 1}";

    return newId;
  }

  Future<void> addServiceintosupabase(String description, DateTime date) async {
    final newID = await _generateServiceID();

    await Supabase.instance.client.from('Service_History').insert({
      'ServiceID': newID,
      'VehicleID': widget.vehicle['Plate No'],
      'Description': description,
      'Service Date': date.toIso8601String(),
    });

    setState(() {
      _serviceFuture = fetchServiceHistory();
    });
  }

  void _showAddServiceDialog() {
    final TextEditingController descCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setStateDialog) {
            return AlertDialog(
              title: const Text("Add Service"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(DateFormat('dd-MM-yyyy').format(selectedDate)),
                      IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: selectedDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setStateDialog(() {
                              selectedDate = picked;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  TextField(
                    controller: descCtrl,
                    decoration:
                    const InputDecoration(labelText: "Description"),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (descCtrl.text.isNotEmpty) {
                      await addServiceintosupabase(descCtrl.text, selectedDate);
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('Service added successfully!'),
                              duration: Duration(seconds: 2),
                          ),
                      );
                    }
                  },
                  child: const Text("Done"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final vehicle = widget.vehicle;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Vehicle Details",
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
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
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text("Make: ${vehicle['Make']}"),
            Text("Model: ${vehicle['Model']}"),
            Text("Color: ${vehicle['Color']}"),
            Text("Year: ${vehicle['Year']}"),

            const SizedBox(height: 18),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Service History",
                    style:
                    TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.add_box_outlined, color: Colors.black87,size: 30,),
                  onPressed: _showAddServiceDialog,
                ),
              ],
            ),

            FutureBuilder<List<Map<String, dynamic>>>(
              future: _serviceFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Text("Error: ${snapshot.error}");
                }
                final data = snapshot.data ?? [];
                if (data.isEmpty) {
                  return const Text("No service history available.",
                      style:
                      TextStyle(fontSize: 20, fontWeight: FontWeight.w200));
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: data.length,
                  itemBuilder: (context, index) {
                    final history = data[index];
                    final date =
                    DateTime.parse(history['Service Date'].toString());
                    final formatted = DateFormat('dd-MM-yyyy').format(date);

                    return ListTile(
                      leading: const Icon(Icons.build),
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
