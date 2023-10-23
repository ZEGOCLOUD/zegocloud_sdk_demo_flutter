import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../zego_live_streaming_manager.dart';
import '../../../zego_sdk_manager.dart';

class PKService {
  ValueNotifier<RoomPKState> roomPKStateNoti =
      ValueNotifier(RoomPKState.isNoPK);
  ValueNotifier<bool> isMuteAnotherAudioNoti = ValueNotifier(false);
  ValueNotifier<bool> onPKViewAvaliableNoti = ValueNotifier(false);

  Map<String, String> pkRoomAttribute = {};
  ZegoSDKUser? pkUser;
  int pkSeq = 0;
  Timer? seiTimer;

  ZegoUserRequest? currentZegoUserRequest;

  List<StreamSubscription> subscriptions = [];

  final incomingPKRequestStreamCtrl =
      StreamController<IncomingPKRequestEvent>.broadcast();
  final incomingPKRequestCancelStreamCtrl =
      StreamController<IncomingPKRequestCancelledEvent>.broadcast();
  final outgoingPKRequestRejectedStreamCtrl =
      StreamController<OutgoingPKRequestRejectedEvent>.broadcast();
  final outgoingPKRequestAcceptStreamCtrl =
      StreamController<OutgoingPKRequestAcceptEvent>.broadcast();
  final incomingPKRequestTimeoutStreamCtrl =
      StreamController<IncomingPKRequestTimeoutEvent>.broadcast();
  final outgoingPKRequestAnsweredTimeoutStreamCtrl =
      StreamController<OutgoingPKRequestTimeoutEvent>.broadcast();
  final onPKStartStreamCtrl = StreamController.broadcast();
  final onPKEndStreamCtrl = StreamController.broadcast();

  void addListener() {
    final zimService = ZEGOSDKManager().zimService;
    final expressService = ZEGOSDKManager().expressService;
    subscriptions.addAll([
      zimService.incomingUserRequestReceivedStreamCtrl.stream
          .listen(onReceiveZegoUserRequest),
      zimService.incomingUserRequestCancelledStreamCtrl.stream
          .listen(onReceivePKCancel),
      zimService.outgoingUserRequestAcceptedStreamCtrl.stream
          .listen(onReceivePKAccept),
      zimService.outgoingUserRequestRejectedStreamCtrl.stream
          .listen(onReceivePKRejected),
      zimService.incomingUserRequestTimeoutStreamCtrl.stream
          .listen(onReceivePKTimeout),
      zimService.outgoingUserRequestTimeoutStreamCtrl.stream
          .listen(onReceivePKAnswerTimeout),
      zimService.roomAttributeUpdateStreamCtrl.stream
          .listen(onRoomAttributeUpdate),
      zimService.roomAttributeBatchUpdatedStreamCtrl.stream
          .listen(onRoomAttributeBatchUpdate),
      expressService.recvAudioFirstFrameCtrl.stream
          .listen(onReceiveAudioFirstFrame),
      expressService.recvVideoFirstFrameCtrl.stream
          .listen(onReceiveVideoFirstFrame),
      expressService.mixerSoundLevelUpdateCtrl.stream
          .listen(onMixerSoundLevelUpdate),
    ]);
  }

  void uninit() {
    for (final subscription in subscriptions) {
      subscription.cancel();
    }
  }

  Future<ZIMCallInvitationSentResult> sendPKBattlesStartRequest(
      String userID) async {
    final requestData = <String, dynamic>{
      'room_id': ZEGOSDKManager().expressService.currentRoomID,
      'user_name': ZEGOSDKManager().currentUser?.userName,
      'type': PKProtocolType.startPK,
    };

    roomPKStateNoti.value = RoomPKState.isRequestPK;
    final result = await ZEGOSDKManager().zimService.sendUserRequest(
      [userID],
      config: ZIMUserRequestSendConfig()
        ..extendedData = jsonEncode(requestData),
    );
    if (result.info.errorInvitees.map((e) => e.userID).contains(userID)) {
      roomPKStateNoti.value = RoomPKState.isNoPK;
    } else {
      currentZegoUserRequest = ZegoUserRequest(result.callID);
      currentZegoUserRequest!.roomID =
          ZEGOSDKManager().expressService.currentRoomID;
      currentZegoUserRequest!.inviterID = ZEGOSDKManager().currentUser?.userID;
      currentZegoUserRequest!.inviterName =
          ZEGOSDKManager().currentUser?.userName;
      currentZegoUserRequest!.invitee = [userID];
    }
    return result;
  }

  Future<ZIMCallInvitationSentResult> sendPKBattleResumeRequest(
      String userID) async {
    final requestData = <String, dynamic>{
      'room_id': ZEGOSDKManager().expressService.currentRoomID,
      'user_name': ZEGOSDKManager().currentUser?.userName,
      'type': PKProtocolType.resume,
    };
    roomPKStateNoti.value = RoomPKState.isStartPK;
    final result = await ZEGOSDKManager().zimService.sendUserRequest(
      [userID],
      config: ZIMUserRequestSendConfig()
        ..timeout = 10
        ..extendedData = jsonEncode(requestData),
    );
    if (result.info.errorInvitees.map((e) => e.userID).contains(userID)) {
      roomPKStateNoti.value = RoomPKState.isNoPK;
      clearData();
    } else {
      currentZegoUserRequest = ZegoUserRequest(result.callID);
      currentZegoUserRequest!.roomID =
          ZEGOSDKManager().expressService.currentRoomID;
      currentZegoUserRequest!.inviterID = ZEGOSDKManager().currentUser?.userID;
      currentZegoUserRequest!.inviterName =
          ZEGOSDKManager().currentUser?.userName;
      currentZegoUserRequest!.invitee = [userID];
    }
    return result;
  }

  Future<void> sendPKBattlesStopRequest() async {
    if (currentZegoUserRequest == null) {
      return;
    }
    final requestData = <String, dynamic>{
      'room_id': ZEGOSDKManager().expressService.currentRoomID,
      'user_name': ZEGOSDKManager().currentUser?.userName,
      'type': PKProtocolType.endPK,
    };
    ZEGOSDKManager().zimService.sendUserRequest(
      [pkUser?.userID ?? ''],
      config: ZIMUserRequestSendConfig()
        ..extendedData = jsonEncode(requestData),
    ).then((value) => null);
    currentZegoUserRequest = null;
    stopPK();
  }

  void cancelPKBattleRequest() {
    roomPKStateNoti.value = RoomPKState.isNoPK;
    if (currentZegoUserRequest == null) {
      return;
    }
    ZEGOSDKManager().zimService.cancelUserRequest(
        currentZegoUserRequest!.invitee,
        currentZegoUserRequest?.requestID ?? '');
  }

  void acceptPKBattleRequest(String requestID) {
    final requestData = <String, dynamic>{
      'room_id': ZEGOSDKManager().expressService.currentRoomID,
      'user_name': ZEGOSDKManager().currentUser?.userName,
      'type': PKProtocolType.startPK,
    };
    ZEGOSDKManager()
        .zimService
        .acceptUserRequest(
          requestID,
          config: ZIMUserRequestAcceptConfig()
            ..extendedData = jsonEncode(requestData),
        )
        .then((value) {
      willStartPK(
        roomID: currentZegoUserRequest?.roomID ?? '',
        userID: currentZegoUserRequest?.inviterID ?? '',
        userName: currentZegoUserRequest?.inviterName ?? '',
      );
    }).catchError((error) {
      debugPrint('acceptPK fail error:$error');
    });
  }

  void acceptResumePKRequest(String requestID) {
    final requestData = <String, dynamic>{
      'room_id': ZEGOSDKManager().expressService.currentRoomID,
      'user_name': ZEGOSDKManager().currentUser?.userName,
      'type': PKProtocolType.resume,
    };

    ZEGOSDKManager()
        .zimService
        .acceptUserRequest(
          requestID,
          config: ZIMUserRequestAcceptConfig()
            ..extendedData = jsonEncode(requestData),
        )
        .then((value) => resumeMixerTask())
        .catchError((error) {
      debugPrint('acceptPK resume fail error:$error');
    });
  }

  void responsePKEndRequest(String requestID) {
    ZEGOSDKManager.instance.zimService.acceptUserRequest(requestID);
  }

  void rejectPKBattleRequest(String requestID) {
    ZEGOSDKManager().zimService.rejectUserRequest(requestID).then((value) {
      if (requestID == currentZegoUserRequest?.requestID) {
        pkUser = null;
        currentZegoUserRequest = null;
      }
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

  void willStartPK(
      {String roomID = '', String userID = '', String userName = ''}) {
    if (ZegoLiveStreamingManager.instance.isLocalUserHost()) {
      startPK(roomID, userID, userName);
    } else {
      roomPKStateNoti.value = RoomPKState.isStartPK;
      ZEGOSDKManager()
          .expressService
          .startPlayingMixerStream(generateMixerStreamID());
    }
    onPKStartStreamCtrl.add(null);
  }

  void startPK(String roomID, String userID, String userName) {
    if (pkUser == null) {
      pkUser = ZegoSDKUser(userID: userID, userName: userName);
    } else {
      pkUser?.userID = userID;
      pkUser?.userName = userName;
    }
    pkUser?.roomID = roomID;
    pkUser?.streamID = anotherHostStreamID();
    roomPKStateNoti.value = RoomPKState.isStartPK;
    pkSeq = pkSeq + 1;
    startMixStreamTask().then((value) {
      if (value.errorCode == 0) {
        pkRoomAttribute = {
          'host': ZEGOSDKManager().currentUser?.userID ?? '',
          'pk_room': roomID,
          'pk_user_id': userID,
          'pk_user_name': userName,
          'pk_seq': '$pkSeq'
        };
        ZEGOSDKManager().zimService.setRoomAttributes(pkRoomAttribute);
        startSendSEI();
        if (ZegoLiveStreamingManager.instance.isLocalUserHost()) {
          ZEGOSDKManager()
              .expressService
              .startPlayingAnotherHostStream(anotherHostStreamID(), pkUser!);
        } else {}
      } else {
        pkUser = null;
        currentZegoUserRequest = null;
        roomPKStateNoti.value = RoomPKState.isNoPK;
      }
    }).catchError((error) {
      debugPrint('startMixStreamTask fail:$error');
    });
  }

  void resumeMixerTask() {
    ZEGOSDKManager.instance.expressService.stopMixerTask();
    startMixStreamTask();
  }

  Future<ZegoMixerStartResult> startMixStreamTask({
    ZegoMixerInputContentType leftContentType = ZegoMixerInputContentType.Video,
    ZegoMixerInputContentType rightContentType =
        ZegoMixerInputContentType.Video,
  }) async {
    if (ZEGOSDKManager().expressService.currentRoomID.isEmpty ||
        ZEGOSDKManager().currentUser?.userID == null) {
      return ZegoMixerStartResult(-1, {});
    }

    // start mixer task
    final leftStreamID = hostStreamID();
    final rightStreamID = anotherHostStreamID();

    final taskID = generateMixerStreamID();
    debugPrint(
        'startMixerTask left:$leftStreamID right:$rightStreamID taskID:$taskID');
    final videoConfig = ZegoMixerVideoConfig.defaultConfig()
      ..width = 540 * 2
      ..height = 960
      ..bitrate = 1200;

    final leftInput = ZegoMixerInput.defaultConfig()
      ..layout = const Rect.fromLTWH(0, 0, 540, 960)
      ..contentType = leftContentType
      ..renderMode = ZegoMixRenderMode.Fill
      ..soundLevelID = 0
      ..volume = 100
      ..streamID = leftStreamID;

    final rightInput = ZegoMixerInput.defaultConfig()
      ..layout = const Rect.fromLTWH(540, 0, 540, 960)
      ..contentType = rightContentType
      ..renderMode = ZegoMixRenderMode.Fill
      ..soundLevelID = 1
      ..volume = 100
      ..streamID = rightStreamID;

    final task = ZegoMixerTask(taskID)
      ..videoConfig = videoConfig
      ..audioConfig = ZegoMixerAudioConfig.defaultConfig()
      ..enableSoundLevel = true
      ..inputList = [leftInput, rightInput]
      ..outputList = [ZegoMixerOutput(generateMixerStreamID())];

    return ZEGOSDKManager().expressService.startMixerTask(task);
  }

  String generateMixerStreamID() {
    return '${ZEGOSDKManager().expressService.currentRoomID}_mix';
  }

  void stopPK() {
    ZEGOSDKManager().expressService.stopMixerTask();
    ZEGOSDKManager().expressService.stopPlayingStream(anotherHostStreamID());
    clearData();
  }

  void muteAnotherHostAudio(bool mute) {
    isMuteAnotherAudioNoti.value = mute;
    startMixStreamTask(
        rightContentType: mute
            ? ZegoMixerInputContentType.VideoOnly
            : ZegoMixerInputContentType.Video);
    ZEGOSDKManager()
        .expressService
        .mutePlayStreamAudio(anotherHostStreamID(), mute);
  }

  void muteMainStream() {
    ZEGOSDKManager().expressService.streamMap.forEach((key, value) {
      if (value.contains('_host')) {
        ZEGOSDKManager().expressService.mutePlayStreamAudio(value, true);
        ZEGOSDKManager().expressService.mutePlayStreamVideo(value, true);
      }
    });
  }

  void cleanPKState() {
    pkSeq = 0;
    pkUser = null;
    currentZegoUserRequest = null;
    onPKViewAvaliableNoti.value = false;
    roomPKStateNoti.value = RoomPKState.isNoPK;
    isMuteAnotherAudioNoti.value = false;
    seiTimer?.cancel();
    onPKEndStreamCtrl.add(null);
    ZEGOSDKManager().expressService.stopPlayingStream(generateMixerStreamID());
  }

  void clearData() {
    cleanPKState();
    if (ZegoLiveStreamingManager.instance.isLocalUserHost() &&
        pkRoomAttribute.keys.isNotEmpty) {
      ZEGOSDKManager()
          .zimService
          .deleteRoomAttributes(pkRoomAttribute.keys.toList());
    }
  }

  String hostStreamID() {
    return '${ZEGOSDKManager().expressService.currentRoomID}_${ZEGOSDKManager().currentUser?.userID ?? ''}_main_host';
  }

  String anotherHostStreamID() {
    return '${pkUser?.roomID}_${pkUser?.userID}_main_host';
  }

  // zim listener
  void onReceiveZegoUserRequest(IncomingUserRequestReceivedEvent event) {
    final invitation = ZegoUserRequest(event.requestID);
    final Map<String, dynamic> invitationMap =
        jsonDecode(event.info.extendedData);
    final int type = invitationMap['type'];
    switch (type) {
      case PKProtocolType.startPK:
        if (roomPKStateNoti.value != RoomPKState.isNoPK ||
            currentZegoUserRequest != null ||
            !ZegoLiveStreamingManager.instance.isLocalUserHost() ||
            !ZegoLiveStreamingManager.instance.isLivingNotifier.value) {
          rejectPKBattleRequest(event.requestID);
          return;
        }
        invitation.roomID = invitationMap['room_id'];
        invitation.inviterName = invitationMap['user_name'];
        invitation.inviterID = event.info.inviter;
        currentZegoUserRequest = invitation;
        incomingPKRequestStreamCtrl
            .add(IncomingPKRequestEvent(requestID: event.requestID));
        break;
      case PKProtocolType.endPK:
        responsePKEndRequest(event.requestID);
        stopPK();
        break;
      case PKProtocolType.resume:
        if (roomPKStateNoti.value != RoomPKState.isStartPK ||
            !ZegoLiveStreamingManager.instance.isLocalUserHost()) {
          rejectPKBattleRequest(event.requestID);
        } else {
          acceptResumePKRequest(event.requestID);
        }
        break;
    }
  }

  void onReceivePKCancel(IncomingUserRequestCancelledEvent event) {
    currentZegoUserRequest = null;
    incomingPKRequestCancelStreamCtrl
        .add(IncomingPKRequestCancelledEvent(requestID: event.requestID));
  }

  void onReceivePKAccept(OutgoingUserRequestAcceptedEvent event) {
    final Map<String, dynamic> invitationMap =
        jsonDecode(event.info.extendedData);
    final String roomID = invitationMap['room_id'];
    final String userName = invitationMap['user_name'];
    final int type = invitationMap['type'];
    if (type == PKProtocolType.startPK || type == PKProtocolType.resume) {
      willStartPK(
          roomID: roomID,
          userID: currentZegoUserRequest?.invitee.first ?? '',
          userName: userName);
      outgoingPKRequestAcceptStreamCtrl
          .add(OutgoingPKRequestAcceptEvent(requestID: event.requestID));
    }
  }

  void onReceivePKRejected(OutgoingUserRequestRejectedEvent event) {
    currentZegoUserRequest = null;
    roomPKStateNoti.value = RoomPKState.isNoPK;
    clearData();
    outgoingPKRequestRejectedStreamCtrl
        .add(OutgoingPKRequestRejectedEvent(requestID: event.requestID));
  }

  void onReceivePKTimeout(IncomingUserRequestTimeoutEvent event) {
    currentZegoUserRequest = null;
    incomingPKRequestTimeoutStreamCtrl
        .add(IncomingPKRequestTimeoutEvent(requestID: event.requestID));
  }

  void onReceivePKAnswerTimeout(OutgoingUserRequestTimeoutEvent event) {
    if (event.requestID == currentZegoUserRequest?.requestID) {
      clearData();
    }
    outgoingPKRequestAnsweredTimeoutStreamCtrl
        .add(OutgoingPKRequestTimeoutEvent(requestID: event.requestID));
  }

  void onRoomAttributeBatchUpdate(
      ZIMServiceRoomAttributeBatchUpdatedEvent event) {
    event.updateInfos.forEach(_onRoomAttributeUpdate);
  }

  void onRoomAttributeUpdate(ZIMServiceRoomAttributeUpdateEvent event) {
    _onRoomAttributeUpdate(event.updateInfo);
  }

  void _onRoomAttributeUpdate(ZIMRoomAttributesUpdateInfo updateInfo) {
    if (!updateInfo.roomAttributes.containsKey('pk_seq')) {
      return;
    }
    if (updateInfo.action == ZIMRoomAttributesUpdateAction.delete) {
      cleanPKState();
      return;
    }
    pkUser ??= ZegoSDKUser(
      userID: updateInfo.roomAttributes['pk_user_id'] ?? '',
      userName: updateInfo.roomAttributes['pk_user_name'] ?? '',
    );
    pkUser!.roomID = updateInfo.roomAttributes['pk_room'] ?? '';
    pkSeq = int.parse(updateInfo.roomAttributes['pk_seq'] ?? '0');
    if (pkUser!.userID.isNotEmpty && pkUser!.roomID.isNotEmpty) {
      if (ZegoLiveStreamingManager.instance.isLocalUserHost()) {
        if (pkRoomAttribute.isEmpty) {
          sendPKBattleResumeRequest(pkUser!.userID);
        }
        pkRoomAttribute = {
          'host': ZEGOSDKManager().currentUser?.userID ?? '',
          'pk_room': pkUser!.roomID,
          'pk_user_id': pkUser!.userID,
          'pk_user_name': pkUser!.userName,
          'pk_seq': '$pkSeq'
        };
      } else {
        if (ZegoLiveStreamingManager.instance.hostNoti.value?.userID != null) {
          willStartPK();
        }
      }
    } else {
      cleanPKState();
    }
  }

  // express listen
  void onReceiveAudioFirstFrame(ZegoRecvAudioFirstFrameEvent event) {
    if (event.streamID.endsWith('_mix')) {
      muteMainStream();
      onPKViewAvaliableNoti.value = true;
    }
  }

  void onReceiveVideoFirstFrame(ZegoRecvVideoFirstFrameEvent event) {
    if (event.streamID.endsWith('_mix')) {
      muteMainStream();
      onPKViewAvaliableNoti.value = true;
    }
  }

  void onMixerSoundLevelUpdate(ZegoMixerSoundLevelUpdateEvent event) {
    //..
  }
}
