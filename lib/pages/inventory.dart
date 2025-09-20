import 'package:flutter/material.dart';

// Dummy spare parts data
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

class Inventorypage extends StatefulWidget {
  @override
  State<Inventorypage> createState() => _InventorypageState();
}

class _InventorypageState extends State<Inventorypage> {
  final TextEditingController _searchController = TextEditingController();

  final List<SparePart> allParts = [
    SparePart(
      name: "Tyre",
      description:
      "Rubber covering around a wheel that provides grip, absorbs shock and supports vehicle's weight.",
      image: "assets/tyre.png", // make sure you have an image in assets folder
      qty: 70,
      details: [
        {"type": "Radial Tyre", "qty": 50},
        {"type": "Off-Road Tyre", "qty": 20},
        {"type": "Performance Tyre", "qty": 0},
      ],
    ),
    SparePart(
      name: "Engine",
      description: "Main power source that converts fuel into motion.",
      image: "assets/engine.png",
      qty: 2,
      details: [
        {"type": "V6 Engine", "qty": 1},
        {"type": "V8 Engine", "qty": 1},
      ],
    ),
    SparePart(
      name: "Spark Plug",
      description: "Device that ignites the air/fuel mixture in combustion engine.",
      image: "assets/spark_plug.png",
      qty: 0,
      details: [
        {"type": "Copper Plug", "qty": 0},
      ],
    ),
  ];

  String searchText = "";

  @override
  Widget build(BuildContext context) {
    final filteredParts = allParts
        .where((part) =>
        part.name.toLowerCase().contains(searchText.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text("Inventory Control")),
      body: Column(
        children: [
          // 🔎 Search bar with clear button
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

          // 📦 Parts list
          Expanded(
            child: ListView.builder(
              itemCount: filteredParts.length,
              itemBuilder: (context, index) {
                final part = filteredParts[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(8),
                    leading: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(part.image, width: 50, height: 50),
                        Text("Qty: ${part.qty}",
                            style: TextStyle(
                                color: part.qty <= 2 ? Colors.red : Colors.black,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                    title: Text(part.name,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(part.description),
                    trailing: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => PartDetailsPage(part: part)),
                        );
                      },
                      child: const Text("View Details"),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// 📄 Details Page
class PartDetailsPage extends StatelessWidget {
  final SparePart part;

  const PartDetailsPage({super.key, required this.part});

  @override
  Widget build(BuildContext context) {
    int totalQty =
    part.details.fold(0, (sum, item) => sum + (item['qty'] as int));

    return Scaffold(
      appBar: AppBar(title: Text("${part.name} Details")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Same layout as list
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Image.asset(part.image, width: 80, height: 80),
                    const SizedBox(height: 8),
                    Text("Qty: ${part.qty}",
                        style: TextStyle(
                            color: part.qty <= 2 ? Colors.red : Colors.black,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(part.name,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(part.description),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Current Inventory Box
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
                  const Text("Current Inventory:",
                      style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const Divider(),
                  ...part.details.map((d) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("${part.name} Type: ${d['type']}"),
                          Text("Qty: ${d['qty']}",
                              style: TextStyle(
                                  color: (d['qty'] as int) <= 2
                                      ? Colors.red
                                      : Colors.black)),
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
                      Text("$totalQty",
                          style: TextStyle(
                              color: totalQty <= 2 ? Colors.red : Colors.black,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
