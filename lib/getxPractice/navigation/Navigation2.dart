import 'package:flutter/material.dart';
import 'package:get/get.dart';

void main() {
  runApp(GetMaterialApp(
      getPages: [
        GetPage(name:'/value2',page:()=>page3()),
        GetPage(name: '/value1', page: () => page2())],
      home: Navigation2()));
}
class Navigation2 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Navigation 2'),
      ),
      body: Center(
        child:Column(
          children:[
            ElevatedButton(
              onPressed: () {
                Get.to(() => const page2());
              },
              child: Text('Page 2'),
            ),

            ElevatedButton(
              onPressed: () {
                Get.to(() => const page3());
              },
              child: Text('Page 3'),
            ),
            ElevatedButton(
              onPressed: () {
                Get.to(() => const page4());
              },
              child: Text('Page 4'),
            ),
          ]
        )
      ),
    );
  }
}

class page3 extends StatelessWidget {
  const page3({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Page3 Screen'),
      ),
      body: Center(
        child:Column(
          children:[
            ElevatedButton(
              onPressed: () {
                Get.back();
              },
              child: Text('Back to Navigation 2'),
            ),
            ElevatedButton(
              onPressed: () {
                Get.offAll(() => Navigation2());
              },
              child: Text('Go to Navigation 2 and remove all previous routes'),
            ),
          ]
        )
      ),
    );
  }
}





class page2 extends StatelessWidget {
  const page2({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Page2 Screen'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Get.back();
          },
          child: Text('Back to Navigation 2'),
        ),
      ),
    );
  }
}





class page4 extends StatelessWidget {
  const page4({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Page2 Screen'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Get.offAll(() => Navigation2());
          },
          child: Text('Back to Navigation 2'),
        ),
      ),
    );
  }
}



