import 'dart:async';
import 'dart:convert' as convert;
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../internal_defines.dart';
import 'express_service.dart';

export 'package:pkbattles/internal/business/business_define.dart';
export 'package:zego_express_engine/zego_express_engine.dart';

export '../../internal_defines.dart';

part 'express_service_mixer.dart';
part 'express_service_room_extra_info.dart';
part 'express_service_sei.dart';
part 'express_service_stream.dart';

class ExpressService {
  ExpressService._internal();
  factory ExpressService() => instance;
  static final ExpressService instance = ExpressService._internal();

  String currentRoomID = '';
  ZegoSDKUser? currentUser;
  List<ZegoSDKUser> userInfoList = [];
  Map<String, String> streamMap = {};
  ZegoMixerTask? currentMixerTask;
  ValueNotifier<Widget?> mixerStreamNotifier = ValueNotifier(null);
  ZegoScenario currentScenario = ZegoScenario.Default;

  void clearRoomData() {
    currentScenario = ZegoScenario.Default;
    currentRoomID = '';
    userInfoList.clear();
    clearLocalUserData();
    streamMap.clear();
    currentMixerTask = null;
    mixerStreamNotifier.value = null;
  }

  Future<void> uploadLog() {
    return ZegoExpressEngine.instance.uploadLog();
  }

  Future<void> init({
    required int appID,
    String? appSign,
    ZegoScenario scenario = ZegoScenario.Default,
  }) async {
    initEventHandle();
    final profile = ZegoEngineProfile(appID, scenario, appSign: appSign)..scenario = scenario;
    currentScenario = scenario;
    await ZegoExpressEngine.createEngineWithProfile(profile);
    ZegoExpressEngine.setEngineConfig(ZegoEngineConfig(advancedConfig: {
      'notify_remote_device_unknown_status': 'true',
      'notify_remote_device_init_status': 'true',
    }));
  }

  Future<void> uninit() async {
    uninitEventHandle();
    await ZegoExpressEngine.destroyEngine();
  }

  Future<void> connectUser(String id, String name, {String? token}) async {
    currentUser = ZegoSDKUser(userID: id, userName: name);
  }

  Future<void> disconnectUser() async {
    currentUser = null;
  }

  ZegoSDKUser? getUser(String userID) {
    for (final user in userInfoList) {
      if (user.userID == userID) {
        return user;
      }
    }
    return null;
  }

  Future<void> setRoomScenario(ZegoScenario scenario) async {
    currentScenario = scenario;
    ZegoExpressEngine.instance.setRoomScenario(scenario);
  }

  Future<ZegoRoomLoginResult> loginRoom(String roomID, {String? token}) async {
    assert(!kIsWeb || token != null, 'token is required for web platform!');
    final joinRoomResult = await ZegoExpressEngine.instance.loginRoom(
      roomID,
      ZegoUser(currentUser!.userID, currentUser!.userName),
      config: ZegoRoomConfig(0, true, token ?? ''),
    );
    if (joinRoomResult.errorCode == 0) {
      currentRoomID = roomID;
    }
    return joinRoomResult;
  }

  Future<ZegoRoomLogoutResult> logoutRoom([String roomID = '']) async {
    final leaveResult = await ZegoExpressEngine.instance.logoutRoom(roomID.isNotEmpty ? roomID : currentRoomID);
    if (leaveResult.errorCode == 0) {
      clearRoomData();
    }
    return leaveResult;
  }

  void clearLocalUserData() {
    currentUser?.streamID = null;
    currentUser?.isCamerOnNotifier.value = false;
    currentUser?.isMicOnNotifier.value = false;
    currentUser?.videoViewNotifier.value = null;
    currentUser?.viewID = -1;
  }

  void useFrontCamera(bool isFrontFacing) {
    ZegoExpressEngine.instance.useFrontCamera(isFrontFacing);
  }

  void enableVideoMirroring(bool isVideoMirror) {
    ZegoExpressEngine.instance.setVideoMirrorMode(
      isVideoMirror ? ZegoVideoMirrorMode.BothMirror : ZegoVideoMirrorMode.NoMirror,
    );
  }

  void muteAllPlayStreamAudio(bool mute) {
    for (final streamID in streamMap.keys) {
      ZegoExpressEngine.instance.mutePlayStreamAudio(streamID, mute);
    }
  }

  void setAudioRouteToSpeaker(bool useSpeaker) {
    if (kIsWeb) {
      muteAllPlayStreamAudio(!useSpeaker);
    } else {
      ZegoExpressEngine.instance.setAudioRouteToSpeaker(useSpeaker);
    }
  }

  void turnCameraOn(bool isOn) {
    currentUser?.isCamerOnNotifier.value = isOn;
    final extraInfo = jsonEncode({
      'mic': currentUser!.isMicOnNotifier.value ? 'on' : 'off',
      'cam': currentUser!.isCamerOnNotifier.value ? 'on' : 'off',
    });
    ZegoExpressEngine.instance.setStreamExtraInfo(extraInfo);
    ZegoExpressEngine.instance.enableCamera(isOn);
  }

  void turnMicrophoneOn(bool isOn) {
    currentUser?.isMicOnNotifier.value = isOn;
    final extraInfo = jsonEncode({
      'mic': currentUser!.isMicOnNotifier.value ? 'on' : 'off',
      'cam': currentUser!.isCamerOnNotifier.value ? 'on' : 'off',
    });
    ZegoExpressEngine.instance.setStreamExtraInfo(extraInfo);
    ZegoExpressEngine.instance.mutePublishStreamAudio(!isOn);
  }

  Future<void> startPlayingStream(String streamID,
      {ZegoViewMode viewMode = ZegoViewMode.AspectFill, ZegoPlayerConfig? config}) async {
    final userID = streamMap[streamID];
    final userInfo = getUser(userID ?? '');
    if (currentScenario == ZegoScenario.HighQualityChatroom ||
        currentScenario == ZegoScenario.StandardChatroom ||
        currentScenario == ZegoScenario.StandardVideoCall ||
        currentScenario == ZegoScenario.StandardVoiceCall ||
        currentScenario == ZegoScenario.HighQualityVideoCall) {
      if (config == null) {
        config = ZegoPlayerConfig.defaultConfig()..resourceMode = ZegoStreamResourceMode.OnlyRTC;
      } else {
        config.resourceMode = ZegoStreamResourceMode.OnlyRTC;
      }
    }
    if (userInfo != null) {
      await ZegoExpressEngine.instance.createCanvasView((viewID) async {
        userInfo.viewID = viewID;
        final canvas = ZegoCanvas(userInfo.viewID, viewMode: ZegoViewMode.AspectFill);
        await ZegoExpressEngine.instance.startPlayingStream(streamID, canvas: canvas, config: config);
      }).then((videoViewWidget) {
        userInfo.videoViewNotifier.value = videoViewWidget;
      });
    }
  }

  final roomUserListUpdateStreamCtrl = StreamController<ZegoRoomUserListUpdateEvent>.broadcast();
  final streamListUpdateStreamCtrl = StreamController<ZegoRoomStreamListUpdateEvent>.broadcast();
  final roomStreamExtraInfoStreamCtrl = StreamController<ZegoRoomStreamExtraInfoEvent>.broadcast();
  final roomStateChangedStreamCtrl = StreamController<ZegoRoomStateEvent>.broadcast();
  final roomExtraInfoUpdateCtrl = StreamController<ZegoRoomExtraInfoEvent>.broadcast();
  final recvAudioFirstFrameCtrl = StreamController<ZegoRecvAudioFirstFrameEvent>.broadcast();
  final recvVideoFirstFrameCtrl = StreamController<ZegoRecvVideoFirstFrameEvent>.broadcast();
  final recvSEICtrl = StreamController<ZegoRecvSEIEvent>.broadcast();
  final mixerSoundLevelUpdateCtrl = StreamController<ZegoMixerSoundLevelUpdateEvent>.broadcast();

  void uninitEventHandle() {
    ZegoExpressEngine.onRoomStreamUpdate = null;
    ZegoExpressEngine.onRoomUserUpdate = null;
    ZegoExpressEngine.onRoomStreamExtraInfoUpdate = null;
    ZegoExpressEngine.onRoomStateChanged = null;
    ZegoExpressEngine.onRoomExtraInfoUpdate = null;
    ZegoExpressEngine.onCapturedSoundLevelUpdate = null;
    ZegoExpressEngine.onRemoteSoundLevelUpdate = null;
    ZegoExpressEngine.onMixerSoundLevelUpdate = null;
    ZegoExpressEngine.onPlayerRecvAudioFirstFrame = null;
    ZegoExpressEngine.onPlayerRecvVideoFirstFrame = null;
    ZegoExpressEngine.onPlayerRecvSEI = null;
  }

  void initEventHandle() {
    ZegoExpressEngine.onRoomStreamUpdate = ExpressService.instance.onRoomStreamUpdate;
    ZegoExpressEngine.onRoomUserUpdate = ExpressService.instance.onRoomUserUpdate;
    ZegoExpressEngine.onRoomStreamExtraInfoUpdate = ExpressService.instance.onRoomStreamExtraInfoUpdate;
    ZegoExpressEngine.onRoomStateChanged = ExpressService.instance.onRoomStateChanged;
    ZegoExpressEngine.onCapturedSoundLevelUpdate = ExpressService.instance.onCapturedSoundLevelUpdate;
    ZegoExpressEngine.onRemoteSoundLevelUpdate = ExpressService.instance.onRemoteSoundLevelUpdate;
    ZegoExpressEngine.onMixerSoundLevelUpdate = ExpressService.instance.onMixerSoundLevelUpdate;
    ZegoExpressEngine.onPlayerRecvAudioFirstFrame = ExpressService.instance.onPlayerRecvAudioFirstFrame;
    ZegoExpressEngine.onPlayerRecvVideoFirstFrame = ExpressService.instance.onPlayerRecvVideoFirstFrame;
    ZegoExpressEngine.onPlayerRecvSEI = ExpressService.instance.onPlayerRecvSEI;
    ZegoExpressEngine.onRoomExtraInfoUpdate = ExpressService.instance.onRoomExtraInfoUpdate;
  }

  void onRoomUserUpdate(
    String roomID,
    ZegoUpdateType updateType,
    List<ZegoUser> userList,
  ) {
    if (updateType == ZegoUpdateType.Add) {
      for (final user in userList) {
        final userInfo = getUser(user.userID);
        if (userInfo == null) {
          userInfoList.add(ZegoSDKUser(userID: user.userID, userName: user.userName));
        } else {
          userInfo
            ..userID = user.userID
            ..userName = user.userName;
        }
      }
    } else {
      for (final user in userList) {
        userInfoList.removeWhere((element) {
          return element.userID == user.userID;
        });
      }
    }
    roomUserListUpdateStreamCtrl.add(ZegoRoomUserListUpdateEvent(roomID, updateType, userList));
  }

  void onRoomStateChanged(
      String roomID, ZegoRoomStateChangedReason reason, int errorCode, Map<String, dynamic> extendedData) {
    roomStateChangedStreamCtrl.add(ZegoRoomStateEvent(roomID, reason, errorCode, extendedData));
  }
}
