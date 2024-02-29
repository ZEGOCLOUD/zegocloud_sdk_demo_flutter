import 'package:flutter/material.dart';

import '../../../zego_sdk_manager.dart';
import '../../sdk/utils/flutter_extension.dart';

bool isHostStreamID(String streamID) {
  return streamID.endsWith('_host');
}

class CoHostService {
  ValueNotifier<ZegoSDKUser?> hostNoti = ValueNotifier(null);
  ListNotifier<ZegoSDKUser> coHostUserListNotifier = ListNotifier([]);

  bool isHost(String userID) {
    return hostNoti.value?.userID == userID;
  }

  bool isCoHost(String userID) {
    for (final user in coHostUserListNotifier.value) {
      if (user.userID == userID) {
        return true;
      }
    }
    return false;
  }

  bool isAudience(String userID) {
    if (isHost(userID) || isCoHost(userID)) {
      return false;
    }
    return true;
  }

  bool iamHost() {
    return isHost(ZEGOSDKManager().currentUser!.userID);
  }

  void clearData() {
    coHostUserListNotifier.clear();
    hostNoti.value = null;
  }

  void startCoHost() {
    coHostUserListNotifier.add(ZEGOSDKManager().currentUser!);
  }

  void endCoHost() {
    coHostUserListNotifier.removeWhere((element) {
      return element.userID == ZEGOSDKManager().currentUser!.userID;
    });
  }

  void onReceiveStreamUpdate(ZegoRoomStreamListUpdateEvent event) {
    if (event.updateType == ZegoUpdateType.Add) {
      for (final element in event.streamList) {
        if (isHostStreamID(element.streamID)) {
          hostNoti.value = ZEGOSDKManager().getUser(element.user.userID);
        } else if (element.streamID.endsWith('_cohost')) {
          final cohostUser = ZEGOSDKManager().getUser(element.user.userID);
          if (cohostUser != null) {
            coHostUserListNotifier.add(cohostUser);
          }
        }
      }
    } else {
      for (final element in event.streamList) {
        if (isHostStreamID(element.streamID)) {
          hostNoti.value = null;
        } else if (element.streamID.endsWith('_cohost')) {
          coHostUserListNotifier.removeWhere((coHostUser) {
            return coHostUser.userID == element.user.userID;
          });
        }
      }
    }
  }

  void onRoomUserListUpdate(ZegoRoomUserListUpdateEvent event) {
    for (final user in event.userList) {
      if (event.updateType == ZegoUpdateType.Delete) {
        coHostUserListNotifier.removeWhere((element) => element.userID == ZEGOSDKManager().currentUser!.userID);
        if (hostNoti.value?.userID == user.userID) {
          hostNoti.value = null;
        }
      }
    }
  }
}
