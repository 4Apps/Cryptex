import 'dart:convert';
import 'dart:async';

import 'package:cryptex/config/constants/app_constants.dart';
import 'package:cryptex/utils/models/url/url_section.dart';
import 'package:cryptex/utils/models/url/url_resource.dart';

import 'package:cryptex/utils/services/sqlite_data_service/base.dart';

extension SQLiteDataProviderUrlResource on SQLiteDataProvider {
  Future<List<UrlSection>> urlsList() async {
    var db = await this.database;

    final List<Map<String, dynamic>> sections =
        await db.rawQuery("SELECT * FROM ${AppConstants.UrlsSectionsTable} AS us ORDER BY sort, id ASC");
    final List<Map<String, dynamic>> urlsRecords =
        await db.rawQuery("SELECT u.* FROM ${AppConstants.UrlsTable} AS u ORDER BY sort, id ASC");

    return List.generate(sections.length, (i) {
      Map<String, dynamic> section = Map.of(sections[i]);

      section['urls'] = urlsRecords.where((element) => element['sectionId'] == section["id"]).map((e) {
        e = Map.from(e);
        e['requestHeaders'] = jsonDecode(e['requestHeaders']);
        e['responseHeaders'] = e.containsKey('responseHeaders') ? jsonDecode(e['responseHeaders']) : [];
        return e;
      }).toList();

      return UrlSection.fromMap(section);
    });
  }

  Future<UrlResource> urlResource(int id) async {
    var db = await this.database;

    final List<Map<String, dynamic>> urlRecords =
        await db.query(AppConstants.UrlsTable, where: 'id = ?', whereArgs: [id]);

    if (urlRecords.length == 0) {
      throw ("Couldn't find url by id $id");
    }

    return UrlResource.fromMap(urlRecords[0]);
  }

  Future<int> insertUrlResource(UrlResource urlResource) async {
    Map<String, dynamic> urlData = urlResource.toMap();
    urlData["requestHeaders"] = jsonEncode(urlData["requestHeaders"]);
    urlData["responseHeaders"] = jsonEncode(urlData["responseHeaders"]);
    urlData.remove("id");

    // Update DB
    var db = await this.database;
    int insertedId = await db.insert(AppConstants.UrlsTable, urlData);

    return insertedId;
  }

  Future<void> saveUrlResource(UrlResource urlItem) async {
    Map<String, dynamic> urlData = urlItem.toMap();
    urlData["requestHeaders"] = jsonEncode(urlData["requestHeaders"]);
    urlData["responseHeaders"] = jsonEncode(urlData["responseHeaders"]);

    // Update DB
    var db = await this.database;
    await db.update(
      AppConstants.UrlsTable,
      urlData,
      where: 'id = ?',
      whereArgs: [urlItem.id],
    );
  }

  Future<void> deleteUrlResource(int id) async {
    var db = await this.database;
    await db.delete(
      AppConstants.UrlsTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteMultipleUrlResources(List<int> ids) async {
    var idsStr = ids.join(',');
    var db = await this.database;
    await db.delete(AppConstants.UrlsTable, where: 'id IN ($idsStr)');
  }

  Future<void> trucateUrlResources() async {
    var db = await this.database;
    await db.delete(AppConstants.UrlsTable);
  }
}
