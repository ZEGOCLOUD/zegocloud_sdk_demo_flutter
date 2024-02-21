import 'dart:async';

import 'package:flutter/foundation.dart';

import 'internal/business/coHost/cohost_service.dart';
import 'internal/business/pk/pk_define.dart';
import 'internal/business/pk/pk_info.dart';
import 'internal/business/pk/pk_service.dart';
import 'internal/sdk/utils/flutter_extension.dart';
import 'utils/zegocloud_token.dart';
import 'zego_live_streaming_manager_extension.dart';
import 'zego_live_streaming_manager_interface.dart';
import 'zego_sdk_key_center.dart';
import 'zego_sdk_manager.dart';

class ZegoLiveStreamingManager implements ZegoLiveStreamingManagerInterface {
  ZegoLiveStreamingManager._internal();
  factory ZegoLiveStreamingManager() => instance;
  static final ZegoLiveStreamingManager instance = ZegoLiveStreamingManager._internal();

  List<ZegoMixerInput> Function(List<String> streamIDList, ZegoMixerVideoConfig videoConfig)? setMixerLayout;

  ValueNotifier<ZegoLiveStreamingRole> currentUserRoleNotifier = ValueNotifier(ZegoLiveStreamingRole.audience);
  ValueNotifier<bool> isLivingNotifier = ValueNotifier(false);
  List<StreamSubscription> subscriptions = [];

  PKInfo? get pkInfo => pkService?.pkInfo;

  ValueNotifier<ZegoSDKUser?> get hostNotifier => cohostService?.hostNoti ?? ValueNotifier(null);

  ListNotifier<ZegoSDKUser> get coHostUserListNotifier => cohostService?.coHostUserListNoti ?? ListNotifier([]);

  ValueNotifier<RoomPKState> get pkStateNotifier => pkService?.pkStateNoti ?? ValueNotifier(RoomPKState.isNoPK);

  ValueNotifier<bool> get isMuteAnotherAudioNotifier => pkService?.isMuteAnotherAudioNoti ?? ValueNotifier(false);

  ValueNotifier<bool> get onPKViewAvailableNotifier => pkService?.onPKViewAvaliableNoti ?? ValueNotifier(false);

  ZegoSDKUser? get pkUser => pkService?.pkUser;

  StreamController<PKBattleReceivedEvent> get onPKBattleReceived =>
      pkService?.onPKBattleReceived ?? StreamController<PKBattleReceivedEvent>.broadcast();

  StreamController<PKBattleCancelledEvent> get onPKBattleCancelStreamCtrl =>
      pkService?.onPKBattleCancelStreamCtrl ?? StreamController<PKBattleCancelledEvent>.broadcast();

  StreamController<PKBattleRejectedEvent> get onPKBattleRejectedStreamCtrl =>
      pkService?.onPKBattleRejectedStreamCtrl ?? StreamController<PKBattleRejectedEvent>.broadcast();

  StreamController<PKBattleAcceptedEvent> get onPKBattleAcceptedCtrl =>
      pkService?.onPKBattleAcceptedCtrl ?? StreamController<PKBattleAcceptedEvent>.broadcast();

  StreamController<PKBattleUserJoinEvent> get onPKUserJoinCtrl =>
      pkService?.onPKUserJoinCtrl ?? StreamController<PKBattleUserJoinEvent>.broadcast();

  StreamController<PKBattleUserQuitEvent> get onPKBattleUserQuitCtrl =>
      pkService?.onPKBattleUserQuitCtrl ?? StreamController<PKBattleUserQuitEvent>.broadcast();

  StreamController<PKBattleUserUpdateEvent> get onPKBattleUserUpdateCtrl =>
      pkService?.onPKBattleUserUpdateCtrl ?? StreamController<PKBattleUserUpdateEvent>.broadcast();

  StreamController get onPKStartStreamCtrl => pkService?.onPKStartStreamCtrl ?? StreamController.broadcast();

  StreamController get onPKEndStreamCtrl => pkService?.onPKEndStreamCtrl ?? StreamController.broadcast();

  StreamController<PKBattleUserConnectingEvent> get onPKUserConnectingCtrl =>
      pkService?.onPKUserConnectingCtrl ?? StreamController<PKBattleUserConnectingEvent>.broadcast();

  StreamController<IncomingPKRequestTimeoutEvent> get incomingPKRequestTimeoutStreamCtrl =>
      pkService?.incomingPKRequestTimeoutStreamCtrl ?? StreamController<IncomingPKRequestTimeoutEvent>.broadcast();

  StreamController<OutgoingPKRequestTimeoutEvent> get outgoingPKRequestAnsweredTimeoutStreamCtrl =>
      pkService?.outgoingPKRequestAnsweredTimeoutStreamCtrl ??
      StreamController<OutgoingPKRequestTimeoutEvent>.broadcast();

  PKService? pkService;
  CoHostService? cohostService;

  @override
  void init() {
    pkService = PKService()
      ..addListener()
      ..setMixerLayout = (streamIDList, videoConfig) {
        if (setMixerLayout != null) {
          return setMixerLayout!(streamIDList, videoConfig);
        } else {
          return [];
        }
      };
    cohostService = CoHostService();
    final expressService = ZEGOSDKManager().expressService;
    subscriptions.addAll([
      expressService.streamListUpdateStreamCtrl.stream.listen(onStreamListUpdate),
      expressService.roomUserListUpdateStreamCtrl.stream.listen(onRoomUserUpdate),
      expressService.recvAudioFirstFrameCtrl.stream.listen(onPlayerRecvAudioFirstFrame),
      expressService.recvVideoFirstFrameCtrl.stream.listen(onPlayerRecvVideoFirstFrame),
      expressService.recvSEICtrl.stream.listen(onPlayerSyncRecvSEI),
    ]);
  }

  @override
  void uninit() {
    pkService?.uninit();
    for (final subscription in subscriptions) {
      subscription.cancel();
    }
  }

  @override
  Future<ZegoRoomLoginResult> startLive(String roomID) async {
    isLivingNotifier.value = true;
    String? token;
    if (kIsWeb) {
      // ! ** Warning: ZegoTokenUtils is only for use during testing. When your application goes live,
      // ! ** tokens must be generated by the server side. Please do not generate tokens on the client side!
      token = ZegoTokenUtils.generateToken(
          SDKKeyCenter.appID, SDKKeyCenter.serverSecret, ZEGOSDKManager().currentUser!.userID);
    }
    final result = await ZEGOSDKManager().loginRoom(roomID, ZegoScenario.Broadcast, token: token);
    return result;
  }

  @override
  Future<void> startCoHost() async {
    ZEGOSDKManager().expressService.turnCameraOn(true);
    ZEGOSDKManager().expressService.turnMicrophoneOn(true);
    ZEGOSDKManager().expressService.startPreview();
    ZEGOSDKManager().expressService.startPublishingStream(coHostStreamID());
    currentUserRoleNotifier.value = ZegoLiveStreamingRole.coHost;
    cohostService?.startCoHost();
  }

  @override
  Future<void> endCoHost() async {
    ZEGOSDKManager().expressService.stopPreview();
    ZEGOSDKManager().expressService.stopPublishingStream();
    currentUserRoleNotifier.value = ZegoLiveStreamingRole.audience;
    cohostService?.endCoHost();
  }

  @override
  bool iamHost() {
    return cohostService?.iamHost() ?? false;
  }

  @override
  bool isHost(String userID) {
    return cohostService?.isHost(userID) ?? false;
  }

  @override
  bool isCoHost(String userID) {
    return cohostService?.isCoHost(userID) ?? false;
  }

  @override
  bool isAudience(String userID) {
    return cohostService?.isAudience(userID) ?? false;
  }

  @override
  void leaveRoom() {
    if (iamHost()) {
      quitPKBattle();
    }
    isLivingNotifier.value = false;
    ZEGOSDKManager().logoutRoom();
    clearData();
  }

  @override
  void clearData() {
    cohostService?.clearData();
    pkService?.clearData();
  }

  @override
  String hostStreamID() {
    return '${ZEGOSDKManager().expressService.currentRoomID}_${ZEGOSDKManager().currentUser!.userID}_main_host';
  }

  @override
  String coHostStreamID() {
    return '${ZEGOSDKManager().expressService.currentRoomID}_${ZEGOSDKManager().currentUser!.userID}_main_cohost';
  }

  @override
  bool isPKUser(String userID) {
    return pkService!.isPKUser(userID);
  }

  @override
  bool isPKUserMuted(String userID) {
    return pkService!.isPKUserMuted(userID);
  }

  @override
  Future<PKInviteSentResult> startPKBattle(String anotherHostID) async {
    return pkService!.invitePKbattle([anotherHostID], true);
  }

  @override
  Future<PKInviteSentResult> startPKBattleWith(List<String> anotherHostIDList) async {
    return pkService!.invitePKbattle(anotherHostIDList, true);
  }

  @override
  Future<PKInviteSentResult> invitePKBattle(String targetUserID) async {
    return pkService!.invitePKbattle([targetUserID], false);
  }

  @override
  Future<PKInviteSentResult> invitePKBattleWith(List<String> targetUserIDList) async {
    return pkService!.invitePKbattle(targetUserIDList, false);
  }

  @override
  Future<void> acceptPKStartRequest(String requestID) async {
    pkService!.acceptPKBattle(requestID);
  }

  @override
  Future<void> rejectPKStartRequest(String requestID) async {
    pkService!.rejectPKBattle(requestID);
  }

  @override
  Future<void> cancelPKBattleRequest(String requestID, String targetUserID) async {
    pkService!.cancelPKBattle(requestID, targetUserID);
  }

  @override
  Future<ZegoMixerStartResult> mutePKUser(List<String> muteUserList, bool mute) async {
    if (pkInfo != null) {
      final muteIndex = <int>[];
      for (final muteUserID in muteUserList) {
        var index = 0;
        for (final user in pkInfo!.pkUserList.value) {
          if (user.userID == muteUserID) {
            muteIndex.add(index);
          }
          index++;
        }
      }
      return pkService!.mutePKUser(muteIndex, mute);
    }
    return ZegoMixerStartResult(-9999, {});
  }

  @override
  Future<void> quitPKBattle() async {
    if (pkService?.pkInfo != null) {
      pkService!.stopPlayAnotherHostStream();
      pkService!.quitPKBattle(pkService?.pkInfo!.requestID ?? '');
      pkService!.stopPKBattle();
    }
  }

  @override
  Future<void> endPKBattle() async {
    if (pkService?.pkInfo != null) {
      pkService!.endPKBattle(pkService?.pkInfo!.requestID ?? '');
      pkService?.stopPKBattle();
    }
  }

  @override
  void removeUserFromPKBattle(String userID) {
    pkService!.removeUserFromPKBattle(userID);
  }

  @override
  void stopPKBattle() {
    pkService!.stopPKBattle();
  }
}
