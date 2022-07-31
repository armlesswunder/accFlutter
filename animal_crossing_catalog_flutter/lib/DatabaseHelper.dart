import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';


class DataBaseHelper {
  DataBaseHelper();
  Database? db;
  SharedPreferences? prefs;

  static const int version = 1;
  static const String DB_NAME = 'acc.db';
  static const String PREFS_VERSION = 'current_version';

  Future<void> createDB() async {
    String dbDir = await getDatabasesPath();
    String dbPath = dbDir + '/acc.db';
    db = await openDatabase(dbPath, version: 1, onCreate: _createDB);
  }

  Future<List<Map<String, Object?>>?>? getData() async {
    return await db?.rawQuery("select * from `acgc_carpet`;");
  }

  void _createDB(Database db, int version) async {
    String cds = await getTextFromFile();
    List<String> sqlArr = cds.split('\n');
    sqlArr.forEach((element) {
      try {
        print(element);
        db.execute(element);
      } catch (e) {
        print(e);
      }
    });
  }

  Future<String> getTextFromFile() async {
    return await rootBundle.loadString('assets/create_db.sql');
  }

  Future<String> loadAsset(BuildContext context) async {
    return await DefaultAssetBundle.of(context).loadString('assets/acc.db');
  }


  void update() {

  }

  void test() {


  }

  void executeSQLFile(String path) {
    /*
    db = sqlite3.openInMemory();
    File(path)
        .openRead()
        .map(utf8.decode)
        .transform(const LineSplitter())
        .forEach((line) => {

    db?.execute(line);
    });


    // You can run select statements with PreparedStatement.select, or directly
    // on the database:
    for (final Row row in resultSet!) {
      print('Artist[id: ${row['id']}, name: ${row['name']}]');
    }

    // Don't forget to dispose the database to avoid memory leaks
    db?.dispose();

     */
  }

}

