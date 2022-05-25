import 'dart:convert';
import 'dart:io';
import 'dart:async';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:cryptex/config/constants/app_constants.dart';
import 'package:cryptex/utils/interfaces/data_provider.dart';

class SQLiteDataProvider implements DataProviderFactory {
  // ! Custom Provider Implementation
  static final SQLiteDataProvider shared = SQLiteDataProvider();
  Database? _database;

  SQLiteDataProvider() {
    initDB().then((value) => {this._database = value});
  }

  // * Get DB
  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await initDB();
    return _database!;
  }

  // * Init DB
  Future<void> initDbV1(Database db) async {
    // UrlsSections
    await db.execute("CREATE TABLE ${AppConstants.UrlsSectionsTable} ("
        "id INTEGER PRIMARY KEY,"
        "name TEXT"
        ")");

    // Urls
    await db.execute("CREATE TABLE ${AppConstants.UrlsTable} ("
        "id INTEGER PRIMARY KEY,"
        "sectionId INTEGER,"
        "name TEXT,"
        "url TEXT,"
        "type INTEGER,"
        "requestData TEXT,"
        "requestHeaders TEXT,"
        "lastResponse TEXT"
        ")");

    // * Migrate from old app
    String dbPath = join((await getApplicationDocumentsDirectory()).path, "migrate.json");
    print("Migrate from json: $dbPath");

    File jsonFile = File(dbPath);
    if (await jsonFile.exists()) {
      final fileContents = await jsonFile.readAsString();
      final jsonContents = jsonDecode(fileContents);

      for (int sectionIndex = 0; sectionIndex < jsonContents.length; sectionIndex++) {
        final section = jsonContents[sectionIndex];
        await db.execute("INSERT INTO ${AppConstants.UrlsSectionsTable} ('id', 'name') values (?, ?)", [
          section["id"],
          section["name"],
        ]);

        for (int urlIndex = 0; urlIndex < section["urls"].length; urlIndex++) {
          final url = section["urls"][urlIndex];
          await db.execute(
              "INSERT INTO ${AppConstants.UrlsTable} "
              "('sectionId', 'name', 'url', 'type', 'requestData', 'requestHeaders', 'lastResponse') "
              "values (?, ?, ?, ?, ?, ?, ?)",
              [
                section["id"], // sectionId
                url["name"], // name
                url["url"], // url
                url["type"], // type
                url["request_data"], // requestData
                jsonEncode(url["request_headers"]), // requestHeaders
                url["last_response"] // lastResponse
              ]);
        }
      }

      jsonFile.delete();
      return;
    }

    // * Data
    await db.insert(AppConstants.UrlsSectionsTable, {"name": "Example Category"});
    await db.insert(AppConstants.UrlsTable, {
      "sectionId": 1,
      "name": "Untitled",
      "url": "",
      "type": 1,
      "requestData": "",
      "requestHeaders": "[{\"id\": 1, \"name\": \"Content-Type\", \"value\": \"application/json\"}]",
      "lastResponse": ""
    });
  }

  Future<void> initDbV2(Database db) async {
    // Settings
    await db.execute("CREATE TABLE ${AppConstants.SettingsTable} ("
        "id INTEGER PRIMARY KEY,"
        "name TEXT UNIQUE,"
        "value TEXT"
        ")");

    await db.insert(AppConstants.SettingsTable,
        {"name": AppConstants.SettingsKeySelectedUrl, "value": '{"sectionId": 1, "urlId": 1}'});
  }

  Future<void> initDbV3(Database db) async {
    // Add responseHeaders
    await db.execute("ALTER TABLE ${AppConstants.UrlsTable} "
        "ADD COLUMN responseHeaders TEXT DEFAULT '[]'");

    // Add section settings
    await db.execute("ALTER TABLE ${AppConstants.UrlsSectionsTable} "
        "ADD COLUMN expanded INTEGER DEFAULT 1");

    // Add sort columns
    await db.execute("ALTER TABLE ${AppConstants.UrlsSectionsTable} "
        "ADD COLUMN sort INTEGER DEFAULT 0");

    await db.execute("ALTER TABLE ${AppConstants.UrlsTable} "
        "ADD COLUMN sort INTEGER DEFAULT 0");
  }

  Future<void> initDbV4(Database db) async {
    await db.execute("ALTER TABLE ${AppConstants.UrlsTable} "
        "ADD COLUMN responseCode INTEGER DEFAULT 200");

    await db.execute("ALTER TABLE ${AppConstants.UrlsTable} "
        "RENAME COLUMN lastResponse TO responseData");
  }

  Future<String> dbPath() async {
    String dbPath = "";

    if (kIsWeb) {
      dbPath = "ApiRequests.db";
    } else {
      try {
        dbPath = join((await getLibraryDirectory()).path, "ApiRequests.db");
      } catch (error) {
        dbPath = join((await getApplicationSupportDirectory()).path, "ApiRequests.db");
      }
      print("Using $dbPath");
    }

    print("Using DB Path: $dbPath");
    return dbPath;
  }

  Future<Database> initDB() async {
    String dbPath = await this.dbPath();

    return await openDatabase(dbPath, version: AppConstants.DbVersion, onOpen: (db) {},
        onCreate: (Database db, int version) async {
      await this.initDbV1(db);
      await this.initDbV2(db);
      await this.initDbV3(db);
      await this.initDbV4(db);
    }, onUpgrade: (db, oldVersion, newVersion) async {
      // -> V2
      if (oldVersion == 1) {
        await this.initDbV2(db);
        await this.initDbV3(db);
        return;
      }

      // -> V3
      if (oldVersion == 2) {
        await this.initDbV3(db);
        return;
      }

      // -> V4
      if (oldVersion == 3) {
        await this.initDbV4(db);
        return;
      }
    });
  }
}
