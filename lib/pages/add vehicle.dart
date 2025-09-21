import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddVehiclepage extends StatefulWidget {
  const AddVehiclepage({super.key});

  @override
  State<AddVehiclepage> createState() => _AddVehiclepageState();
}

class _AddVehiclepageState extends State<AddVehiclepage> {
  final _formkey = GlobalKey<FormState>();
  final platenoctrl = TextEditingController();
  final makectrl = TextEditingController();
  final modelctrl = TextEditingController();
  final colorctrl = TextEditingController();
  final yearctrl = TextEditingController();

  File? _vehicleimage;
  String? _selectedCustomerId;
  List<Map<String, dynamic>> _customers = [];

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    final response = await Supabase.instance.client
        .from('Customer')
        .select('ID, Name')
        .order('Name');
    setState(() {
      _customers = List<Map<String, dynamic>>.from(response);
    });
  }

  Future<void> _pickImage() async{
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null){
      setState(() {
        _vehicleimage = File(picked.path);
      });
    }
  }

  Future<void> _savetosupabase() async {
    if (!_formkey.currentState!.validate() || _vehicleimage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please complete the form and upload an image.")),
      );
      return;
    }
    try{
      final fileName = "${DateTime.now().millisecondsSinceEpoch}_${platenoctrl.text}.jpg";
      await Supabase.instance.client.storage.from("Vehicles").upload(fileName, _vehicleimage!);
      final imageUrl = Supabase.instance.client.storage.from("Vehicles").getPublicUrl(fileName);

      await Supabase.instance.client.from("Vehicle").insert({
        "Plate No": platenoctrl.text,
        'Make': makectrl.text,
        'Model': modelctrl.text,
        'Color': colorctrl.text,
        'Year': int.parse(yearctrl.text),
        'ImageURL': imageUrl,
        'customerID':_selectedCustomerId,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vehicle added successfully!")),
      );

      platenoctrl.clear();
      makectrl.clear();
      modelctrl.clear();
      colorctrl.clear();
      yearctrl.clear();

      setState(() {
        _vehicleimage = null;
        _selectedCustomerId = null;
      });
    }catch(e){
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error Add vehicle: $e")),
      );
      debugPrint("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Add New Vehicle",
        style: TextStyle(fontSize: 30,fontWeight: FontWeight.w600)),
        centerTitle:true,
      ),
      body: Form(
        key: _formkey,
        child: SingleChildScrollView(
          child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24,vertical: 16),
          child:Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 38),
              Padding(padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: DropdownButtonFormField<String>(
                    value: _selectedCustomerId,
                    decoration: const InputDecoration(labelText: "Vehicle Owner"),
                    items: _customers
                    .map((c) => DropdownMenuItem(
                        value: c['ID'] as String,
                        child: Text(c['Name']))).toList(),
                    onChanged: (value)=> setState(() {
                        _selectedCustomerId = value;
                      }),
                    validator: (value) =>
                      value == null ? "Please choose a customer" : null,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child:TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Plate Number',
                  ),
                controller: platenoctrl,
                validator: (value){
                  if(value == null || value.isEmpty){
                    return "Please Enter Plate Number!";
                  }
                  return null;
                },
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              child:TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Make',
                ),
                controller: makectrl,
                validator: (value){
                  if(value == null || value.isEmpty){
                    return "Please Enter Make of Vehicle!";
                  }
                  return null;
                },
              ),
            ), Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Model',
                ),
                controller: modelctrl,
                validator: (value){
                  return null;
                },
                ),
              ),
            Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child:
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Color',
                ),
                controller: colorctrl,
                validator: (value){
                  return null;
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              child:
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Year(s)',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                controller: yearctrl,
                validator: (value){
                  return null;
                },
              ),
            ),
            Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey, width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _vehicleimage == null
                    ? const Center(
                  child: Text(
                    "No Image Selected",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                )
                    : ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    _vehicleimage!,
                    width: 150,
                    height: 150,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
              ElevatedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.upload),
                label: const Text("Upload Image"),
              ),
              SizedBox(height: 20),
              ElevatedButton(onPressed : (){
                if(_formkey.currentState!.validate()){
                  _savetosupabase();
                }
              }, child: const Text("Add"))
              ],
            ),
          )
        ),
      ),
    );
  }
  @override
  void dispose(){
    super.dispose();
    platenoctrl.dispose();
    makectrl.dispose();
    modelctrl.dispose();
    colorctrl.dispose();
    yearctrl.dispose();
  }
}

