import 'package:flutter/material.dart';

typedef OnPressed = Function();

class SmallElevatedButton extends StatelessWidget {
  final String label;
  final String icon;
  final OnPressed onPressed;

  SmallElevatedButton(this.label, this.icon, this.onPressed);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
        icon: Padding(
            padding: EdgeInsets.only(top: 2),
            child: Image.asset(
              this.icon,
              height: 10,
              width: 10,
            )),
        label: Text(this.label, style: TextStyle(fontSize: 12)),
        style: ButtonStyle(padding: MaterialStateProperty.all<EdgeInsets>(EdgeInsets.all(5))),
        onPressed: () {
          this.onPressed();
        });
  }
}
