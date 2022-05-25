import 'package:api_requests/utils/models/url/request_type.dart';
import 'package:http/http.dart' as http;

import 'package:api_requests/utils/models/url/url_resource.dart';

typedef RequestCallbackFunc = void Function(UrlResource, http.Response?, String?);

void makeRequest(UrlResource urlItem, RequestCallbackFunc callback) async {
  Map<String, String> headers = {};

  for (var item in urlItem.requestHeaders) {
    headers[item.name] = item.value;
  }

  http.Response response;

  try {
    switch (urlItem.type) {
      case RequestType.GET:
        response = await http.get(
          Uri.parse(urlItem.url),
          headers: headers,
        );
        break;
      case RequestType.POST:
        response = await http.post(
          Uri.parse(urlItem.url),
          body: urlItem.requestData,
          headers: headers,
        );
        break;
      case RequestType.PUT:
        response = await http.put(
          Uri.parse(urlItem.url),
          body: urlItem.requestData,
          headers: headers,
        );
        break;
      case RequestType.PATCH:
        response = await http.patch(
          Uri.parse(urlItem.url),
          body: urlItem.requestData,
          headers: headers,
        );
        break;
      case RequestType.DELETE:
        response = await http.delete(
          Uri.parse(urlItem.url),
          body: urlItem.requestData,
          headers: headers,
        );
        break;
      case RequestType.HEAD:
        response = await http.head(
          Uri.parse(urlItem.url),
          headers: headers,
        );
        break;
    }

    // } on SocketException {
    //   callback(urlItem, null, 'Connection failed');
  } catch (error) {
    callback(urlItem, null, 'Unknown error: $error');
    return;
  }

  callback(urlItem, response, null);
}
