import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class AddCustomerpage extends StatefulWidget {
  const AddCustomerpage({super.key});

  @override
  State<AddCustomerpage> createState() => _AddCustomerpageState();
}

class _AddCustomerpageState extends State<AddCustomerpage> {
  final _formkey = GlobalKey<FormState>();
  final namectrl = TextEditingController();
  final addressctrl = TextEditingController();
  final contnoctrl = TextEditingController();
  final gmailctrl = TextEditingController();

  File? _customerimage;

  Future<void> _pickImage() async{
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null){
      setState(() {
        _customerimage = File(picked.path);
      });
    }
  }

  //auto generate customer id
  Future<String> _generateCustomerID() async {
    final response = await Supabase.instance.client
        .from("Customer")
        .select("ID")
        .order("ID", ascending: false)
        .limit(1);

    if (response.isEmpty) {
      return "C101";
    }

    final latestId = response[0]["ID"] as String;

    final numberPart = int.parse(latestId.substring(1));

    final newId = "C${numberPart + 1}";

    return newId;
  }

  Future<void> _savetosupabase() async {
    if (!_formkey.currentState!.validate() || _customerimage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please complete the form and upload an image.")),
      );
      return;
    }
    try{
      final newID = await _generateCustomerID();

      final fileName = "${DateTime.now().millisecondsSinceEpoch}_$newID.jpg";
      await Supabase.instance.client.storage.from("Customers").upload(fileName, _customerimage!);
      final imageUrl = Supabase.instance.client.storage.from("Customers").getPublicUrl(fileName);

      await Supabase.instance.client.from("Vehicle").insert({
        "ID": newID,
        "Name": namectrl.text,
        'Address': addressctrl.text,
        'ContactNo': contnoctrl.text,
        'Gmail': gmailctrl.text,
        'ImageURL': imageUrl,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Customer added successfully!")),
      );

      namectrl.clear();
      addressctrl.clear();
      contnoctrl.clear();
      gmailctrl.clear();

      setState(() {
        _customerimage = null;
      });
    }catch(e){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error Add customer: $e")),
      );
      debugPrint("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Add New Customer",
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
                  SizedBox(height: 40),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10.0),
                    child:TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Customer Name',
                      ),
                      controller: namectrl,
                      validator: (value){
                        if(value == null || value.isEmpty){
                          return "Please Enter Customer Name!";
                        }
                        return null;
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10.0),
                    child:TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Address',
                      ),
                      controller: addressctrl,
                      validator: (value){
                        return null;
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10.0),
                    child: TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Contact No',
                      ),
                      controller: contnoctrl,
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
                        labelText: 'Gmail',
                      ),
                      controller: gmailctrl,
                      validator: (value){
                        return null;
                      },
                    ),
                  ),
                  SizedBox(height: 10,),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10.0),
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey, width: 2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: _customerimage == null
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
                          _customerimage!,
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
    namectrl.dispose();
    addressctrl.dispose();
    contnoctrl.dispose();
    gmailctrl.dispose();
  }
}

