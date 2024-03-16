import 'dart:io';

import 'package:animal_crossing_catalog_flutter/settings_page.dart';
import 'package:animal_crossing_catalog_flutter/theme.dart';
import 'package:animal_crossing_catalog_flutter/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'data.dart';

List<String> acgcTables = <String>[];
List<String> acwwTables = <String>[];
List<String> accfTables = <String>[];
List<String> acnlTables = <String>[];
List<String> acnhTables = <String>[];

void main() async {
  if (Platform.isWindows || Platform.isLinux) {
    // Initialize FFI
    sqfliteFfiInit();
  }
  // Change the default factory. On iOS/Android, if not using `sqlite_flutter_lib` you can forget
  // this step, it will use the sqlite version available on the system.
  databaseFactory = databaseFactoryFfi;
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
        valueListenable: notifier,
        builder: (_, mode, __) {
          return MaterialApp(
            title: 'Animal Crossing Catalog',
            theme: darkTheme,
            darkTheme: darkTheme,
            themeMode: ThemeMode.dark,
            home: const MyHomePage(title: 'Animal Crossing Catalog'),
          );
        });
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  num lastHotkeyPress = 0;

  void _onKey(RawKeyEvent event) {
    bool keyEventHandled = false;
    num currentTime = DateTime.now().millisecondsSinceEpoch;
    num timeDifference = currentTime - lastHotkeyPress;
    if (timeDifference < 200) return;
    if (event.isControlPressed && event.logicalKey == LogicalKeyboardKey.keyF) {
      searchFocus.requestFocus();
      keyEventHandled = true;
    }
    if (keyEventHandled) {
      lastHotkeyPress = currentTime;
    }
  }

  @override
  void initState() {
    initialLoad();

    listController.addListener(_ScrollPosition);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarBrightness: Brightness.light,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black87,
    ));
    super.initState();
  }

  _ScrollPosition() async {
    cachePosition = listController.position.pixels;
  }

  void onSearchChanged(String text) async {
    filter(text: text);
  }

  void onFromSearchChanged(String text) async {
    from = text;
    filter(text: controller.text);
  }

  @override
  Widget build(BuildContext context) {
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;
    mainState = setState;
    return RawKeyboardListener(
        autofocus: true,
        focusNode: mainFocus,
        onKey: _onKey,
        child: SafeArea(
            child: SafeArea(
                child: Scaffold(
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
                              return const SettingsPage();
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
                focusNode: searchFocus,
                onTapOutside: (e) {
                  mainFocus.requestFocus();
                },
                style: TextStyle(color: darkMode ? Colors.white : Colors.black),
                controller: controller,
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
                      controller.text = "";
                      onSearchChanged("");
                    },
                    icon: Icon(Icons.clear,
                        color: darkMode ? Colors.white : Colors.black),
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
            buildKeys(),
            Expanded(
              key: UniqueKey(),
              child: Scrollbar(
                thumbVisibility: isMobile() ? false : true,
                thickness: isMobile() ? 0.0 : 16.0,
                controller: listController,
                child: ListView.builder(
                    controller: listController,
                    itemCount: displayList.length,
                    itemBuilder: (BuildContext context, int index) {
                      return buildListItem(index);
                    }),
              ),
            )
          ],
        )))));
  }

  Widget buildListItem(int index) {
    return isMobile() || (game + type).contains('_all')
        ? mobileListItem(index)
        : desktopListItem(index);
  }

  Widget mobileListItem(int index) {
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
                        color: (darkMode ? Colors.white60 : Colors.black87)),
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
                  color: getInfoIconColor(displayList[index]['Status']),
                  tooltip: 'More Info',
                  onPressed: () {
                    showDialog(
                        context: context,
                        builder: (BuildContext context) =>
                            getInfoDialog(displayList[index]));
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
                        void Function(void Function()) setState) {
                      return Theme(
                          data: darkMode ? darkTheme : lightTheme,
                          child: Checkbox(
                            value: displayList[index]['Selected'] == 1,
                            onChanged: (bool? value) {
                              db1!.updateData(displayList[index]['Type'],
                                  displayList[index]['Index'], value!);
                              var data = displayList[index];
                              addAuditData(data);
                              displayList[index]['Selected'] = value ? 1 : 0;
                              if (selectedFilter != FILTER_SELECTED_ALL) {
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
  }

  int getMaxColumns() {
    var d = screenWidth / cellWidthMultiplier;
    return d.toInt();
  }

  Widget desktopListItem(int index) {
    int maxColumns = getMaxColumns();
    List<String> keys = displayList[index].keys.toList();
    List<Widget> widgets = [];
    for (int i = 0; i < keys.length; i++) {
      if (i > maxColumns) break;
      String key = keys[i];
      if (skipables.contains(key.toLowerCase())) continue;
      widgets.add(Expanded(
        child: Text('${displayList[index][key]}',
            style: const TextStyle(color: Colors.white70)),
      ));
    }

    if ((game + type).contains('_all')) {
      if (widgets.length > 2) {
        widgets = widgets.sublist(0, 2);
      }
    }
    return Card(
        margin: const EdgeInsets.all(8.0),
        color: getCardColor(displayList[index]),
        child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ...widgets,
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: IconButton(
                      icon: const Icon(Icons.info),
                      color: getInfoIconColor(displayList[index]['Status']),
                      tooltip: 'More Info',
                      onPressed: () {
                        showDialog(
                            context: context,
                            builder: (BuildContext context) =>
                                getInfoDialog(displayList[index]));
                      },
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                      padding: const EdgeInsets.all(8.0),
                      child: StatefulBuilder(
                        builder: (BuildContext context,
                            void Function(void Function()) setState) {
                          return Checkbox(
                            value: displayList[index]['Selected'] == 1,
                            onChanged: (bool? value) {
                              db1!.updateData(displayList[index]['Type'],
                                  displayList[index]['Index'], value!);
                              var data = displayList[index];
                              addAuditData(data);
                              displayList[index]['Selected'] = value ? 1 : 0;
                              if (selectedFilter != FILTER_SELECTED_ALL) {
                                filter(resetScroll: false);
                              } else {
                                setState(() {});
                              }
                            },
                          );
                        },
                      )),
                ),
              ],
            )));
  }

  int headersCount = 0;
  Widget buildKeys() {
    int maxColumns = getMaxColumns();
    if (isMobile() || (game + type).contains('_all') || displayList.isEmpty)
      return Container();
    List<String> keys = displayList[0].keys.toList();
    List<Widget> widgets = [];

    for (int j = 0; j < keys.length; j++) {
      if (j > maxColumns) break;
      String key = keys[j];
      if (skipables.contains(key.toLowerCase())) continue;

      widgets.add(Expanded(
        child: Text(key, style: const TextStyle(color: Colors.white70)),
      ));
    }
    if ((game + type).contains('_all')) {
      if (widgets.length > 2) {
        widgets = widgets.sublist(0, 2);
      }
    }
    widgets.add(const Expanded(child: SizedBox(width: 1)));
    widgets.add(const Expanded(child: SizedBox(width: 1)));
    headersCount = widgets.length;
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
            mainAxisAlignment: MainAxisAlignment.center, children: widgets));
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
                    filter(text: controller.value.text);
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
                        onTapOutside: (e) {
                          mainFocus.requestFocus();
                        },
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
}
