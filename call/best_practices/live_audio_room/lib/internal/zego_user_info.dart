import 'package:flutter/material.dart';
import 'package:live_audio_room_demo/define.dart';

class ZegoUserInfo {
  ZegoUserInfo({
    required this.userID,
    required this.userName,
  });

  late String userID;
  late String userName;

  ValueNotifier<ZegoLiveRole> roleNotifier = ValueNotifier(ZegoLiveRole.audience);
  String? streamID;
  int viewID = -1;
  ValueNotifier<Widget?> videoViewNotifier = ValueNotifier(null);
  ValueNotifier<bool> isCamerOnNotifier = ValueNotifier(false);
  ValueNotifier<bool> isMicOnNotifier = ValueNotifier(false);
  ValueNotifier<String?> avatarUrlNotifier = ValueNotifier(null);
}
