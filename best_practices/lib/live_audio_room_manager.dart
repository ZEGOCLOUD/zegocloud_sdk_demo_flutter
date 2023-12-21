import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import 'internal/business/audioRoom/live_audio_room_seat.dart';
import 'internal/business/audioRoom/room_seat_service.dart';
import 'main.dart';
import 'zego_sdk_manager.dart';

class ZegoLiveAudioRoomManager {
  factory ZegoLiveAudioRoomManager() => instance;
  ZegoLiveAudioRoomManager._internal();
  static final ZegoLiveAudioRoomManager instance = ZegoLiveAudioRoomManager._internal();

  static const String roomKey = 'audioRoom';

  Map<String, dynamic> roomExtraInfoDict = {};
  List<StreamSubscription<dynamic>> subscriptions = [];

  ValueNotifier<bool> isLockSeat = ValueNotifier(false);
  ValueNotifier<ZegoSDKUser?> hostUserNoti = ValueNotifier(null);
  ValueNotifier<ZegoLiveAudioRoomRole> roleNoti = ValueNotifier(ZegoLiveAudioRoomRole.audience);

  RoomSeatService? roomSeatService;

  int get hostSeatIndex {
    return roomSeatService?.hostSeatIndex ?? 0;
  }

  List<ZegoLiveAudioRoomSeat> get seatList {
    return roomSeatService?.seatList ?? [];
  }

  Future<ZegoRoomLoginResult> loginRoom(String roomID, ZegoLiveAudioRoomRole role, {String? token}) async {
    roomSeatService = RoomSeatService();
    roleNoti.value = role;
    final expressService = ZEGOSDKManager().expressService;
    final zimService = ZEGOSDKManager().zimService;
    subscriptions.addAll([
      expressService.roomExtraInfoUpdateCtrl.stream.listen(onRoomExtraInfoUpdate),
      expressService.roomUserListUpdateStreamCtrl.stream.listen(onRoomUserListUpdate),
      zimService.onRoomCommandReceivedEventStreamCtrl.stream.listen(onRoomCommandReceived)
    ]);
    roomSeatService?.initWithConfig(role);
    return ZEGOSDKManager().loginRoom(roomID, ZegoScenario.HighQualityChatroom, token: token);
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

    final result = await ZEGOSDKManager().expressService.setRoomExtraInfo(roomKey, dataJson);
    if (result.errorCode == 0) {
      isLockSeat.value = !isLockSeat.value;
    }
    return result;
  }

  Future<ZIMRoomAttributesOperatedCallResult?> takeSeat(int seatIndex, {bool? isForce}) async {
    final result = await roomSeatService?.takeSeat(seatIndex, isForce: isForce);
    if (result != null) {
      if (!result.errorKeys.contains(seatIndex.toString())) {
        for (final element in seatList) {
          if (element.seatIndex == seatIndex) {
            if (roleNoti.value != ZegoLiveAudioRoomRole.host) {
              roleNoti.value = ZegoLiveAudioRoomRole.speaker;
            }
            break;
          }
        }
      }
    }
    if (result != null && !result.errorKeys.contains(ZEGOSDKManager().currentUser!.userID)) {
      openMicAndStartPublishStream();
    }
    return result;
  }

  void openMicAndStartPublishStream() {
    ZEGOSDKManager().expressService.turnCameraOn(false);
    ZEGOSDKManager().expressService.turnMicrophoneOn(true);
    ZEGOSDKManager().expressService.startPublishingStream(generateStreamID());
  }

  String generateStreamID() {
    final userID = ZEGOSDKManager().currentUser!.userID;
    final roomID = ZEGOSDKManager().expressService.currentRoomID;
    final streamID =
        '${roomID}_${userID}_${ZegoLiveAudioRoomManager().roleNoti.value == ZegoLiveAudioRoomRole.host ? 'host' : 'speaker'}';
    return streamID;
  }

  Future<ZIMRoomAttributesBatchOperatedResult?> switchSeat(int fromSeatIndex, int toSeatIndex) async {
    return roomSeatService?.switchSeat(fromSeatIndex, toSeatIndex);
  }

  Future<ZIMRoomAttributesOperatedCallResult?> leaveSeat(int seatIndex) async {
    return roomSeatService?.leaveSeat(seatIndex);
  }

  Future<ZIMRoomAttributesOperatedCallResult?> removeSpeakerFromSeat(String userID) async {
    return roomSeatService?.removeSpeakerFromSeat(userID);
  }

  Future<ZIMMessageSentResult> muteSpeaker(String userID, bool isMute) async {
    final messageType = isMute ? RoomCommandType.muteSpeaker : RoomCommandType.unMuteSpeaker;
    final commandMap = {'room_command_type': messageType, 'receiver_id': userID};
    final result = await ZEGOSDKManager().zimService.sendRoomCommand(jsonEncode(commandMap));
    return result;
  }

  Future<ZIMMessageSentResult> kickOutRoom(String userID) async {
    final commandMap = {'room_command_type': RoomCommandType.kickOutRoom, 'receiver_id': userID};
    final result = await ZEGOSDKManager().zimService.sendRoomCommand(jsonEncode(commandMap));
    return result;
  }

  void logoutRoom() {
    ZEGOSDKManager().logoutRoom();
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
    if (ZEGOSDKManager().currentUser == null) {
      return null;
    }
    roomExtraInfoDict['host'] = ZEGOSDKManager().currentUser!.userID;
    final dataJson = jsonEncode(roomExtraInfoDict);
    final result = await ZEGOSDKManager().expressService.setRoomExtraInfo(roomKey, dataJson);
    if (result.errorCode == 0) {
      roleNoti.value = ZegoLiveAudioRoomRole.host;
      hostUserNoti.value = ZEGOSDKManager().currentUser;
    }
    return result;
  }

  String? getUserAvatar(String userID) {
    return ZEGOSDKManager().zimService.getUserAvatar(userID);
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
      ZEGOSDKManager().zimService.queryUsersInfo(userIDList);
    } else {
      // empty seat
    }
  }

  void onRoomCommandReceived(OnRoomCommandReceivedEvent event) {
    final Map<String, dynamic> messageMap = jsonDecode(event.command);
    if (messageMap.keys.contains('room_command_type')) {
      final type = messageMap['room_command_type'];
      final receiverID = messageMap['receiver_id'];
      if (receiverID == ZEGOSDKManager().currentUser!.userID) {
        if (type == RoomCommandType.muteSpeaker) {
          ScaffoldMessenger.of(navigatorKey.currentContext!)
              .showSnackBar(const SnackBar(content: Text('You have been mute speaker by the host')));
          ZEGOSDKManager().expressService.turnMicrophoneOn(false);
        } else if (type == RoomCommandType.unMuteSpeaker) {
          ScaffoldMessenger.of(navigatorKey.currentContext!)
              .showSnackBar(const SnackBar(content: Text('You have been kick out of the room by the host')));
          ZEGOSDKManager().expressService.turnMicrophoneOn(true);
        } else if (type == RoomCommandType.kickOutRoom) {
          logoutRoom();
          Navigator.pop(navigatorKey.currentContext!);
        }
      }
    }
  }

  ZegoSDKUser? getHostUser(String userID) {
    return ZEGOSDKManager().getUser(userID);
  }
}
