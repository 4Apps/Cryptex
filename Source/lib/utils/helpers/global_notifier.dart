import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:api_requests/utils/models/url/url_resource.dart';
import 'package:api_requests/utils/models/url/selected_url.dart';

class GlobalNotifier with ChangeNotifier {
  SelectedUrl selectedUrl = SelectedUrl(sectionId: 0, urlId: 0);
  UrlResource? selectedUrlItem;

  reload() {
    notifyListeners();
  }

  reloadWithData() {
    notifyListeners();
  }

  onSelectedUrlItem(UrlResource urlItem) {
    this.selectedUrlItem = urlItem;
    notifyListeners();
  }
}
