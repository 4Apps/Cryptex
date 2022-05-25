import 'package:api_requests/utils/models/url/header_entry.dart';

extension HeaderList on List<HeaderEntry> {
  String asString() {
    return this.join("\n");
  }

  static List<HeaderEntry> fromString(String text) {
    if (text.isEmpty) {
      return [];
    }

    List<String> list = text.split('\n');
    List<HeaderEntry> hList = [];
    int id = 0;
    for (String item in list) {
      List<String> keyValue = item.split(': ');
      hList.add(HeaderEntry(id, name: keyValue[0], value: keyValue[1]));
      id += 1;
    }
    return hList;
  }
}
