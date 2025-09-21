import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path_provider/path_provider.dart';

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
    setState(() {
      isLoading = true;
    });
    try {
      final data = await supabase
          .from('Invoice')
          .select('''
            invoiceNo, payment_date, payment_amt, customer_id, Status,
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
                                  Text("Amount: RM ${total.toStringAsFixed(2)}"),
                                  Text("Status: ${invoice['Status'] ?? 'Unpaid'}"),
                                  Text("Customer: ${invoice['Customer']?['Name'] ?? 'Unknown'}"),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: ElevatedButton(
                                      onPressed: () async {
                                        await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                InvoiceDetailPage(invoice: invoice),
                                          ),
                                        );
                                        // Refresh list after returning from detail
                                        fetchInvoices();
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
    final status = invoice['Status'] ?? 'Unpaid';

    double total = 0;
    for (var assoc in items) {
      final item = assoc['inventory'] ?? {};
      int purchasedQty = assoc['item_purchased_quantity'] ?? 0;
      double price = (item['price'] ?? 0).toDouble();
      total += purchasedQty * price;
    }

    Future<void> generateInvoiceTXT() async {
      try {
        StringBuffer content = StringBuffer();
        content.writeln("Invoice No: ${invoice['invoiceNo']}");
        content.writeln("Payment Date: ${invoice['payment_date'].toString().substring(0, 10)}");
        content.writeln("Customer: ${customer['Name'] ?? 'Unknown'}");
        content.writeln("Status: $status");
        content.writeln("\nItems:");
        content.writeln("Description | Qty | Price(Unit) | Price(Set)");

        for (var assoc in items) {
          final item = assoc['inventory'] ?? {};
          int purchasedQty = assoc['item_purchased_quantity'] ?? 0;
          double unitPrice = (item['price'] ?? 0).toDouble();
          double lineTotal = purchasedQty * unitPrice;
          content.writeln("${item['name']} | $purchasedQty | RM ${unitPrice.toStringAsFixed(2)} | RM ${lineTotal.toStringAsFixed(2)}");
        }

        content.writeln("\nTotal Payable: RM ${total.toStringAsFixed(2)}");

        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/Invoice_${invoice['invoiceNo']}.txt');
        await file.writeAsString(content.toString());

        print('Invoice saved at: ${file.path}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invoice saved to ${file.path}')),
        );
        // View -> Tool Windows -> Device Explorer -> ctrl+f(assgn1)

      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating invoice: $e')),
        );
      }
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
            const SizedBox(height: 8),
            // Status chip
            Row(
              children: [
                const Text("Status: ", style: TextStyle(fontWeight: FontWeight.bold)),
                Chip(
                  label: Text(status),
                  backgroundColor: status == 'Paid' ? Colors.green[300] : Colors.red[300],
                ),
              ],
            ),
            const Divider(),
            // Items Table Header
            Container(
              color: Colors.grey[300],
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: Row(
                children: const [
                  Expanded(flex: 4, child: Text("Description", style: TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(flex: 2, child: Text("Qty", style: TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(flex: 3, child: Text("Price (Unit)", style: TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(flex: 3, child: Text("Price (Set)", style: TextStyle(fontWeight: FontWeight.bold))),
                ],
              ),
            ),
            const Divider(height: 0),
            ...items.map((assoc) {
              final item = assoc['inventory'] ?? {};
              int purchasedQty = assoc['item_purchased_quantity'] ?? 0;
              double unitPrice = (item['price'] ?? 0).toDouble();
              double lineTotal = purchasedQty * unitPrice;

              return Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: Row(
                  children: [
                    Expanded(flex: 4, child: Text(item['name'] ?? '')),
                    Expanded(flex: 2, child: Text(purchasedQty.toString())),
                    Expanded(flex: 3, child: Text("RM ${unitPrice.toStringAsFixed(2)}")),
                    Expanded(flex: 3, child: Text("RM ${lineTotal.toStringAsFixed(2)}")),
                  ],
                ),
              );
            }).toList(),
            const Divider(),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                "Total Payable Amount: RM ${total.toStringAsFixed(2)}",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: status == 'Paid' ? null : () async {
                    try {
                      await supabase
                          .from('Invoice')
                          .update({'Status': 'Paid'})
                          .eq('invoiceNo', invoice['invoiceNo']);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Invoice approved!')),
                      );
                      Navigator.pop(context);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error approving invoice: $e')),
                      );
                    }
                  },
                  child: const Text("Approve Invoice"),
                ),
                ElevatedButton(
                  onPressed: status == 'Paid' ? generateInvoiceTXT : null,
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