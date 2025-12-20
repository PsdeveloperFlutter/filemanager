import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
/// Slider with Provider
void main() {
  runApp(ChangeNotifierProvider(
    create: (_) => Slider_Provider(),
    child: MaterialApp(
      home: Sliderwithprovider(),
    ),
  ));
}

class Sliderwithprovider extends StatelessWidget {
  const Sliderwithprovider({super.key});

  @override
  Widget build(BuildContext context) {
    print("Build \n");
    return Scaffold(
        appBar: AppBar(
          title: Text("Slider with Provider"),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Consumer<Slider_Provider>(builder: (context, value, child) {
                return Container(
                  color: Colors.blue.shade400,
                  width: 200,
                  height: value.slider_value,
                );
              }),
              Consumer<Slider_Provider>(builder: (context, provider, child) {
                return Slider(
                    min: 0.0,
                    max: 500.0,
                    value: provider.slider_value,
                    onChanged: (value) {
                      context.read<Slider_Provider>().changeValue(value);
                    });
              })
            ],
          ),
        ));
  }
}

class Slider_Provider extends ChangeNotifier {
  double slider_value = 0.0;

  void changeValue(double slider_value) {
    this.slider_value = slider_value;
    notifyListeners();
  }
}
