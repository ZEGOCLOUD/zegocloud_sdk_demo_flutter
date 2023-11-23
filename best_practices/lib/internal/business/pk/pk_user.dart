import 'dart:convert';
import 'dart:ffi';

import 'package:flutter/material.dart';

import '../../../zego_sdk_manager.dart';

class PKUser {
  final String userID;
  String roomID = '';
  String userName = '';

  ValueNotifier<bool> camera = ValueNotifier(false);
  ValueNotifier<bool> microphone = ValueNotifier(false);
  ZIMCallUserState callUserState = ZIMCallUserState.unknown;
  bool isMute = false;
  String extendedData = '';
  Rect rect = Rect.zero;

  bool _hasAccepted = false;
  bool get hasAccepted {
    return _hasAccepted;
  }

  bool _isWaiting = false;
  bool get isWaiting {
    return _isWaiting;
  }

  String get pkUserStream {
    return '${roomID}_${userID}_main_host';
  }

  ZegoSDKUser sdkUser;

  PKUser({
    required this.userID,
    required this.sdkUser,
  });

  String toJsonString() {
    final userMap = <String, dynamic>{};
    userMap['uid'] = userID;
    userMap['rid'] = roomID;
    userMap['u_name'] = userName;
    final rectMap = <String, double>{};
    rectMap['top'] = rect.top;
    rectMap['left'] = rect.left;
    rectMap['right'] = rect.right;
    rectMap['bottom'] = rect.bottom;
    userMap['rect'] = rectMap;
    return jsonEncode(userMap);
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};
    map['uid'] = userID;
    map['rid'] = roomID;
    map['u_name'] = userName;
    final rectMap = <String, dynamic>{};
    rectMap['top'] = rect.top;
    rectMap['left'] = rect.left;
    rectMap['right'] = rect.right;
    rectMap['bottom'] = rect.bottom;
    map['rect'] = rectMap;
    return map;
  }

  static PKUser parse(String string) {
    final Map<String, dynamic> userMap = jsonDecode(string);
    final String uid = userMap['uid'];
    final String rid = userMap['rid'];
    final name = userMap['u_name'] ?? '';
    final Map<String, double> rectMap = userMap['rect'];
    final top = rectMap['top'] ?? 0;
    final left = rectMap['left'] ?? 0;
    final right = rectMap['right'] ?? 0;
    final bottom = rectMap['bottom'] ?? 0;
    final user = PKUser(userID: uid, sdkUser: ZegoSDKUser(userID: uid, userName: name))
      ..roomID = rid
      ..userName = name
      ..rect = Rect.fromLTRB(left, top, right, bottom);
    return user;
  }
}
