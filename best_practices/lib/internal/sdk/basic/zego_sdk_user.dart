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
  ValueNotifier<bool> isCameraOnNotifier = ValueNotifier(false);
  ValueNotifier<bool> isUsingSpeaker = ValueNotifier(true);
  ValueNotifier<bool> isMicOnNotifier = ValueNotifier(false);
  ValueNotifier<bool> isUsingFrontCameraNotifier = ValueNotifier(true);

  ValueNotifier<String?> avatarUrlNotifier = ValueNotifier(null);

  @override
  String toString() {
    return 'ZegoSDKUser:{id:$userID, name:$userName, roomID:$roomID, streamID:$streamID, viewID:$viewID}';
  }
}
