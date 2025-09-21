import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Supabase client
final supabase = Supabase.instance.client;

class Invoicepage extends StatefulWidget {
  const Invoicepage({super.key});

  @override
  _InvoicepageState createState() => _InvoicepageState();
}

class _InvoicepageState extends State<Invoicepage> {
  String searchQuery = "";
  Map<String, List<dynamic>> invoicesByMonth = {};
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchInvoices();
  }

  Future<void> fetchInvoices() async {
    try {
      final data = await supabase
          .from('Invoice')
          .select('''
            invoiceNo, payment_date, payment_amt, customer_id, 
            Customer(ID, Name, Address, ContactNo, ImageURL, Gmail),
            Invoice_Inventory(*, inventory(item_id, name, description, image_url, qty, details, price))
          ''')
          .order('payment_date', ascending: false);

      print('Supabase raw data: $data');

      if (data == null || data.isEmpty) {
        setState(() {
          invoicesByMonth = {};
          isLoading = false;
        });
        return;
      }

      Map<String, List<dynamic>> grouped = {};

      for (var invoice in data) {
        String invoiceNo = invoice['invoiceNo'].toString();
        int monthDigits = int.tryParse(invoiceNo.substring(2, 4)) ?? DateTime.now().month;
        String month = monthName(monthDigits);

        if (!grouped.containsKey(month)) grouped[month] = [];
        grouped[month]!.add(invoice);
      }

      setState(() {
        invoicesByMonth = grouped;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching invoices: $e');
      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
    }
  }

  String monthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Invoice List"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : errorMessage != null
            ? Center(child: Text("Error: $errorMessage"))
            : Column(
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: "Search Invoice...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase();
                });
              },
            ),
            const SizedBox(height: 20),
            Expanded(
              child: invoicesByMonth.isEmpty
                  ? const Center(child: Text("No invoices found"))
                  : ListView(
                children: invoicesByMonth.entries.map((entry) {
                  final month = entry.key;
                  final invoices = entry.value.where((invoice) {
                    final customerName = invoice['Customer']?['Name']?.toString() ?? '';
                    return invoice['invoiceNo'].toString().toLowerCase().contains(searchQuery) ||
                        customerName.toLowerCase().contains(searchQuery);
                  }).toList();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      Text(
                        month,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      const SizedBox(height: 5),
                      invoices.isEmpty
                          ? const Text("(no invoices found)")
                          : Column(
                        children: invoices.map((invoice) {
                          final items = invoice['Invoice_Inventory'] ?? [];
                          double total = 0;
                          for (var assoc in items) {
                            final item = assoc['inventory'] ?? {};
                            int purchasedQty = assoc['item_purchased_quantity'] ?? 0;
                            double price = (item['price'] ?? 0).toDouble();
                            total += purchasedQty * price;
                          }

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Date: ${invoice['payment_date'].toString().substring(0, 10)}"),
                                  Text("Bill No: ${invoice['invoiceNo']}"),
                                  Text("Amount: MYR ${total.toStringAsFixed(2)}"), // total payable
                                  Text("Customer: ${invoice['Customer']?['Name'] ?? 'Unknown'}"),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                InvoiceDetailPage(invoice: invoice),
                                          ),
                                        );
                                      },
                                      child: const Text("View"),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class InvoiceDetailPage extends StatelessWidget {
  final dynamic invoice;

  const InvoiceDetailPage({super.key, required this.invoice});

  @override
  Widget build(BuildContext context) {
    final customer = invoice['Customer'] ?? {};
    final items = invoice['Invoice_Inventory'] ?? [];

    double total = 0;
    for (var assoc in items) {
      final item = assoc['inventory'] ?? {};
      int purchasedQty = assoc['item_purchased_quantity'] ?? 0;
      double price = (item['price'] ?? 0).toDouble();
      total += purchasedQty * price;
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Invoice Detail")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Invoice Detail",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            Text("Buyer Name    : ${customer['Name'] ?? 'Unknown'}"),
            Text("Buyer Reg. No : ${customer['ID'] ?? 'Unknown'}"),
            Text("Contact No    : ${customer['ContactNo'] ?? 'Unknown'}"),
            Text("Address       : ${customer['Address'] ?? 'Unknown'}"),
            const SizedBox(height: 20),
            Text("Payment Date  : ${invoice['payment_date'].toString().substring(0, 10)}"),
            Text("Invoice No    : ${invoice['invoiceNo']}"),
            const Divider(),
            // Table header
            Container(
              color: Colors.grey[300],
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: Row(
                children: const [
                  Expanded(flex: 5, child: Text("Description", style: TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(flex: 2, child: Text("Qty", style: TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(flex: 3, child: Text("Price", style: TextStyle(fontWeight: FontWeight.bold))),
                ],
              ),
            ),
            const Divider(height: 0),
            ...items.map((assoc) {
              final item = assoc['inventory'] ?? {};
              int purchasedQty = assoc['item_purchased_quantity'] ?? 0;
              double price = (item['price'] ?? 0).toDouble();
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: Row(
                  children: [
                    Expanded(flex: 5, child: Text(item['name'] ?? '')),
                    Expanded(flex: 2, child: Text(purchasedQty.toString())),
                    Expanded(flex: 3, child: Text("MYR ${price.toStringAsFixed(2)}")),
                  ],
                ),
              );
            }).toList(),
            const Divider(),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                "Total Payable Amount: MYR ${total.toStringAsFixed(2)}",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {},
                  child: const Text("Approve Invoice"),
                ),
                ElevatedButton(
                  onPressed: () {},
                  child: const Text("Generate Invoice"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
