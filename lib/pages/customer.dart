import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'addCustomer.dart';
import 'customerdetails.dart';

class Customerpage extends StatefulWidget {
  const Customerpage({super.key});

  @override
  State<Customerpage> createState() => CustomerpageState();
}

class CustomerpageState extends State<Customerpage> {
  final supabase = Supabase.instance.client;
  String searchQuery = "";

  Future<List<Map<String, dynamic>>> fetchCustomer() async{
    final response = await supabase.from('Customer').select();
    return response;
  }

  Future<void> deleteCustomer(String customerId) async {
    try {
      await Supabase.instance.client
          .from('Customer')
          .delete()
          .eq('ID', customerId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Customer deleted successfully"),
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
      appBar: AppBar(title: const Text("Customer List",
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
                "Serviced Customer",
                style: TextStyle(fontSize: 24,fontWeight: FontWeight.w400),),
            ),
          ),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search by ID / Name",
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
                  future: fetchCustomer(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final customers = snapshot.data!;

                    final filteredCustomers = customers.where((customer) {
                      final cid = customer['ID']
                          ?.toString()
                          .toLowerCase() ?? "";
                      final cname = customer['Name']?.toString().toLowerCase() ?? "";

                      return cid.contains(searchQuery) ||
                          cname.contains(searchQuery);
                    }).toList();

                    if(filteredCustomers.isEmpty){
                      return const Center(
                        child: Text(
                          "No Customer found",
                          style: TextStyle(fontSize: 20,fontWeight: FontWeight.w300),
                        ),
                      );
                    }

                    return ListView.builder(
                        itemCount: filteredCustomers.length,
                        itemBuilder: (context, index) {
                          final customer = filteredCustomers[index];
                          final imageURL = customer['ImageURL'];
                          return InkWell(
                            onDoubleTap: (){
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:(context)=>
                                        CustomerDetailsPage(customer:customer),
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
                                          width: 160,
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
                                              Text("${customer['Name']}",
                                                style: const TextStyle(
                                                  fontSize: 19,
                                                  fontWeight: FontWeight.w600,
                                                ),),
                                              IconButton(
                                                icon: const Icon(Icons.delete),
                                                onPressed:(){
                                                  showDialog(context: context,
                                                      builder:(context) => AlertDialog(
                                                        title: const Text("Delete Customer"),
                                                        content: Text("Are you sure you want to delete ${customer['Name']}?"),
                                                        actions: [
                                                          TextButton(onPressed: () => Navigator.pop(context),
                                                              child: const Text("Cancel")),
                                                          TextButton(onPressed: () async{
                                                            Navigator.pop(context);

                                                            await deleteCustomer(customer['ID']);

                                                            setState(() {});
                                                          }, child: const Text(
                                                            "Delete",style: TextStyle(color: Colors.red),
                                                          ))
                                                        ],
                                                      ));
                                                },)
                                            ],
                                          ),
                                          Text("Customer ID: ${customer['ID']} ",
                                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w400),),
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
            MaterialPageRoute(builder: (context)=> const AddCustomerpage(),),
          );
        },
        backgroundColor: const Color(0xB6D1FFFF),
        child: const Icon(Icons.add, size:32, color: Colors.black),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
