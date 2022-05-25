enum RequestType { GET, POST, HEAD, PUT, PATCH, DELETE }

extension RequestTypeExtension on RequestType {
  // static List<String> asList() {
  //   return ['GET', 'POST', 'HEAD', 'PUT', 'DELETE', 'PATCH'];
  // }

  static List<RequestType> asList() {
    return [
      RequestType.GET,
      RequestType.POST,
      RequestType.PUT,
      RequestType.PATCH,
      RequestType.DELETE,
      RequestType.HEAD,
    ];
  }

  static fromString(String text) {
    switch (text) {
      case "GET":
        return RequestType.GET;
      case "POST":
        return RequestType.POST;
      case "PUT":
        return RequestType.PUT;
      case "PATCH":
        return RequestType.PATCH;
      case "DELETE":
        return RequestType.DELETE;
      case "HEAD":
        return RequestType.HEAD;
    }
  }

  static fromInt(int code) {
    switch (code) {
      case 1:
        return RequestType.GET;
      case 2:
        return RequestType.POST;
      case 4:
        return RequestType.PUT;
      case 5:
        return RequestType.PATCH;
      case 6:
        return RequestType.DELETE;
      case 3:
        return RequestType.HEAD;
    }
  }

  String asString() {
    switch (this) {
      case RequestType.GET:
        return "GET";
      case RequestType.POST:
        return "POST";
      case RequestType.PUT:
        return "PUT";
      case RequestType.PATCH:
        return "PATCH";
      case RequestType.DELETE:
        return "DELETE";
      case RequestType.HEAD:
        return "HEAD";
    }
  }

  int asInt() {
    switch (this) {
      case RequestType.GET:
        return 1;
      case RequestType.POST:
        return 2;
      case RequestType.PUT:
        return 4;
      case RequestType.PATCH:
        return 5;
      case RequestType.DELETE:
        return 6;
      case RequestType.HEAD:
        return 3;
    }
  }
}
