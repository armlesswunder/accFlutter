import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'MyDB.dart';
import 'audit.dart';
import 'data.dart';
import 'main.dart';

String cellWidthKey(String type) => '${type}_CELL_WIDTH_BASELINE';

String getAuditTimestamp(DateTime time) {
  var formatter = DateFormat('MM/dd/yyyy hh:mm:ss');
  var stringDate = formatter.format(time);
  return stringDate;
  //return "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} - ${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')}";
}

Future<void> saveFile(String data) async {
  String timestamp = getTimestamp();
  String filePath = '';

  if (isMobile()) {
    final directory = await getApplicationDocumentsDirectory();
    var d = Directory(directory.path);
    var c = await d.exists();
    if (!c) {
      await d.create();
    }
    File file = File('${d.path}/acc$timestamp.acb');
    await writeFile(file.path, data);
    await Share.shareFiles([file.path]);
  } else {
    final documentsDir = await getApplicationDocumentsDirectory();
    var result = await FilePicker.platform.saveFile(
        initialDirectory: documentsDir.path,
        type: FileType.custom,
        allowedExtensions: ['acb']);
    if (result != null) {
      filePath = result;
      File file = File(filePath + '.acb');
      await file.create();
      await file.writeAsString(data);
      SnackBar(
        content: Text('Saved file: $filePath'),
      );
    }
  }
}

Color getCardColor(Map<String, dynamic> data) {
  var basicColor = !darkMode
      ? const Color.fromARGB(240, 255, 255, 255)
      : const Color.fromARGB(255, 38, 38, 38);
  if (!critterColors || data["PresentNextMonth"] == null) {
    return basicColor;
  } else if (data["PresentNextMonth"] == false) {
    return const Color.fromARGB(128, 255, 118, 118);
  } else if (data["PresentPreviousMonth"] == false) {
    return const Color.fromARGB(128, 127, 255, 133);
  } else {
    return basicColor;
  }
}

void addAuditData(Map<String, dynamic> data) {
  insertAuditData(data['Type'], data['Index'], data['Selected'] == 1);
}

void updateFromAuditData(Map<String, dynamic> data, bool selected) {
  for (var el in masterList) {
    if (el['Index'] == data['Index'] && el['Type'] == data['Type']) {
      el['Selected'] = selected ? 1 : 0;
    }
  }
  db1!.updateData(data['Type'], data['Index'], selected);
  filter(text: controller.text);
}

Color getInfoIconColor(String? status) {
  switch (status) {
    case null:
      return darkMode ? Colors.white60 : Colors.black38;
    case "unorderable":
      return Colors.orange;
    default:
      return Colors.green;
  }
}

String getTimestamp() {
  DateTime d = DateTime.now();
  var y = d.year;
  var m = d.month.toString().padLeft(2, '0');
  var dd = d.day.toString().padLeft(2, '0');
  var h = d.hour.toString().padLeft(2, '0');
  var mm = d.minute.toString().padLeft(2, '0');
  var s = d.second.toString().padLeft(2, '0');
  return '$y$m$dd$h$mm$s';
}

void openURL(Uri url) async {
  try {
    await launchUrl(url);
  } catch (err) {
    print(err);
  }
}

Future clearCache() async {
  if (Platform.isWindows) return;
  final directory = await getApplicationDocumentsDirectory();
  var d = Directory(directory.path);
  var c = await d.exists();
  if (!c) {
    await d.create();
  }
  var fileList = d.listSync();
  for (var element in fileList) {
    var s = element.path;
    if (s.endsWith('.acb')) {
      File(s).deleteSync();
    }
  }
}

void openFile() async {
  final documentsDir = await getApplicationDocumentsDirectory();
  FilePickerResult? result;
  if (Platform.isWindows) {
    result = await FilePicker.platform.pickFiles(
        initialDirectory: documentsDir.path,
        type: FileType.custom,
        allowedExtensions: ['acb', 'sql']);
  } else {
    result = await FilePicker.platform
        .pickFiles(initialDirectory: documentsDir.path);
  }
  if (result != null) {
    String? path = result.files.single.path;
    await loadFile(path!);
    initialLoad();
  } else {
    // User canceled the picker
  }
}

Future getPrefs() async {
  prefs = await SharedPreferences.getInstance();
  game = prefs?.getString("game") ?? defaultGame;
  type = prefs?.getString("type") ?? defaultType;
  oldVersion = prefs?.getInt("dbVersion") ?? dbVersion;
  from = prefs?.getString("${game + type}From") ?? "";

  selectedFilter =
      prefs?.getInt("${game + type}SelectedFilter") ?? FILTER_SELECTED_ALL;
  selectedMonth = useCurrentDate
      ? getCurrentMonth()
      : prefs?.getInt("${game + type}SelectedMonth") ?? 0;

  darkMode = prefs?.getBool("darkMode") ?? false;
  critterColors = prefs?.getBool("critterColors") ?? true;
  useCurrentDate = prefs?.getBool("useCurrentDate") ?? false;

  var gameIndex = prefixList.indexOf(game);
  gameDisplay = gamesList[gameIndex];
  getAuditData(type);
}

int getCurrentMonth() {
  DateTime now = DateTime.now();
  int month = now.month;
  int day = now.day;
  //month++;
  //august
  if (month == 8) {
    if (day > 15) {
      month++;
    }
  } else if (month == 9) {
    month++;
    if (day > 15) {
      month++;
    }
  } else if (month > 9) {
    month += 2;
  }
  return month;
  /*
    if (useCurrentSeason) {
      seasonIndex = thisSeason
      selectedSeasonIndex = seasonIndex
    }
    else {
      seasonIndex = selectedSeasonIndex
    }
     */
}

String getTable() {
  return game + type;
}

void getVersion() async {
  PackageInfo packageInfo = await PackageInfo.fromPlatform();
  String version = packageInfo.version;
  String code = packageInfo.buildNumber;
  versionStr = '$version ($code)';
}

Future<void> initializeTypes() async {
  acgcTables = await db1!.getTableData('acgc_table');
  acwwTables = await db1!.getTableData('acww_table');
  accfTables = await db1!.getTableData('accf_table');
  acnlTables = await db1!.getTableData('acnl_table');
  acnhTables = await db1!.getTableData('acnh_table');
  typeTables = <List<String>>[
    acgcTables,
    acwwTables,
    accfTables,
    acnlTables,
    acnhTables
  ];
  typeTable = typeTables[prefixList.indexOf(game)];
}

List<String> seasonalTypes = <String>[
  "sea_creature",
  "seafood",
  "fish",
  "insect"
];

bool isSeasonalType(String table) {
  for (String type in seasonalTypes) {
    if (table.contains(type)) return true;
  }
  return false;
}

Future<void> getData({bool refreshPrefs = true}) async {
  List<Map<String, dynamic>> r;
  if (refreshPrefs) {
    await getPrefs();
  }
  if (isSeasonalType(type) && selectedMonth > 0) {
    r = await db1!.getSeasonalData(
        game, type, monthValues[selectedMonth], selectedMonth, monthValues);
  } else {
    r = await db1!.getData(game, type);
  }
  masterList.clear();
  displayList.clear();
  fromList.clear();
  masterList.addAll(r);
  displayList.addAll(masterList);
  for (var data in masterList) {
    if (data["From"] != null) {
      fromList.add(data["From"]);
    }
  }
  filter(text: controller.value.text);
}

void filter({String text = '', bool resetScroll = true}) {
  displayList = <Map<String, dynamic>>[];
  for (int i = 0; i < masterList.length; i++) {
    if (masterList[i]['Name']
        .toString()
        .toUpperCase()
        .replaceAll('-', ' ')
        .contains(text.toUpperCase().replaceAll('-', ' '))) {
      if (masterList[i]['From'] == null ||
          masterList[i]['From']
              .toString()
              .toUpperCase()
              .replaceAll('-', ' ')
              .contains(from.toUpperCase().replaceAll('-', ' '))) {
        displayList.add(masterList[i]);
      }
    }
  }

  if (selectedFilter > 0) {
    if (selectedFilter == FILTER_SELECTED_CHECKED) {
      displayList.removeWhere((element) => element['Selected'] == 0);
    } else {
      displayList.removeWhere((element) => element['Selected'] == 1);
    }
  }
  if (resetScroll) {
    cachePosition = 0.0;
  }
  mSetState();
}

Future<void> showConfirmDialog(BuildContext context, Function callback,
    {String title = 'Confirm', String content = 'Are you sure?'}) async {
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: Text(title),
        actions: <Widget>[
          TextButton(
            child: const Text('OK', style: TextStyle(color: Colors.white70)),
            onPressed: () {
              Navigator.of(context).pop();
              callback.call();
            },
          ),
          TextButton(
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white70),
            ),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}

void mSetState() {
  mainState!(() {
    Timer(const Duration(milliseconds: 50),
        () => listController.jumpTo(cachePosition));
  });
}

void initialLoad() async {
  initDirs();
  //notifier.value = ThemeMode.dark;
}

Future loadFile(String path) async {
  if (path.isEmpty) return;
  try {
    File file = File(path);
    var s = file.openRead().map(utf8.decode);
    var str = '';
    await s.forEach((element) {
      str += element;
    });
    // its safe to assume this is sql update data
    if (str.contains('update') &&
        str.contains('set') &&
        str.contains('where')) {
      var dataList = str.split('\n');
      for (int i = 0; i < dataList.length; i++) {
        var element = dataList[i];
        if (element.contains('version=')) continue;
        if (element.trim().isEmpty) continue;
        db1?.rawUpdate(element);
      }
      //otherwise we'll assume its the newer version of update data
    } else {
      var dataList = str.split('\n');
      for (int i = 0; i < dataList.length; i++) {
        var element = dataList[i];
        if (element.trim().isEmpty || !element.contains(':')) continue;
        var arr = element.split(':');
        var table = arr[0];
        var index = arr[1];
        db1?.updateData(table, int.parse(index), true);
      }
    }
  } catch (err) {
    print(err);
  }
}

Future writeFile(String path, String data) {
  File file = File(path);
  return file.writeAsString(data);
}

bool isMobile() {
  return Platform.isAndroid || Platform.isIOS;
}
