import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class CustomerDetailsPage extends StatefulWidget {
  final Map<String, dynamic> customer;

  const CustomerDetailsPage({Key? key, required this.customer}) : super(key: key);

  @override
  State<CustomerDetailsPage> createState() => _CustomerDetailsPageState();
}

class _CustomerDetailsPageState extends State<CustomerDetailsPage> {
  late Future<List<Map<String, dynamic>>> _serviceFuture;

  @override
  void initState() {
    super.initState();
    _serviceFuture = fetchCommunicationHistory();
  }

  //get foreign key
  Future<List<Map<String, dynamic>>> fetchCommunicationHistory() async {
    final response = await Supabase.instance.client
        .from('Communication_History')
        .select()
        .eq('CustomerID', widget.customer['ID'])
        .order('Date', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  //auto generate Communication History id
  Future<String> _generateCommunicationID() async {
    final response = await Supabase.instance.client
        .from("Communication_History")
        .select("CHid")
        .order("CHid", ascending: false)
        .limit(1);

    if (response.isEmpty) {
      return "CH101";
    }

    final latestId = response[0]["CHid"] as String;

    final numberPart = int.parse(latestId.substring(2));

    final newId = "CH${numberPart + 1}";

    return newId;
  }

  //save into supabase
  Future<void> addCHintosupabase(String description, DateTime date, String type) async {
    final newID = await _generateCommunicationID();

    await Supabase.instance.client.from('Communication_History').insert({
      'CHid': newID,
      'CustomerID': widget.customer['ID'],
      'Description': description,
      'Type': type,
      'Date': date.toIso8601String(),
    });

    setState(() {
      _serviceFuture = fetchCommunicationHistory();
    });
  }

    void _showAddCHDialog() {
      final TextEditingController descCtrl = TextEditingController();
      String selectedtype = "Phone Call";
      DateTime selectedDate = DateTime.now();

      showDialog(
        context: context,
        builder: (ctx) {
          return StatefulBuilder(
            builder: (ctx, setStateDialog) {
              return AlertDialog(
                title: const Text("Add Communication History"),
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
                    const SizedBox(height: 10,),
                    DropdownButtonFormField<String>(
                      value: selectedtype,
                      decoration: const InputDecoration(labelText: "Type"),
                      items: <String>['Phone Call', 'Gmail', 'SMS', 'Whatsapp']
                          .map((type) => DropdownMenuItem(
                        value: type,
                        child: Text(type),
                      )).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setStateDialog(() {
                            selectedtype = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 10,),
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
                        await addCHintosupabase(descCtrl.text, selectedDate,selectedtype);
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Communication History added successfully!'),
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
    final customer = widget.customer;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Customer Details",
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(
              customer['ImageURL'],
              height: 300,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
            const SizedBox(height: 20),
            Text("Customer ID: ${customer['ID']}"),
            Text("Name: ${customer['Name']}"),
            Text("Address: ${customer['Address']}"),
            Text("Contact Number: ${customer['ContactNo']}"),
            Text("Gmail: ${customer['Gmail']}"),

            const SizedBox(height: 18),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Communication History",
                    style:
                    TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.add_box_outlined, color: Colors.black87,size: 30,),
                  onPressed: _showAddCHDialog,
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
                  return const Text("No Communication History Available.",
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
                    DateTime.parse(history['Date'].toString());
                    final formatted = DateFormat('dd-MM-yyyy').format(date);
                    final type = history['Type']??'';

                    return ListTile(
                      leading: const Icon(Icons.support_agent),
                      title: Text(history['Description']),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Date: $formatted"),
                          Text("Type: $type"),
                        ],
                      )
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

