import 'dart:convert' show utf8, jsonDecode;
import 'dart:typed_data';
import 'package:flutter/material.dart';

import 'package:file_picker_cross/file_picker_cross.dart';

bool validateHeaders(String? text) {
  if (text == null || text.isEmpty) {
    return false;
  }

  List<String> list = text.split('\n');
  for (String item in list) {
    List<String> keyValue = item.split(': ');
    if (keyValue.length != 2) {
      return false;
    }
  }

  return true;
}

void showAlert(BuildContext context, String title, String message) {
  // set up the button
  Widget okButton = TextButton(
    child: Text("OK"),
    onPressed: () {
      Navigator.of(context).pop();
    },
  );

  // set up the AlertDialog
  AlertDialog alert = AlertDialog(
    title: Text(title),
    content: Text(message),
    actions: [
      okButton,
    ],
  );

  // show the dialog
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return alert;
    },
  );
}

typedef ConfirmCallbackFn = Function(bool);
void showConfirm(BuildContext context, String title, String message, ConfirmCallbackFn callback) {
// set up the buttons
  Widget cancelButton = TextButton(
    child: Text("Cancel"),
    onPressed: () {
      Navigator.of(context).pop();
      callback(false);
    },
  );
  Widget confirmButton = TextButton(
    child: Text("Confirm"),
    onPressed: () {
      Navigator.of(context).pop();
      callback(true);
    },
  ); // set up the AlertDialog
  AlertDialog alert = AlertDialog(
    title: Text(title),
    content: Text(message),
    actions: [
      cancelButton,
      confirmButton,
    ],
  ); // show the dialog
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return alert;
    },
  );
}

typedef Confirm2CallbackFn = Function(int buttonIndex);
void showConfirm2(BuildContext context, String title, String message, String button1Title, String button2Title,
    Confirm2CallbackFn callback) {
// set up the buttons
  Widget cancelButton = TextButton(
    child: Text("Cancel"),
    onPressed: () {
      Navigator.of(context).pop();
      callback(0);
    },
  );
  Widget button1 = TextButton(
    child: Text(button1Title),
    onPressed: () {
      Navigator.of(context).pop();
      callback(1);
    },
  );
  Widget button2 = TextButton(
    child: Text(button2Title),
    onPressed: () {
      Navigator.of(context).pop();
      callback(2);
    },
  );
  AlertDialog alert = AlertDialog(
    title: Text(title),
    content: Text(message),
    actions: [cancelButton, button1, button2],
  ); // show the dialog
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return alert;
    },
  );
}

typedef InputCallbackFn = Function(bool success, String newInputValue);
void showInput(BuildContext context, String title, String message, String? inputValue, InputCallbackFn callback) {
  late FocusNode textFocusNode = FocusNode();
  var textController = TextEditingController();
  textController.text = inputValue != null ? inputValue : "";

  var textField = TextField(
    controller: textController,
    focusNode: textFocusNode,
    cursorColor: Colors.white,
    decoration: InputDecoration(hintText: "Please enter section name"),
    onSubmitted: (value) {
      Navigator.of(context).pop();
      callback(true, value);
    },
  );

  Widget cancelButton = TextButton(
    child: Text("Cancel"),
    onPressed: () {
      Navigator.of(context).pop();
      callback(false, "");
    },
  );
  Widget confirmButton = TextButton(
    child: Text("Confirm"),
    onPressed: () {
      textField.onSubmitted!(textController.text);
    },
  );

  // Set up the AlertDialog
  AlertDialog alert = AlertDialog(
    title: Text(title),
    content: textField,
    actions: [
      cancelButton,
      confirmButton,
    ],
  );

  // Show the dialog
  Future.delayed(const Duration(milliseconds: 250), () {
    textFocusNode.requestFocus();
    textController.selection = TextSelection(baseOffset: 0, extentOffset: textController.text.length);
  });
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return alert;
    },
  );
}

Future<String?> saveFile(String mime, String name, String data) async {
  var encodedData = utf8.encode(data);
  Uint8List fileData = Uint8List.fromList(encodedData);
  FilePickerCross filePickerCross = FilePickerCross(fileData);

  return filePickerCross.exportToStorage(fileName: "ar_export.json").then((path) {
    return path;
  });
}

Future<String> loadFile(String fileExt) async {
  return FilePickerCross.importFromStorage(fileExtension: fileExt).then((file) {
    return file.toString();
  });
}

Future<Map<String, dynamic>> loadJsonFile() async {
  return loadFile('.json').then((stringData) {
    return jsonDecode(stringData);
  });
}
