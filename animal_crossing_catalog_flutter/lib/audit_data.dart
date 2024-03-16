import 'package:animal_crossing_catalog_flutter/data.dart';

class AuditData {
  late String time;
  late String index;
  late String type;
  late String selected;

  AuditData(String str) {
    var arr = str.split(';;');
    time = arr[0];
    index = arr[1];
    selected = arr[2];
    try {
      type = arr[3];
    } catch (e) {
      type = '???';
    }
  }

  DateTime getTime() {
    try {
      var t = int.parse(time);
      return DateTime.fromMicrosecondsSinceEpoch(t);
    } catch (err) {
      print(err);
    }
    return DateTime.fromMicrosecondsSinceEpoch(1);
  }

  bool getSelected() {
    try {
      var t = bool.parse(selected);
      return t;
    } catch (err) {
      print(err);
    }
    return false;
  }

  int getIndex() {
    try {
      var t = int.parse(index);
      return t;
    } catch (err) {
      print(err);
    }
    return -1;
  }

  Map<String, dynamic> getData() {
    try {
      var data = masterList.firstWhere((element) =>
          element['Type'] == type && element['Index'] == getIndex());
      return data;
    } catch (err) {
      print(err);
    }
    return {'Name': '???'};
  }

  @override
  String toString() {
    return '$time;;$index;;$selected;;$type';
  }
}
