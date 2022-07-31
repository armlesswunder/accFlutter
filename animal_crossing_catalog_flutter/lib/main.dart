import 'package:animal_crossing_catalog_flutter/DatabaseHelper.dart';
import 'package:animal_crossing_catalog_flutter/MyDatabase.dart';
import 'package:flutter/material.dart';

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
        primarySwatch: Colors.blue,
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
  DataBaseHelper dbHelper = DataBaseHelper();
  MyDatabase? db;
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

  String game = "acgc_";
  String gameDisplay = "Gamecube";
  String type = "carpet";

  @override
  void initState() {
    db = MyDatabase();
    initialLoad();
    super.initState();
  }

  void initialLoad() async {
    await initializeTypes();
    await getData(getTable());
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
    typeTable = acgcTables;
  }

  Future<void> getData(String table) async {
    var r = await db!.getData(table);
    masterList.clear();
    displayList.clear();
    masterList.addAll(r);
    displayList.addAll(masterList);
    setState(() {
    });
  }

  void onSearchChanged(String text) async {
    displayList = <Map<String, dynamic>>[];
    for (int i = 0; i < masterList.length; i++) {
      if (masterList[i]['Name'].toString().toUpperCase().contains(text.toUpperCase())) displayList.add(masterList[i]);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
        appBar: AppBar(
          actions: [
            gameDropDown(),
            typeDropDown(),
          ],
        ),
        body: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
              child: TextField(
                onChanged: onSearchChanged,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            Expanded(
              key: UniqueKey(),
              child: ListView.builder(
                  itemCount: displayList.length,
                  itemBuilder: (BuildContext context, int index) {
                    //return filteredEntries.length < index ? Text('Out of bounds...') : Text('${testText} ${filteredEntries[index]}');
                    return Card(
                        margin: EdgeInsets.all(4.0),
                        color: Colors.white,
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(8.0),
                              child: Center(
                                child: Text(displayList[index]['Name']),
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.all(8.0),
                              child: Checkbox(value: displayList[index]['Selected'] == 1,
                                onChanged: (bool? value) {
                                  db!.updateData(getTable(), displayList[index]['Index'], value!);
                                  displayList[index]['Selected'] = value ? 1 : 0;
                                  setState(() {});
                                },
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
            getData(getTable());
      });


  }

  Widget typeDropDown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(10)),

      // dropdown below..
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
              getData(getTable());
            }
      ),
    );
  }
}
