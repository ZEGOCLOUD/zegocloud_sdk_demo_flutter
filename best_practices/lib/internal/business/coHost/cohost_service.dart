import 'dart:async';

import 'package:flutter/material.dart';
import '../../../zego_sdk_manager.dart';
import '../../sdk/basic/zego_sdk_user.dart';
import '../../sdk/utils/flutter_extension.dart';

class CoHostService {
  ValueNotifier<ZegoSDKUser?> hostNoti = ValueNotifier(null);

  List<StreamSubscription> subscriptions = [];
  ListNotifier<ZegoSDKUser> coHostUserListNoti = ListNotifier([]);

  void addListener() {
    final expressService = ZEGOSDKManager().expressService;
    subscriptions.addAll([
      expressService.streamListUpdateStreamCtrl.stream
          .listen(onStreamListUpdate),
      expressService.roomUserListUpdateStreamCtrl.stream
          .listen(onRoomUserListUpdate),
    ]);
  }

  void uninit() {
    for (final subscription in subscriptions) {
      subscription.cancel();
    }
  }

  bool isHost(String userID) {
    return hostNoti.value?.userID == userID;
  }

  bool isCoHost(String userID) {
    for (final user in coHostUserListNoti.value) {
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

  bool isLocalUserHost() {
    return isHost(ZEGOSDKManager().currentUser?.userID ?? '');
  }

  void clearData() {
    coHostUserListNoti.clear();
    hostNoti.value = null;
  }

  void startCoHost() {
    coHostUserListNoti.add(ZEGOSDKManager().currentUser!);
  }

  void endCoHost() {
    coHostUserListNoti.removeWhere((element) {
      return element.userID == ZEGOSDKManager().currentUser?.userID;
    });
  }

  void onStreamListUpdate(ZegoRoomStreamListUpdateEvent event) {
    if (event.updateType == ZegoUpdateType.Add) {
      for (final element in event.streamList) {
        if (element.streamID.endsWith('_host')) {
          hostNoti.value = ZEGOSDKManager().getUser(element.user.userID);
        } else if (element.streamID.endsWith('_cohost')) {
          final cohostUser = ZEGOSDKManager().getUser(element.user.userID);
          if (cohostUser != null) {
            coHostUserListNoti.add(cohostUser);
          }
        }
      }
    } else {
      for (final element in event.streamList) {
        if (element.streamID.endsWith('_host')) {
          hostNoti.value = null;
        } else if (element.streamID.endsWith('_cohost')) {
          coHostUserListNoti.removeWhere((coHostUser) {
            return coHostUser.userID == element.user.userID;
          });
        }
      }
    }
  }

  void onRoomUserListUpdate(ZegoRoomUserListUpdateEvent event) {
    for (final user in event.userList) {
      if (event.updateType == ZegoUpdateType.Delete) {
        coHostUserListNoti
            .removeWhere((element) => element.userID == ZEGOSDKManager().currentUser?.userID);
        if (hostNoti.value?.userID == user.userID) {
          hostNoti.value = null;
        }
      }
    }
  }
}
