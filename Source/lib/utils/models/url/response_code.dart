import 'package:flutter/material.dart';

enum ResponseStatus { SUCCESS, FAILED }

extension ResponseStatusExtension on ResponseStatus {
  Color get color {
    switch (this) {
      case ResponseStatus.SUCCESS:
        return Colors.green;
      case ResponseStatus.FAILED:
        return Colors.red;
    }
  }

  static ResponseStatus fromHttpStatus(int httpCode) {
    if (httpCode >= 200 && httpCode < 300) {
      return ResponseStatus.SUCCESS;
    }

    return ResponseStatus.FAILED;
  }
}

class ResponseCode {
  final int code;
  ResponseStatus status;

  ResponseCode(this.code) : this.status = ResponseStatusExtension.fromHttpStatus(code);
}
