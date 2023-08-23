import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:live_audio_room_demo/define.dart';
import 'package:live_audio_room_demo/internal/zego_express_service.dart';
import 'package:live_audio_room_demo/live_audio_room_seat.dart';
import 'package:live_audio_room_demo/page/layout_config.dart';
import 'package:live_audio_room_demo/zego_sdk_manager.dart';

class ZegoLiveAudioRoomManager {
  ZegoLiveAudioRoomManager._internal();

  static final ZegoLiveAudioRoomManager shared = ZegoLiveAudioRoomManager._internal();

  static const String roomKey = 'audioRoom';

  int hostSeatIndex = 0;
  Map<String, dynamic> roomExtraInfoDict = {};
  List<StreamSubscription<dynamic>?> subscriptions = [];
  List<ZegoLiveAudioRoomSeat> seatList = [];

  ValueNotifier<bool> isLockSeat = ValueNotifier(false);
  ValueNotifier<ZegoUserInfo?> hostUserNoti = ValueNotifier(null);
  ValueNotifier<ZegoLiveRole> roleNoti = ValueNotifier(ZegoLiveRole.audience);
  bool isBatchOperation = false;

  ZegoLiveAudioRoomLayoutConfig? layoutConfig;

  void initWithConfig(ZegoLiveAudioRoomLayoutConfig config, ZegoLiveRole role) {
    roleNoti.value = role;
    layoutConfig = config;
    subscriptions
      ..add(ZEGOSDKManager.instance.expressService.roomExtraInfoUpdateCtrl.stream.listen(onRoomExtraInfoUpdate))
      ..add(ZEGOSDKManager.instance.expressService.roomStreamExtraInfoStreamCtrl.stream.listen((event) {}))
      ..add(ZEGOSDKManager.instance.expressService.roomUserListUpdateStreamCtrl.stream.listen(onRoomUserListUpdate))
      ..add(ZEGOSDKManager.instance.zimService.roomAttributeUpdateStreamCtrl.stream.listen(roomAttributeUpdate))
      ..add(ZEGOSDKManager.instance.zimService.roomAttributeBatchUpdatedStreamCtrl.stream
          .listen(roomAttributeBatchUpdated));
    initSeat(config);
  }

  void initSeat(ZegoLiveAudioRoomLayoutConfig config) {
    for (var columIndex = 0; columIndex < config.rowConfigs.length; columIndex++) {
      var rowConfig = config.rowConfigs[columIndex];
      for (var rowIndex = 0; rowIndex < rowConfig.count; rowIndex++) {
        ZegoLiveAudioRoomSeat seat = ZegoLiveAudioRoomSeat(seatList.length, rowIndex, columIndex);
        seatList.add(seat);
      }
    }
  }

  bool isSeatLocked() {
    return isLockSeat.value;
  }

  Future<ZegoRoomSetRoomExtraInfoResult> lockSeat() async {
    roomExtraInfoDict['lockseat'] = !isLockSeat.value;
    final dataJson = jsonEncode(roomExtraInfoDict);

    ZegoRoomSetRoomExtraInfoResult result =
        await ZEGOSDKManager.instance.expressService.setRoomExtraInfo(roomKey, dataJson);
    if (result.errorCode == 0) {
      isLockSeat.value = !isLockSeat.value;
    }
    return result;
  }

  Future<ZIMRoomAttributesOperatedCallResult?> tryTakeSeat(int seatIndex) async {
    ZIMRoomAttributesOperatedCallResult? result = await ZEGOSDKManager.instance.zimService
        .setRoomAttributes(seatIndex.toString(), ZEGOSDKManager.instance.localUser?.userID ?? '', false, true, true);
    if (result != null) {
      if (!result.errorKeys.contains(seatIndex.toString())) {
        for (var element in seatList) {
          if (element.seatIndex == seatIndex) {
            roleNoti.value = ZegoLiveRole.coHost;
            element.currentUser.value = ZEGOSDKManager.instance.localUser;
            break;
          }
        }
      }
    }
    return result;
  }

  Future<ZIMRoomAttributesOperatedCallResult?> takeSeat(int seatIndex) async {
    ZIMRoomAttributesOperatedCallResult? result = await ZEGOSDKManager.instance.zimService
        .setRoomAttributes(seatIndex.toString(), ZEGOSDKManager.instance.localUser?.userID ?? '', false, true, true);
    if (result != null) {
      if (!result.errorKeys.contains(seatIndex.toString())) {
        for (var element in seatList) {
          if (element.seatIndex == seatIndex) {
            if (roleNoti.value != ZegoLiveRole.host) {
              roleNoti.value = ZegoLiveRole.coHost;
            }
            element.currentUser.value = ZEGOSDKManager.instance.localUser;
            break;
          }
        }
      }
    }
    return result;
  }

  Future<ZIMRoomAttributesBatchOperatedResult?> switchSeat(int fromSeatIndex, int toSeatIndex) async {
    if (!isBatchOperation) {
      ZEGOSDKManager.instance.zimService.beginRoomPropertiesBatchOperation();
      isBatchOperation = true;
      tryTakeSeat(toSeatIndex);
      leaveSeat(fromSeatIndex);
      ZIMRoomAttributesBatchOperatedResult? result =
          await ZEGOSDKManager.instance.zimService.endRoomPropertiesBatchOperation();
      isBatchOperation = false;
      return result;
    }
    return null;
  }

  Future<ZIMRoomAttributesOperatedCallResult?> leaveSeat(int seatIndex) async {
    ZIMRoomAttributesOperatedCallResult? result =
        await ZEGOSDKManager.instance.zimService.deleteRoomAttributes([seatIndex.toString()]);
    if (result != null) {
      if (result.errorKeys.contains(seatIndex.toString())) {
        for (var element in seatList) {
          if (element.seatIndex == seatIndex) {
            element.currentUser.value = null;
          }
        }
      }
    }
    return result;
  }

  Future<ZIMRoomAttributesOperatedCallResult?> removeSpeakerFromSeat(String userID) async {
    for (var seat in seatList) {
      if (seat.currentUser.value?.userID == userID) {
        ZIMRoomAttributesOperatedCallResult? result = await leaveSeat(seat.seatIndex);
        return result;
      }
    }
    return null;
  }

  void leaveRoom() {
    ZEGOSDKManager.instance.logoutRoom();
    clear();
  }

  void clear() {
    roomExtraInfoDict.clear();
    subscriptions.clear();
    seatList.clear();
    isLockSeat.value = false;
    hostUserNoti.value = null;
    isBatchOperation = false;
    for (final subscription in subscriptions) {
      subscription?.cancel();
    }
  }

  Future<ZegoRoomSetRoomExtraInfoResult?> setSelfHost() async {
    if (ZEGOSDKManager.instance.localUser == null) {
      return null;
    }
    roomExtraInfoDict['host'] = ZEGOSDKManager.instance.localUser!.userID;
    final dataJson = jsonEncode(roomExtraInfoDict);
    ZegoRoomSetRoomExtraInfoResult result =
        await ZEGOSDKManager.instance.expressService.setRoomExtraInfo(roomKey, dataJson);
    if (result.errorCode == 0) {
      ZEGOSDKManager.instance.localUser?.roleNotifier.value = ZegoLiveRole.host;
    }
    return result;
  }

  Future<ZIMUserAvatarUrlUpdatedResult> updateUserAvatarUrl(String url) async {
    return await ZEGOSDKManager.instance.zimService.updateUserAvatarUrl(url);
  }

  Future<ZIMUsersInfoQueriedResult> queryUsersInfo(List<String> userIDList) async {
    return await ZEGOSDKManager.instance.zimService.queryUsersInfo(userIDList);
  }

  String? getUserAvatar(String userID) {
    return ZEGOSDKManager.instance.zimService.getUserAvatar(userID);
  }

  void onRoomExtraInfoUpdate(ZegoRoomExtraInfoEvent event) {
    for (var extraInfo in event.extraInfoList) {
      if (extraInfo.key == roomKey) {
        roomExtraInfoDict = jsonDecode(extraInfo.value);
        if (roomExtraInfoDict.containsKey('lockseat')) {
          bool temp = roomExtraInfoDict['lockseat'];
          isLockSeat.value = temp;
        }
        if (roomExtraInfoDict.containsKey('host')) {
          String tempUserID = roomExtraInfoDict['host'];
          hostUserNoti.value = getHostUser(tempUserID);
        }
      }
    }
  }

  void onRoomUserListUpdate(ZegoRoomUserListUpdateEvent event) {
    if (event.updateType == ZegoUpdateType.Add) {
      List<String> userIDList = [];
      for (var element in event.userList) {
        userIDList.add(element.userID);
        ZEGOSDKManager.instance.zimService.roomAttributesMap.forEach((key, value) {
          if (element.userID == value) {
            for (var seat in seatList) {
              if (seat.seatIndex.toString() == key) {
                seat.currentUser.value = ZEGOSDKManager.instance.getUser(value);
                break;
              }
            }
          }
        });
      }
      queryUsersInfo(userIDList);
    } else {
      // empty seat
    }
  }

  ZegoUserInfo? getHostUser(String userID) {
    return ZEGOSDKManager().getUser(userID);
  }

  //zimservice event
  void roomAttributeUpdate(ZIMServiceRoomAttributeUpdateEvent event) {
    if (event.updateInfo.action == ZIMRoomAttributesUpdateAction.set) {
      event.updateInfo.roomAttributes.forEach((key, value) {
        for (var element in seatList) {
          if (element.seatIndex.toString() == key) {
            if (value == ZEGOSDKManager.instance.localUser?.userID) {
              element.currentUser.value = ZEGOSDKManager.instance.localUser;
            } else {
              element.currentUser.value = ZEGOSDKManager.instance.getUser(value);
            }
          }
        }
      });
    } else {
      event.updateInfo.roomAttributes.forEach((key, value) {
        for (var element in seatList) {
          if (element.seatIndex.toString() == key) {
            element.currentUser.value = null;
          }
        }
      });
    }
  }

  void roomAttributeBatchUpdated(ZIMServiceRoomAttributeBatchUpdatedEvent event) {
    for (var updateInfo in event.updateInfo) {
      if (updateInfo.action == ZIMRoomAttributesUpdateAction.set) {
        updateInfo.roomAttributes.forEach((key, value) {
          for (var element in seatList) {
            if (element.seatIndex.toString() == key) {
              if (value == ZEGOSDKManager.instance.localUser?.userID) {
                element.currentUser.value = ZEGOSDKManager.instance.localUser;
              } else {
                element.currentUser.value = ZEGOSDKManager.instance.getUser(value);
              }
            }
          }
        });
      } else {
        updateInfo.roomAttributes.forEach((key, value) {
          for (var element in seatList) {
            if (element.seatIndex.toString() == key) {
              element.currentUser.value = null;
            }
          }
        });
      }
    }
  }
}
