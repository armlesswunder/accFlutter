import 'package:animal_crossing_catalog_flutter/theme.dart';
import 'package:animal_crossing_catalog_flutter/utils.dart';
import 'package:flutter/material.dart';

import 'audit.dart';
import 'data.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  void dispose() {
    prefs?.setInt(cellWidthKey(type), cellWidthMultiplier);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
        data: darkMode ? darkTheme : lightTheme,
        child: Scaffold(
            appBar: AppBar(
              title: const Text('Settings'),
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
                                color: (darkMode
                                    ? Colors.white60
                                    : Colors.black87)),
                          )),
                    ),
                    Expanded(
                        flex: 2,
                        child: Checkbox(
                          value: darkMode,
                          onChanged: (bool? value) {
                            prefs?.setBool('darkMode', value ??= false);
                            darkMode = value ??= false;
                            notifier.value =
                                darkMode ? ThemeMode.dark : ThemeMode.light;
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
                                color: (darkMode
                                    ? Colors.white60
                                    : Colors.black87)),
                          )),
                    ),
                    Expanded(
                        flex: 2,
                        child: Checkbox(
                          value: useCurrentDate,
                          onChanged: (bool? value) {
                            prefs?.setBool('useCurrentDate', value ??= true);
                            useCurrentDate = value ??= false;
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
                                color: (darkMode
                                    ? Colors.white60
                                    : Colors.black87)),
                          )),
                    ),
                    Expanded(
                        flex: 2,
                        child: Checkbox(
                          value: critterColors,
                          onChanged: (bool? value) {
                            prefs?.setBool('critterColors', value ??= false);
                            critterColors = value ??= false;
                            setState(() {});
                          },
                        ))
                  ],
                ),
                isMobile()
                    ? Container()
                    : Row(mainAxisSize: MainAxisSize.min, children: [
                        Text('Cell Width Multiplier:'),
                        Expanded(
                            child: Slider(
                          value: cellWidthMultiplier.toDouble(),
                          max: 300,
                          min: 25,
                          label: cellWidthMultiplier.round().toString(),
                          onChanged: (double value) {
                            setState(() {
                              cellWidthMultiplier = value.toInt();
                            });
                          },
                        ))
                      ]),
                TextButton(
                    onPressed: () async {
                      var s = await db1?.backupData();
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
                          builder: (BuildContext context) =>
                              getProgressDialog());
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
                TextButton(
                    onPressed: () {
                      showConfirmDialog(context, () {
                        db1!.unselectAllFromGame(typeTable, game);
                      });
                    },
                    child: Text(
                      'Reset Game',
                      style: TextStyle(
                          color: darkMode ? Colors.white70 : Colors.deepOrange),
                      textAlign: TextAlign.center,
                    )),
                TextButton(
                    onPressed: () {
                      showConfirmDialog(context, () {
                        db1!.unselectAllFromTable(game + type);
                      });
                    },
                    child: Text(
                      'Reset Current List ($type)',
                      style: TextStyle(
                          color: darkMode ? Colors.white70 : Colors.deepOrange),
                      textAlign: TextAlign.center,
                    )),
                Text(
                  'Version: $versionStr',
                  textAlign: TextAlign.center,
                )
              ],
            )));
  }
}

Dialog getAuditDialog() {
  //TODO: sort audit list by time and removed expanded error
  getAuditData(type);
  return Dialog(
      backgroundColor:
          darkMode ? const Color.fromARGB(255, 90, 90, 90) : Colors.white,
      elevation: 10,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Container(
        key: UniqueKey(),
        child: Scrollbar(
          thumbVisibility: isMobile() ? false : true,
          thickness: isMobile() ? 0.0 : 16.0,
          controller: auditListController,
          child: ListView.builder(
              controller: auditListController,
              itemCount: auditData.length,
              itemBuilder: (BuildContext context, int index) {
                return Card(
                    margin: const EdgeInsets.all(4.0),
                    color: getCardColor(auditData[index].getData()),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          flex: isMobile() ? 60 : 80,
                          child: Container(
                            padding: const EdgeInsets.all(8.0),
                            child: Center(
                              child: Text(
                                auditData[index].getData()['Name'] +
                                    ' @ ' +
                                    getAuditTimestamp(
                                        auditData[index].getTime()),
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
                                        value: auditData[index].getSelected(),
                                        onChanged: (bool? value) {
                                          if (value != null) {
                                            auditData[index].selected =
                                                '${value}';
                                            updateFromAuditData(
                                                auditData[index].getData(),
                                                value);
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
            color: Colors.deepOrange,
            value: displayProgressCount / displayList.length,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(15.0),
          child: Text(
              '$gameDisplay ${type.replaceAll('_', ' ')} (Without Current Filter) $masterProgressCount/${masterList.length} ${(masterProgressCount * 100 / masterList.length).floor()}%'),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 15.0, right: 15.0, bottom: 8.0),
          child: LinearProgressIndicator(
            color: Colors.deepOrange,
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
