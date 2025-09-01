import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AddVehiclepage extends StatefulWidget {
  const AddVehiclepage({super.key});

  @override
  State<AddVehiclepage> createState() => _AddVehiclepageState();
}

class _AddVehiclepageState extends State<AddVehiclepage> {
  double _la = 0.0;
  double _dpa = 0.0;
  double _irate = 0.0;
  int _period =0;
  double _interest=0.0;
  double _monthpay = 0.0;
  String _replaymentoutput = '';

  final lactrl = TextEditingController();
  final dpactrl = TextEditingController();
  final iratectrl = TextEditingController();
  final periodctrl = TextEditingController();

  final _formkey = GlobalKey<FormState>();

  void calculateloan(){

    _la = double.parse(lactrl.text);
    _dpa = double.parse(dpactrl.text);
    _irate = double.parse(iratectrl.text);
    _period = int.parse(periodctrl.text);

    _interest = (_la - _dpa) * _period * _irate;
    _monthpay = (_la - _dpa + _interest) / (_period * 12);

    setState(() {
      _replaymentoutput = 'RM ${_monthpay.toStringAsFixed(2)}\n';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Placeholder();
  }
}

