import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '/utils/LoginStaff.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  final supabase = Supabase.instance.client;
  String? staffname;
  List<Map<String, dynamic>> monthlyRevenue = [];
  List<Map<String, dynamic>> lowStockItems = [];
  Map<String, dynamic>? minStockItem;
  int weeklyCount = 0;
  int monthlyCount = 0;
  int activeCount = 0;
  int expiredCount = 0;
  int futureCount = 0;
  Map<String, int> dailyTrend = {};
  List<Map<String, dynamic>> topBusyHours = [];
  List<Map<String, dynamic>> recentCommunications = [];
  List<Map<String, dynamic>> recentServices = [];

  @override
  void initState() {
    super.initState();
    _loadStaffName();
    _loadRevenue();
    _loadInventory();
    _loadRecentCommunications();
    _loadRecentServices();
  }

  Future<void> _loadStaffName() async {
    String? name = await getStaffName();
    setState(() {
      staffname = name;
    });
  }

  Future<void> _loadRevenue() async {
    final data = await fetchMonthlyRevenue();
    setState(() {
      monthlyRevenue = data;
    });
  }

  Future<List<Map<String, dynamic>>> fetchMonthlyRevenue() async {
    final response = await supabase.from('Invoice').select('payment_amt,payment_date,Status').neq('Status', 'Unpaid');
    Map<String, double> revenueMap = {};
    for (var row in response) {
      DateTime date = DateTime.parse(row['payment_date']);
      String key = "${date.year}-${date.month.toString().padLeft(2, '0')}";
      revenueMap[key] = (revenueMap[key] ?? 0) + (row['payment_amt'] as num).toDouble();
    }
    return revenueMap.entries.map((e) {
      return {'month': e.key, 'revenue': e.value};
    }).toList();
  }

  Future<void> _loadInventory() async {
    final response = await supabase.from('inventory').select('name,qty,image_url');
    List<Map<String, dynamic>> items = List<Map<String, dynamic>>.from(response);
    final lowStock = items.where((item) => item['qty'] <= 10).toList();
    Map<String, dynamic>? minItem;
    if (items.isNotEmpty) {
      minItem = items.reduce((curr, next) => curr['qty'] < next['qty'] ? curr : next);
    }
    setState(() {
      lowStockItems = lowStock;
      minStockItem = minItem;
    });
  }

  Future<void> _loadRecentCommunications() async {
    final response = await supabase
        .from('Communication_History')
        .select('Date,Description,Customer(Name,ImageURL)')
        .order('Date', ascending: false)
        .limit(5);
    setState(() {
      recentCommunications = List<Map<String, dynamic>>.from(response);
    });
  }

  Future<void> _loadRecentServices() async {
    final response = await supabase
        .from('Service_History')
        .select('"Service Date",Description,Vehicle("Plate No",Make,Model)')
        .order("Service Date", ascending: false)
        .limit(5);
    setState(() {
      recentServices = List<Map<String, dynamic>>.from(response);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(staffname != null ? "Welcome, Mr $staffname" : "Welcome"),
        centerTitle: true,
        shape: const Border(bottom: BorderSide(color: Colors.black38, width: 1)),
        actions: [
          IconButton(
              onPressed: () async{
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('staffname');
                if(!mounted) return;
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => LoginPage()),
                );
              },
              icon: const Icon(Icons.logout),
              tooltip: 'Logout',
          )
        ],
      ),
      body: monthlyRevenue.isEmpty && dailyTrend.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (minStockItem != null) ...[
                Text("Lowest Stock Item: ${minStockItem!['name']} (Qty: ${minStockItem!['qty']})", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)),
                const SizedBox(height: 10),
              ],
              if (lowStockItems.isNotEmpty) ...[
                const Text("Items with Quantity ≤ 10:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 15),
                Column(
                  children: lowStockItems.map((item) {
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children: [
                            item['image_url'] != null
                                ? Image.asset('assets/${item['image_url']}', width: 100, height: 100, fit: BoxFit.cover)
                                : const Icon(Icons.inventory, size: 60),
                            const SizedBox(height: 8),
                            Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text("Qty: ${item['qty']}", style: const TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const Divider(thickness: 1),
              ],
              SizedBox(
                width: 250,
                height: 350,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            int index = value.toInt();
                            if (index < monthlyRevenue.length) {
                              return Text(monthlyRevenue[index]['month'], style: const TextStyle(fontSize: 10));
                            }
                            return const Text('');
                          },
                        ),
                      ),
                    ),
                    barGroups: monthlyRevenue.asMap().entries.map((entry) {
                      int index = entry.key;
                      double revenue = entry.value['revenue'];
                      return BarChartGroupData(
                        x: index,
                        barRods: [BarChartRodData(toY: revenue, color: Colors.blue, width: 18)],
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Text("Monthly Revenue Chart", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
              SizedBox(height: 10,),
              const Divider(thickness: 1),

              SizedBox(height: 10,),

              const Text("Recent Communications", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Column(
                children: recentCommunications.map((comm) {
                  final customer = comm['Customer'];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      leading: CircleAvatar(
                        radius: 25,
                        backgroundImage: NetworkImage(customer['ImageURL']),
                      ),
                      title: Text(customer['Name'] ?? 'Unknown'),
                      subtitle: Text(comm['Description'] ?? ''),
                      trailing: Text(
                        comm['Date'].toString().split('T')[0],
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const Divider(thickness: 1),
              const Text("Recent Services", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 18),
              Column(
                children: recentServices.map((service) {
                  final vehicle = service['Vehicle'];
                  final vehicleName = "${vehicle['Plate No']} (${vehicle['Make']} ${vehicle['Model']})";
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      leading: vehicle['ImageURL'] != null
                          ? Image.network(vehicle['ImageURL'], width: 50, height: 50, fit: BoxFit.cover)
                          : const Icon(Icons.directions_car, color: Colors.blueGrey),
                      title: Text(vehicleName),
                      subtitle: Text(service['Description'] ?? ''),
                      trailing: Text(
                        service['Service Date'].toString().split('T')[0],
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
