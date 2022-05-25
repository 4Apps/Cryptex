import 'dart:async';

import 'package:cryptex/config/constants/app_constants.dart';
import 'package:cryptex/utils/models/url/url_section.dart';

import 'package:cryptex/utils/services/sqlite_data_service/base.dart';

extension SQLiteDataProviderUrlSection on SQLiteDataProvider {
  Future<UrlSection> urlResource(int id) async {
    var db = await this.database;

    final List<Map<String, dynamic>> dbRecords =
        await db.query(AppConstants.UrlsSectionsTable, where: 'id = ?', whereArgs: [id]);

    if (dbRecords.length == 0) {
      throw ("Couldn't find url by id $id");
    }

    return UrlSection.fromMap(dbRecords[0]);
  }

  Future<int> insertUrlSection(UrlSection urlSection) async {
    Map<String, dynamic> sectionData = urlSection.toMap();
    sectionData.remove("id");
    sectionData.remove("urls");

    // Update DB
    var db = await this.database;
    int insertedId = await db.insert(AppConstants.UrlsSectionsTable, sectionData);

    return insertedId;
  }

  Future<void> updateUrlSection(UrlSection urlSection) async {
    var urlData = {'name': urlSection.name, 'expanded': urlSection.expanded ? 1 : 0, 'sort': urlSection.sort};

    // Update DB
    var db = await this.database;
    await db.update(
      AppConstants.UrlsSectionsTable,
      urlData,
      where: 'id = ?',
      whereArgs: [urlSection.id],
    );
  }

  Future<void> deleteUrlSection(int id) async {
    var db = await this.database;
    await db.delete(
      AppConstants.UrlsSectionsTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> trucateUrlSections() async {
    var db = await this.database;
    await db.delete(AppConstants.UrlsSectionsTable);
  }
}
