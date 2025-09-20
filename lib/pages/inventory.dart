import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// SparePart model class
class SparePart {
  final String name;
  final String description;
  final String image;
  final int qty;
  final List<Map<String, dynamic>> details;

  SparePart({
    required this.name,
    required this.description,
    required this.image,
    required this.qty,
    required this.details,
  });
}

// Inventory Page
class Inventorypage extends StatefulWidget {
  @override
  State<Inventorypage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<Inventorypage> {
  final TextEditingController _searchController = TextEditingController();
  String searchText = "";

  // Fetch data from Supabase
  Future<List<SparePart>> fetchSpareParts() async {
    final data = await Supabase.instance.client
        .from('inventory')
        .select()
        .then((value) => value as List<dynamic>);

    return data.map((e) {
      return SparePart(
        name: e['name'] as String,
        description: e['description'] as String,
        image: e['image_url'] as String,
        qty: e['qty'] as int,
        details: List<Map<String, dynamic>>.from(e['details'] ?? []),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Inventory Control")),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: "Search for spare parts",
                hintStyle: const TextStyle(color: Colors.grey),
                border: const OutlineInputBorder(),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                      searchText = "";
                    });
                  },
                )
                    : null,
              ),
              onChanged: (value) {
                setState(() {
                  searchText = value;
                });
              },
            ),
          ),

          // Parts list
          Expanded(
            child: FutureBuilder<List<SparePart>>(
              future: fetchSpareParts(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final filteredParts = snapshot.data!
                    .where((part) => part.name
                    .toLowerCase()
                    .contains(searchText.toLowerCase()))
                    .toList();

                if (filteredParts.isEmpty) {
                  return const Center(child: Text('No spare parts found.'));
                }

                return ListView.builder(
                  itemCount: filteredParts.length,
                  itemBuilder: (context, index) {
                    final part = filteredParts[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Left image + qty
                            Column(
                              children: [
                                Image.asset(
                                  'assets/${part.image}',
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Qty: ${part.qty}",
                                  style: TextStyle(
                                    color: part.qty <= 2
                                        ? Colors.red
                                        : Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 16),

                            // Right text + button
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    part.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    part.description,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                PartDetailsPage(part: part),
                                          ),
                                        );
                                      },
                                      child: const Text("View Details"),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Details Page
class PartDetailsPage extends StatelessWidget {
  final SparePart part;
  const PartDetailsPage({super.key, required this.part});

  @override
  Widget build(BuildContext context) {
    int totalQty =
    part.details.fold(0, (sum, item) => sum + (item['qty'] as int));

    return Scaffold(
      appBar: AppBar(title: Text("${part.name} Details")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image, name, desc, qty
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Image.asset(
                      'assets/${part.image}',
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Quantity : ${part.qty}",
                      style: TextStyle(
                        color: part.qty <= 2 ? Colors.red : Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        part.name,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(part.description),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Current Inventory
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Current Inventory :",
                      style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const Divider(),
                  ...part.details.map((d) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Type :"),
                              Text("${d['type']}"),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Quantity   :"),
                              Text(
                                "${d['qty']}",
                                style: TextStyle(
                                  color: (d['qty'] as int) <= 2 ? Colors.red : Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Total Quantity:",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(
                        "$totalQty",
                        style: TextStyle(
                          color: totalQty <= 2 ? Colors.red : Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text("Add-on request submitted!")),
                        );
                      },
                      child: const Text("Request to Add On"),
                    ),
                  )
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Only for Tyre -> Recent Usage
            if (part.name.toLowerCase() == "tyre")
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text("Recent Usage :",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    Divider(),
                    Text("Tyre Type : Radial Tyre"),
                    Text("Usage     : 30"),
                    Text("Purpose   : Fixing"),
                    SizedBox(height: 12),
                    Text("Tyre Type : Off-Road Tyre"),
                    Text("Usage     : 40"),
                    Text("Purpose   : Selling"),
                    SizedBox(height: 12),
                    Text("Tyre Type : Performance Tyre"),
                    Text("Usage     : 0"),
                    Text("Purpose   : -"),
                  ],
                ),
              ),

            // Only for Engine -> Recent Usage
            if (part.name.toLowerCase() == "engine")
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text("Recent Usage :",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Divider(),
                    Text("Engine Type : V6 Engine"),
                    Text("Usage     : 15"),
                    Text("Purpose   : Fixing"),
                    SizedBox(height: 12),
                    Text("Engine Type : V8 Engine"),
                    Text("Usage     : 22"),
                    Text("Purpose   : Selling"),
                  ],
                ),
              ),

            // Only for Spark Plug -> Recent Usage
            if (part.name.toLowerCase() == "spark plug")
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text("Recent Usage :",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Divider(),
                    Text("Spark Plug Type : Copper Spark Plug"),
                    Text("Usage     : 0"),
                    Text("Purpose   : -"),
                  ],
                ),
              ),

            // Only for Wheel -> Recent Usage
            if (part.name.toLowerCase() == "wheel")
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text("Recent Usage :",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Divider(),
                    Text("Wheel Type : Alloy Wheel"),
                    Text("Usage     : 8"),
                    Text("Purpose   : Fixing"),
                    SizedBox(height: 12),
                    Text("Wheel Type : Steel Wheel"),
                    Text("Usage     : 5"),
                    Text("Purpose   : Selling"),
                  ],
                ),
              ),

            // Only for Brake Pad -> Recent Usage
            if (part.name.toLowerCase() == "brake pad")
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text("Recent Usage :",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Divider(),
                    Text("Brake Pad Type : Ceramic Pad"),
                    Text("Usage     : 12"),
                    Text("Purpose   : Fixing"),
                    SizedBox(height: 12),
                    Text("Brake Pad Type : Semi-Metallic Pad"),
                    Text("Usage     : 7"),
                    Text("Purpose   : Selling"),
                  ],
                ),
              ),

            // Only for Window -> Recent Usage
            if (part.name.toLowerCase() == "window")
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text("Recent Usage :",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Divider(),
                    Text("Window Type : Front Window"),
                    Text("Usage     : 2"),
                    Text("Purpose   : Fixing"),
                    SizedBox(height: 12),
                    Text("Window Type : Rear Window"),
                    Text("Usage     : 4"),
                    Text("Purpose   : Selling"),
                  ],
                ),
              ),

            // Only for Steering Wheel -> Recent Usage
            if (part.name.toLowerCase() == "steering wheel")
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text("Recent Usage :",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Divider(),
                    Text("Steering Wheel Type : Standard"),
                    Text("Usage     : 5"),
                    Text("Purpose   : Selling"),
                    SizedBox(height: 12),
                    Text("Steering Wheel Type : Sport"),
                    Text("Usage     : 3"),
                    Text("Purpose   : Fixing"),
                  ],
                ),
              ),

            // Only for Wiper -> Recent Usage
            if (part.name.toLowerCase() == "wiper")
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text("Recent Usage :",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Divider(),
                    Text("Wiper Type : Front Wiper"),
                    Text("Usage     : 12"),
                    Text("Purpose   : Fixing"),
                    SizedBox(height: 12),
                    Text("Wiper Type : Rear Wiper"),
                    Text("Usage     : 8"),
                    Text("Purpose   : Selling"),
                  ],
                ),
              ),

          ],
        ),
      ),
    );
  }
}
