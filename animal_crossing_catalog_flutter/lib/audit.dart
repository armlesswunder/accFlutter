import 'audit_data.dart';
import 'data.dart';

String auditKey(String type) => '${type}_AUDIT';

void getAuditData(String type) {
  List<String> tables = mAllTables[game + type] ??= [game + type];
  auditData = [];
  for (String t in tables) {
    auditData.addAll(
        prefs!.getStringList(auditKey(t))?.map((e) => AuditData(e)).toList() ??
            []);
  }
  auditData.sort((e1, e2) => e2.time.compareTo(e1.time));
}

void insertAuditData(String type, int index, bool change) {
  var time = DateTime.now().microsecondsSinceEpoch;
  auditData.insert(0, AuditData('$time;;$index;;${!change};;$type'));
  print(change);
  setAuditData(type);
}

void setAuditData(String type) {
  var strArr = auditData.map((e) => e.toString()).toList();
  strArr.removeWhere((element) => !element.contains(type));
  var subList = strArr;
  if (strArr.length > 25) {
    subList = strArr.sublist(0, 25);
  }
  prefs!.setStringList(auditKey(type), subList);
}
