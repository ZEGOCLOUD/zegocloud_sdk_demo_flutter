import 'dart:convert';

class PKExtendedData {
  String? roomID;
  String? userName;
  int type = 91000;
  String userID = '';
  bool autoAccept = false;

  static const START_PK = 91000;

  static PKExtendedData? parse(String extendedData) {
    final Map<String, dynamic> extendedDataMap = jsonDecode(extendedData);
    if (extendedDataMap.keys.contains('type')) {
      final type = extendedDataMap['type'] as int;
      if (type == START_PK) {
        final data = PKExtendedData();
        data.type = type;
        data.roomID = extendedDataMap['room_id'] as String;
        data.userName = extendedDataMap['user_name'] as String;
        if (extendedDataMap.keys.contains('user_id')) {
          data.userID = extendedDataMap['user_id'] as String;
        }
        if (extendedDataMap.keys.contains('auto_accept')) {
          data.autoAccept = extendedDataMap['auto_accept'] as bool;
        }
        return data;
      }
    }
    return null;
  }

  String? toJsonString() {
    final map = <String, dynamic>{};
    map['room_id'] = roomID;
    map['user_name'] = userName;
    map['type'] = type;
    if (userID.isNotEmpty) {
      map['user_id'] = userID;
    }
    map['auto_accept'] = autoAccept;
    return jsonEncode(map);
  }
}
