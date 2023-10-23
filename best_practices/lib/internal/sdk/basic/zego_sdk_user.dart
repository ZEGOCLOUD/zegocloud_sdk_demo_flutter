import 'package:flutter/material.dart';

class ZegoSDKUser {
  ZegoSDKUser({
    required this.userID,
    required this.userName,
  });

  late String userID;
  late String userName;
  String roomID = '';

  String? streamID;
  int viewID = -1;
  ValueNotifier<Widget?> videoViewNotifier = ValueNotifier(null);
  ValueNotifier<bool> isCamerOnNotifier = ValueNotifier(false);
  ValueNotifier<bool> isMicOnNotifier = ValueNotifier(false);
  ValueNotifier<String?> avatarUrlNotifier = ValueNotifier(null);
}
