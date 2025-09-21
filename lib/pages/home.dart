import 'package:flutter/material.dart';
import '/utils/LoginStaff.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  final supabase = Supabase.instance.client;
  String? staffname;
  List<Map<String, dynamic>> monthlyRevenue = [];

  @override
  void initState(){
    super.initState();
    _loadStaffName();
    _loadRevenue();
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
    final response = await supabase
        .from('Invoice')
        .select('payment_amt,payment_date,Status')
        .neq('Status', 'Unpaid');

    Map<String, double> revenueMap = {};
    for (var row in response) {
      DateTime date = DateTime.parse(row['payment_date']);
      String key = "${date.year}-${date.month.toString().padLeft(2, '0')}";

      revenueMap[key] = (revenueMap[key] ?? 0) +
          (row['payment_amt'] as num).toDouble();
    }

    return revenueMap.entries.map((e) {
      return {
        'month': e.key,
        'revenue': e.value,
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(staffname != null ? "Welcome, Mr $staffname" : "Welcome"),
        centerTitle: true,
      ),
      body: monthlyRevenue.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: true),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    int index = value.toInt();
                    if (index < monthlyRevenue.length) {
                      return Text(monthlyRevenue[index]['month']);
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
                barRods: [
                  BarChartRodData(
                    toY: revenue,
                    color: Colors.blue,
                    width: 20,
                  )
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
