import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// SparePart model class
class SparePart {
  final String name;
  final String description;
  final String image;
  final int qty;
  final List<Map<String, dynamic>> details;
  final List<Map<String, dynamic>> usage;

  SparePart({
    required this.name,
    required this.description,
    required this.image,
    required this.qty,
    required this.details,
    required this.usage,
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
        usage: List<Map<String, dynamic>>.from(e['Usage'] ?? []),
      );
    }).toList();
  }

  // Check if any subitem is < 10
  bool hasLowSubItem(SparePart part) {
    for (var d in part.details) {
      if ((d['qty'] ?? 0) < 10) return true;
    }
    return false;
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
                            // Image + Qty
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
                                  "Qty: ${part.qty}${hasLowSubItem(part) ? ' !' : ''}",
                                  style: TextStyle(
                                    color: part.qty <= 10 || hasLowSubItem(part)
                                        ? Colors.red
                                        : Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 16),

                            // Text + Button
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
                      "Quantity : ${part.qty}${part.qty <= 10 ? ' !' : ''}",
                      style: TextStyle(
                        color: part.qty <= 10 ? Colors.red : Colors.black,
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
                    final qty = d['qty'] as int? ?? 0;
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
                                "$qty${qty <= 10 ? ' !' : ''}",
                                style: TextStyle(
                                  color: qty <= 10 ? Colors.red : Colors.black,
                                  fontWeight: FontWeight.bold,
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
                        "$totalQty${totalQty <= 10 ? ' !' : ''}",
                        style: TextStyle(
                          color: totalQty <= 10 ? Colors.red : Colors.black,
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

            // Dynamic Usage Section
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
                  const Text("Recent Usage :",
                      style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const Divider(),
                  if (part.usage.isEmpty)
                    const Text("(No recent usage found)"),
                  ...part.usage.map((u) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("${u['type'] ?? 'Unknown'}"),
                          Text("Usage: ${u['usage'] ?? 0}"),
                          Text("Purpose: ${u['purpose'] ?? '-'}"),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
