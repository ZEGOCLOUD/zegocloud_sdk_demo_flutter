import 'dart:async';
import 'dart:convert';
import 'dart:ffi';

import 'package:flutter/material.dart';

import '../../../zego_live_streaming_manager.dart';
import '../../../zego_sdk_manager.dart';
import 'pk_define.dart';
import 'pk_extended.dart';
import 'pk_info.dart';
import 'pk_service_express_extension.dart';
import 'pk_service_zim_extension.dart';
import 'pk_service_interface.dart';
import 'pk_user.dart';

class PKService implements PKServiceInterface {
  // ValueNotifier<RoomPKState> roomPKStateNoti = ValueNotifier(RoomPKState.isNoPK);

  late final List<ZegoMixerInput> Function(List<String> streamIDList, ZegoMixerVideoConfig videoConfig)? setMixerLayout;

  ValueNotifier<bool> isMuteAnotherAudioNoti = ValueNotifier(false);
  ValueNotifier<bool> onPKViewAvaliableNoti = ValueNotifier(false);
  ValueNotifier<RoomPKState> pkStateNoti = ValueNotifier(RoomPKState.isNoPK);

  Map<String, String> pkRoomAttribute = {};
  Map<String, int> seiTimeMap = {};
  ZegoSDKUser? pkUser;
  int pkSeq = 0;
  Timer? seiTimer;
  Timer? checkSEITimer;

  PKInfo? pkInfo;
  ZegoMixerTask? task;

  List<StreamSubscription> subscriptions = [];

  ZegoSDKUser? get localUser => ZEGOSDKManager().currentUser;

  final onPKBattleReceived = StreamController<PKBattleReceivedEvent>.broadcast();
  final onPKBattleCancelStreamCtrl = StreamController<PKBattleCancelledEvent>.broadcast();
  final onPKBattleRejectedStreamCtrl = StreamController<PKBattleRejectedEvent>.broadcast();
  final onPKBattleAcceptedCtrl = StreamController<PKBattleAcceptedEvent>.broadcast();

  final incomingPKRequestTimeoutStreamCtrl = StreamController<IncomingPKRequestTimeoutEvent>.broadcast();
  final outgoingPKRequestAnsweredTimeoutStreamCtrl = StreamController<OutgoingPKRequestTimeoutEvent>.broadcast();

  final onPKStartStreamCtrl = StreamController.broadcast();
  final onPKEndStreamCtrl = StreamController.broadcast();
  final onPKUserJoinCtrl = StreamController<PKBattleUserJoinEvent>.broadcast();
  final onPKBattleTimeoutCtrl = StreamController<PKBattleTimeoutEvent>.broadcast();
  final onPKBattleUserQuitCtrl = StreamController<PKBattleUserQuitEvent>.broadcast();
  final onPKBattleUserUpdateCtrl = StreamController<PKBattleUserUpdateEvent>.broadcast();
  final onPKUserConnectingCtrl = StreamController<PKBattleUserConnectingEvent>.broadcast();

  @override
  void addListener() {
    final zimService = ZEGOSDKManager().zimService;
    final expressService = ZEGOSDKManager().expressService;
    subscriptions.addAll([
      zimService.incomingUserRequestReceivedStreamCtrl.stream.listen(onReceiveUserRequest),
      zimService.incomingUserRequestCancelledStreamCtrl.stream.listen(onReceiveUserRequestCancel),
      zimService.incomingUserRequestTimeoutStreamCtrl.stream.listen(onReceivePKTimeout),
      zimService.outgoingUserRequestTimeoutStreamCtrl.stream.listen(onReceivePKAnswerTimeout),
      zimService.userRequestEndStreamCtrl.stream.listen(onUserRequestEnded),
      zimService.userRequestStateChangeStreamCtrl.stream.listen(onUserRequestStateChanged),
      zimService.userRequestTimeOutStreamCtrl.stream.listen((event) {}),
      zimService.roomAttributeUpdateStreamCtrl2.stream.listen(onRoomAttributesUpdated2),
      expressService.recvAudioFirstFrameCtrl.stream.listen(onReceiveAudioFirstFrame),
      expressService.recvVideoFirstFrameCtrl.stream.listen(onReceiveVideoFirstFrame),
      expressService.mixerSoundLevelUpdateCtrl.stream.listen(onMixerSoundLevelUpdate),
    ]);
  }

  @override
  void uninit() {
    for (final subscription in subscriptions) {
      subscription.cancel();
    }
  }

  @override
  Future<PKInviteSentResult> invitePKbattle(List<String> targetUserIDList, bool autoAccept) async {
    if (pkInfo != null) {
      final result = await addUserToRequest(targetUserIDList, pkInfo!.requestID ?? '');
      return PKInviteSentResult(requestID: result.callID, errorUserList: result.info.errorUserList);
    } else {
      pkInfo = PKInfo();
      final pkExtendedData = getPKExtendedData(PKExtendedData.START_PK) ?? '';
      final Map<String, dynamic> pkExtendedMap = jsonDecode(pkExtendedData) ?? {};
      pkExtendedMap['user_id'] = localUser?.userID;
      pkExtendedMap['auto_accept'] = autoAccept;
      pkStateNoti.value = RoomPKState.isRequestPK;
      final result = await sendUserRequest(targetUserIDList, jsonEncode(pkExtendedMap), true).catchError((error) {
        pkStateNoti.value = RoomPKState.isNoPK;
      });
      pkInfo!.requestID = result.callID;
      return PKInviteSentResult(requestID: result.callID, errorUserList: result.info.errorUserList);
    }
  }

  @override
  Future<void> acceptPKBattle(String requestID) async {
    if (pkInfo != null && pkInfo!.requestID == requestID) {
      final extendedData = getPKExtendedData(PKExtendedData.START_PK) ?? '';
      acceptUserRequest(requestID, extendedData).then((value) {
        debugPrint('acceptPK sucess');
      }).catchError((error) {
        debugPrint('acceptPK fail error:$error');
        pkInfo = null;
      });
    }
  }

  @override
  Future<ZIMCallQuitSentResult> quitPKBattle(String requestID) async {
    if (isPKUser(ZEGOSDKManager().currentUser?.userID ?? '')) {
      if (ZegoLiveStreamingManager().isLocalUserHost()) {
        stopPlayAnotherHostStream();
      }
      return quitUserRequest(requestID, '');
    }
    return ZIMCallQuitSentResult(callID: requestID, info: ZIMCallQuitSentInfo());
  }

  @override
  Future<ZIMCallEndSentResult> endPKBattle(String requestID) async {
    final extendedData = getPKExtendedData(PKExtendedData.START_PK) ?? '';
    ZIMCallEndSentResult result;
    if (isPKUser(ZEGOSDKManager().currentUser?.userID ?? '')) {
      result = await endUserRequest(requestID, extendedData);
    } else {
      result = ZIMCallEndSentResult(callID: requestID, info: ZIMCallEndedSentInfo());
    }
    if (pkInfo?.requestID == requestID) {
      pkInfo = null;
    }
    return result;
  }

  @override
  Future<void> cancelPKBattle(String requestID, String userID) async {
    if (pkInfo != null && pkInfo!.requestID == requestID) {
      final extendedData = getPKExtendedData(PKExtendedData.START_PK) ?? '';
      cancelUserRequest(userID, requestID, extendedData);
      pkInfo = null;
    }
  }

  @override
  Future<void> rejectPKBattle(String requestID) async {
    final extendedData = getPKExtendedData(PKExtendedData.START_PK) ?? '';
    rejectUserRequest(requestID, extendedData);
    if (pkInfo?.requestID == requestID) {
      pkInfo = null;
    }
  }

  @override
  void removeUserFromPKBattle(String userID) {
    if (pkInfo != null) {
      final timeoutQuitUsers = <PKUser>[];
      for (final pkuser in pkInfo!.pkUserList.value) {
        if (userID == pkuser.userID) {
          pkuser.callUserState = ZIMCallUserState.quited;
          timeoutQuitUsers.add(pkuser);
        }
      }
      if (timeoutQuitUsers.isNotEmpty) {
        for (final timeoutQuitUser in timeoutQuitUsers) {
          final callUserInfo = ZIMCallUserInfo()
            ..userID = timeoutQuitUser.userID
            ..extendedData = timeoutQuitUser.extendedData
            ..state = timeoutQuitUser.callUserState;
          onReceivePKUserQuit(pkInfo!.requestID ?? '', callUserInfo);
        }
      }
    }
    seiTimeMap.remove(userID);
  }

  @override
  Future<ZegoMixerStartResult> mutePKUser(List<int> muteIndexList, bool mute) async {
    if (task == null || (task != null && task!.inputList.isEmpty)) {
      return ZegoMixerStartResult(-9999, {});
    }
    final muteStreamList = <String>[];
    for (final index in muteIndexList) {
      if (index < task!.inputList.length) {
        final mixerInput = task!.inputList[index];
        if (mute) {
          mixerInput.contentType = ZegoMixerInputContentType.VideoOnly;
          muteStreamList.add(mixerInput.streamID);
        } else {
          mixerInput.contentType = ZegoMixerInputContentType.Video;
        }
      }
    }

    final result = await ZEGOSDKManager().expressService.startMixerTask(task!);
    if (result.errorCode == 0) {
      if (pkInfo != null) {
        for (final streamID in muteStreamList) {
          for (final pkuser in pkInfo!.pkUserList.value) {
            if (pkuser.pkUserStream == streamID) {
              pkuser.isMute = true;
              ZEGOSDKManager().expressService.mutePlayStreamAudio(streamID, mute);
            }
          }
        }
      }
    }
    return result;
  }

  @override
  void stopPKBattle() {
    if (ZegoLiveStreamingManager.instance.isLocalUserHost()) {
      delectPKAttributes();
      stopMixTask();
      //...
    } else {
      muteHostAudioVideo(false);
    }
    pkInfo = null;
    cancelTime();
    seiTimeMap.clear();
    pkStateNoti.value = RoomPKState.isNoPK;
    onPKEndStreamCtrl.add(null);
  }

  void muteHostAudioVideo(bool mute) {
    if (ZegoLiveStreamingManager().hostNoti.value != null) {
      final hostMainStreamID = ZegoLiveStreamingManager().hostStreamID();
      ZEGOSDKManager().expressService.mutePlayStreamAudio(hostMainStreamID, mute);
      ZEGOSDKManager().expressService.mutePlayStreamVideo(hostMainStreamID, mute);
    }
  }

  void stopPlayAnotherHostStream() {
    if (pkInfo == null) {
      return;
    }
    for (final pkuser in pkInfo!.pkUserList.value) {
      if (pkuser.userID != ZegoLiveStreamingManager().hostNoti.value?.userID) {
        ZEGOSDKManager().expressService.stopPlayingStream(pkuser.pkUserStream);
      }
    }
  }

  void stopMixTask() {
    if (task == null) {
      return;
    }
    ZEGOSDKManager().expressService.stopMixerTask().then((value) {
      if (value.errorCode == 0) {
        task = null;
      }
    });
  }

  void updatePKRoomAttributes() {
    if (pkInfo == null) {
      return;
    }
    final pkMap = <String, String>{};
    if (ZegoLiveStreamingManager().hostNoti.value != null) {
      pkMap['host_user_id'] = ZegoLiveStreamingManager().hostNoti.value?.userID ?? '';
    }
    pkMap['request_id'] = pkInfo!.requestID ?? '';

    final pkAcceptedUserList = <PKUser>[];
    for (final pkuser in pkInfo!.pkUserList.value) {
      if (pkuser.hasAccepted) {
        pkAcceptedUserList.add(pkuser);
      }
    }
    if (task != null) {
      for (final pkuser in pkAcceptedUserList) {
        for (final input in task!.inputList) {
          if (pkuser.pkUserStream == input.streamID) {
            pkuser.rect = input.layout;
          }
        }
      }
    }
    final pkUsers = pkAcceptedUserList.map((e) => e.toMap()).toList();
    final pkUsersStr = jsonEncode(pkUsers);
    pkMap['pk_users'] = pkUsersStr;
    ZEGOSDKManager().zimService.setRoomAttributes(pkMap, isDeleteAfterOwnerLeft: false);
  }

  void delectPKAttributes() {
    if (pkRoomAttribute.keys.isEmpty) {
      return;
    }
    if (pkRoomAttribute.keys.contains('pk_users')) {
      final keys = ['request_id', 'host_user_id', 'pk_users'];
      ZEGOSDKManager().zimService.deleteRoomAttributes(keys);
    }
  }

  Future<ZegoMixerStartResult> updatePKMixTask() async {
    if (pkInfo == null) {
      return ZegoMixerStartResult(-9999, {});
    }
    final pkStreamList = <String>[];
    for (final user in pkInfo!.pkUserList.value) {
      if (user.hasAccepted) {
        pkStreamList.add(user.pkUserStream);
      }
    }
    final videoConfig = ZegoMixerVideoConfig.defaultConfig()
      ..width = 1080
      ..height = 960;

    var inputList = <ZegoMixerInput>[];
    if (setMixerLayout != null) {
      inputList = setMixerLayout!(pkStreamList, videoConfig);
      if (inputList.isEmpty) {
        inputList = getMixVideoInputs(pkStreamList, videoConfig);
      }
    } else {
      inputList = getMixVideoInputs(pkStreamList, videoConfig);
    }
    if (task == null) {
      final mixStreamID = '${ZEGOSDKManager().expressService.currentRoomID}_mix';
      task = ZegoMixerTask(mixStreamID);
      task!.videoConfig = videoConfig;
      task!.inputList = inputList;

      final mixerOutput = ZegoMixerOutput(mixStreamID);
      final outputList = <ZegoMixerOutput>[];
      outputList.add(mixerOutput);
      task!.outputList = outputList;

      task!.enableSoundLevel = true;
    } else {
      task!.inputList = inputList;
    }

    final result = await ZEGOSDKManager().expressService.startMixerTask(task!);
    if (result.errorCode == 0) {
      updatePKRoomAttributes();
    }
    return result;
  }

  List<ZegoMixerInput> getMixVideoInputs(List<String> streamList, ZegoMixerVideoConfig videoConfig) {
    final inputList = <ZegoMixerInput>[];
    if (streamList.length == 2) {
      for (var i = 0; i < 2; i++) {
        double left = (videoConfig.width / streamList.length) * i;
        double top = 0;
        double width = 1080 / 2;
        double height = 960;
        final rect = Rect.fromLTRB(left, top, width * (i + 1), height);
        final input = ZegoMixerInput.defaultConfig()
          ..streamID = streamList[i]
          ..contentType = ZegoMixerInputContentType.Video
          ..layout = rect
          ..soundLevelID = 0;
        inputList.add(input);
      }
    } else {
      int row = 2;
      int maxCellCount = streamList.length % 2 == 0 ? streamList.length : (streamList.length + 1);
      int column = maxCellCount ~/ row;
      double cellWidth = 1080 / column;
      double cellHeight = 960 / row;
      double left, top, right, bottom;
      for (var i = 0; i < streamList.length; i++) {
        left = cellWidth * (i % column);
        top = cellHeight * (i < column ? 0 : 1);
        right = left + cellWidth;
        bottom = top + cellHeight;
        final rect = Rect.fromLTRB(left, top, right, bottom);
        final input = ZegoMixerInput.defaultConfig()
          ..streamID = streamList[i]
          ..contentType = ZegoMixerInputContentType.Video
          ..layout = rect;
        inputList.add(input);
      }
    }
    return inputList;
  }

  @override
  bool isPKUser(String userID) {
    if (pkInfo != null) {
      for (final user in pkInfo!.pkUserList.value) {
        if (user.userID == userID) {
          return true;
        }
      }
    }
    return false;
  }

  @override
  bool isPKUserMuted(String userID) {
    if (pkInfo != null) {
      for (final pkuser in pkInfo!.pkUserList.value) {
        if (pkuser.userID == userID) {
          return pkuser.isMute;
        }
      }
    }
    return false;
  }

  String? getPKExtendedData(int type) {
    final currentRoomID = ZEGOSDKManager.instance.expressService.currentRoomID;
    final data = PKExtendedData()
      ..roomID = currentRoomID
      ..userName = ZEGOSDKManager().currentUser?.userName ?? ''
      ..type = type;
    return data.toJsonString();
  }

  Future<ZIMCallInvitationSentResult> sendUserRequest(List<String> userIDList, String extendedData, bool advanced) {
    final config = ZIMCallInviteConfig()..timeout = 200;
    if (advanced) {
      config.mode = ZIMCallInvitationMode.advanced;
    }
    config.extendedData = extendedData;
    return ZEGOSDKManager.instance.zimService.sendUserRequest(userIDList, config: config);
  }

  Future<ZIMCallingInvitationSentResult> addUserToRequest(List<String> invitees, String requestID) async {
    final config = ZIMCallingInviteConfig();
    return ZEGOSDKManager.instance.zimService.addUserToRequest(invitees, requestID, config);
  }

  Future<ZIMCallAcceptanceSentResult> acceptUserRequest(String requestID, String extendedData) async {
    final config = ZIMCallAcceptConfig()..extendedData = extendedData;
    return ZEGOSDKManager.instance.zimService.acceptUserRequest(requestID, config: config);
  }

  Future<ZIMCallQuitSentResult> quitUserRequest(String requestID, String extendedData) async {
    final config = ZIMCallQuitConfig()..extendedData = extendedData;
    return ZEGOSDKManager().zimService.quitUserRequest(requestID, config);
  }

  Future<ZIMCallEndSentResult> endUserRequest(String requestID, String extendedData) async {
    final config = ZIMCallEndConfig()..extendedData = extendedData;
    return ZEGOSDKManager().zimService.endUserRequest(requestID, config);
  }

  Future<ZIMCallCancelSentResult> cancelUserRequest(String userID, String requestID, String extendedData) async {
    final config = ZIMCallCancelConfig()..extendedData = extendedData;
    return ZEGOSDKManager().zimService.cancelUserRequest([userID], requestID, config: config);
  }

  Future<ZIMCallRejectionSentResult> rejectUserRequest(String requestID, String extendedData) async {
    final config = ZIMCallRejectConfig()..extendedData = extendedData;
    return ZEGOSDKManager().zimService.rejectUserRequest(requestID, config: config);
  }

  PKUser? getPKUser(PKInfo pkBattleInfo, String userID) {
    for (final user in pkBattleInfo.pkUserList.value) {
      if (user.userID == userID) {
        return user;
      }
    }
    return null;
  }

  void checkIfPKEnd(String requestID, ZegoSDKUser currentUser) {
    if (pkInfo == null) {
      return;
    }
    final selfPKUser = getPKUser(pkInfo!, ZEGOSDKManager().currentUser?.userID ?? '');
    if (selfPKUser != null) {
      if (selfPKUser.hasAccepted) {
        var hasWaitingUser = false;
        for (final pkuser in pkInfo!.pkUserList.value) {
          if (pkuser.userID != ZEGOSDKManager().currentUser?.userID) {
            // except self
            if (pkuser.hasAccepted || pkuser.isWaiting) {
              hasWaitingUser = true;
            }
          }
        }
        if (!hasWaitingUser) {
          quitPKBattle(requestID);
          stopPKBattle();
        }
      }
    }
  }

  String generateMixerStreamID() {
    return '${ZEGOSDKManager().expressService.currentRoomID}_mix';
  }

  void cleanPKState() {
    pkSeq = 0;
    pkUser = null;
    onPKViewAvaliableNoti.value = false;
    pkStateNoti.value = RoomPKState.isNoPK;
    isMuteAnotherAudioNoti.value = false;
    cancelTime();
    onPKEndStreamCtrl.add(null);
    ZEGOSDKManager().expressService.stopPlayingStream(generateMixerStreamID());
  }

  void clearData() {
    cleanPKState();
    if (ZegoLiveStreamingManager.instance.isLocalUserHost() && pkRoomAttribute.keys.isNotEmpty) {
      ZEGOSDKManager().zimService.deleteRoomAttributes(pkRoomAttribute.keys.toList());
    }
  }

  String hostStreamID() {
    return '${ZEGOSDKManager().expressService.currentRoomID}_${ZEGOSDKManager().currentUser?.userID ?? ''}_main_host';
  }

  String anotherHostStreamID() {
    return '${pkUser?.roomID}_${pkUser?.userID}_main_host';
  }

  void checkSEITime() {
    checkSEITimer = Timer.periodic(const Duration(milliseconds: 2500), (timer) {
      final now = DateTime.now().millisecondsSinceEpoch;
      seiTimeMap.forEach((key, value) {
        final timerStamp = value;
        final duration = now - timerStamp;
        if (pkInfo != null) {
          getPKUser(pkInfo!, key)?.connectingDuration.value = duration;
        }
        onPKUserConnectingCtrl.add(PKBattleUserConnectingEvent(userID: key, duration: duration));
      });
    });
  }

  void startSendSEI() {
    seiTimer = Timer.periodic(const Duration(milliseconds: 2500), (timer) {
      final currentUser = ZEGOSDKManager().currentUser;
      final seiData = <String, dynamic>{
        'type': SEIType.deviceState,
        'sender_id': currentUser!.userID,
        'mic': currentUser.isMicOnNotifier.value,
        'cam': currentUser.isCamerOnNotifier.value
      };
      final jsonStr = jsonEncode(seiData);
      ZEGOSDKManager().expressService.sendSEI(jsonStr);
    });
  }

  void cancelTime() {
    seiTimer?.cancel();
    checkSEITimer?.cancel();
  }
}
