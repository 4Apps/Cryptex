import 'package:flutter/material.dart';

class ApiRequestsTheme {
  static ThemeData get lightTheme {
    return ThemeData(
        primaryColor: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Montserrat',
        inputDecorationTheme: InputDecorationTheme(
            labelStyle: TextStyle(fontFamily: 'Monospace', fontSize: 14),
            hintStyle: TextStyle(fontFamily: 'Monospace', fontSize: 14)),
        elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
          primary: Colors.blue,
        )));
  }

  static ThemeData get darkTheme {
    return ThemeData(
        primaryColor: Colors.black,
        scaffoldBackgroundColor: Colors.grey,
        fontFamily: 'Montserrat',
        elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
          primary: Colors.blue,
        )));
  }
}
