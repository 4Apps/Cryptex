import 'package:flutter/material.dart';

class DashedLineVerticalPainter extends CustomPainter {
  double thickness, dashHeight, dashSpace, startX, startY;
  Color strokeColor;

  DashedLineVerticalPainter(
      {this.thickness = 1,
      this.dashHeight = 5,
      this.dashSpace = 3,
      this.startX = 0,
      this.startY = 0,
      this.strokeColor = Colors.grey});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = strokeColor
      ..strokeWidth = thickness;
    while (startY < size.height) {
      canvas.drawLine(
          Offset(startX, startY), Offset(startX, startY + dashHeight), paint);
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
