import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:provider/provider.dart';

import 'package:cryptex/utils/models/url/url_resource.dart';
import 'package:cryptex/utils/helpers/global_functions.dart';
import 'package:cryptex/utils/helpers/global_notifier.dart';
import 'package:cryptex/utils/services/sqlite_data_service/base.dart';
import 'package:cryptex/utils/services/sqlite_data_service/url_resource.dart';

class AppBarTitle extends StatefulWidget {
  @override
  AppBarTitleState createState() => AppBarTitleState();
}

class AppBarTitleState extends State<AppBarTitle> {
  bool isEditing = false;
  bool isEditButtonVisible = false;
  final textController = TextEditingController();
  // UrlResource? selectedUrlItem;

  String name(UrlResource? selectedUrlItem) {
    return (selectedUrlItem != null ? selectedUrlItem.name : "Untitled");
  }

  bool? checked = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        // crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Theme(
                  data: Theme.of(context).copyWith(unselectedWidgetColor: Colors.white),
                  child: ToggleButtons(
                    borderColor: Colors.transparent,
                    selectedBorderColor: Colors.transparent,
                    selectedColor: Colors.white,
                    children: [
                      Icon(
                        Icons.edit,
                        size: 14,
                        color: Colors.white,
                      ),
                    ],
                    isSelected: [isEditing],
                    onPressed: (index) {
                      setState(() {
                        isEditing = !isEditing;
                      });
                    },
                  ))),
          Consumer<GlobalNotifier>(builder: (context, ulNotifier, child) {
            if (isEditing && ulNotifier.selectedUrlItem != null) {
              textController.text = this.name(ulNotifier.selectedUrlItem);

              return Expanded(
                  child: Theme(
                      data: Theme.of(context).copyWith(
                        textTheme: TextTheme(subtitle1: TextStyle(color: Colors.white, fontSize: 16)),
                        textSelectionTheme: TextSelectionThemeData(selectionColor: Colors.lightBlue),
                        inputDecorationTheme: InputDecorationTheme(
                          focusedBorder: UnderlineInputBorder(borderSide: BorderSide(width: 1, color: Colors.black)),
                        ),
                        colorScheme:
                            Theme.of(context).colorScheme.copyWith(primary: Colors.white, onSurface: Colors.black),
                      ),
                      child: RawKeyboardListener(
                        child: TextField(
                          controller: textController,
                          decoration: InputDecoration(hintText: 'Enter name of the URL'),
                          autofocus: true,
                          cursorColor: Colors.white,
                          onSubmitted: (value) {
                            if (ulNotifier.selectedUrlItem != null) {
                              ulNotifier.selectedUrlItem!.name = value;
                              SQLiteDataProvider.shared.saveUrlResource(ulNotifier.selectedUrlItem!).then((value) {
                                setState(() {
                                  isEditing = false;
                                });
                                var abtNotifier = context.read<GlobalNotifier>();
                                abtNotifier.reload();
                              }).catchError((error) {
                                showAlert(context, "Error", "Error saving URL name: {$error.toString()}");
                              });
                            }
                          },
                        ),
                        focusNode: FocusNode(),
                        onKey: (event) {
                          if (event.logicalKey == LogicalKeyboardKey.escape) {
                            setState(() {
                              isEditing = false;
                            });
                          }
                        },
                      )));
            }

            // Make sure its really disabled
            isEditing = false;

            return Text(this.name(ulNotifier.selectedUrlItem));
          })
        ],
      ),
      onEnter: (event) {
        if (isEditing) {
          return;
        }

        setState(() {
          isEditButtonVisible = true;
        });
      },
      onExit: (event) {
        if (isEditing) {
          return;
        }

        setState(() {
          isEditButtonVisible = false;
        });
      },
    );
  }
}
