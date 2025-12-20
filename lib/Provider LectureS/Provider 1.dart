import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => CounterProvider(),
      child: MaterialApp(
        home: ProviderLecture(),
      ),
    ),
  );
}

class CounterProvider with ChangeNotifier {
  int counter = 0;

  void increment() {
    counter++;
    notifyListeners();
  }

  void decrement() {
    counter--;
    notifyListeners();
  }
}

class ProviderLecture extends StatelessWidget {
  const ProviderLecture({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Provider Lecture")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Consumer<CounterProvider>(
              builder: (context, provider, child) {
                return Text(
                  "${provider.counter}",
                  style: const TextStyle(fontSize: 20),
                );
              },
            ),
            ElevatedButton(
              onPressed: () {
                Provider.of<CounterProvider>(context, listen: false)
                    .increment();
              },
              child: const Text("Increment"),
            ),
            ElevatedButton(
              onPressed: () {
                Provider.of<CounterProvider>(context, listen: false)
                    .decrement();
              },
              child: const Text("Decrement"),
            ),
          ],
        ),
      ),
    );
  }
}
