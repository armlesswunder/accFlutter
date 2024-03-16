import 'package:flutter/material.dart';

ThemeData lightTheme = ThemeData(
    sliderTheme: SliderThemeData(
        valueIndicatorColor: Colors.green,
        showValueIndicator: ShowValueIndicator.onlyForContinuous,
        valueIndicatorTextStyle: TextStyle(color: Colors.grey.shade900)),
    colorScheme: ColorScheme(
        onPrimary: Colors.grey.shade900,
        brightness: Brightness.light,
        primary: Colors.green,
        secondary: Colors.greenAccent,
        onSecondary: Colors.grey.shade900,
        error: Colors.red,
        onError: Colors.grey.shade900,
        background: Colors.grey.shade100,
        onBackground: Colors.grey.shade900,
        surface: Colors.green.shade700,
        onSurface: Colors.grey.shade900),
    primarySwatch: Colors.green,
    scaffoldBackgroundColor: Colors.grey.shade900,
    dialogBackgroundColor: Colors.grey.shade700,
    dialogTheme: DialogTheme(backgroundColor: Colors.grey.shade700),
    canvasColor: Colors.grey.shade200,
    hintColor: Colors.grey.shade100,
    textTheme: const TextTheme().apply(
      bodyColor: Colors.grey.shade900,
      displayColor: Colors.grey.shade900,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey.shade200,
      iconColor: Colors.grey.shade900,
      hintStyle: TextStyle(color: Colors.grey.shade900),
      labelStyle: TextStyle(color: Colors.grey.shade900),
    ));

ThemeData darkTheme = ThemeData(
    sliderTheme: const SliderThemeData(
        activeTrackColor: Colors.deepOrangeAccent,
        inactiveTrackColor: Colors.grey,
        inactiveTickMarkColor: Colors.grey,
        thumbColor: Colors.deepOrange,
        valueIndicatorColor: Colors.deepOrange,
        showValueIndicator: ShowValueIndicator.onlyForContinuous,
        valueIndicatorTextStyle: TextStyle(color: Colors.white70)),
    colorScheme: ColorScheme(
        onPrimary: Colors.white70,
        brightness: Brightness.dark,
        primary: Colors.grey.shade900,
        secondary: Colors.grey.shade700,
        onSecondary: Colors.white70,
        error: Colors.red,
        onError: Colors.white70,
        background: Colors.grey.shade900,
        onBackground: Colors.white70,
        surface: Colors.grey.shade900,
        onSurface: Colors.white70),
    primarySwatch: Colors.grey,
    checkboxTheme: CheckboxThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2.0)),
      side: MaterialStateBorderSide.resolveWith(
          (states) => BorderSide(width: 2, color: Colors.white)),
      checkColor: MaterialStateProperty.all(Colors.white),
      fillColor: MaterialStateProperty.all(Colors.transparent),
    ),
    scaffoldBackgroundColor: Colors.grey.shade900,
    dialogBackgroundColor: Colors.grey.shade700,
    dialogTheme: DialogTheme(backgroundColor: Colors.grey.shade700),
    canvasColor: Colors.black,
    hintColor: Colors.black87,
    textTheme: const TextTheme().apply(
      bodyColor: Colors.white70,
      displayColor: Colors.white70,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey.shade700,
      iconColor: Colors.white70,
      hintStyle: const TextStyle(color: Colors.white70),
      labelStyle: const TextStyle(color: Colors.white70),
    ));
