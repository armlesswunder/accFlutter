import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:animal_crossing_catalog_flutter/MyDatabase.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

const guideURL = "https://github.com/armlesswunder/accFlutter#guide";
const faqURL = "https://github.com/armlesswunder/accFlutter#faq";
const mySiteURL = "https://armlesswunder.github.io/";

bool darkMode = true;

ThemeData lightTheme = ThemeData(
    primarySwatch: Colors.green,
    scaffoldBackgroundColor: Colors.white,
    dialogBackgroundColor: Colors.white,
    canvasColor: Colors.white,
    hintColor: Colors.white70,
    unselectedWidgetColor: Colors.black87,
    textTheme: const TextTheme(
      bodyText1: TextStyle(),
      bodyText2: TextStyle(),
      button: TextStyle(),
    ).apply(
      bodyColor: Colors.black87,
      displayColor: Colors.black87,
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: Colors.white10,
      iconColor: Colors.black87,
      hintStyle: TextStyle(color: Colors.black87),
      labelStyle: TextStyle(color: Colors.black87),
    ));

ThemeData darkTheme = ThemeData(
    primarySwatch: Colors.deepOrange,
    scaffoldBackgroundColor: Colors.black87,
    dialogBackgroundColor: Colors.grey,
    canvasColor: Colors.black,
    hintColor: Colors.black87,
    unselectedWidgetColor: Colors.white70,
    textTheme: const TextTheme(
      bodyText1: TextStyle(),
      bodyText2: TextStyle(),
      button: TextStyle(),
    ).apply(
      bodyColor: Colors.white70,
      displayColor: Colors.white70,
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey,
      iconColor: Colors.white70,
      hintStyle: TextStyle(color: Colors.white70),
      labelStyle: TextStyle(color: Colors.white70),
    ));

final ValueNotifier<ThemeMode> _notifier = ValueNotifier(ThemeMode.light);

List<String> acgcTables = <String>[];
List<String> acwwTables = <String>[];
List<String> accfTables = <String>[];
List<String> acnlTables = <String>[];
List<String> acnhTables = <String>[];

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
        valueListenable: _notifier,
        builder: (_, mode, __) {
          return MaterialApp(
            title: 'Animal Crossing Catalog',
            theme: lightTheme,
            darkTheme: darkTheme,
            themeMode: mode,
            home: const MyHomePage(title: 'Animal Crossing Catalog'),
          );
        });
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  MyDatabase? db;
  SharedPreferences? prefs;
  List<Map<String, dynamic>> masterList = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> displayList = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> auditList = <Map<String, dynamic>>[];

  List<String> prefixList = <String>[
    'acgc_',
    'acww_',
    'accf_',
    'acnl_',
    'acnh_'
  ];
  List<String> gamesList = <String>[
    'Gamecube',
    'Wild World',
    'City Folk',
    'New Leaf',
    'New Horizons'
  ];
  List<String> monthDisplay = <String>[
    "(no filter)",
    "January",
    "February",
    "March",
    "April",
    "May",
    "June",
    "July",
    "August - 1st Half",
    "August - 2nd Half",
    "September - 1st Half",
    "September - 2nd Half",
    "October",
    "November",
    "December"
  ];
  List<String> monthValues = <String>[
    "",
    "jan_",
    "feb_",
    "mar_",
    "apr_",
    "may_",
    "jun_",
    "jul_",
    "aug1_",
    "aug2_",
    "sep1_",
    "sep2_",
    "oct_",
    "nov_",
    "dec_"
  ];
  int selectedMonth = 0;

  List<List<String>> typeTables = <List<String>>[];
  List<String> typeTable = <String>[];
  List<String> fromList = <String>[];

  static const String defaultGame = "acnh_";
  static const String defaultType = "houseware";

  static const List<String> filterSelectedChoices = [
    'All Items',
    'Unchecked Items',
    'Checked Items'
  ];

  static const int FILTER_SELECTED_ALL = 0;
  static const int FILTER_SELECTED_UNCHECKED = 1;
  static const int FILTER_SELECTED_CHECKED = 2;

  String game = defaultGame;
  String gameDisplay = "New Horizons";
  String type = defaultType;
  String from = "";
  String versionStr = '[Unknown Version]';

  int selectedFilter = FILTER_SELECTED_ALL;

  final TextEditingController _controller = TextEditingController();
  final ScrollController _listController = ScrollController();

  bool critterColors = true;
  bool useCurrentDate = false;

  @override
  void initState() {
    db = MyDatabase();
    initialLoad();
    super.initState();
  }

  void initialLoad() async {
    _listController.addListener(_ScrollPosition);
    await getPrefs();
    await initializeTypes();
    await getData();
    getVersion();
    clearCache();
    //_notifier.value = ThemeMode.dark;
  }

  Future getPrefs() async {
    prefs = await SharedPreferences.getInstance();
    game = prefs?.getString("game") ?? defaultGame;
    type = prefs?.getString("type") ?? defaultType;
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
    acgcTables = await db!.getTableData('acgc_table');
    acwwTables = await db!.getTableData('acww_table');
    accfTables = await db!.getTableData('accf_table');
    acnlTables = await db!.getTableData('acnl_table');
    acnhTables = await db!.getTableData('acnh_table');
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
      r = await db!.getSeasonalData(
          game, type, monthValues[selectedMonth], selectedMonth, monthValues);
    } else {
      r = await db!.getData(game, type);
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
    filter(text: _controller.value.text);
  }

  double cachePosition = 0.0;

  _ScrollPosition() async {
    cachePosition = _listController.position.pixels;
  }

  void mSetState() {
    setState(() {
      Timer(const Duration(milliseconds: 50),
          () => _listController.jumpTo(cachePosition));
    });
  }

  void onSearchChanged(String text) async {
    filter(text: text);
  }

  void onFromSearchChanged(String text) async {
    from = text;
    filter(text: _controller.text);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: darkMode ? Colors.black87 : Colors.white,
        appBar: AppBar(
          backgroundColor: darkMode
              ? const Color.fromARGB(255, 0, 0, 0)
              : const Color.fromARGB(255, 0, 50, 0),
          toolbarHeight: 0.0,
        ),
        body: Column(
          children: <Widget>[
            Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      gameDropDown(),
                      IconButton(
                        icon: const Icon(Icons.settings),
                        color: darkMode ? Colors.white60 : Colors.green,
                        tooltip: 'Settings',
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute<void>(
                            builder: (BuildContext context) {
                              return Theme(
                                data: darkMode ? darkTheme : lightTheme,
                                child: getSettingsScreen(),
                              );
                            },
                          ));
                        },
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      typeDropDown(),
                      IconButton(
                        icon: const Icon(Icons.search),
                        color: darkMode ? Colors.white60 : Colors.green,
                        tooltip: 'Filter',
                        onPressed: () {
                          showDialog(
                              context: context,
                              builder: (BuildContext context) =>
                                  getFilterDialog());
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: TextField(
                style: TextStyle(color: darkMode ? Colors.white : Colors.black),
                controller: _controller,
                onChanged: onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Name',
                  hintStyle:
                      TextStyle(color: darkMode ? Colors.white : Colors.black),
                  prefixIcon: Icon(
                    Icons.search,
                    color: darkMode ? Colors.white : Colors.black,
                  ),
                  suffixIcon: IconButton(
                    onPressed: () {
                      _controller.text = "";
                      onSearchChanged("");
                    },
                    icon: Icon(Icons.clear,
                        color: darkMode ? Colors.white : Colors.black),
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
            Expanded(
              key: UniqueKey(),
              child: Scrollbar(
                thumbVisibility: isMobile() ? false : true,
                thickness: isMobile() ? 0.0 : 16.0,
                controller: _listController,
                child: ListView.builder(
                    controller: _listController,
                    itemCount: displayList.length,
                    itemBuilder: (BuildContext context, int index) {
                      return Card(
                          margin: const EdgeInsets.all(4.0),
                          color: getCardColor(displayList[index]),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                flex: isMobile() ? 70 : 80,
                                child: Container(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Center(
                                    child: Text(
                                      displayList[index]['Name'],
                                      style: TextStyle(
                                          color: (darkMode
                                              ? Colors.white60
                                              : Colors.black87)),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: isMobile() ? 10 : 10,
                                child: Container(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: IconButton(
                                    icon: const Icon(Icons.info),
                                    color: getInfoIconColor(
                                        displayList[index]['Status']),
                                    tooltip: 'More Info',
                                    onPressed: () {
                                      showDialog(
                                          context: context,
                                          builder: (BuildContext context) =>
                                              getInfoDialog(
                                                  displayList[index]));
                                    },
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: isMobile() ? 20 : 10,
                                child: Container(
                                    padding: const EdgeInsets.all(8.0),
                                    child: StatefulBuilder(
                                      builder: (BuildContext context,
                                          void Function(void Function())
                                              setState) {
                                        return Theme(
                                            data: darkMode
                                                ? darkTheme
                                                : lightTheme,
                                            child: Checkbox(
                                              value: displayList[index]
                                                      ['Selected'] ==
                                                  1,
                                              onChanged: (bool? value) {
                                                db!.updateData(
                                                    displayList[index]['Type'],
                                                    displayList[index]['Index'],
                                                    value!);
                                                var data = displayList[index];
                                                final now = DateTime.now();
                                                data['updatedAt'] = now;
                                                addAuditData(data);
                                                displayList[index]['Selected'] =
                                                    value ? 1 : 0;
                                                if (selectedFilter !=
                                                    FILTER_SELECTED_ALL) {
                                                  filter(resetScroll: false);
                                                } else {
                                                  setState(() {});
                                                }
                                              },
                                            ));
                                      },
                                    )),
                              ),
                            ],
                          ));
                    }),
              ),
            )
          ],
        ));
  }

  void addAuditData(Map<String, dynamic> data) {
    auditList.removeWhere((element) => element['Index'] == data['Index']);
    auditList.add(data);
  }

  void updateFromAuditData(Map<String, dynamic> data) {
    for (var el in masterList) {
      if (el['Index'] == data['Index'] && el['Type'] == data['Type']) {
        el['Selected'] = data['Selected'];
      }
    }
    db!.updateData(data['Type'], data['Index'], data['Selected'] == 1);
    filter(text: _controller.text);
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

  Widget getSettingsScreen() {
    return StatefulBuilder(builder: (BuildContext context, StateSetter state) {
      return Scaffold(
          appBar: AppBar(
            backgroundColor: (darkMode ? Colors.white10 : Colors.green),
            title: Text(
              'Settings',
              style: TextStyle(
                  color: (darkMode ? Colors.white60 : Colors.white70)),
            ),
          ),
          body: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 8,
                    child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          'Dark Mode: ',
                          style: TextStyle(
                              color:
                                  (darkMode ? Colors.white60 : Colors.black87)),
                        )),
                  ),
                  Expanded(
                      flex: 2,
                      child: Checkbox(
                        value: darkMode,
                        onChanged: (bool? value) {
                          prefs?.setBool('darkMode', value ??= false);
                          darkMode = value ??= false;
                          _notifier.value =
                              darkMode ? ThemeMode.dark : ThemeMode.light;
                          state(() {});
                          setState(() {});
                        },
                      ))
                ],
              ),
              Row(
                children: [
                  Expanded(
                    flex: 8,
                    child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          'Use Current Date: ',
                          style: TextStyle(
                              color:
                                  (darkMode ? Colors.white60 : Colors.black87)),
                        )),
                  ),
                  Expanded(
                      flex: 2,
                      child: Checkbox(
                        value: useCurrentDate,
                        onChanged: (bool? value) {
                          prefs?.setBool('useCurrentDate', value ??= true);
                          useCurrentDate = value ??= false;
                          state(() {});
                          setState(() {});
                        },
                      ))
                ],
              ),
              Row(
                children: [
                  Expanded(
                    flex: 8,
                    child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          'Critter Warning Colors: ',
                          style: TextStyle(
                              color:
                                  (darkMode ? Colors.white60 : Colors.black87)),
                        )),
                  ),
                  Expanded(
                      flex: 2,
                      child: Checkbox(
                        value: critterColors,
                        onChanged: (bool? value) {
                          prefs?.setBool('critterColors', value ??= false);
                          critterColors = value ??= false;
                          state(() {});
                          setState(() {});
                        },
                      ))
                ],
              ),
              TextButton(
                  onPressed: () async {
                    var s = await db?.backupData();
                    if (s != null) {
                      saveFile(s);
                    }
                  },
                  child: Text(
                    'Export Data',
                    style: TextStyle(
                        color: darkMode ? Colors.white70 : Colors.deepOrange),
                    textAlign: TextAlign.center,
                  )),
              TextButton(
                  onPressed: () {
                    openFile();
                  },
                  child: Text(
                    'Import Data',
                    style: TextStyle(
                        color: darkMode ? Colors.white70 : Colors.deepOrange),
                    textAlign: TextAlign.center,
                  )),
              TextButton(
                  onPressed: () {
                    openURL(Uri.parse(guideURL));
                  },
                  child: const Text(
                    'Guide',
                    style: TextStyle(color: Colors.green),
                    textAlign: TextAlign.center,
                  )),
              TextButton(
                  onPressed: () {
                    openURL(Uri.parse(faqURL));
                  },
                  child: const Text(
                    'FAQ',
                    style: TextStyle(color: Colors.green),
                    textAlign: TextAlign.center,
                  )),
              TextButton(
                  onPressed: () {
                    openURL(Uri.parse(mySiteURL));
                  },
                  child: Text(
                    'My Site',
                    style: TextStyle(
                        color: darkMode ? Colors.white70 : Colors.deepOrange),
                    textAlign: TextAlign.center,
                  )),
              TextButton(
                  onPressed: () {
                    showDialog(
                        context: context,
                        builder: (BuildContext context) => getProgressDialog());
                  },
                  child: Text(
                    'Progress',
                    style: TextStyle(
                        color: darkMode ? Colors.white70 : Colors.deepOrange),
                    textAlign: TextAlign.center,
                  )),
              TextButton(
                  onPressed: () {
                    showDialog(
                        context: context,
                        builder: (BuildContext context) => getAuditDialog());
                  },
                  child: Text(
                    'Audit',
                    style: TextStyle(
                        color: darkMode ? Colors.white70 : Colors.deepOrange),
                    textAlign: TextAlign.center,
                  )),
              Text(
                'Version: $versionStr',
                textAlign: TextAlign.center,
              )
            ],
          ));
    });
  }

  Dialog getAuditDialog() {
    //TODO: sort audit list by time and removed expanded error
    return Dialog(
        backgroundColor:
            darkMode ? const Color.fromARGB(255, 90, 90, 90) : Colors.white,
        elevation: 10,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        child: Expanded(
          key: UniqueKey(),
          child: Scrollbar(
            thumbVisibility: isMobile() ? false : true,
            thickness: isMobile() ? 0.0 : 16.0,
            controller: _listController,
            child: ListView.builder(
                controller: _listController,
                itemCount: auditList.length,
                itemBuilder: (BuildContext context, int index) {
                  return Card(
                      margin: const EdgeInsets.all(4.0),
                      color: getCardColor(auditList[index]),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            flex: isMobile() ? 60 : 80,
                            child: Container(
                              padding: const EdgeInsets.all(8.0),
                              child: Center(
                                child: Text(
                                  auditList[index]['Name'] +
                                      ' @ ' +
                                      auditList[index]['updatedAt'].toString(),
                                  style: TextStyle(
                                      color: (darkMode
                                          ? Colors.white60
                                          : Colors.black87)),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: isMobile() ? 20 : 10,
                            child: Container(
                                padding: const EdgeInsets.all(8.0),
                                child: StatefulBuilder(
                                  builder: (BuildContext context,
                                      void Function(void Function()) setState) {
                                    return Theme(
                                        data: darkMode ? darkTheme : lightTheme,
                                        child: Checkbox(
                                          value:
                                              auditList[index]['Selected'] == 1,
                                          onChanged: (bool? value) {
                                            if (value != null) {
                                              auditList[index]['Selected'] =
                                                  value ? 1 : 0;
                                              updateFromAuditData(
                                                  auditList[index]);
                                              setState(() {});
                                            }
                                          },
                                        ));
                                  },
                                )),
                          ),
                        ],
                      ));
                }),
          ),
        ));
  }

  Dialog getProgressDialog() {
    int displayProgressCount = getDisplayProgressCount();
    int masterProgressCount = getMasterProgressCount();
    return Dialog(
      backgroundColor:
          darkMode ? const Color.fromARGB(255, 90, 90, 90) : Colors.white,
      elevation: 10,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: Text(
                '$gameDisplay ${type.replaceAll('_', ' ')} (With Current Filter) $displayProgressCount/${displayList.length} ${(displayProgressCount * 100 / displayList.length).floor()}%'),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 15.0, right: 15.0),
            child: LinearProgressIndicator(
              value: displayProgressCount / displayList.length,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: Text(
                '$gameDisplay ${type.replaceAll('_', ' ')} (Without Current Filter) $masterProgressCount/${masterList.length} ${(masterProgressCount * 100 / masterList.length).floor()}%'),
          ),
          Padding(
            padding:
                const EdgeInsets.only(left: 15.0, right: 15.0, bottom: 8.0),
            child: LinearProgressIndicator(
              value: masterProgressCount / masterList.length,
            ),
          ),
        ],
      ),
    );
  }

  int getDisplayProgressCount() {
    int count = 0;
    for (var element in displayList) {
      if (element['Selected'] == 1) {
        count++;
      }
    }
    return count;
  }

  int getMasterProgressCount() {
    int count = 0;
    for (var element in masterList) {
      if (element['Selected'] == 1) {
        count++;
      }
    }
    return count;
  }

  Dialog getInfoDialog(Map<String, dynamic> data) {
    var items = <Widget>[];

    for (String key in data.keys) {
      if (![
        "Index",
        "Selected",
        "Type",
        "PresentPreviousMonth",
        "PresentNextMonth"
      ].contains(key)) {
        items.add(Padding(
          padding: const EdgeInsets.all(15.0),
          child: Text(
            '$key: ${data[key]}',
            style:
                TextStyle(color: (darkMode ? Colors.white60 : Colors.black87)),
            textAlign: TextAlign.center,
          ),
        ));
      }
    }

    return Dialog(
      backgroundColor:
          darkMode ? const Color.fromARGB(255, 90, 90, 90) : Colors.white,
      elevation: 10,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: items,
      ),
    );
  }

  Dialog getFilterDialog() {
    return Dialog(
        backgroundColor:
            darkMode ? const Color.fromARGB(255, 90, 90, 90) : Colors.white,
        elevation: 10,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        child: StatefulBuilder(builder: (BuildContext context, state) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              DropdownButton<String>(
                  dropdownColor: darkMode
                      ? const Color.fromARGB(255, 90, 90, 90)
                      : Colors.white,
                  hint: Text(
                    filterSelectedChoices[selectedFilter],
                    style: TextStyle(
                        color: !darkMode ? Colors.black87 : Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                  items: filterSelectedChoices.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(
                        value,
                        style: TextStyle(
                            color:
                                (darkMode ? Colors.white60 : Colors.black87)),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }).toList(),
                  onChanged: (s) async {
                    selectedFilter = filterSelectedChoices.indexOf(s!);
                    await prefs?.setInt(
                        "${game + type}SelectedFilter", selectedFilter);
                    filter(text: _controller.value.text);
                    state(() {});
                  }),
              Visibility(
                visible: isSeasonalType(type),
                child: DropdownButton<String>(
                    dropdownColor:
                        darkMode ? const Color(-12632257) : Colors.white,
                    hint: Text(monthDisplay[selectedMonth],
                        style: TextStyle(
                            color:
                                !darkMode ? Colors.black87 : Colors.white70)),
                    items: monthDisplay.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value,
                            style: TextStyle(
                                color: (darkMode
                                    ? Colors.white60
                                    : Colors.black87))),
                      );
                    }).toList(),
                    onChanged: (s) async {
                      selectedMonth = monthDisplay.indexOf(s!);
                      await prefs?.setInt(
                          "${game + type}SelectedMonth", selectedMonth);
                      getData(refreshPrefs: !useCurrentDate);
                      state(() {});
                    }),
              ),
              Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Autocomplete<String>(
                    optionsBuilder: (TextEditingValue textEditingValue) async {
                      await prefs?.setString("${game + type}From", from);
                      if (textEditingValue.text == '') {
                        return fromList.toSet();
                      }
                      return fromList.where((String option) {
                        return option
                            .toLowerCase()
                            .contains(textEditingValue.text.toLowerCase());
                      }).toSet();
                    },
                    fieldViewBuilder: (BuildContext context,
                        TextEditingController fieldTextEditingController,
                        FocusNode fieldFocusNode,
                        VoidCallback onFieldSubmitted) {
                      return TextField(
                        style: TextStyle(
                            color: darkMode ? Colors.white : Colors.black),
                        focusNode: fieldFocusNode,
                        controller: fieldTextEditingController..text = from,
                        onChanged: onFromSearchChanged,
                        decoration: InputDecoration(
                          hintText: 'From',
                          hintStyle: TextStyle(
                              color: darkMode ? Colors.white : Colors.black),
                          prefixIcon: Icon(Icons.search,
                              color: darkMode ? Colors.white : Colors.black),
                          suffixIcon: IconButton(
                            color: darkMode ? Colors.white : Colors.black,
                            onPressed: () {
                              fieldTextEditingController.text = "";
                              onFromSearchChanged("");
                              prefs?.setString("${game + type}From", from);
                            },
                            icon: Icon(Icons.clear,
                                color: darkMode ? Colors.white : Colors.black),
                          ),
                          border: InputBorder.none,
                        ),
                      );
                    },
                    onSelected: (String selection) async {
                      onFromSearchChanged(selection);
                      await prefs?.setString("${game + type}From", from);
                    },
                  )),
            ],
          );
        }));
  }

  Widget gameDropDown() {
    return DropdownButton<String>(
        dropdownColor: darkMode ? const Color(-12632257) : Colors.white,
        hint: Text(gameDisplay,
            style:
                TextStyle(color: !darkMode ? Colors.black87 : Colors.white70)),
        items: gamesList.map((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value,
                style: TextStyle(
                    color: (darkMode ? Colors.white60 : Colors.black87))),
          );
        }).toList(),
        onChanged: (s) async {
          if (s == "Gamecube") {
            game = "acgc_";
            gameDisplay = 'Gamecube';
            typeTable = acgcTables;
          } else if (s == "Wild World") {
            game = "acww_";
            gameDisplay = 'Wild World';
            typeTable = acwwTables;
          } else if (s == "City Folk") {
            game = "accf_";
            gameDisplay = 'City Folk';
            typeTable = accfTables;
          } else if (s == "New Leaf") {
            game = "acnl_";
            gameDisplay = 'New Leaf';
            typeTable = acnlTables;
          } else if (s == "New Horizons") {
            game = "acnh_";
            gameDisplay = 'New Horizons';
            typeTable = acnhTables;
          }
          type = typeTable[0];
          await prefs?.setString("game", game);
          await prefs?.setString("type", type);
          getData();
        });
  }

  Widget typeDropDown() {
    return Container(
      child: DropdownButton<String>(
          dropdownColor: darkMode ? const Color(-12632257) : Colors.white,
          hint: Text(type.replaceAll('_', ' '),
              style: TextStyle(
                  color: !darkMode ? Colors.black87 : Colors.white70)),
          items: typeTable.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value.replaceAll('_', ' '),
                  style: TextStyle(
                      color: (darkMode ? Colors.white60 : Colors.black87))),
            );
          }).toList(),
          onChanged: (s) async {
            type = s!;
            await prefs?.setString("type", type);
            getData();
          }),
    );
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
      File file = File(d.path + '/acc$timestamp.acb');
      await writeFile(file.path, data);
      await Share.shareFiles([file.path]);
    } else {
      final documentsDir = await getApplicationDocumentsDirectory();
      var result = await FilePicker.platform
          .saveFile(initialDirectory: documentsDir.path);
      if (result != null) {
        filePath = result;
        File file = File(filePath);
        await file.create();
        await file.writeAsString(data);
        SnackBar(
          content: Text('Saved file: $filePath'),
        );
      }
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
    FilePickerResult? result = await FilePicker.platform
        .pickFiles(initialDirectory: documentsDir.path);
    if (result != null) {
      String? path = result.files.single.path;
      await loadFile(path!);
      initialLoad();
    } else {
      // User canceled the picker
    }
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
      var dataList = str.split('\n');
      for (int i = 0; i < dataList.length; i++) {
        var element = dataList[i];
        if (element.trim().isEmpty || !element.contains(':')) continue;
        var arr = element.split(':');
        var table = arr[0];
        var index = arr[1];
        db?.updateData(table, int.parse(index), true);
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
}
