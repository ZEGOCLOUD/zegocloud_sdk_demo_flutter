import 'dart:async';
import 'dart:convert';

// Flutter imports:
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:live_audio_room_demo/zego_sdk_manager.dart';

import 'zego_service_define.dart';

class ZIMService {
  ZIMService._internal();
  factory ZIMService() => instance;
  static final ZIMService instance = ZIMService._internal();

  Map<String, String> roomAttributesMap = {};
  Map<String, String> userAvatarUrlMap = {};

  Future<void> init({required int appID, String? appSign}) async {
    initEventHandle();
    ZIM.create(
      ZIMAppConfig()
        ..appID = appID
        ..appSign = appSign ?? '',
    );
  }

  Future<void> uninit() async {
    uninitEventHandle();
    ZIM.getInstance()?.destroy();
  }

  Future<void> connectUser(String userID, String userName, {String? token}) async {
    ZIMUserInfo userInfo = ZIMUserInfo();
    userInfo.userID = userID;
    userInfo.userName = userName;
    zimUserInfo = userInfo;
    await ZIM.getInstance()!.login(userInfo, token);
  }

  Future<void> disconnectUser() async {
    ZIM.getInstance()!.logout();
  }

  String? currentRoomID;
  Future<ZegoRoomLoginResult> loginRoom(
    String roomID, {
    String? roomName,
    Map<String, String> roomAttributes = const {},
    int roomDestroyDelayTime = 0,
  }) async {
    currentRoomID = roomID;

    ZegoRoomLoginResult result = ZegoRoomLoginResult(0, {});

    await ZIM
        .getInstance()!
        .enterRoom(
            ZIMRoomInfo()
              ..roomID = roomID
              ..roomName = roomName ?? '',
            ZIMRoomAdvancedConfig()
              ..roomAttributes = roomAttributes
              ..roomDestroyDelayTime = roomDestroyDelayTime)
        .then((value) {
      result.errorCode = 0;
    }).catchError((error) {
      result.errorCode = int.tryParse(error.code) ?? -1;
      result.extendedData['errorMessage'] = error.message;
      result.extendedData['error'] = error;
    });
    return result;
  }

  Future<ZIMRoomLeftResult> logoutRoom() async {
    if (currentRoomID != null) {
      final ret = await ZIM.getInstance()!.leaveRoom(currentRoomID!);
      currentRoomID = null;
      return ret;
    } else {
      debugPrint('currentRoomID is null');
      return ZIMRoomLeftResult(roomID: '');
    }
  }

  Future<ZIMMessageSentResult> sendCustomProtocolRequest(String signaling) {
    return ZIM.getInstance()!.sendMessage(
          ZIMCommandMessage(message: Uint8List.fromList(utf8.encode(signaling))),
          currentRoomID!,
          ZIMConversationType.room,
          ZIMMessageSendConfig(),
        );
  }

  Future<ZIMUserAvatarUrlUpdatedResult> updateUserAvatarUrl(String url) async {
    ZIMUserAvatarUrlUpdatedResult result = await ZIM.getInstance()!.updateUserAvatarUrl(url);
    userAvatarUrlMap[zimUserInfo!.userID] = result.userAvatarUrl;
    ZEGOSDKManager.instance.localUser?.avatarUrlNotifier.value = result.userAvatarUrl;
    return result;
  }

  Future<ZIMUsersInfoQueriedResult> queryUsersInfo(List<String> userIDList) async {
    var config = ZIMUserInfoQueryConfig();
    ZIMUsersInfoQueriedResult result = await ZIM.getInstance()!.queryUsersInfo(userIDList, config);
    for (var userFullInfo in result.userList) {
      userAvatarUrlMap[userFullInfo.baseInfo.userID] = userFullInfo.userAvatarUrl;
      ZEGOSDKManager.instance.getUser(userFullInfo.baseInfo.userID)?.avatarUrlNotifier.value =
          userFullInfo.userAvatarUrl;
    }
    return result;
  }

  String? getUserAvatar(String userID) {
    return userAvatarUrlMap[userID];
  }

  Future<ZIMRoomAttributesOperatedCallResult?> setRoomAttributes(
      String key, String value, bool isForce, bool isUpdateOwner, bool isDeleteAfterOwnerLeft) async {
    if (ZIM.getInstance() != null) {
      var config = ZIMRoomAttributesSetConfig();
      config.isForce = isForce;
      config.isUpdateOwner = isUpdateOwner;
      config.isDeleteAfterOwnerLeft = isDeleteAfterOwnerLeft;
      ZIMRoomAttributesOperatedCallResult result =
          await ZIM.getInstance()!.setRoomAttributes({key: value}, currentRoomID ?? '', config);
      if (!result.errorKeys.contains(key)) {
        roomAttributesMap[key] = value;
      }
      return result;
    } else {
      return null;
    }
  }

  void beginRoomPropertiesBatchOperation() {
    var config = ZIMRoomAttributesBatchOperationConfig();
    config.isForce = true;
    config.isDeleteAfterOwnerLeft = false;
    config.isUpdateOwner = false;
    ZIM.getInstance()?.beginRoomAttributesBatchOperation(currentRoomID ?? '', config);
  }

  Future<ZIMRoomAttributesBatchOperatedResult?> endRoomPropertiesBatchOperation() async {
    return await ZIM.getInstance()?.endRoomAttributesBatchOperation(currentRoomID ?? '');
  }

  Future<ZIMRoomAttributesOperatedCallResult?> deleteRoomAttributes(List<String> keys) async {
    if (ZIM.getInstance() != null) {
      var config = ZIMRoomAttributesDeleteConfig();
      config.isForce = true;
      ZIMRoomAttributesOperatedCallResult result =
          await ZIM.getInstance()!.deleteRoomAttributes(keys, currentRoomID ?? '', config);
      List<String> tempKeys = List.from(keys);
      if (result.errorKeys.isNotEmpty) {
        tempKeys.removeWhere((element) {
          return result.errorKeys.contains(element);
        });
      }
      for (var element in tempKeys) {
        roomAttributesMap.remove(element);
      }
      return result;
    } else {
      return null;
    }
  }

  void initEventHandle() {
    ZIMEventHandler.onConnectionStateChanged = onConnectionStateChanged;
    ZIMEventHandler.onRoomStateChanged = onRoomStateChanged;
    ZIMEventHandler.onReceiveRoomMessage = onReceiveRoomMessage;
    ZIMEventHandler.onRoomAttributesUpdated = onRoomAttributesUpdated;
    ZIMEventHandler.onRoomAttributesBatchUpdated = onRoomAttributesBatchUpdated;
  }

  void onReceiveRoomMessage(_, List<ZIMMessage> messageList, String fromRoomID) {
    for (var element in messageList) {
      if (element is ZIMCommandMessage) {
        String signaling = utf8.decode(element.message);
        debugPrint('onReceiveRoomCommandMessage: $signaling');

        receiveRoomCustomSignalingStreamCtrl.add(ZIMServiceReceiveRoomCustomSignalingEvent(signaling: signaling));
      } else if (element is ZIMTextMessage) {
        debugPrint('onReceiveRoomTextMessage: ${element.message}');
      }
    }
  }

  void onConnectionStateChanged(_, ZIMConnectionState state, ZIMConnectionEvent event, Map extendedData) {
    connectionStateStreamCtrl.add(ZIMServiceConnectionStateChangedEvent(state, event, extendedData));
  }

  void onRoomStateChanged(_, ZIMRoomState state, ZIMRoomEvent event, Map extendedData, String roomID) {
    roomStateChangedStreamCtrl.add(ZIMServiceRoomStateChangedEvent(roomID, state, event, extendedData));
  }

  void onRoomAttributesUpdated(_, ZIMRoomAttributesUpdateInfo updateInfo, String roomID) {
    updateInfo.roomAttributes.forEach((key, value) {
      if (updateInfo.action == ZIMRoomAttributesUpdateAction.set) {
        roomAttributesMap[key] = value;
      } else {
        roomAttributesMap.remove(key);
      }
    });

    roomAttributeUpdateStreamCtrl.add(ZIMServiceRoomAttributeUpdateEvent(roomID, updateInfo));
  }

  void onRoomAttributesBatchUpdated(_, List<ZIMRoomAttributesUpdateInfo> updateInfo, String roomID) {
    for (ZIMRoomAttributesUpdateInfo info in updateInfo) {
      info.roomAttributes.forEach((key, value) {
        if (info.action == ZIMRoomAttributesUpdateAction.set) {
          roomAttributesMap[key] = value;
        } else {
          roomAttributesMap.remove(key);
        }
      });
    }

    roomAttributeBatchUpdatedStreamCtrl.add(ZIMServiceRoomAttributeBatchUpdatedEvent(roomID, updateInfo));
  }

  void uninitEventHandle() {
    ZIMEventHandler.onRoomStateChanged = null;
    ZIMEventHandler.onConnectionStateChanged = null;
    ZIMEventHandler.onRoomAttributesBatchUpdated = null;
    ZIMEventHandler.onRoomAttributesUpdated = null;
    ZIMEventHandler.onReceiveRoomMessage = null;
  }

  ZIMUserInfo? zimUserInfo;

  final connectionStateStreamCtrl = StreamController<ZIMServiceConnectionStateChangedEvent>.broadcast();
  final roomStateChangedStreamCtrl = StreamController<ZIMServiceRoomStateChangedEvent>.broadcast();
  final receiveRoomCustomSignalingStreamCtrl = StreamController<ZIMServiceReceiveRoomCustomSignalingEvent>.broadcast();
  final roomAttributeUpdateStreamCtrl = StreamController<ZIMServiceRoomAttributeUpdateEvent>.broadcast();
  final roomAttributeBatchUpdatedStreamCtrl = StreamController<ZIMServiceRoomAttributeBatchUpdatedEvent>.broadcast();
}
