import 'dart:convert';

import 'package:flutter/foundation.dart';

class CallExtendedData {
  late int type;

  static CallExtendedData? parse(String extendedData) {
    try {
      final Map<String, dynamic> dataMap = jsonDecode(extendedData);
      if (dataMap.isNotEmpty) {
        if (dataMap.keys.contains('type')) {
          final type = dataMap['type'] as int;
          final data = CallExtendedData()..type = type;
          return data;
        }
      }
    } catch (e) {
      debugPrint('callExtendedData parse error:$e');
    }
    return null;
  }

  String toJsonString() {
    final dataMap = <String, dynamic>{};
    dataMap['type'] = type;
    return jsonEncode(dataMap);
  }
}
