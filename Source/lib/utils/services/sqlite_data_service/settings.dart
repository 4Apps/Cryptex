import 'dart:convert';
import 'dart:async';

import 'package:cryptex/config/constants/app_constants.dart';

import 'package:cryptex/utils/services/sqlite_data_service/base.dart';

extension SQLiteDataProviderSettings on SQLiteDataProvider {
  Future<T> settings<T>(String name) async {
    var db = await this.database;

    final List<Map<String, dynamic>> settingsRecords = await db.query('Settings', where: 'name = ?', whereArgs: [name]);

    if (settingsRecords.length == 0) {
      throw ("Couldn't find settings record by name $name");
    }

    T recordValue = settingsRecords[0]['value'];
    return recordValue;
  }

  Future<T> settingsJson<T>(String name, T factory(Map<String, dynamic> data)) async {
    String stringValue = await this.settings(name);
    return factory(jsonDecode(stringValue) as Map<String, dynamic>);
  }

  Future<void> setSettings(String name, String value) async {
    var db = await this.database;

    // Update
    int updateCount = await db.update(AppConstants.SettingsTable, {"name": name, "value": value},
        where: 'name = ?', whereArgs: [name]);

    // Insert
    if (updateCount == 0) {
      await db.insert(AppConstants.SettingsTable, {"name": name, "value": value});
    }
  }

  Future<void> setSettingsJson(String name, dynamic mapObject) async {
    String newValue = jsonEncode(mapObject);
    return this.setSettings(name, newValue);
  }
}
