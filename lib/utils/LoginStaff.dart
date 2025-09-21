import 'package:shared_preferences/shared_preferences.dart';

Future<void> saveStaffName(String name) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('staffName', name);
}

Future<String?> getStaffName() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('staffName');
}