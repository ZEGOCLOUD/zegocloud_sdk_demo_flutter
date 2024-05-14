import 'dart:async';
import 'dart:convert' as convert;
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../internal_defines.dart';
import 'express_service.dart';

export 'package:zego_express_engine/zego_express_engine.dart';

export '../../internal_defines.dart';

part 'express_service_media.dart';
part 'express_service_mixer.dart';
part 'express_service_room_extra_info.dart';
part 'express_service_sei.dart';
part 'express_service_stream.dart';

class ExpressService {
  ExpressService._internal();

  factory ExpressService() => instance;
  static final ExpressService instance = ExpressService._internal();

  String currentRoomID = '';
  ZegoRoomStateChangedReason currentRoomState = ZegoRoomStateChangedReason.Logout;
  ZegoSDKUser? currentUser;
  List<ZegoSDKUser> userInfoList = [];
  var remoteStreamUserInfoListNotifier = ValueNotifier<List<ZegoSDKUser>>([]);
  Map<String, String> streamMap = {};
  ZegoMixerTask? currentMixerTask;
  ValueNotifier<Widget?> mixerStreamNotifier = ValueNotifier(null);
  ZegoScenario currentScenario = ZegoScenario.Default;
  ValueNotifier<ZegoPublisherState> publisherState = ValueNotifier<ZegoPublisherState>(ZegoPublisherState.NoPublish);

  void clearRoomData() {
    currentScenario = ZegoScenario.Default;
    currentRoomID = '';
    currentRoomState = ZegoRoomStateChangedReason.Logout;
    userInfoList.clear();
    // remoteStreamUserInfoListNotifier.value = <ZegoSDKUser>[];
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
    ZegoExpressEngine.setEngineConfig(ZegoEngineConfig(advancedConfig: {'vcap_external_mem_class': '1'}));
    final profile = ZegoEngineProfile(appID, scenario, appSign: appSign);
    if (Platform.isIOS) {
      profile.enablePlatformView = true;
    }

    currentScenario = scenario;
    await ZegoExpressEngine.createEngineWithProfile(profile);
    ZegoExpressEngine.instance.enableHardwareEncoder(true);
    ZegoExpressEngine.instance.enableHardwareDecoder(true);
    ZegoExpressEngine.setEngineConfig(ZegoEngineConfig(advancedConfig: {
      'notify_remote_device_unknown_status': 'true',
      'notify_remote_device_init_status': 'true',
      'keep_audio_session_active': 'true',
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

  ZegoSDKUser? getRemoteUser(String userID) {
    for (final user in remoteStreamUserInfoListNotifier.value) {
      if (user.userID == userID) {
        return user;
      }
    }

    return null;
  }

  Future<void> setRoomScenario(ZegoScenario scenario) async {
    currentScenario = scenario;
    return ZegoExpressEngine.instance.setRoomScenario(scenario);
  }

  Future<ZegoRoomLoginResult> loginRoom(String roomID, {String? token}) async {
    assert(!kIsWeb || token != null, 'token is required for web platform!');

    debugPrint('express service, ready loginRoom, '
        'current room id:$currentRoomID, '
        'target room id:$roomID, ');

    currentRoomID = roomID;

    final joinRoomResult = await ZegoExpressEngine.instance.loginRoom(
      roomID,
      ZegoUser(currentUser!.userID, currentUser!.userName),
      config: ZegoRoomConfig(0, true, token ?? ''),
    );
    debugPrint('express service, loginRoom, id:$roomID, result:${joinRoomResult.errorCode}');
    if (joinRoomResult.errorCode != 0) {
      currentRoomID = '';
    }

    return joinRoomResult;
  }

  Future<ZegoRoomLogoutResult> logoutRoom([String roomID = '']) async {
    debugPrint('express service, ready logoutRoom, room id:$currentRoomID');

    final targetRoomID = roomID.isNotEmpty ? roomID : currentRoomID;
    clearRoomData();

    final leaveResult = await ZegoExpressEngine.instance.logoutRoom();
    debugPrint('express service, logoutRoom, id:$targetRoomID, result:${leaveResult.errorCode}');

    return leaveResult;
  }

  void clearLocalUserData() {
    currentUser!.streamID = null;
    currentUser!.isCameraOnNotifier.value = false;
    currentUser!.isMicOnNotifier.value = false;
    currentUser!.isUsingFrontCameraNotifier.value = true;
    currentUser!.isUsingSpeaker.value = true;
    currentUser!.videoViewNotifier.value = null;
    currentUser!.viewID = -1;
  }

  void useFrontCamera(bool isFrontFacing) {
    currentUser!.isUsingFrontCameraNotifier.value = isFrontFacing;
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
    currentUser!.isUsingSpeaker.value = useSpeaker;
    if (kIsWeb) {
      muteAllPlayStreamAudio(!useSpeaker);
    } else {
      ZegoExpressEngine.instance.setAudioRouteToSpeaker(useSpeaker);
    }
  }

  void turnCameraOn(bool isOn) {
    currentUser!.isCameraOnNotifier.value = isOn;
    updateStreamExtraInfo();
    ZegoExpressEngine.instance.enableCamera(isOn);
  }

  void turnMicrophoneOn(bool isOn) {
    currentUser!.isMicOnNotifier.value = isOn;
    updateStreamExtraInfo();
    ZegoExpressEngine.instance.mutePublishStreamAudio(!isOn);
  }

  Future<void> startPlayingStream(String streamID, {ZegoViewMode viewMode = ZegoViewMode.AspectFill, ZegoPlayerConfig? config}) async {
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
      if (userInfo.viewID != -1) {
        final canvas = ZegoCanvas(userInfo.viewID, viewMode: streamPlayViewMode);
        await ZegoExpressEngine.instance.startPlayingStream(streamID, canvas: canvas, config: config);
      } else {
        await ZegoExpressEngine.instance.createCanvasView((viewID) async {
          userInfo.viewID = viewID;
          final canvas = ZegoCanvas(userInfo.viewID, viewMode: streamPlayViewMode);
          await ZegoExpressEngine.instance.startPlayingStream(streamID, canvas: canvas, config: config);
        }).then((videoViewWidget) {
          userInfo.videoViewNotifier.value = videoViewWidget;
        });
      }
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
  final onMediaPlayerStateUpdateCtrl = StreamController<ZegoPlayerStateChangeEvent>.broadcast();
  final onMediaPlayerFirstFrameEventCtrl = StreamController<ZegoMediaPlayerFirstFrameEvent>.broadcast();

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
    ZegoExpressEngine.onPublisherStateUpdate = null;
    ZegoExpressEngine.onMediaPlayerFirstFrameEvent = null;
    ZegoExpressEngine.onMediaPlayerStateUpdate = null;
  }

  void initEventHandle() {
    ZegoExpressEngine.onRoomStreamUpdate = ExpressService().onRoomStreamUpdate;
    ZegoExpressEngine.onRoomUserUpdate = ExpressService().onRoomUserUpdate;
    ZegoExpressEngine.onRoomStreamExtraInfoUpdate = ExpressService().onRoomStreamExtraInfoUpdate;
    ZegoExpressEngine.onRoomStateChanged = ExpressService().onRoomStateChanged;
    ZegoExpressEngine.onCapturedSoundLevelUpdate = ExpressService().onCapturedSoundLevelUpdate;
    ZegoExpressEngine.onRemoteSoundLevelUpdate = ExpressService().onRemoteSoundLevelUpdate;
    ZegoExpressEngine.onMixerSoundLevelUpdate = ExpressService().onMixerSoundLevelUpdate;
    ZegoExpressEngine.onPlayerRecvAudioFirstFrame = ExpressService().onPlayerRecvAudioFirstFrame;
    ZegoExpressEngine.onPlayerRecvVideoFirstFrame = ExpressService().onPlayerRecvVideoFirstFrame;
    ZegoExpressEngine.onPlayerRecvSEI = ExpressService().onPlayerRecvSEI;
    ZegoExpressEngine.onRoomExtraInfoUpdate = ExpressService().onRoomExtraInfoUpdate;
    ZegoExpressEngine.onPublisherStateUpdate = ExpressService().onPublisherStateUpdate;
    ZegoExpressEngine.onMediaPlayerStateUpdate = ExpressService().onMediaPlayerStateUpdate;
    ZegoExpressEngine.onMediaPlayerFirstFrameEvent = ExpressService().onMediaPlayerFirstFrameEvent;
  }

  void onRoomUserUpdate(
    String roomID,
    ZegoUpdateType updateType,
    List<ZegoUser> userList,
  ) {
    if (updateType == ZegoUpdateType.Add) {
      for (final user in userList) {
        var userInfo = getUser(user.userID);
        if (userInfo == null) {
          userInfo = getRemoteUser(user.userID);
          if (userInfo == null) {
            userInfoList.add(ZegoSDKUser(userID: user.userID, userName: user.userName));
          } else {
            ///  sync from remote user
            userInfo
              ..userID = user.userID
              ..userName = user.userName;
          }
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
    String roomID,
    ZegoRoomStateChangedReason reason,
    int errorCode,
    Map<String, dynamic> extendedData,
  ) {
    currentRoomState = reason;

    debugPrint('express service, onRoomStateChanged, '
        'room id:$roomID, '
        'reason:$reason, ');

    roomStateChangedStreamCtrl.add(ZegoRoomStateEvent(roomID, reason, errorCode, extendedData));
  }
}
