import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'MyDB.dart';
import 'audit_data.dart';

final ValueNotifier<ThemeMode> notifier = ValueNotifier(ThemeMode.light);

const guideURL = "https://github.com/armlesswunder/accFlutter#guide";
const faqURL = "https://github.com/armlesswunder/accFlutter#faq";
const mySiteURL = "https://armlesswunder.github.io/";

StateSetter? mainState;

final FocusNode mainFocus = FocusNode();
final FocusNode searchFocus = FocusNode();

double screenWidth = 0;
double screenHeight = 0;

double cachePosition = 0.0;
bool darkMode = true;

//MyDatabase? db;
MyDatabase1? db1;
SharedPreferences? prefs;
List<Map<String, dynamic>> masterList = <Map<String, dynamic>>[];
List<Map<String, dynamic>> displayList = <Map<String, dynamic>>[];

List<AuditData> auditData = [];

List<String> skipables = [
  "Index",
  "Selected",
  "Type",
  "Status",
  "PresentPreviousMonth",
  "PresentNextMonth"
].map((e) => e.toLowerCase()).toList();

List<String> prefixList = <String>['acgc_', 'acww_', 'accf_', 'acnl_', 'acnh_'];
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

const String defaultGame = "acnh_";
const String defaultType = "houseware";

const List<String> filterSelectedChoices = [
  'All Items',
  'Unchecked Items',
  'Checked Items'
];

const int FILTER_SELECTED_ALL = 0;
const int FILTER_SELECTED_UNCHECKED = 1;
const int FILTER_SELECTED_CHECKED = 2;

String game = defaultGame;
String gameDisplay = "New Horizons";
String type = defaultType;
String from = "";
String versionStr = '[Unknown Version]';
int dbVersion = 2;
int oldVersion = 1;

int selectedFilter = FILTER_SELECTED_ALL;

final TextEditingController controller = TextEditingController();
final ScrollController listController = ScrollController();
final ScrollController auditListController = ScrollController();

bool critterColors = true;
bool useCurrentDate = false;

Map<String, ResultSetImplementation<dynamic, dynamic>>? tableMap;
Map<String, TableInfo>? tableInfoMap;

Map<String, List<String>> mAllTables = <String, List<String>>{
  "acgc_all_housewares": [
    "acgc_furniture",
    "acgc_carpet",
    "acgc_wallpaper",
    "acgc_gyroid"
  ],
  "acww_all_housewares": [
    "acww_furniture",
    "acww_carpet",
    "acww_wallpaper",
    "acww_gyroid"
  ],
  "acww_all_clothing": ["acww_accessory", "acww_shirt"],
  "accf_all_housewares": [
    "accf_furniture",
    "accf_carpet",
    "accf_wallpaper",
    "accf_gyroid",
    "accf_painting"
  ],
  "accf_all_clothing": ["accf_accessory", "accf_shirt"],
  "acnl_all_housewares": [
    "acnl_furniture",
    "acnl_carpet",
    "acnl_wallpaper",
    "acnl_gyroid",
    "acnl_song"
  ],
  "acnl_all_clothing": [
    "acnl_accessory",
    "acnl_bottom",
    "acnl_dress",
    "acnl_feet",
    "acnl_hat",
    "acnl_shirt",
    "acnl_wet_suit"
  ],
  "acnl_all_critters": ["acnl_fish", "acnl_insect", "acnl_seafood"],
  "acnh_all_housing": [
    "acnh_houseware",
    "acnh_misc",
    "acnh_ceiling",
    "acnh_interior",
    "acnh_wall_mounted",
    "acnh_art",
    "acnh_flooring",
    "acnh_rug",
    "acnh_wallpaper"
  ],
  "acnh_all_clothing": [
    "acnh_accessory",
    "acnh_bag",
    "acnh_bottom",
    "acnh_dress",
    "acnh_headwear",
    "acnh_shoe",
    "acnh_sock",
    "acnh_top",
    "acnh_other_clothing"
  ],
};

int cellWidthMultiplier = 140;
