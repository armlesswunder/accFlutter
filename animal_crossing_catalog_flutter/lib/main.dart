import 'package:animal_crossing_catalog_flutter/MyDatabase.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Animal Crossing Catalog',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: const MyHomePage(title: 'Animal Crossing Catalog'),
    );
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

  List<String> prefixList = <String>['acgc_', 'acww_', 'accf_', 'acnl_', 'acnh_'];
  List<String> gamesList = <String>['Gamecube', 'Wild World', 'City Folk', 'New Leaf', 'New Horizons'];

  List<String> acgcTables = <String>[];
  List<String> acwwTables = <String>[];
  List<String> accfTables = <String>[];
  List<String> acnlTables = <String>[];
  List<String> acnhTables = <String>[];

  List<List<String>> typeTables = <List<String>>[];
  List<String> typeTable = <String>[];

  static const String defaultGame = "acnh_";
  static const String defaultType = "houseware";

  static const List<String> filterSelectedChoices = ['All Items', 'Unchecked Items', 'Checked Items'];

  static const int FILTER_SELECTED_ALL = 0;
  static const int FILTER_SELECTED_UNCHECKED = 1;
  static const int FILTER_SELECTED_CHECKED = 2;

  String game = defaultGame;
  String gameDisplay = "New Horizons";
  String type = defaultType;

  int selectedFilter = FILTER_SELECTED_ALL;

  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    db = MyDatabase();
    initialLoad();
    super.initState();
  }

  void initialLoad() async {
    await getPrefs();
    await initializeTypes();
    await getData(getTable());

  }

  Future getPrefs() async {
    prefs = await SharedPreferences.getInstance();
    game = prefs?.getString("game") ?? defaultGame;
    type = prefs?.getString("type") ?? defaultType;
    selectedFilter = prefs?.getInt("selectedFilter") ?? FILTER_SELECTED_ALL;

    var gameIndex = prefixList.indexOf(game);
    gameDisplay = gamesList[gameIndex];
  }

  void setPrefs() async {
    prefs = await SharedPreferences.getInstance();
    prefs?.setString("game", game);
    prefs?.setString("type", type);
    prefs?.setInt("selectedFilter", selectedFilter);
  }

  String getTable() {
    return game + type;
  }

  Future<void> initializeTypes() async {
    acgcTables = await db!.getTableData('acgc_table');
    acwwTables = await db!.getTableData('acww_table');
    accfTables = await db!.getTableData('accf_table');
    acnlTables = await db!.getTableData('acnl_table');
    acnhTables = await db!.getTableData('acnh_table');
    typeTables = <List<String>>[acgcTables,acwwTables,accfTables,acnlTables,acnhTables];
    typeTable = typeTables[prefixList.indexOf(game)];
  }

  Future<void> getData(String table) async {
    var r = await db!.getData(table);
    masterList.clear();
    displayList.clear();
    masterList.addAll(r);
    displayList.addAll(masterList);
    filter();
    setState(() {
    });
  }

  void onSearchChanged(String text) async {
    filter(text: text);
  }

  void filter({String text = ''}) {
    displayList = <Map<String, dynamic>>[];
    for (int i = 0; i < masterList.length; i++) {
      if (masterList[i]['Name'].toString().toUpperCase().replaceAll('-', ' ').contains(text.toUpperCase().replaceAll('-', ' '))) displayList.add(masterList[i]);
    }

    if (selectedFilter > 0) {
      if (selectedFilter == FILTER_SELECTED_CHECKED) {
        displayList.removeWhere((element) => element['Selected'] == 0);
      }
      else {
        displayList.removeWhere((element) => element['Selected'] == 1);
      }
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
        appBar: AppBar(
          backgroundColor: const Color.fromARGB(255, 0, 50, 0),
          toolbarHeight: 0.0,
        ),
        body: Column(
          children: <Widget>[
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      gameDropDown(),
                      IconButton(
                        icon: const Icon(Icons.settings),
                        color: Colors.green,
                        tooltip: 'Settings',
                        onPressed: () {
                          
                        },
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      typeDropDown(),
                      IconButton(
                        icon: const Icon(Icons.search),
                        color: Colors.green,
                        tooltip: 'Filter',
                        onPressed: () {
                          showDialog(context: context, builder: (BuildContext context) => getFilterDialog());
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
                controller: _controller,
                onChanged: onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Name',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    onPressed: () {
                      _controller.text = "";
                      onSearchChanged("");
                    },
                    icon: const Icon(Icons.clear),
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
            Expanded(
              key: UniqueKey(),
              child: ListView.builder(
                  itemCount: displayList.length,
                  itemBuilder: (BuildContext context, int index) {
                    return Card(
                        margin: const EdgeInsets.all(4.0),
                        color: const Color.fromARGB(240, 255, 255, 255),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                          Expanded(
                            flex: 8,
                            child: Container(
                              padding: const EdgeInsets.all(8.0),
                              child: Center(
                                child: Text(displayList[index]['Name']),
                              ),
                            ),
                          ),
                            Expanded(
                              flex: 1,
                              child: Container(
                                padding: const EdgeInsets.all(8.0),
                                child: IconButton(
                                  icon: const Icon(Icons.info),
                                  color: Colors.green,
                                  tooltip: 'More Info',
                                  onPressed: () {
                                    showDialog(context: context, builder: (BuildContext context) => getInfoDialog(displayList[index]));
                                  },
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Container(
                                padding: const EdgeInsets.all(8.0),
                                child: Checkbox(value: displayList[index]['Selected'] == 1,
                                  onChanged: (bool? value) {
                                    db!.updateData(getTable(), displayList[index]['Index'], value!);
                                    displayList[index]['Selected'] = value ? 1 : 0;
                                    setState(() {});
                                  },
                                ),
                              ),
                            ),
                          ],
                        )
                    );
                  }
              ),
            )
          ],
        )
    );
  }

  Dialog getInfoDialog(Map<String, dynamic> data) {

    var items = <Widget>[];

    for (String key in data.keys) {
      items.add(Padding(
        padding:  const EdgeInsets.all(15.0),
        child: Text('$key: ${data[key]}'),
      ));
    }

    return Dialog(
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
      elevation: 10,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
      DropdownButton<String>(
        hint: Text(filterSelectedChoices[selectedFilter]),
        items: filterSelectedChoices.map((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
        onChanged: (s) {
          selectedFilter = filterSelectedChoices.indexOf(s!);
          setPrefs();
          filter();
        }),
        ],
      ),
    );
  }

  Widget gameDropDown() {
    return DropdownButton<String>(
          hint: Text(gameDisplay),
          items: gamesList.map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: (s) {
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
            setPrefs();
            getData(getTable());
      });


  }

  Widget typeDropDown() {
    return Container(
        child: DropdownButton<String>(
            hint: Text(type),
            items: typeTable.map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (s) {
              type = s!;
              setPrefs();
              getData(getTable());
            }
      ),
    );
  }
}
