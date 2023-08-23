import 'dart:async';
import 'dart:convert' as convert;
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:live_audio_room_demo/zego_sdk_manager.dart';

import '../define.dart';
import 'zego_service_define.dart';

export 'zego_service_define.dart';
export 'package:zego_express_engine/zego_express_engine.dart';

class ExpressService {
  ExpressService._internal();
  factory ExpressService() => instance;
  static final ExpressService instance = ExpressService._internal();

  String currentRoomID = '';
  ZegoUserInfo? localUser;
  List<ZegoUserInfo> userInfoList = [];
  Map<String, String> streamMap = {};

  Future<void> init({
    required int appID,
    String? appSign,
    ZegoScenario scenario = ZegoScenario.Broadcast,
  }) async {
    initEventHandle();
    final profile = ZegoEngineProfile(appID, scenario, appSign: appSign);
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
    localUser = ZegoUserInfo(userID: id, userName: name);
  }

  Future<void> disconnectUser() async {
    localUser = null;
  }

  ZegoUserInfo? getUserInfo(String userID) {
    for (var user in userInfoList) {
      if (user.userID == userID) {
        return user;
      }
    }
    return null;
  }

  Future<ZegoRoomLoginResult> loginRoom(String roomID, {String? token}) async {
    assert(!kIsWeb || token != null, 'token is required for web platform!');
    final joinRoomResult = await ZegoExpressEngine.instance.loginRoom(
      roomID,
      ZegoUser(localUser!.userID, localUser!.userName),
      config: ZegoRoomConfig(0, true, token ?? ''),
    );
    if (joinRoomResult.errorCode == 0) {
      currentRoomID = roomID;
    }
    return joinRoomResult;
  }

  Future<ZegoRoomLogoutResult> logoutRoom([String roomID = '']) async {
    if (roomID.isEmpty) roomID = currentRoomID;
    final leaveResult = await ZegoExpressEngine.instance.logoutRoom(roomID);
    if (leaveResult.errorCode == 0) {
      currentRoomID = '';
      userInfoList.clear();
      resertLocalUser();
      streamMap.clear();
    }
    return leaveResult;
  }

  void resertLocalUser() {
    localUser?.streamID = null;
    localUser?.isCamerOnNotifier.value = false;
    localUser?.isMicOnNotifier.value = false;
    localUser?.videoViewNotifier.value = null;
    localUser?.viewID = -1;
    localUser?.roleNotifier.value = ZegoLiveRole.audience;
  }

  void useFrontFacingCamera(bool isFrontFacing) {
    ZegoExpressEngine.instance.useFrontCamera(isFrontFacing);
  }

  void enableVideoMirroring(bool isVideoMirror) {
    ZegoExpressEngine.instance.setVideoMirrorMode(
      isVideoMirror ? ZegoVideoMirrorMode.BothMirror : ZegoVideoMirrorMode.NoMirror,
    );
  }

  void muteAllPlayStreamAudio(bool mute) {
    for (var streamID in streamMap.keys) {
      ZegoExpressEngine.instance.mutePlayStreamAudio(streamID, mute);
    }
  }

  void setAudioOutputToSpeaker(bool useSpeaker) {
    if (kIsWeb) {
      muteAllPlayStreamAudio(!useSpeaker);
    } else {
      ZegoExpressEngine.instance.setAudioRouteToSpeaker(useSpeaker);
    }
  }

  void turnCameraOn(bool isOn) {
    localUser?.isCamerOnNotifier.value = isOn;
    final extraInfo = jsonEncode({
      'mic': localUser?.isMicOnNotifier.value ?? false ? 'on' : 'off',
      'cam': localUser?.isCamerOnNotifier.value ?? false ? 'on' : 'off',
    });
    ZegoExpressEngine.instance.setStreamExtraInfo(extraInfo);
    ZegoExpressEngine.instance.enableCamera(isOn);
  }

  void turnMicrophoneOn(bool isOn) {
    localUser?.isMicOnNotifier.value = isOn;
    final extraInfo = jsonEncode({
      'mic': localUser?.isMicOnNotifier.value ?? false ? 'on' : 'off',
      'cam': localUser?.isCamerOnNotifier.value ?? false ? 'on' : 'off',
    });
    ZegoExpressEngine.instance.setStreamExtraInfo(extraInfo);
    ZegoExpressEngine.instance.mutePublishStreamAudio(!isOn);
  }

  Future<void> startPlayingStream(String streamID) async {
    String? userID = streamMap[streamID];
    ZegoUserInfo? userInfo = getUserInfo(userID ?? '');
    if (userInfo != null) {
      await ZegoExpressEngine.instance.createCanvasView((viewID) async {
        userInfo.viewID = viewID;
        ZegoCanvas canvas = ZegoCanvas(userInfo.viewID, viewMode: ZegoViewMode.AspectFill);
        await ZegoExpressEngine.instance.startPlayingStream(streamID, canvas: canvas);
      }).then((videoViewWidget) {
        userInfo.videoViewNotifier.value = videoViewWidget;
      });
    }
  }

  Future<void> stopPlayingStream(String streamID) async {
    String? userID = streamMap[streamID];
    ZegoUserInfo? userInfo = getUserInfo(userID ?? '');
    if (userInfo != null) {
      userInfo.streamID = '';
      userInfo.videoViewNotifier.value = null;
      userInfo.viewID = -1;
    }
    await ZegoExpressEngine.instance.stopPlayingStream(streamID);
  }

  Future<void> startPreview() async {
    if (localUser != null) {
      await ZegoExpressEngine.instance.createCanvasView((viewID) async {
        localUser!.viewID = viewID;
        final previewCanvas = ZegoCanvas(
          localUser!.viewID,
          viewMode: ZegoViewMode.AspectFill,
        );
        await ZegoExpressEngine.instance.startPreview(canvas: previewCanvas);
      }).then((videoViewWidget) {
        localUser!.videoViewNotifier.value = videoViewWidget;
      });
    }
  }

  Future<void> stopPreview() async {
    localUser?.videoViewNotifier.value = null;
    localUser?.viewID = -1;
    await ZegoExpressEngine.instance.stopPreview();
  }

  Future<void> startPublishingStream(String streamID) async {
    localUser?.streamID = streamID;
    final extraInfo = jsonEncode({
      'mic': localUser?.isMicOnNotifier.value ?? false ? 'on' : 'off',
      'cam': localUser?.isCamerOnNotifier.value ?? false ? 'on' : 'off',
    });
    await ZegoExpressEngine.instance.startPublishingStream(streamID);
    if (kIsWeb) {
      // delay 1s to set extra info
      await Future.delayed(const Duration(seconds: 1));
    }
    await ZegoExpressEngine.instance.setStreamExtraInfo(extraInfo);
  }

  Future<void> stopPublishingStream() async {
    localUser?.streamID = null;
    localUser?.isCamerOnNotifier.value = false;
    localUser?.isMicOnNotifier.value = false;
    await ZegoExpressEngine.instance.stopPublishingStream();
  }

  Future<ZegoRoomSetRoomExtraInfoResult> setRoomExtraInfo(String key, String value) async {
    ZegoRoomSetRoomExtraInfoResult result =
        await ZegoExpressEngine.instance.setRoomExtraInfo(currentRoomID, key, value);
    return result;
  }

  final roomUserListUpdateStreamCtrl = StreamController<ZegoRoomUserListUpdateEvent>.broadcast();
  final streamListUpdateStreamCtrl = StreamController<ZegoRoomStreamListUpdateEvent>.broadcast();
  final roomStreamExtraInfoStreamCtrl = StreamController<ZegoRoomStreamExtraInfoEvent>.broadcast();
  final roomStateChangedStreamCtrl = StreamController<ZegoRoomStateEvent>.broadcast();
  final roomExtraInfoUpdateCtrl = StreamController<ZegoRoomExtraInfoEvent>.broadcast();

  void uninitEventHandle() {
    ZegoExpressEngine.onRoomStreamUpdate = null;
    ZegoExpressEngine.onRoomUserUpdate = null;
    ZegoExpressEngine.onRoomStreamExtraInfoUpdate = null;
    ZegoExpressEngine.onRoomStateChanged = null;
    ZegoExpressEngine.onRoomExtraInfoUpdate = null;
  }

  void initEventHandle() {
    ZegoExpressEngine.onRoomStreamUpdate = ExpressService.instance.onRoomStreamUpdate;
    ZegoExpressEngine.onRoomUserUpdate = ExpressService.instance.onRoomUserUpdate;
    ZegoExpressEngine.onRoomStreamExtraInfoUpdate = ExpressService.instance.onRoomStreamExtraInfoUpdate;
    ZegoExpressEngine.onRoomStateChanged = ExpressService.instance.onRoomStateChanged;
    ZegoExpressEngine.onRoomExtraInfoUpdate = ExpressService.instance.onRoomExtraInfoUpdate;
  }

  Future<void> onRoomStreamUpdate(
      String roomID, ZegoUpdateType updateType, List<ZegoStream> streamList, Map<String, dynamic> extendedData) async {
    for (ZegoStream stream in streamList) {
      if (updateType == ZegoUpdateType.Add) {
        streamMap[stream.streamID] = stream.user.userID;
        ZegoUserInfo? userInfo = getUserInfo(stream.user.userID);
        if (userInfo == null) {
          userInfo = ZegoUserInfo(userID: stream.user.userID, userName: stream.user.userName);
          userInfoList.add(userInfo);
        }
        userInfo.streamID = stream.streamID;
        try {
          Map<String, dynamic> extraInfoMap = convert.jsonDecode(stream.extraInfo);
          bool isMicOn = (extraInfoMap['mic'] == 'on') ? true : false;
          bool isCameraOn = (extraInfoMap['cam'] == 'on') ? true : false;
          userInfo.isCamerOnNotifier.value = isCameraOn;
          userInfo.isMicOnNotifier.value = isMicOn;
        } catch (e) {
          debugPrint('stream.extraInfo: ${stream.extraInfo}.');
        }

        startPlayingStream(stream.streamID);
      } else {
        streamMap[stream.streamID] = '';
        ZegoUserInfo? userInfo = getUserInfo(stream.user.userID);
        userInfo?.streamID = '';
        userInfo?.isCamerOnNotifier.value = false;
        userInfo?.isMicOnNotifier.value = false;
        stopPlayingStream(stream.streamID);
      }
    }
    streamListUpdateStreamCtrl.add(ZegoRoomStreamListUpdateEvent(roomID, updateType, streamList, extendedData));
  }

  void onRoomUserUpdate(
    String roomID,
    ZegoUpdateType updateType,
    List<ZegoUser> userList,
  ) {
    if (updateType == ZegoUpdateType.Add) {
      for (var user in userList) {
        ZegoUserInfo? userInfo = getUserInfo(user.userID);
        if (userInfo == null) {
          userInfo = ZegoUserInfo(userID: user.userID, userName: user.userName);
          userInfo.avatarUrlNotifier.value = ZEGOSDKManager.instance.zimService.getUserAvatar(user.userID);
          userInfoList.add(userInfo);
        } else {
          userInfo.userID = user.userID;
          userInfo.userName = user.userName;
          userInfo.avatarUrlNotifier.value = ZEGOSDKManager.instance.zimService.getUserAvatar(user.userID);
        }
      }
    } else {
      for (var user in userList) {
        userInfoList.removeWhere((element) {
          return element.userID == user.userID;
        });
      }
    }
    roomUserListUpdateStreamCtrl.add(ZegoRoomUserListUpdateEvent(roomID, updateType, userList));
  }

  void onRoomStreamExtraInfoUpdate(String roomID, List<ZegoStream> streamList) {
    for (var user in userInfoList) {
      for (ZegoStream stream in streamList) {
        if (stream.streamID == user.streamID) {
          try {
            Map<String, dynamic> extraInfoMap = convert.jsonDecode(stream.extraInfo);
            bool isMicOn = (extraInfoMap['mic'] == 'on') ? true : false;
            bool isCameraOn = (extraInfoMap['cam'] == 'on') ? true : false;
            user.isCamerOnNotifier.value = isCameraOn;
            user.isMicOnNotifier.value = isMicOn;
          } catch (e) {
            debugPrint('stream.extraInfo: ${stream.extraInfo}.');
          }
        }
      }
    }
    roomStreamExtraInfoStreamCtrl.add(ZegoRoomStreamExtraInfoEvent(roomID, streamList));
  }

  void onRoomStateChanged(
      String roomID, ZegoRoomStateChangedReason reason, int errorCode, Map<String, dynamic> extendedData) {
    roomStateChangedStreamCtrl.add(ZegoRoomStateEvent(roomID, reason, errorCode, extendedData));
  }

  void onRoomExtraInfoUpdate(String roomID, List<ZegoRoomExtraInfo> roomExtraInfoList) {
    roomExtraInfoUpdateCtrl.add(ZegoRoomExtraInfoEvent(roomExtraInfoList));
  }
}
