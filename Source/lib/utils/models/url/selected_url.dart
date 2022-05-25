class SelectedUrl {
  final int sectionId;
  final int urlId;

  SelectedUrl({this.sectionId = 0, this.urlId = 0});

  SelectedUrl.fromMap(Map<String, dynamic> data)
      : sectionId = data['sectionId'],
        urlId = data['urlId'];

  Map<String, dynamic> toMap() => {'sectionId': sectionId, 'urlId': urlId};

  @override
  String toString() {
    return "sectionId: $sectionId, urlId: $urlId";
  }
}
