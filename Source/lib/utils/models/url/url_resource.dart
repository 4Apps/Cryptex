import 'package:api_requests/utils/models/url/header_entry.dart';
import 'package:api_requests/utils/models/url/request_type.dart';

class UrlResource {
  int id;
  int sectionId;
  int sort;
  String name;
  String url;
  RequestType type;
  String requestData;
  List<HeaderEntry> requestHeaders;
  String responseData;
  int responseCode;
  List<HeaderEntry> responseHeaders;

  UrlResource(
    this.id,
    this.sectionId, {
    this.sort = 0,
    this.name = "",
    this.url = "",
    this.type = RequestType.POST,
    this.requestData = "",
    this.requestHeaders = const [],
    this.responseCode = 200,
    this.responseData = "",
    this.responseHeaders = const [],
  });

  UrlResource.from(UrlResource data)
      : id = data.id,
        sectionId = data.sectionId,
        sort = data.sort,
        name = data.name,
        url = data.url,
        type = data.type,
        requestData = data.requestData,
        requestHeaders = data.requestHeaders,
        responseCode = data.responseCode,
        responseData = data.responseData,
        responseHeaders = data.responseHeaders;

  UrlResource.fromMap(Map<String, dynamic> data)
      : id = data['id'],
        sectionId = data['sectionId'],
        sort = data.containsKey('sectionId') ? data['sectionId'] : 0,
        name = data['name'],
        url = data['url'],
        type = RequestTypeExtension.fromInt(data['type']),
        requestData = data['requestData'],
        requestHeaders = List<HeaderEntry>.generate(
            data['requestHeaders'].length, (index) => HeaderEntry.fromMap(data['requestHeaders'][index])),
        responseCode = data.containsKey('responseCode') ? data['responseCode'] : 200,
        responseData = data.containsKey('lastResponse') ? data['lastResponse'] : data['responseData'],
        responseHeaders = List<HeaderEntry>.generate(
            data['responseHeaders'].length, (index) => HeaderEntry.fromMap(data['responseHeaders'][index]));

  Map<String, dynamic> toMap() => {
        'id': id,
        'sectionId': sectionId,
        'sort': sort,
        'name': name,
        'url': url,
        'type': type.asInt(),
        'requestData': requestData,
        'requestHeaders': List.generate(requestHeaders.length, (index) => requestHeaders[index].toMap()),
        'responseCode': responseCode,
        'responseData': responseData,
        'responseHeaders': List.generate(responseHeaders.length, (index) => responseHeaders[index].toMap()),
      };
}
