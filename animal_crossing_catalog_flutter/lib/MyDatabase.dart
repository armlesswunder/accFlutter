// These imports are only needed to open the database
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'main.dart';

part 'MyDatabase.g.dart';


LazyDatabase _openConnection() {
  // the LazyDatabase util lets us find the right location for the file async.
  return LazyDatabase(() async {
    // put the database file, called db.sqlite here, into the documents folder
    // for your app.
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'app.db'));

    if (!await file.exists()) {
      // Extract the pre-populated database file from assets
      final blob = await rootBundle.load('assets/acc.db');
      final buffer = blob.buffer;
      await file.writeAsBytes(buffer.asUint8List(blob.offsetInBytes, blob.lengthInBytes));
    }

    return NativeDatabase(file);
  });
}

@DriftDatabase(
  include: {'tables.drift'},)
class MyDatabase extends _$MyDatabase {
  // we tell the database where to store the data with this constructor
  MyDatabase() : super(_openConnection());

  // you should bump this number whenever you change or add a table definition.
  // Migrations are covered later in the documentation.
  @override
  int get schemaVersion => 1;

  Map<String, ResultSetImplementation<dynamic, dynamic>>? tableMap;
  Map<String, TableInfo>? tableInfoMap;

  Map<String, List<String>> mAllTables = <String, List<String>>{
    "acgc_all_housewares": ["acgc_furniture", "acgc_carpet", "acgc_wallpaper", "acgc_gyroid"],
    "acww_all_housewares": ["acww_furniture", "acww_carpet", "acww_wallpaper", "acww_gyroid"],
    "acww_all_clothing": ["acww_accessory", "acww_shirt"],
    "accf_all_housewares": ["accf_furniture", "accf_carpet", "accf_wallpaper", "accf_gyroid", "accf_painting"],
    "accf_all_clothing": ["accf_accessory", "accf_shirt"],
    "acnl_all_housewares": ["acnl_furniture", "acnl_carpet", "acnl_wallpaper", "acnl_gyroid", "acnl_song"],
    "acnl_all_clothing": ["acnl_accessory", "acnl_bottom", "acnl_dress", "acnl_feet", "acnl_hat", "acnl_shirt", "acnl_wet_suit"],
    "acnh_all_housing": ["acnh_houseware", "acnh_misc", "acnh_ceiling", "acnh_interior", "acnh_wall_mounted", "acnh_art", "acnh_flooring", "acnh_rug", "acnh_wallpaper"],
    "acnh_all_clothing": ["acnh_accessory", "acnh_bag", "acnh_bottom", "acnh_dress", "acnh_headwear", "acnh_shoe", "acnh_sock", "acnh_top", "acnh_other_clothing"],
  };

  Future<List<Map<String, dynamic>>> getData(String game, String type) async {
    var tempArr = <Map<String, dynamic>> [];
    String table = game + type;
    List<String> tables = mAllTables[table] ??= [table];
    for (String t in tables) {
      List<Set<Map<String, dynamic>>> e = await mGetData(t);
      for (var e1 in e) {
        try {
          e1.first["Type"] = t;
          tempArr.add(e1.first);
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
  
  Future<List<Map<String, dynamic>>> getSeasonalData(String game, String type, String month, int monthNum, List<String> monthList) async {
    var tempArr = <Map<String, dynamic>> [];
    List<Map<String, dynamic>> filteredArr = [];
    var seasonArr = <Map<String, dynamic>> [];
    List<Set<Map<String, dynamic>>> e = await mGetData(game + type);
    for (var e1 in e) {
      try {
        e1.first["Type"] = game + type;
        tempArr.add(e1.first);
      } catch (err) {
        print(err);
      }
    }

    e = await mGetSeasonData(game + month + type);
    for (var e1 in e) {
      try {
        seasonArr.add(e1.first);
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

    List<Set<Map<String, dynamic>>> nextMonthData = await mGetData(game + monthList[nextMonthIndex] + type);
    List<Set<Map<String, dynamic>>> previousMonthData = await mGetData(game + monthList[previousMonthIndex] + type);

    List<int> nextMonthIndexes = [];
    List<int> previousMonthIndexes = [];

    for (var element1 in nextMonthData) {
      var l = element1.toList();
      for (var element2 in l) {
        var x = element2["id"] ??= -1;
        nextMonthIndexes.add(x);
      }
    }
    for (var element1 in previousMonthData) {
      var l = element1.toList();
      for (var element2 in l) {
        var x = element2["id"] ??= -1;
        previousMonthIndexes.add(x);
      }
    }

    for (Map<String, dynamic> indexObj in seasonArr) {
      int index = indexObj["id"];
      for (Map<String, dynamic> data in tempArr) {
        if (data["Index"] == index) {
          var x = data["Index"];
          data["GoneNextMonth"] = false;
          data["GonePreviousMonth"] = false;
          for (int i in nextMonthIndexes) {
            if (i == x) {
              data["GoneNextMonth"] = true;
              break;
            }
          }
          for (int i in previousMonthIndexes) {
            if (i == x) {
              data["GonePreviousMonth"] = true;
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
    var tempArr = <String> [];
    List<Set<Map<String, dynamic>>> e = await mGetData(table);
    for (var e1 in e) {
      try {
        for (String s in e1.first.values) {
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
      tempArr.insert(0, ("all_clothing"));
      tempArr.insert(0, ("all_housewares"));
    } else if (table == "acnh_table") {
      tempArr.insert(0, ("all_clothing"));
      tempArr.insert(0, ("all_housing"));
    }

    return tempArr;
  }

  Future<dynamic> mGetData(String table) {
    if (table == null) {
      print('Get data called with null table...');
    }

    return customSelect(
      'SELECT * FROM $table',
      readsFrom: {getTable(table)!},
    ).map((row) => {
      row.data
    }).get();
  }

  Future<dynamic> mGetSeasonData(String table) {
    if (table == null) {
      print('Get data called with null table...');
    }

    return customSelect(
      'SELECT * FROM $table',
      readsFrom: {getTable(table)!},
    ).map((row) => {
      row.data
    }).get();
  }

  ResultSetImplementation<dynamic, dynamic>? getTable(String table) {
    initTableMap();
    return tableMap?[table];
  }

  TableInfo? getTableInfo(String table) {
    initTableInfoMap();
    return tableInfoMap?[table]!;
  }

  Future<void> exportInto(File file) async {
    // Make sure the directory of the target file exists
    await file.parent.create(recursive: true);

    // Override an existing backup, sqlite expects the target file to be empty
    if (file.existsSync()) {
      file.deleteSync();
    }
    await customStatement('VACUUM INTO ?', [file.path]);
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
    List<Set<Map<String, dynamic>>> e = await mGetData(table);
    for (var e1 in e) {
      try {
        tempArr.add(e1.first);
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

  void initTableMap() {
    tableMap ??= {
      'acgc_carpet': acgcCarpet,
      'acgc_wallpaper': acgcWallpaper,
      'acgc_fish': acgcFish,
      'acgc_fossil': acgcFossil,
      'acgc_gyroid': acgcGyroid,
      'acgc_insect': acgcInsect,
      'acgc_shirt': acgcShirt,
      'acgc_song': acgcSong,
      'acgc_stationery': acgcStationery,
      'acgc_tool': acgcTool,
      'acww_accessory': acwwAccessory,
      'acww_carpet': acwwCarpet,
      'acww_fish': acwwFish,
      'acww_fossil': acwwFossil,
      'acww_furniture': acwwFurniture,
      'acww_gyroid': acwwGyroid,
      'acww_insect': acwwInsect,
      'acww_shirt': acwwShirt,
      'acww_song': acwwSong,
      'acww_stationery': acwwStationery,
      'acww_tool': acwwTool,
      'acww_wallpaper': acwwWallpaper,
      'accf_accessory': accfAccessory,
      'accf_carpet': accfCarpet,
      'accf_fossil': accfFossil,
      'accf_fish': accfFish,
      'accf_furniture': accfFurniture,
      'accf_gyroid': accfGyroid,
      'accf_insect': accfInsect,
      'accf_painting': accfPainting,
      'accf_shirt': accfShirt,
      'accf_song': accfSong,
      'accf_stationery': accfStationery,
      'accf_tool': accfTool,
      'accf_wallpaper': accfWallpaper,
      'acnl_accessory': acnlAccessory,
      'acnl_art': acnlArt,
      'acnl_bottom': acnlBottom,
      'acnl_carpet': acnlCarpet,
      'acnl_dlc': acnlDlc,
      'acnl_dress': acnlDress,
      'acnl_feet': acnlFeet,
      'acnl_fish': acnlFish,
      'acnl_fossil': acnlFossil,
      'acnl_fossil_model': acnlFossilModel,
      'acnl_furniture': acnlFurniture,
      'acnl_gyroid': acnlGyroid,
      'acnl_hat': acnlHat,
      'acnl_insect': acnlInsect,
      'acnl_music_box': acnlMusicBox,
      'acnl_seafood': acnlSeafood,
      'acnl_shirt': acnlShirt,
      'acnl_song': acnlSong,
      'acnl_stationery': acnlStationery,
      'acnl_tool': acnlTool,
      'acnl_villager_picture': acnlVillagerPicture,
      'acnl_wallpaper': acnlWallpaper,
      'acnl_wet_suit': acnlWetSuit,
      'acgc_jan_fish': acgcJanFish,
      'acgc_feb_fish': acgcFebFish,
      'acgc_mar_fish': acgcMarFish,
      'acgc_apr_fish': acgcAprFish,
      'acgc_may_fish': acgcMayFish,
      'acgc_jun_fish': acgcJunFish,
      'acgc_jul_fish': acgcJulFish,
      'acgc_aug1_fish': acgcAug1Fish,
      'acgc_aug2_fish': acgcAug2Fish,
      'acgc_sep1_fish': acgcSep1Fish,
      'acgc_sep2_fish': acgcSep2Fish,
      'acgc_oct_fish': acgcOctFish,
      'acgc_nov_fish': acgcNovFish,
      'acgc_dec_fish': acgcDecFish,
      'acgc_jan_insect': acgcJanInsect,
      'acgc_feb_insect': acgcFebInsect,
      'acgc_mar_insect': acgcMarInsect,
      'acgc_apr_insect': acgcAprInsect,
      'acgc_may_insect': acgcMayInsect,
      'acgc_jun_insect': acgcJunInsect,
      'acgc_jul_insect': acgcJulInsect,
      'acgc_aug1_insect': acgcAug1Insect,
      'acgc_aug2_insect': acgcAug2Insect,
      'acgc_sep1_insect': acgcSep1Insect,
      'acgc_sep2_insect': acgcSep2Insect,
      'acgc_oct_insect': acgcOctInsect,
      'acgc_nov_insect': acgcNovInsect,
      'acgc_dec_insect': acgcDecInsect,
      'acww_jan_fish': acwwJanFish,
      'acww_feb_fish': acwwFebFish,
      'acww_mar_fish': acwwMarFish,
      'acww_apr_fish': acwwAprFish,
      'acww_may_fish': acwwMayFish,
      'acww_jun_fish': acwwJunFish,
      'acww_jul_fish': acwwJulFish,
      'acww_aug1_fish': acwwAug1Fish,
      'acww_aug2_fish': acwwAug2Fish,
      'acww_sep1_fish': acwwSep1Fish,
      'acww_sep2_fish': acwwSep2Fish,
      'acww_oct_fish': acwwOctFish,
      'acww_nov_fish': acwwNovFish,
      'acww_dec_fish': acwwDecFish,
      'acww_jan_insect': acwwJanInsect,
      'acww_feb_insect': acwwFebInsect,
      'acww_mar_insect': acwwMarInsect,
      'acww_apr_insect': acwwAprInsect,
      'acww_may_insect': acwwMayInsect,
      'acww_jun_insect': acwwJunInsect,
      'acww_jul_insect': acwwJulInsect,
      'acww_aug1_insect': acwwAug1Insect,
      'acww_aug2_insect': acwwAug2Insect,
      'acww_sep1_insect': acwwSep1Insect,
      'acww_sep2_insect': acwwSep2Insect,
      'acww_oct_insect': acwwOctInsect,
      'acww_nov_insect': acwwNovInsect,
      'acww_dec_insect': acwwDecInsect,
      'accf_jan_fish': accfJanFish,
      'accf_feb_fish': accfFebFish,
      'accf_mar_fish': accfMarFish,
      'accf_apr_fish': accfAprFish,
      'accf_may_fish': accfMayFish,
      'accf_jun_fish': accfJunFish,
      'accf_jul_fish': accfJulFish,
      'accf_aug1_fish': accfAug1Fish,
      'accf_aug2_fish': accfAug2Fish,
      'accf_sep1_fish': accfSep1Fish,
      'accf_sep2_fish': accfSep2Fish,
      'accf_oct_fish': accfOctFish,
      'accf_nov_fish': accfNovFish,
      'accf_dec_fish': accfDecFish,
      'accf_jan_insect': accfJanInsect,
      'accf_feb_insect': accfFebInsect,
      'accf_mar_insect': accfMarInsect,
      'accf_apr_insect': accfAprInsect,
      'accf_may_insect': accfMayInsect,
      'accf_jun_insect': accfJunInsect,
      'accf_jul_insect': accfJulInsect,
      'accf_aug1_insect': accfAug1Insect,
      'accf_aug2_insect': accfAug2Insect,
      'accf_sep1_insect': accfSep1Insect,
      'accf_sep2_insect': accfSep2Insect,
      'accf_oct_insect': accfOctInsect,
      'accf_nov_insect': accfNovInsect,
      'accf_dec_insect': accfDecInsect,
      'acnl_jan_fish': acnlJanFish,
      'acnl_feb_fish': acnlFebFish,
      'acnl_mar_fish': acnlMarFish,
      'acnl_apr_fish': acnlAprFish,
      'acnl_may_fish': acnlMayFish,
      'acnl_jun_fish': acnlJunFish,
      'acnl_jul_fish': acnlJulFish,
      'acnl_aug1_fish': acnlAug1Fish,
      'acnl_aug2_fish': acnlAug2Fish,
      'acnl_sep1_fish': acnlSep1Fish,
      'acnl_sep2_fish': acnlSep2Fish,
      'acnl_oct_fish': acnlOctFish,
      'acnl_nov_fish': acnlNovFish,
      'acnl_dec_fish': acnlDecFish,
      'acnl_jan_insect': acnlJanInsect,
      'acnl_feb_insect': acnlFebInsect,
      'acnl_mar_insect': acnlMarInsect,
      'acnl_apr_insect': acnlAprInsect,
      'acnl_may_insect': acnlMayInsect,
      'acnl_jun_insect': acnlJunInsect,
      'acnl_jul_insect': acnlJulInsect,
      'acnl_aug1_insect': acnlAug1Insect,
      'acnl_aug2_insect': acnlAug2Insect,
      'acnl_sep1_insect': acnlSep1Insect,
      'acnl_sep2_insect': acnlSep2Insect,
      'acnl_oct_insect': acnlOctInsect,
      'acnl_nov_insect': acnlNovInsect,
      'acnl_dec_insect': acnlDecInsect,
      'acnl_jan_seafood': acnlJanSeafood,
      'acnl_feb_seafood': acnlFebSeafood,
      'acnl_mar_seafood': acnlMarSeafood,
      'acnl_apr_seafood': acnlAprSeafood,
      'acnl_may_seafood': acnlMaySeafood,
      'acnl_jun_seafood': acnlJunSeafood,
      'acnl_jul_seafood': acnlJulSeafood,
      'acnl_aug1_seafood': acnlAug1Seafood,
      'acnl_aug2_seafood': acnlAug2Seafood,
      'acnl_sep1_seafood': acnlSep1Seafood,
      'acnl_sep2_seafood': acnlSep2Seafood,
      'acnl_oct_seafood': acnlOctSeafood,
      'acnl_nov_seafood': acnlNovSeafood,
      'acnl_dec_seafood': acnlDecSeafood,
      'acgc_table': acgcTable,
      'acww_table': acwwTable,
      'accf_table': accfTable,
      'acnl_table': acnlTable,
      'acnh_table': acnhTable,
      'acnh_accessory': acnhAccessory,
      'acnh_art': acnhArt,
      'acnh_bag': acnhBag,
      'acnh_bottom': acnhBottom,
      'acnh_dress': acnhDress,
      'acnh_fencing': acnhFencing,
      'acnh_fish': acnhFish,
      'acnh_jan_fish': acnhJanFish,
      'acnh_feb_fish': acnhFebFish,
      'acnh_mar_fish': acnhMarFish,
      'acnh_apr_fish': acnhAprFish,
      'acnh_may_fish': acnhMayFish,
      'acnh_jun_fish': acnhJunFish,
      'acnh_jul_fish': acnhJulFish,
      'acnh_aug1_fish': acnhAug1Fish,
      'acnh_aug2_fish': acnhAug2Fish,
      'acnh_sep1_fish': acnhSep1Fish,
      'acnh_sep2_fish': acnhSep2Fish,
      'acnh_oct_fish': acnhOctFish,
      'acnh_nov_fish': acnhNovFish,
      'acnh_dec_fish': acnhDecFish,
      'acnh_flooring': acnhFlooring,
      'acnh_fossil': acnhFossil,
      'acnh_headwear': acnhHeadwear,
      'acnh_houseware': acnhHouseware,
      'acnh_misc': acnhMisc,
      'acnh_wall_mounted': acnhWallMounted,
      'acnh_ceiling': acnhCeiling,
      'acnh_interior': acnhInterior,
      'acnh_gyroid': acnhGyroid,
      'acnh_hybrid': acnhHybrid,
      'acnh_insect': acnhInsect,
      'acnh_jan_insect': acnhJanInsect,
      'acnh_feb_insect': acnhFebInsect,
      'acnh_mar_insect': acnhMarInsect,
      'acnh_apr_insect': acnhAprInsect,
      'acnh_may_insect': acnhMayInsect,
      'acnh_jun_insect': acnhJunInsect,
      'acnh_jul_insect': acnhJulInsect,
      'acnh_aug1_insect': acnhAug1Insect,
      'acnh_aug2_insect': acnhAug2Insect,
      'acnh_sep1_insect': acnhSep1Insect,
      'acnh_sep2_insect': acnhSep2Insect,
      'acnh_oct_insect': acnhOctInsect,
      'acnh_nov_insect': acnhNovInsect,
      'acnh_dec_insect': acnhDecInsect,
      'acnh_photo': acnhPhoto,
      'acnh_poster': acnhPoster,
      'acnh_recipe': acnhRecipe,
      'acnh_rug': acnhRug,
      'acnh_shoe': acnhShoe,
      'acnh_sock': acnhSock,
      'acnh_song': acnhSong,
      'acnh_tool': acnhTool,
      'acnh_top': acnhTop,
      'acnh_umbrella': acnhUmbrella,
      'acnh_wallpaper': acnhWallpaper,
      'acgc_furniture': acgcFurniture,
      'acnh_other_clothing': acnhOtherClothing,
      'acnh_sea_creature': acnhSeaCreature,
      'acnh_jan_sea_creature': acnhJanSeaCreature,
      'acnh_feb_sea_creature': acnhFebSeaCreature,
      'acnh_mar_sea_creature': acnhMarSeaCreature,
      'acnh_apr_sea_creature': acnhAprSeaCreature,
      'acnh_may_sea_creature': acnhMaySeaCreature,
      'acnh_jun_sea_creature': acnhJunSeaCreature,
      'acnh_jul_sea_creature': acnhJulSeaCreature,
      'acnh_aug1_sea_creature': acnhAug1SeaCreature,
      'acnh_aug2_sea_creature': acnhAug2SeaCreature,
      'acnh_sep1_sea_creature': acnhSep1SeaCreature,
      'acnh_sep2_sea_creature': acnhSep2SeaCreature,
      'acnh_oct_sea_creature': acnhOctSeaCreature,
      'acnh_nov_sea_creature': acnhNovSeaCreature,
      'acnh_dec_sea_creature': acnhDecSeaCreature,
    };
  }

  void initTableInfoMap() {
    tableInfoMap ??= {
      'acgc_carpet': acgcCarpet,
      'acgc_wallpaper': acgcWallpaper,
      'acgc_fish': acgcFish,
      'acgc_fossil': acgcFossil,
      'acgc_gyroid': acgcGyroid,
      'acgc_insect': acgcInsect,
      'acgc_shirt': acgcShirt,
      'acgc_song': acgcSong,
      'acgc_stationery': acgcStationery,
      'acgc_tool': acgcTool,
      'acww_accessory': acwwAccessory,
      'acww_carpet': acwwCarpet,
      'acww_fish': acwwFish,
      'acww_fossil': acwwFossil,
      'acww_furniture': acwwFurniture,
      'acww_gyroid': acwwGyroid,
      'acww_insect': acwwInsect,
      'acww_shirt': acwwShirt,
      'acww_song': acwwSong,
      'acww_stationery': acwwStationery,
      'acww_tool': acwwTool,
      'acww_wallpaper': acwwWallpaper,
      'accf_accessory': accfAccessory,
      'accf_carpet': accfCarpet,
      'accf_fossil': accfFossil,
      'accf_fish': accfFish,
      'accf_furniture': accfFurniture,
      'accf_gyroid': accfGyroid,
      'accf_insect': accfInsect,
      'accf_painting': accfPainting,
      'accf_shirt': accfShirt,
      'accf_song': accfSong,
      'accf_stationery': accfStationery,
      'accf_tool': accfTool,
      'accf_wallpaper': accfWallpaper,
      'acnl_accessory': acnlAccessory,
      'acnl_art': acnlArt,
      'acnl_bottom': acnlBottom,
      'acnl_carpet': acnlCarpet,
      'acnl_dlc': acnlDlc,
      'acnl_dress': acnlDress,
      'acnl_feet': acnlFeet,
      'acnl_fish': acnlFish,
      'acnl_fossil': acnlFossil,
      'acnl_fossil_model': acnlFossilModel,
      'acnl_furniture': acnlFurniture,
      'acnl_gyroid': acnlGyroid,
      'acnl_hat': acnlHat,
      'acnl_insect': acnlInsect,
      'acnl_music_box': acnlMusicBox,
      'acnl_seafood': acnlSeafood,
      'acnl_shirt': acnlShirt,
      'acnl_song': acnlSong,
      'acnl_stationery': acnlStationery,
      'acnl_tool': acnlTool,
      'acnl_villager_picture': acnlVillagerPicture,
      'acnl_wallpaper': acnlWallpaper,
      'acnl_wet_suit': acnlWetSuit,
      'acgc_jan_fish': acgcJanFish,
      'acgc_feb_fish': acgcFebFish,
      'acgc_mar_fish': acgcMarFish,
      'acgc_apr_fish': acgcAprFish,
      'acgc_may_fish': acgcMayFish,
      'acgc_jun_fish': acgcJunFish,
      'acgc_jul_fish': acgcJulFish,
      'acgc_aug1_fish': acgcAug1Fish,
      'acgc_aug2_fish': acgcAug2Fish,
      'acgc_sep1_fish': acgcSep1Fish,
      'acgc_sep2_fish': acgcSep2Fish,
      'acgc_oct_fish': acgcOctFish,
      'acgc_nov_fish': acgcNovFish,
      'acgc_dec_fish': acgcDecFish,
      'acgc_jan_insect': acgcJanInsect,
      'acgc_feb_insect': acgcFebInsect,
      'acgc_mar_insect': acgcMarInsect,
      'acgc_apr_insect': acgcAprInsect,
      'acgc_may_insect': acgcMayInsect,
      'acgc_jun_insect': acgcJunInsect,
      'acgc_jul_insect': acgcJulInsect,
      'acgc_aug1_insect': acgcAug1Insect,
      'acgc_aug2_insect': acgcAug2Insect,
      'acgc_sep1_insect': acgcSep1Insect,
      'acgc_sep2_insect': acgcSep2Insect,
      'acgc_oct_insect': acgcOctInsect,
      'acgc_nov_insect': acgcNovInsect,
      'acgc_dec_insect': acgcDecInsect,
      'acww_jan_fish': acwwJanFish,
      'acww_feb_fish': acwwFebFish,
      'acww_mar_fish': acwwMarFish,
      'acww_apr_fish': acwwAprFish,
      'acww_may_fish': acwwMayFish,
      'acww_jun_fish': acwwJunFish,
      'acww_jul_fish': acwwJulFish,
      'acww_aug1_fish': acwwAug1Fish,
      'acww_aug2_fish': acwwAug2Fish,
      'acww_sep1_fish': acwwSep1Fish,
      'acww_sep2_fish': acwwSep2Fish,
      'acww_oct_fish': acwwOctFish,
      'acww_nov_fish': acwwNovFish,
      'acww_dec_fish': acwwDecFish,
      'acww_jan_insect': acwwJanInsect,
      'acww_feb_insect': acwwFebInsect,
      'acww_mar_insect': acwwMarInsect,
      'acww_apr_insect': acwwAprInsect,
      'acww_may_insect': acwwMayInsect,
      'acww_jun_insect': acwwJunInsect,
      'acww_jul_insect': acwwJulInsect,
      'acww_aug1_insect': acwwAug1Insect,
      'acww_aug2_insect': acwwAug2Insect,
      'acww_sep1_insect': acwwSep1Insect,
      'acww_sep2_insect': acwwSep2Insect,
      'acww_oct_insect': acwwOctInsect,
      'acww_nov_insect': acwwNovInsect,
      'acww_dec_insect': acwwDecInsect,
      'accf_jan_fish': accfJanFish,
      'accf_feb_fish': accfFebFish,
      'accf_mar_fish': accfMarFish,
      'accf_apr_fish': accfAprFish,
      'accf_may_fish': accfMayFish,
      'accf_jun_fish': accfJunFish,
      'accf_jul_fish': accfJulFish,
      'accf_aug1_fish': accfAug1Fish,
      'accf_aug2_fish': accfAug2Fish,
      'accf_sep1_fish': accfSep1Fish,
      'accf_sep2_fish': accfSep2Fish,
      'accf_oct_fish': accfOctFish,
      'accf_nov_fish': accfNovFish,
      'accf_dec_fish': accfDecFish,
      'accf_jan_insect': accfJanInsect,
      'accf_feb_insect': accfFebInsect,
      'accf_mar_insect': accfMarInsect,
      'accf_apr_insect': accfAprInsect,
      'accf_may_insect': accfMayInsect,
      'accf_jun_insect': accfJunInsect,
      'accf_jul_insect': accfJulInsect,
      'accf_aug1_insect': accfAug1Insect,
      'accf_aug2_insect': accfAug2Insect,
      'accf_sep1_insect': accfSep1Insect,
      'accf_sep2_insect': accfSep2Insect,
      'accf_oct_insect': accfOctInsect,
      'accf_nov_insect': accfNovInsect,
      'accf_dec_insect': accfDecInsect,
      'acnl_jan_fish': acnlJanFish,
      'acnl_feb_fish': acnlFebFish,
      'acnl_mar_fish': acnlMarFish,
      'acnl_apr_fish': acnlAprFish,
      'acnl_may_fish': acnlMayFish,
      'acnl_jun_fish': acnlJunFish,
      'acnl_jul_fish': acnlJulFish,
      'acnl_aug1_fish': acnlAug1Fish,
      'acnl_aug2_fish': acnlAug2Fish,
      'acnl_sep1_fish': acnlSep1Fish,
      'acnl_sep2_fish': acnlSep2Fish,
      'acnl_oct_fish': acnlOctFish,
      'acnl_nov_fish': acnlNovFish,
      'acnl_dec_fish': acnlDecFish,
      'acnl_jan_insect': acnlJanInsect,
      'acnl_feb_insect': acnlFebInsect,
      'acnl_mar_insect': acnlMarInsect,
      'acnl_apr_insect': acnlAprInsect,
      'acnl_may_insect': acnlMayInsect,
      'acnl_jun_insect': acnlJunInsect,
      'acnl_jul_insect': acnlJulInsect,
      'acnl_aug1_insect': acnlAug1Insect,
      'acnl_aug2_insect': acnlAug2Insect,
      'acnl_sep1_insect': acnlSep1Insect,
      'acnl_sep2_insect': acnlSep2Insect,
      'acnl_oct_insect': acnlOctInsect,
      'acnl_nov_insect': acnlNovInsect,
      'acnl_dec_insect': acnlDecInsect,
      'acnl_jan_seafood': acnlJanSeafood,
      'acnl_feb_seafood': acnlFebSeafood,
      'acnl_mar_seafood': acnlMarSeafood,
      'acnl_apr_seafood': acnlAprSeafood,
      'acnl_may_seafood': acnlMaySeafood,
      'acnl_jun_seafood': acnlJunSeafood,
      'acnl_jul_seafood': acnlJulSeafood,
      'acnl_aug1_seafood': acnlAug1Seafood,
      'acnl_aug2_seafood': acnlAug2Seafood,
      'acnl_sep1_seafood': acnlSep1Seafood,
      'acnl_sep2_seafood': acnlSep2Seafood,
      'acnl_oct_seafood': acnlOctSeafood,
      'acnl_nov_seafood': acnlNovSeafood,
      'acnl_dec_seafood': acnlDecSeafood,
      'acgc_table': acgcTable,
      'acww_table': acwwTable,
      'accf_table': accfTable,
      'acnl_table': acnlTable,
      'acnh_table': acnhTable,
      'acnh_accessory': acnhAccessory,
      'acnh_art': acnhArt,
      'acnh_bag': acnhBag,
      'acnh_bottom': acnhBottom,
      'acnh_dress': acnhDress,
      'acnh_fencing': acnhFencing,
      'acnh_fish': acnhFish,
      'acnh_jan_fish': acnhJanFish,
      'acnh_feb_fish': acnhFebFish,
      'acnh_mar_fish': acnhMarFish,
      'acnh_apr_fish': acnhAprFish,
      'acnh_may_fish': acnhMayFish,
      'acnh_jun_fish': acnhJunFish,
      'acnh_jul_fish': acnhJulFish,
      'acnh_aug1_fish': acnhAug1Fish,
      'acnh_aug2_fish': acnhAug2Fish,
      'acnh_sep1_fish': acnhSep1Fish,
      'acnh_sep2_fish': acnhSep2Fish,
      'acnh_oct_fish': acnhOctFish,
      'acnh_nov_fish': acnhNovFish,
      'acnh_dec_fish': acnhDecFish,
      'acnh_flooring': acnhFlooring,
      'acnh_fossil': acnhFossil,
      'acnh_headwear': acnhHeadwear,
      'acnh_houseware': acnhHouseware,
      'acnh_misc': acnhMisc,
      'acnh_wall_mounted': acnhWallMounted,
      'acnh_ceiling': acnhCeiling,
      'acnh_interior': acnhInterior,
      'acnh_gyroid': acnhGyroid,
      'acnh_hybrid': acnhHybrid,
      'acnh_insect': acnhInsect,
      'acnh_jan_insect': acnhJanInsect,
      'acnh_feb_insect': acnhFebInsect,
      'acnh_mar_insect': acnhMarInsect,
      'acnh_apr_insect': acnhAprInsect,
      'acnh_may_insect': acnhMayInsect,
      'acnh_jun_insect': acnhJunInsect,
      'acnh_jul_insect': acnhJulInsect,
      'acnh_aug1_insect': acnhAug1Insect,
      'acnh_aug2_insect': acnhAug2Insect,
      'acnh_sep1_insect': acnhSep1Insect,
      'acnh_sep2_insect': acnhSep2Insect,
      'acnh_oct_insect': acnhOctInsect,
      'acnh_nov_insect': acnhNovInsect,
      'acnh_dec_insect': acnhDecInsect,
      'acnh_photo': acnhPhoto,
      'acnh_poster': acnhPoster,
      'acnh_recipe': acnhRecipe,
      'acnh_rug': acnhRug,
      'acnh_shoe': acnhShoe,
      'acnh_sock': acnhSock,
      'acnh_song': acnhSong,
      'acnh_tool': acnhTool,
      'acnh_top': acnhTop,
      'acnh_umbrella': acnhUmbrella,
      'acnh_wallpaper': acnhWallpaper,
      'acgc_furniture': acgcFurniture,
      'acnh_other_clothing': acnhOtherClothing,
      'acnh_sea_creature': acnhSeaCreature,
      'acnh_jan_sea_creature': acnhJanSeaCreature,
      'acnh_feb_sea_creature': acnhFebSeaCreature,
      'acnh_mar_sea_creature': acnhMarSeaCreature,
      'acnh_apr_sea_creature': acnhAprSeaCreature,
      'acnh_may_sea_creature': acnhMaySeaCreature,
      'acnh_jun_sea_creature': acnhJunSeaCreature,
      'acnh_jul_sea_creature': acnhJulSeaCreature,
      'acnh_aug1_sea_creature': acnhAug1SeaCreature,
      'acnh_aug2_sea_creature': acnhAug2SeaCreature,
      'acnh_sep1_sea_creature': acnhSep1SeaCreature,
      'acnh_sep2_sea_creature': acnhSep2SeaCreature,
      'acnh_oct_sea_creature': acnhOctSeaCreature,
      'acnh_nov_sea_creature': acnhNovSeaCreature,
      'acnh_dec_sea_creature': acnhDecSeaCreature,
    };
  }

  void updateData(String table, int index, bool selected) async {
    int s = boolToInt(selected);

    switch(table) {
      case 'acgc_carpet': { await update(acgcCarpet)
      ..where((tbl) => acgcCarpet.index.equals(index))
      ..write(AcgcCarpetData(selected: s));
      break; }
      case 'acgc_wallpaper': { await update(acgcWallpaper)
      ..where((tbl) => acgcWallpaper.index.equals(index))
      ..write(AcgcWallpaperData(selected: s));
      break; }
      case 'acgc_fish': { await update(acgcFish)
      ..where((tbl) => acgcFish.index.equals(index))
      ..write(AcgcFishData(selected: s));
      break; }
      case 'acgc_fossil': { await update(acgcFossil)
      ..where((tbl) => acgcFossil.index.equals(index))
      ..write(AcgcFossilData(selected: s));
      break; }
      case 'acgc_gyroid': { await update(acgcGyroid)
      ..where((tbl) => acgcGyroid.index.equals(index))
      ..write(AcgcGyroidData(selected: s));
      break; }
      case 'acgc_insect': { await update(acgcInsect)
      ..where((tbl) => acgcInsect.index.equals(index))
      ..write(AcgcInsectData(selected: s));
      break; }
      case 'acgc_shirt': { await update(acgcShirt)
      ..where((tbl) => acgcShirt.index.equals(index))
      ..write(AcgcShirtData(selected: s));
      break; }
      case 'acgc_song': { await update(acgcSong)
      ..where((tbl) => acgcSong.index.equals(index))
      ..write(AcgcSongData(selected: s));
      break; }
      case 'acgc_stationery': { await update(acgcStationery)
      ..where((tbl) => acgcStationery.index.equals(index))
      ..write(AcgcStationeryData(selected: s));
      break; }
      case 'acgc_tool': { await update(acgcTool)
      ..where((tbl) => acgcTool.index.equals(index))
      ..write(AcgcToolData(selected: s));
      break; }
      case 'acww_accessory': { await update(acwwAccessory)
      ..where((tbl) => acwwAccessory.index.equals(index))
      ..write(AcwwAccessoryData(selected: s));
      break; }
      case 'acww_carpet': { await update(acwwCarpet)
      ..where((tbl) => acwwCarpet.index.equals(index))
      ..write(AcwwCarpetData(selected: s));
      break; }
      case 'acww_fish': { await update(acwwFish)
      ..where((tbl) => acwwFish.index.equals(index))
      ..write(AcwwFishData(selected: s));
      break; }
      case 'acww_fossil': { await update(acwwFossil)
      ..where((tbl) => acwwFossil.index.equals(index))
      ..write(AcwwFossilData(selected: s));
      break; }
      case 'acww_furniture': { await update(acwwFurniture)
      ..where((tbl) => acwwFurniture.index.equals(index))
      ..write(AcwwFurnitureData(selected: s));
      break; }
      case 'acww_gyroid': { await update(acwwGyroid)
      ..where((tbl) => acwwGyroid.index.equals(index))
      ..write(AcwwGyroidData(selected: s));
      break; }
      case 'acww_insect': { await update(acwwInsect)
      ..where((tbl) => acwwInsect.index.equals(index))
      ..write(AcwwInsectData(selected: s));
      break; }
      case 'acww_shirt': { await update(acwwShirt)
      ..where((tbl) => acwwShirt.index.equals(index))
      ..write(AcwwShirtData(selected: s));
      break; }
      case 'acww_song': { await update(acwwSong)
      ..where((tbl) => acwwSong.index.equals(index))
      ..write(AcwwSongData(selected: s));
      break; }
      case 'acww_stationery': { await update(acwwStationery)
      ..where((tbl) => acwwStationery.index.equals(index))
      ..write(AcwwStationeryData(selected: s));
      break; }
      case 'acww_tool': { await update(acwwTool)
      ..where((tbl) => acwwTool.index.equals(index))
      ..write(AcwwToolData(selected: s));
      break; }
      case 'acww_wallpaper': { await update(acwwWallpaper)
      ..where((tbl) => acwwWallpaper.index.equals(index))
      ..write(AcwwWallpaperData(selected: s));
      break; }
      case 'accf_accessory': { await update(accfAccessory)
      ..where((tbl) => accfAccessory.index.equals(index))
      ..write(AccfAccessoryData(selected: s));
      break; }
      case 'accf_carpet': { await update(accfCarpet)
      ..where((tbl) => accfCarpet.index.equals(index))
      ..write(AccfCarpetData(selected: s));
      break; }
      case 'accf_fossil': { await update(accfFossil)
      ..where((tbl) => accfFossil.index.equals(index))
      ..write(AccfFossilData(selected: s));
      break; }
      case 'accf_fish': { await update(accfFish)
      ..where((tbl) => accfFish.index.equals(index))
      ..write(AccfFishData(selected: s));
      break; }
      case 'accf_furniture': { await update(accfFurniture)
      ..where((tbl) => accfFurniture.index.equals(index))
      ..write(AccfFurnitureData(selected: s));
      break; }
      case 'accf_gyroid': { await update(accfGyroid)
      ..where((tbl) => accfGyroid.index.equals(index))
      ..write(AccfGyroidData(selected: s));
      break; }
      case 'accf_insect': { await update(accfInsect)
      ..where((tbl) => accfInsect.index.equals(index))
      ..write(AccfInsectData(selected: s));
      break; }
      case 'accf_painting': { await update(accfPainting)
      ..where((tbl) => accfPainting.index.equals(index))
      ..write(AccfPaintingData(selected: s));
      break; }
      case 'accf_shirt': { await update(accfShirt)
      ..where((tbl) => accfShirt.index.equals(index))
      ..write(AccfShirtData(selected: s));
      break; }
      case 'accf_song': { await update(accfSong)
      ..where((tbl) => accfSong.index.equals(index))
      ..write(AccfSongData(selected: s));
      break; }
      case 'accf_stationery': { await update(accfStationery)
      ..where((tbl) => accfStationery.index.equals(index))
      ..write(AccfStationeryData(selected: s));
      break; }
      case 'accf_tool': { await update(accfTool)
      ..where((tbl) => accfTool.index.equals(index))
      ..write(AccfToolData(selected: s));
      break; }
      case 'accf_wallpaper': { await update(accfWallpaper)
      ..where((tbl) => accfWallpaper.index.equals(index))
      ..write(AccfWallpaperData(selected: s));
      break; }
      case 'acnl_accessory': { await update(acnlAccessory)
      ..where((tbl) => acnlAccessory.index.equals(index))
      ..write(AcnlAccessoryData(selected: s));
      break; }
      case 'acnl_art': { await update(acnlArt)
      ..where((tbl) => acnlArt.index.equals(index))
      ..write(AcnlArtData(selected: s));
      break; }
      case 'acnl_bottom': { await update(acnlBottom)
      ..where((tbl) => acnlBottom.index.equals(index))
      ..write(AcnlBottomData(selected: s));
      break; }
      case 'acnl_carpet': { await update(acnlCarpet)
      ..where((tbl) => acnlCarpet.index.equals(index))
      ..write(AcnlCarpetData(selected: s));
      break; }
      case 'acnl_dlc': { await update(acnlDlc)
      ..where((tbl) => acnlDlc.index.equals(index))
      ..write(AcnlDlcData(selected: s));
      break; }
      case 'acnl_dress': { await update(acnlDress)
      ..where((tbl) => acnlDress.index.equals(index))
      ..write(AcnlDres(selected: s));
      break; }
      case 'acnl_feet': { await update(acnlFeet)
      ..where((tbl) => acnlFeet.index.equals(index))
      ..write(AcnlFeetData(selected: s));
      break; }
      case 'acnl_fish': { await update(acnlFish)
      ..where((tbl) => acnlFish.index.equals(index))
      ..write(AcnlFishData(selected: s));
      break; }
      case 'acnl_fossil': { await update(acnlFossil)
      ..where((tbl) => acnlFossil.index.equals(index))
      ..write(AcnlFossilData(selected: s));
      break; }
      case 'acnl_fossil_model': { await update(acnlFossilModel)
      ..where((tbl) => acnlFossilModel.index.equals(index))
      ..write(AcnlFossilModelData(selected: s));
      break; }
      case 'acnl_furniture': { await update(acnlFurniture)
      ..where((tbl) => acnlFurniture.index.equals(index))
      ..write(AcnlFurnitureData(selected: s));
      break; }
      case 'acnl_gyroid': { await update(acnlGyroid)
      ..where((tbl) => acnlGyroid.index.equals(index))
      ..write(AcnlGyroidData(selected: s));
      break; }
      case 'acnl_hat': { await update(acnlHat)
      ..where((tbl) => acnlHat.index.equals(index))
      ..write(AcnlHatData(selected: s));
      break; }
      case 'acnl_insect': { await update(acnlInsect)
      ..where((tbl) => acnlInsect.index.equals(index))
      ..write(AcnlInsectData(selected: s));
      break; }
      case 'acnl_music_box': { await update(acnlMusicBox)
      ..where((tbl) => acnlMusicBox.index.equals(index))
      ..write(AcnlMusicBoxData(selected: s));
      break; }
      case 'acnl_seafood': { await update(acnlSeafood)
      ..where((tbl) => acnlSeafood.index.equals(index))
      ..write(AcnlSeafoodData(selected: s));
      break; }
      case 'acnl_shirt': { await update(acnlShirt)
      ..where((tbl) => acnlShirt.index.equals(index))
      ..write(AcnlShirtData(selected: s));
      break; }
      case 'acnl_song': { await update(acnlSong)
      ..where((tbl) => acnlSong.index.equals(index))
      ..write(AcnlSongData(selected: s));
      break; }
      case 'acnl_stationery': { await update(acnlStationery)
      ..where((tbl) => acnlStationery.index.equals(index))
      ..write(AcnlStationeryData(selected: s));
      break; }
      case 'acnl_tool': { await update(acnlTool)
      ..where((tbl) => acnlTool.index.equals(index))
      ..write(AcnlToolData(selected: s));
      break; }
      case 'acnl_villager_picture': { await update(acnlVillagerPicture)
      ..where((tbl) => acnlVillagerPicture.index.equals(index))
      ..write(AcnlVillagerPictureData(selected: s));
      break; }
      case 'acnl_wallpaper': { await update(acnlWallpaper)
      ..where((tbl) => acnlWallpaper.index.equals(index))
      ..write(AcnlWallpaperData(selected: s));
      break; }
      case 'acnl_wet_suit': { await update(acnlWetSuit)
      ..where((tbl) => acnlWetSuit.index.equals(index))
      ..write(AcnlWetSuitData(selected: s));
      break; }
      case 'acnh_accessory': { await update(acnhAccessory)
      ..where((tbl) => acnhAccessory.index.equals(index))
      ..write(AcnhAccessoryData(selected: s));
      break; }
      case 'acnh_art': { await update(acnhArt)
      ..where((tbl) => acnhArt.index.equals(index))
      ..write(AcnhArtData(selected: s));
      break; }
      case 'acnh_bag': { await update(acnhBag)
      ..where((tbl) => acnhBag.index.equals(index))
      ..write(AcnhBagData(selected: s));
      break; }
      case 'acnh_bottom': { await update(acnhBottom)
      ..where((tbl) => acnhBottom.index.equals(index))
      ..write(AcnhBottomData(selected: s));
      break; }
      case 'acnh_dress': { await update(acnhDress)
      ..where((tbl) => acnhDress.index.equals(index))
      ..write(AcnhDres(selected: s));
      break; }
      case 'acnh_fencing': { await update(acnhFencing)
      ..where((tbl) => acnhFencing.index.equals(index))
      ..write(AcnhFencingData(selected: s));
      break; }
      case 'acnh_fish': { await update(acnhFish)
      ..where((tbl) => acnhFish.index.equals(index))
      ..write(AcnhFishData(selected: s));
      break; }
      case 'acnh_flooring': { await update(acnhFlooring)
      ..where((tbl) => acnhFlooring.index.equals(index))
      ..write(AcnhFlooringData(selected: s));
      break; }
      case 'acnh_fossil': { await update(acnhFossil)
      ..where((tbl) => acnhFossil.index.equals(index))
      ..write(AcnhFossilData(selected: s));
      break; }
      case 'acnh_headwear': { await update(acnhHeadwear)
      ..where((tbl) => acnhHeadwear.index.equals(index))
      ..write(AcnhHeadwearData(selected: s));
      break; }
      case 'acnh_houseware': { await update(acnhHouseware)
      ..where((tbl) => acnhHouseware.index.equals(index))
      ..write(AcnhHousewareData(selected: s));
      break; }
      case 'acnh_misc': { await update(acnhMisc)
      ..where((tbl) => acnhMisc.index.equals(index))
      ..write(AcnhMiscData(selected: s));
      break; }
      case 'acnh_wall_mounted': { await update(acnhWallMounted)
      ..where((tbl) => acnhWallMounted.index.equals(index))
      ..write(AcnhWallMountedData(selected: s));
      break; }
      case 'acnh_ceiling': { await update(acnhCeiling)
      ..where((tbl) => acnhCeiling.index.equals(index))
      ..write(AcnhCeilingData(selected: s));
      break; }
      case 'acnh_interior': { await update(acnhInterior)
      ..where((tbl) => acnhInterior.index.equals(index))
      ..write(AcnhInteriorData(selected: s));
      break; }
      case 'acnh_gyroid': { await update(acnhGyroid)
      ..where((tbl) => acnhGyroid.index.equals(index))
      ..write(AcnhGyroidData(selected: s));
      break; }
      case 'acnh_hybrid': { await update(acnhHybrid)
      ..where((tbl) => acnhHybrid.index.equals(index))
      ..write(AcnhHybridData(selected: s));
      break; }
      case 'acnh_insect': { await update(acnhInsect)
      ..where((tbl) => acnhInsect.index.equals(index))
      ..write(AcnhInsectData(selected: s));
      break; }
      case 'acnh_photo': { await update(acnhPhoto)
      ..where((tbl) => acnhPhoto.index.equals(index))
      ..write(AcnhPhotoData(selected: s));
      break; }
      case 'acnh_poster': { await update(acnhPoster)
      ..where((tbl) => acnhPoster.index.equals(index))
      ..write(AcnhPosterData(selected: s));
      break; }
      case 'acnh_recipe': { await update(acnhRecipe)
      ..where((tbl) => acnhRecipe.index.equals(index))
      ..write(AcnhRecipeData(selected: s));
      break; }
      case 'acnh_rug': { await update(acnhRug)
      ..where((tbl) => acnhRug.index.equals(index))
      ..write(AcnhRugData(selected: s));
      break; }
      case 'acnh_shoe': { await update(acnhShoe)
      ..where((tbl) => acnhShoe.index.equals(index))
      ..write(AcnhShoeData(selected: s));
      break; }
      case 'acnh_sock': { await update(acnhSock)
      ..where((tbl) => acnhSock.index.equals(index))
      ..write(AcnhSockData(selected: s));
      break; }
      case 'acnh_song': { await update(acnhSong)
      ..where((tbl) => acnhSong.index.equals(index))
      ..write(AcnhSongData(selected: s));
      break; }
      case 'acnh_tool': { await update(acnhTool)
      ..where((tbl) => acnhTool.index.equals(index))
      ..write(AcnhToolData(selected: s));
      break; }
      case 'acnh_top': { await update(acnhTop)
      ..where((tbl) => acnhTop.index.equals(index))
      ..write(AcnhTopData(selected: s));
      break; }
      case 'acnh_umbrella': { await update(acnhUmbrella)
      ..where((tbl) => acnhUmbrella.index.equals(index))
      ..write(AcnhUmbrellaData(selected: s));
      break; }
      case 'acnh_wallpaper': { await update(acnhWallpaper)
      ..where((tbl) => acnhWallpaper.index.equals(index))
      ..write(AcnhWallpaperData(selected: s));
      break; }
      case 'acgc_furniture': { await update(acgcFurniture)
      ..where((tbl) => acgcFurniture.index.equals(index))
      ..write(AcgcFurnitureData(selected: s));
      break; }
      case 'acnh_other_clothing': { await update(acnhOtherClothing)
      ..where((tbl) => acnhOtherClothing.index.equals(index))
      ..write(AcnhOtherClothingData(selected: s));
      break; }
      case 'acnh_sea_creature': { await update(acnhSeaCreature)
      ..where((tbl) => acnhSeaCreature.index.equals(index))
      ..write(AcnhSeaCreatureData(selected: s));
      break; }
    }
  }
}
