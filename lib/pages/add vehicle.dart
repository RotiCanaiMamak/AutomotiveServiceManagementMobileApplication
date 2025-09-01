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
    return Scaffold(
      appBar: AppBar(
        title: Text("Car Loan Calculation"),
      ),
      body: Form(
        key: _formkey,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Loan Amount',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                controller: lactrl,
                validator: (value){
                  if(value == null || value.isEmpty){
                    return "Please Enter Loan Amount!";
                  }
                  return null;
                },
              ),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Down Payment Amount',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                controller: dpactrl,
                validator: (value){
                  if(value == null || value.isEmpty){
                    return "Please Enter Down Payment Amount!";
                  }
                  return null;
                },
              ),
              TextFormField(
                keyboardType: TextInputType.numberWithOptions(
                  decimal: true,
                  signed: false
              ),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                decoration: const InputDecoration(
                  labelText: 'Interest rate (%)',
                ),

                controller: iratectrl,
                validator: (value){
                  if(value == null || value.isEmpty){
                    return "Please Enter Interest rate!";
                  }
                  return null;
                },
              ),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Loan Period (years)',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                controller: periodctrl,
                validator: (value){
                  if(value == null || value.isEmpty){
                    return "Please Enter Loan Period!";
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              Text(_replaymentoutput),
              SizedBox(height: 20),
              ElevatedButton(onPressed : (){
                if(_formkey.currentState!.validate()){
                  calculateloan();
                }
              }, child: const Text("Calculate"))

            ],
          ),
        ),
      ),
    );
  }
  @override
  void dispose(){
    super.dispose();
    lactrl.dispose();
    dpactrl.dispose();
    iratectrl.dispose();
    periodctrl.dispose();
  }
}

