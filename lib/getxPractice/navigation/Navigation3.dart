import'package:flutter/material.dart';
import 'package:get/get.dart';

class Routes{
  static final pages = [
    GetPage(name: '/page1', page: ()=> Pages1()),
    GetPage(name: '/page2', page: ()=> Pages2()),
    GetPage(name: '/page3', page: ()=> Pages3()),
    GetPage(name: '/page4', page: ()=> Pages4()),
    GetPage(name: '/page5', page: ()=> Pages5()),
    GetPage(name: '/page6', page: ()=> Pages6()),
    GetPage(name: '/page7', page: ()=> Pages7()),
    GetPage(name: '/page8', page: ()=> Pages8()),
    GetPage(name: '/page9', page: ()=> Pages9()),
    GetPage(name: '/page10', page: ()=> Pages10()),
  ];
}




void main(){
  runApp(GetMaterialApp(
    getPages: Routes.pages,
    home: Navigation(),
  ));
}

class Navigation extends StatelessWidget {
   Navigation({super.key});
  var backValue = ''.obs;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Navigation'),
      ),
      body: Center(
        child: Column(children: [
          ElevatedButton(
            onPressed: () async {
              var result= await Get.toNamed('/page1', parameters: {'id':'101','name':'Priyanshu'}) ?? '';
             backValue.value=result??'No data from Page 1';
            },
            child: Text('Page 1'),
          ),
         Obx(()=> Text(backValue.value)),
          ElevatedButton(
            onPressed: () async{
             var result= await Get.toNamed('/page2');
             backValue.value=result['name']??'No data from Page 2';
            },
            child: Text('Page 2'),
          ),
          Obx(()=> Text(backValue.value)),
          ElevatedButton(
            onPressed: () {
              Get.toNamed('/page3');
            },
            child: Text('Page 3'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.toNamed('/page4');
            },
            child: Text('Page 4'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.toNamed('/page5');
            },
            child: Text('Page 5'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.toNamed('/page6');
            },
            child: Text('Page 6'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.toNamed('/page7');
            },
            child: Text('Page 7'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.toNamed('/page8');
            },
            child: Text('Page 8'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.toNamed('/page9');
            },
            child: Text('Page 9'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.toNamed('/page10');
            },
            child: Text('Page 10'),
          ),
          
        ]),
      ),
    );
  }
}

class Pages1 extends StatelessWidget {
  const Pages1({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Page1 Screen'),
      ),
      body: Center(
        child:Column(
          children:[
            Text('ID :${Get.parameters['id']}'),
            Text('Name : ${Get.parameters['name']}'),
            ElevatedButton(onPressed: (){
              Get.back(result: "Data from Page 1");
            }, child: Text('Back'))
          ]
        )
      ),
    );
  }
}

class Pages2 extends StatelessWidget {
  const Pages2({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Page2 Screen'),
      ),
      body: Center(
        child:Column(
          children:[
            ElevatedButton(onPressed: (){
              Get.back(result: {'name':'Satija Priyanshu'});
            }, child: Text('Back'))
          ]
        )
      ),
    );
  }
}



class Pages3 extends StatelessWidget {
  const Pages3({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Page3 Screen'),
      ),
      body: Center(
        child:Column(
          children:[

          ]
        )
      ),
    );
  }
}
class Pages4 extends StatelessWidget {
  const Pages4({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Page4 Screen'),
      ),
      body: Center(
        child:Column(
          children:[

          ]
        )
      ),
    );
  }
}
class Pages5 extends StatelessWidget {
  const Pages5({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Page5 Screen'),
      ),
      body: Center(
        child:Column(
          children:[

          ]
        )
      ),
    );
  }
}
class Pages6 extends StatelessWidget {
  const Pages6({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Page6 Screen'),
      ),
      body: Center(
        child:Column(
          children:[

          ]
        )
      ),
    );
  }
}
class Pages7 extends StatelessWidget {
  const Pages7({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Page7 Screen'),
      ),
      body: Center(
        child:Column(
          children:[

          ]
        )
      ),
    );
  }
}
class Pages8 extends StatelessWidget {
  const Pages8({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Page8 Screen'),
      ),
      body: Center(
        child:Column(
          children:[

          ]
        )
      ),
    );
  }
}
class Pages9 extends StatelessWidget {
  const Pages9({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Page9 Screen'),
      ),
      body: Center(
        child:Column(
          children:[

          ]
        )
      ),
    );
  }
}
class Pages10 extends StatelessWidget {
  const Pages10({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Page10 Screen'),
      ),
      body: Center(
        child:Column(
          children:[

          ]
        )
      ),
    );
  }
}