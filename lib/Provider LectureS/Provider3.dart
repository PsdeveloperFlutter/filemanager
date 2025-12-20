import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(ChangeNotifierProvider(
    create: (_) => countProvider(),
    child: MaterialApp(home: providercount()),
  ));
}

//ChangeNotifier Class
class countProvider extends ChangeNotifier {
  int count = 0;

  void increment() {
    count++;
    notifyListeners();
  }

  void decrement() {
    count--;
    notifyListeners();
  }
}

//UI Class
class providercount extends StatelessWidget {
  const providercount({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Consumer<countProvider>(builder: (context, Provider, child) {
            return Text(
              "${Provider.count}",
              style: TextStyle(fontSize: 20),
            );
          }),
          ElevatedButton(
              onPressed: () {
                Provider.of<countProvider>(context, listen: false).increment();
              },
              child: Text("Increment")),
          ElevatedButton(
              onPressed: () {
                Provider.of<countProvider>(context, listen: false).decrement();
              },
              child: Text("Decrement"))
        ],
      ),
    );
  }
}
