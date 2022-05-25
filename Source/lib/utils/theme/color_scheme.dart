import 'package:flutter/material.dart';

class ColorVariant {
  final Color background;
  final Color foreground;

  ColorVariant(this.background, this.foreground);
}

extension ColorSchemeExtension on ColorScheme {
  ColorVariant get info => ColorVariant(
      this.brightness == Brightness.light ? Color.fromRGBO(24, 162, 184, 1.0) : Color.fromRGBO(24, 162, 184, 1.0),
      Colors.white);
  ColorVariant get success => ColorVariant(
      this.brightness == Brightness.light ? Color.fromRGBO(40, 167, 68, 1.0) : Color.fromRGBO(40, 167, 68, 1.0),
      Colors.white);
  ColorVariant get warning => ColorVariant(
      this.brightness == Brightness.light ? Color.fromRGBO(255, 193, 7, 1.0) : Color.fromRGBO(255, 193, 7, 1.0),
      Colors.white);
  ColorVariant get danger => ColorVariant(
      this.brightness == Brightness.light ? Color.fromRGBO(220, 54, 68, 1.0) : Color.fromRGBO(220, 54, 68, 1.0),
      Colors.white);
}
