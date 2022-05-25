import 'package:api_requests/utils/models/url/url_resource.dart';

class UrlSection {
  int id;
  String name;
  bool expanded;
  int sort;
  List<UrlResource> urls;

  UrlSection({this.id = 0, this.name = "", this.expanded = true, this.sort = 0, this.urls = const []});

  UrlSection.fromMap(Map<String, dynamic> data)
      : id = data['id'],
        name = data['name'],
        expanded = data['expanded'] == 1,
        sort = data.containsKey('sort') ? data['sort'] : 0,
        urls = data.containsKey('urls')
            ? List<UrlResource>.generate(data['urls'].length, (index) => UrlResource.fromMap(data['urls'][index]))
            : [];

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'expanded': expanded ? 1 : 0,
        'sort': sort,
        'urls': List.generate(urls.length, (index) => urls[index].toMap()),
      };
}
