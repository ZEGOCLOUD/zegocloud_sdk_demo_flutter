import 'package:flutter/foundation.dart';

import '../../../zego_sdk_manager.dart';

class CallUserInfo {
  final String userID;
  ValueNotifier<ZegoSDKUser?> sdkUserNoti = ValueNotifier(null);

  String? get userName => ZEGOSDKManager().zimService.getUserName(userID);

  ValueNotifier<ZIMCallUserState> callUserState = ValueNotifier(ZIMCallUserState.unknown);

  String extendedData = '';
  String? get headUrl => ZEGOSDKManager().zimService.getUserAvatar(userID);
  String get streamID => '${ZEGOSDKManager().expressService.currentRoomID}_${userID}_main';

  ValueNotifier<bool> hasAccepted = ValueNotifier(false);
  ValueNotifier<bool> isWaiting = ValueNotifier(false);

  CallUserInfo({required this.userID});

  void updateCallUserState(ZIMCallUserState state) {
    callUserState.value = state;
    hasAccepted.value = state == ZIMCallUserState.accepted;
    if (state == ZIMCallUserState.received || state == ZIMCallUserState.inviting) {
      isWaiting.value = true;
    } else {
      isWaiting.value = false;
    }
  }
}
