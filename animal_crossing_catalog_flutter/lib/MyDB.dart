import 'dart:io';

import 'package:animal_crossing_catalog_flutter/utils.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'data.dart';
import 'main.dart';

String defaultDir = '';
String dbPath = '';
late Database myDB;

void initDirs() {
  if (Platform.isWindows) {
    getApplicationDocumentsDirectory().then((value) {
      defaultDir = '${value.path}${Platform.pathSeparator}accFlutter';
      if (!Directory(defaultDir).existsSync()) {
        Directory(defaultDir).createSync(recursive: true);
      }
      initMyDb();
    });
  }
  if (Platform.isAndroid) {
    getExternalStorageDirectory().then((value) {
      if (!value!.existsSync()) {
        value.createSync();
      }
      defaultDir = '${value.path}${Platform.pathSeparator}data';
      if (!Directory(defaultDir).existsSync()) {
        Directory(defaultDir).createSync();
      }
      initMyDb();
    });
  }
}

void initMyDb() async {
  dbPath = '$defaultDir${Platform.pathSeparator}acc.db';
  var file = File(dbPath);
  if (!file.existsSync()) {
    // Extract the pre-populated database file from assets
    final blob = await rootBundle.load('assets/acc.db');
    final buffer = blob.buffer;
    await file.writeAsBytes(
        buffer.asUint8List(blob.offsetInBytes, blob.lengthInBytes));
  }

  myDB = await openDatabase(dbPath);
  db1 = MyDatabase1();
  await getPrefs();
  await initializeTypes();
  db1!.doUpdate();
  await getData();
  getVersion();
  clearCache();
}

class MyDatabase1 {
  MyDatabase1() : super();

  void doUpdate() {
    print('dbVersion is $dbVersion, oldVersion is $oldVersion');
    if (oldVersion != dbVersion) {
      print('update required!');
      if (oldVersion < 2) {
        update('update1.sql');
      }
    }
    prefs?.setInt('dbVersion', dbVersion);
  }

  void update(String fileName) async {
    final blob = await rootBundle.load('assets/$fileName');
    final buffer = blob.buffer;
    File tempFile = File('$defaultDir${Platform.pathSeparator}temp.sql');
    await tempFile.writeAsBytes(
        buffer.asUint8List(blob.offsetInBytes, blob.lengthInBytes));
    var str = tempFile.readAsStringSync();
    var dataList = str.split('\n');
    for (int i = 0; i < dataList.length; i++) {
      try {
        var element = dataList[i];
        if (element.trim().isEmpty) continue;
        await myDB.execute(element);
      } catch (e) {
        print(e);
      }
    }
    tempFile.deleteSync();
  }

  Future<List<Map<String, dynamic>>> getData(String game, String type) async {
    var tempArr = <Map<String, dynamic>>[];
    String table = game + type;
    List<String> tables = mAllTables[table] ??= [table];
    for (int i = 0; i < tables.length; i++) {
      String t = tables[i];
      List<Map<String, dynamic>> e = await mGetData(t);
      print(e.length);
      for (int j = 0; j < e.length; j++) {
        var e1 = e[j];
        try {
          var map = Map.of(e1);
          map["Type"] = t;
          tempArr.add(map);
        } catch (err) {
          print(err);
        }
      }
    }

    if (table.contains('acnh_') || table.contains('acnl_')) {
      tempArr.sort((m1, m2) => m1["Name"].compareTo(m2["Name"]));
    }

    return tempArr;
  }

  Future<List<Map<String, dynamic>>> getSeasonalData(String game, String type,
      String month, int monthNum, List<String> monthList) async {
    var tempArr = <Map<String, dynamic>>[];
    List<Map<String, dynamic>> filteredArr = [];
    var seasonArr = <Map<String, dynamic>>[];
    List<Map<String, dynamic>> e = await mGetData(game + type);
    for (int j = 0; j < e.length; j++) {
      var e1 = e[j];
      try {
        var map = Map.of(e1);
        map["Type"] = game + type;
        tempArr.add(map);
      } catch (err) {
        print(err);
      }
    }

    e = await mGetSeasonData(game + month + type);
    for (int k = 0; k < e.length; k++) {
      var e1 = e[k];
      try {
        seasonArr.add(e1);
      } catch (err) {
        print(err);
      }
    }

    int nextMonthIndex = monthNum + 1;
    int previousMonthIndex = monthNum - 1;

    if (nextMonthIndex >= monthList.length) {
      nextMonthIndex = 1;
    }
    if (previousMonthIndex < 1) {
      previousMonthIndex = monthList.length - 1;
    }

    List<Map<String, dynamic>> nextMonthData =
        await mGetData(game + monthList[nextMonthIndex] + type);
    List<Map<String, dynamic>> previousMonthData =
        await mGetData(game + monthList[previousMonthIndex] + type);

    List<int> nextMonthIndexes = [];
    List<int> previousMonthIndexes = [];

    for (Map<String, dynamic> element2 in nextMonthData) {
      var x = element2["id"] ??= -1;
      nextMonthIndexes.add(x);
    }

    for (Map<String, dynamic> element2 in previousMonthData) {
      var x = element2["id"] ??= -1;
      previousMonthIndexes.add(x);
    }

    for (Map<String, dynamic> indexObj in seasonArr) {
      int index = indexObj["id"];
      for (Map<String, dynamic> data in tempArr) {
        if (data["Index"] == index) {
          var x = data["Index"];
          data["PresentNextMonth"] = false;
          data["PresentPreviousMonth"] = false;
          for (int i in nextMonthIndexes) {
            if (i == x) {
              data["PresentNextMonth"] = true;
              break;
            }
          }
          for (int i in previousMonthIndexes) {
            if (i == x) {
              data["PresentPreviousMonth"] = true;
              break;
            }
          }
          filteredArr.add(data);
        }
      }
    }

    return filteredArr;
  }

  Future<List<String>> getTableData(String table) async {
    var tempArr = <String>[];
    List<Map<String, dynamic>> e = await mGetData(table);
    for (var e1 in e) {
      try {
        for (String s in e1.values) {
          tempArr.add(s);
        }
      } catch (err) {
        print(err);
      }
    }

    if (table == "acgc_table") {
      tempArr.insert(0, "all_housewares");
    } else if (table == "acww_table") {
      tempArr.insert(0, ("all_clothing"));
      tempArr.insert(0, ("all_housewares"));
    } else if (table == "accf_table") {
      tempArr.insert(0, ("all_clothing"));
      tempArr.insert(0, ("all_housewares"));
    } else if (table == "acnl_table") {
      tempArr.insert(0, ("all_critters"));
      tempArr.insert(0, ("all_clothing"));
      tempArr.insert(0, ("all_housewares"));
    } else if (table == "acnh_table") {
      tempArr.insert(0, ("all_clothing"));
      tempArr.insert(0, ("all_housing"));
    }

    return tempArr;
  }

  Future<dynamic> mGetData(String table) async {
    if (table == null) {
      print('Get data called with null table...');
    }
    var cmd = await myDB.rawQuery(
      'SELECT * FROM $table;',
    );

    return cmd;
  }

  Future<dynamic> mGetSeasonData(String table) async {
    if (table == null) {
      print('Get data called with null table...');
    }

    var cmd = await myDB.rawQuery(
      'SELECT * FROM $table',
    );

    return cmd;
  }

  Future<void> exportInto(File file) async {
    // Make sure the directory of the target file exists
    await file.parent.create(recursive: true);

    // Override an existing backup, sqlite expects the target file to be empty
    if (file.existsSync()) {
      file.deleteSync();
    }
    await myDB.execute('VACUUM INTO ?', [file.path]);
  }

  void unselectAllFromGame(List<String> tables, String prefix,
      {bool selected = false}) async {
    //acgc backup
    for (String table in tables) {
      var tableName = (prefix + table).replaceAll(" ", "_");
      if (tableName.contains("_all_")) continue;

      var tempArr = <Map<String, dynamic>>[];
      List<Map<String, dynamic>> e = await mGetData(tableName);
      for (var e1 in e) {
        try {
          tempArr.add(e1);
        } catch (err) {
          print(err);
        }
      }
      for (Map<String, dynamic> map in tempArr) {
        updateData(tableName, map['Index'], selected);
      }
    }
  }

  void unselectAllFromTable(String table, {bool selected = false}) async {
    var tableName = (table).replaceAll(" ", "_");
    if (tableName.contains("_all_")) return;

    var tempArr = <Map<String, dynamic>>[];
    List<Map<String, dynamic>> e = await mGetData(table);
    for (var e1 in e) {
      try {
        tempArr.add(e1);
      } catch (err) {
        print(err);
      }
    }
    for (Map<String, dynamic> map in tempArr) {
      updateData(tableName, map['Index'], selected);
    }
  }

  Future<String> backupData() async {
    StringBuffer buffer = StringBuffer();

    //buffer += "version=$DB_VERSION;

    //acgc backup
    for (String table in acgcTables) {
      var tableName = ("acgc_" + table).replaceAll(" ", "_");
      if (tableName.contains("_all_")) continue;
      var backupList = await getBackupData(tableName);

      for (int writeData in backupList) {
        buffer.writeln("$tableName:$writeData");
      }
    }
    //acww backup
    for (String table in acwwTables) {
      var tableName = ("acww_" + table).replaceAll(" ", "_");
      if (tableName.contains("_all_")) continue;
      var backupList = await getBackupData(tableName);

      for (int writeData in backupList) {
        buffer.writeln("$tableName:$writeData");
      }
    }
    //accf backup
    for (String table in accfTables) {
      var tableName = ("accf_" + table).replaceAll(" ", "_");
      if (tableName.contains("_all_")) continue;
      var backupList = await getBackupData(tableName);

      for (int writeData in backupList) {
        buffer.writeln("$tableName:$writeData");
      }
    }
    //acnl backup
    for (String table in acnlTables) {
      var tableName = ("acnl_" + table).replaceAll(" ", "_");
      if (tableName.contains("_all_")) continue;
      var backupList = await getBackupData(tableName);

      for (int writeData in backupList) {
        buffer.writeln("$tableName:$writeData");
      }
    }
    //acnh backup
    for (String table in acnhTables) {
      var tableName = ("acnh_" + table).replaceAll(" ", "_");
      if (tableName.contains("_all_")) continue;
      var backupList = await getBackupData(tableName);

      for (int writeData in backupList) {
        buffer.writeln("$tableName:$writeData");
      }
    }
    var r = buffer.toString();
    return r;
  }

  Future<List<int>> getBackupData(String table) async {
    var myDataset = <int>[];
    var tempArr = <Map<String, dynamic>>[];
    List<Map<String, dynamic>> e = await mGetData(table);
    for (var e1 in e) {
      try {
        tempArr.add(e1);
      } catch (err) {
        print(err);
      }
    }
    for (Map<String, dynamic> map in tempArr) {
      if (map['Selected'] == 1) {
        myDataset.add(map['Index']);
      }
    }
    return myDataset;
  }

  int boolToInt(bool) {
    return bool ? 1 : 0;
  }

  void updateData(String table, int index, bool selected) async {
    int s = boolToInt(selected);
    await myDB
        .rawUpdate('update $table set "Selected" = $s where "Index" = $index;');
  }

  void rawUpdate(String sql) async {
    await myDB.rawUpdate(sql);
  }
}
