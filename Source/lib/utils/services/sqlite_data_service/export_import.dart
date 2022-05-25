import 'dart:convert';
import 'dart:async';

import 'package:cryptex/config/constants/app_constants.dart';
import 'package:cryptex/utils/models/settings.dart';
import 'package:cryptex/utils/models/url/url_section.dart';
import 'package:cryptex/utils/models/url/url_resource.dart';

import 'package:cryptex/utils/services/sqlite_data_service/url_section.dart';
import 'package:cryptex/utils/services/sqlite_data_service/url_resource.dart';

import 'package:cryptex/utils/services/sqlite_data_service/base.dart';

class JsonExport {
  int version;
  List<Settings> settings;
  List<UrlResource> urls;
  List<UrlSection> urlSections;

  JsonExport(this.version, this.settings, this.urlSections, this.urls);

  JsonExport.fromMap(Map<String, dynamic> data)
      : version = data['version'],
        settings =
            List<Settings>.generate(data['settings'].length, (index) => Settings.fromMap(data['settings'][index])),
        urlSections = List<UrlSection>.generate(
            data['url_sections'].length, (index) => UrlSection.fromMap(data['url_sections'][index])),
        urls = List<UrlResource>.generate(data['urls'].length, (index) => UrlResource.fromMap(data['urls'][index]));

  Map<String, dynamic> toMap() => {
        'version': version,
        'settings': List.generate(settings.length, (index) => settings[index].toMap()),
        'url_sections': List.generate(urlSections.length, (index) => urlSections[index].toMap()),
        'urls': List.generate(urls.length, (index) => urls[index].toMap()),
      };
}

extension SQLiteDataProviderUrlResource on SQLiteDataProvider {
  Future<String> makeExportJson() async {
    var db = await this.database;

    final List<Map<String, dynamic>> settingsRaw =
        await db.rawQuery("SELECT s.* FROM ${AppConstants.SettingsTable} AS s");
    final List<Map<String, dynamic>> sectionsRaw =
        await db.rawQuery("SELECT * FROM ${AppConstants.UrlsSectionsTable} AS us");
    final List<Map<String, dynamic>> urlsRaw = await db.rawQuery("SELECT u.* FROM ${AppConstants.UrlsTable} AS u");

    var settings = List<Settings>.generate(settingsRaw.length, (index) => Settings.fromMap(settingsRaw[index]));
    var urlSections = List<UrlSection>.generate(sectionsRaw.length, (index) => UrlSection.fromMap(sectionsRaw[index]));
    var urls = List<UrlResource>.generate(urlsRaw.length, (index) {
      var url = Map<String, dynamic>.from(urlsRaw[index]);
      url['requestHeaders'] = jsonDecode(url['requestHeaders']);
      url['responseHeaders'] = jsonDecode(url['responseHeaders']);
      return UrlResource.fromMap(url);
    });
    var jsonExport = JsonExport(AppConstants.DbVersion, settings, urlSections, urls);
    var jsonData = jsonExport.toMap();
    var jsonString = jsonEncode(jsonData);

    // For debugging:
    // JsonEncoder encoder = new JsonEncoder.withIndent('  ');
    // String jsonString = encoder.convert(jsonData);

    return jsonString;
  }

  Future<void> importJson(JsonExport dataToImport) async {
    for (var urlSection in dataToImport.urlSections) {
      await SQLiteDataProvider.shared.insertUrlSection(urlSection).then((newSectionId) async {
        for (var urlItem in dataToImport.urls) {
          if (urlSection.id == urlItem.sectionId) {
            urlItem.sectionId = newSectionId;
            await SQLiteDataProvider.shared.insertUrlResource(urlItem);
          }
        }
      });
    }
  }
}
