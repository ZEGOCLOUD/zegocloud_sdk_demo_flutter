import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'internal/business/audioRoom/live_audio_room_seat.dart';
import 'internal/business/audioRoom/layout_config.dart';
import 'internal/business/audioRoom/room_seat_service.dart';
import 'main.dart';
import 'zego_sdk_manager.dart';

class ZegoLiveAudioRoomManager {
  ZegoLiveAudioRoomManager._internal();

  static final ZegoLiveAudioRoomManager instance =
      ZegoLiveAudioRoomManager._internal();

  static const String roomKey = 'audioRoom';

  Map<String, dynamic> roomExtraInfoDict = {};
  List<StreamSubscription<dynamic>> subscriptions = [];

  ValueNotifier<bool> isLockSeat = ValueNotifier(false);
  ValueNotifier<ZegoSDKUser?> hostUserNoti = ValueNotifier(null);
  ValueNotifier<ZegoLiveRole> roleNoti = ValueNotifier(ZegoLiveRole.audience);

  RoomSeatService? roomSeatService;

  ZegoLiveAudioRoomLayoutConfig? get layoutConfig {
    return roomSeatService?.layoutConfig;
  }

  int get hostSeatIndex {
    return roomSeatService?.hostSeatIndex ?? 0;
  }

  List<ZegoLiveAudioRoomSeat> get seatList {
    return roomSeatService?.seatList ?? [];
  }

  get currentUserRoleNoti => null;

  void initWithConfig(ZegoLiveAudioRoomLayoutConfig config, ZegoLiveRole role) {
    roomSeatService = RoomSeatService();
    roleNoti.value = role;
    final expressService = ZEGOSDKManager.instance.expressService;
    final zimService = ZEGOSDKManager.instance.zimService;
    subscriptions.addAll([
      expressService.roomExtraInfoUpdateCtrl.stream
          .listen(onRoomExtraInfoUpdate),
      expressService.roomUserListUpdateStreamCtrl.stream
          .listen(onRoomUserListUpdate),
      zimService.onRoomCommandReceivedEventStreamCtrl.stream
          .listen(onRoomCommandReceived)
    ]);
    roomSeatService?.initWithConfig(config, role);
  }

  void unInit() {
    for (final subscription in subscriptions) {
      subscription.cancel();
    }
    subscriptions.clear();
    roomSeatService?.unInit();
  }

  bool isSeatLocked() {
    return isLockSeat.value;
  }

  Future<ZegoRoomSetRoomExtraInfoResult> lockSeat() async {
    roomExtraInfoDict['lockseat'] = !isLockSeat.value;
    final dataJson = jsonEncode(roomExtraInfoDict);

    final result = await ZEGOSDKManager.instance.expressService
        .setRoomExtraInfo(roomKey, dataJson);
    if (result.errorCode == 0) {
      isLockSeat.value = !isLockSeat.value;
    }
    return result;
  }

  Future<ZIMRoomAttributesOperatedCallResult?> takeSeat(int seatIndex) async {
    final result = await roomSeatService?.takeSeat(seatIndex);
    if (result != null) {
      if (!result.errorKeys.contains(seatIndex.toString())) {
        for (final element in seatList) {
          if (element.seatIndex == seatIndex) {
            if (roleNoti.value != ZegoLiveRole.host) {
              roleNoti.value = ZegoLiveRole.coHost;
            }
            break;
          }
        }
      }
    }
    return result;
  }

  Future<ZIMRoomAttributesBatchOperatedResult?> switchSeat(
      int fromSeatIndex, int toSeatIndex) async {
    return roomSeatService?.switchSeat(fromSeatIndex, toSeatIndex);
  }

  Future<ZIMRoomAttributesOperatedCallResult?> leaveSeat(int seatIndex) async {
    return roomSeatService?.leaveSeat(seatIndex);
  }

  Future<ZIMRoomAttributesOperatedCallResult?> removeSpeakerFromSeat(
      String userID) async {
    return roomSeatService?.removeSpeakerFromSeat(userID);
  }

  Future<ZIMMessageSentResult> muteSpeaker(String userID, bool isMute) async {
    final messageType =
        isMute ? RoomCommandType.muteSpeaker : RoomCommandType.unMuteSpeaker;
    final commandMap = {
      'room_command_type': messageType,
      'receiver_id': userID
    };
    final result = await ZEGOSDKManager()
        .zimService
        .sendRoomCommand(jsonEncode(commandMap));
    return result;
  }

  Future<ZIMMessageSentResult> kickOutRoom(String userID) async {
    final commandMap = {
      'room_command_type': RoomCommandType.kickOutRoom,
      'receiver_id': userID
    };
    final result = await ZEGOSDKManager()
        .zimService
        .sendRoomCommand(jsonEncode(commandMap));
    return result;
  }

  void leaveRoom() {
    ZEGOSDKManager.instance.logoutRoom();
    clear();
  }

  void clear() {
    roomSeatService?.clear();
    roomExtraInfoDict.clear();
    isLockSeat.value = false;
    hostUserNoti.value = null;
    for (final subscription in subscriptions) {
      subscription.cancel();
    }
    subscriptions.clear();
  }

  Future<ZegoRoomSetRoomExtraInfoResult?> setSelfHost() async {
    if (ZEGOSDKManager.instance.currentUser == null) {
      return null;
    }
    roomExtraInfoDict['host'] = ZEGOSDKManager.instance.currentUser!.userID;
    final dataJson = jsonEncode(roomExtraInfoDict);
    final result = await ZEGOSDKManager.instance.expressService
        .setRoomExtraInfo(roomKey, dataJson);
    if (result.errorCode == 0) {
      roleNoti.value = ZegoLiveRole.host;
    }
    return result;
  }

  Future<ZIMUserAvatarUrlUpdatedResult> updateUserAvatarUrl(String url) async {
    return ZEGOSDKManager.instance.zimService.updateUserAvatarUrl(url);
  }

  Future<ZIMUsersInfoQueriedResult> queryUsersInfo(
      List<String> userIDList) async {
    return ZEGOSDKManager.instance.zimService.queryUsersInfo(userIDList);
  }

  String? getUserAvatar(String userID) {
    return ZEGOSDKManager.instance.zimService.getUserAvatar(userID);
  }

  void onRoomExtraInfoUpdate(ZegoRoomExtraInfoEvent event) {
    for (final extraInfo in event.extraInfoList) {
      if (extraInfo.key == roomKey) {
        roomExtraInfoDict = jsonDecode(extraInfo.value);
        if (roomExtraInfoDict.containsKey('lockseat')) {
          final bool temp = roomExtraInfoDict['lockseat'];
          isLockSeat.value = temp;
        }
        if (roomExtraInfoDict.containsKey('host')) {
          final String tempUserID = roomExtraInfoDict['host'];
          hostUserNoti.value = getHostUser(tempUserID);
        }
      }
    }
  }

  void onRoomUserListUpdate(ZegoRoomUserListUpdateEvent event) {
    if (event.updateType == ZegoUpdateType.Add) {
      final userIDList = <String>[];
      for (final element in event.userList) {
        userIDList.add(element.userID);
      }
      queryUsersInfo(userIDList);
    } else {
      // empty seat
    }
  }

  void onRoomCommandReceived(OnRoomCommandReceivedEvent event) {
    Map<String, dynamic> messageMap = jsonDecode(event.command);
    if (messageMap.keys.contains('room_command_type')) {
      final type = messageMap['room_command_type'];
      final receiverID = messageMap['receiver_id'];
      if (receiverID == ZEGOSDKManager().currentUser?.userID) {
        if (type == RoomCommandType.muteSpeaker) {
          ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
              const SnackBar(
                  content: Text('You have been mute speaker by the host')));
          ZEGOSDKManager().expressService.turnMicrophoneOn(false);
        } else if (type == RoomCommandType.unMuteSpeaker) {
          ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
              const SnackBar(
                  content: Text('You have been kick out of the room by the host')));
          ZEGOSDKManager().expressService.turnMicrophoneOn(true);
        } else if (type == RoomCommandType.kickOutRoom) {
          leaveRoom();
          Navigator.pop(navigatorKey.currentContext!);
        }
      }
    }
  }

  ZegoSDKUser? getHostUser(String userID) {
    return ZEGOSDKManager().getUser(userID);
  }
}
