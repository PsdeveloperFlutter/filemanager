import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DBHelper {
  ///Singleton Object
  ///It means that only one object will be created throughout the app lifecycle
  ///This is done to avoid multiple instances of database connections
  ///This is a common practice in database management to ensure efficient resource usage
  ///and to prevent potential conflicts from multiple connections
  DBHelper._();

  static final DBHelper getInstance = DBHelper._();
  String TableName='users';

  ///db Open (Path -> if exist then open else create new one)

  Database? myDb;

  Future<Database> getDb() async {
    if (myDb != null) {
      return myDb!;
    } else {
      myDb = await openDb();
      return myDb!;
    }
  }

  ///Open DataBase
  Future<Database> openDb() async {
    Directory appDir = await getApplicationDocumentsDirectory();
    String dbPath = join(appDir.path, 'myDatabase.db');
//Open the database
  return await openDatabase(dbPath, version: 1, onCreate: ((db, version) async {
      //Create table
      await db.execute('''
  CREATE TABLE $TableName(
   id INTEGER PRIMARY KEY AUTOINCREMENT,
   name TEXT,
    age INTEGER,
    email TEXT
  )
  ''');
    }));
  }

  ///Insert Data into Table with Map
  Future<int>insertData(String name,int age,String email)async{
    Database db=await getDb();
    Map<String,dynamic>row={
      'name':name,
      'age':age,
      'email':email
    };
    return await db.insert(TableName, row);
  }

  ///Fetch Data from Table
Future<List<Map<String,dynamic>>>fetchData()async{
    Database db=await getDb();
    return await db.query(TableName);
}
///Delete Data from Table
Future<int>deleteData(int id)async{
    Database db=await getDb();
    return await db.delete(TableName,where: 'id=?',whereArgs: [id]);
}
///Update Data in Table
Future<int>updateData(int id, String name , int age , String email)async{
   Database db=await getDb();
    //Update logic here
    Map<String,dynamic>row={
      'name':name,
      'age':age,
      'email':email
    };
  return await db.update(TableName,row,where:'id=?',whereArgs: [id]);
}

///Close Database
Future closeDb()async{
  Database db=await getDb();
  db.close();
}
}

