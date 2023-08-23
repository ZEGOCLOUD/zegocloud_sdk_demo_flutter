part of 'express_service.dart';

extension ExpressServiceStream on ExpressService {
  Future<void> stopPlayingStream(String streamID) async {
    final userID = streamMap[streamID];
    final userInfo = getUser(userID ?? '');
    if (userInfo != null) {
      userInfo.streamID = '';
      userInfo.videoViewNotifier.value = null;
      userInfo.viewID = -1;
    }
    await ZegoExpressEngine.instance.stopPlayingStream(streamID);
  }

  Future<void> startPreview({viewMode = ZegoViewMode.AspectFill}) async {
    if (currentUser != null) {
      await ZegoExpressEngine.instance.createCanvasView((viewID) async {
        currentUser!.viewID = viewID;
        final previewCanvas = ZegoCanvas(
          currentUser!.viewID,
          viewMode: viewMode,
        );
        await ZegoExpressEngine.instance.startPreview(canvas: previewCanvas);
      }).then((videoViewWidget) {
        currentUser!.videoViewNotifier.value = videoViewWidget;
      });
    }
  }

  Future<void> stopPreview() async {
    currentUser?.videoViewNotifier.value = null;
    currentUser?.viewID = -1;
    await ZegoExpressEngine.instance.stopPreview();
  }

  Future<void> startPublishingStream(String streamID, {ZegoPublishChannel channel = ZegoPublishChannel.Main}) async {
    currentUser?.streamID = streamID;
    final extraInfo = jsonEncode({
      'mic': currentUser?.isMicOnNotifier.value ?? false ? 'on' : 'off',
      'cam': currentUser?.isCamerOnNotifier.value ?? false ? 'on' : 'off',
    });
    debugPrint('startPublishingStream:$streamID');
    await ZegoExpressEngine.instance.startPublishingStream(streamID, channel: channel);
    if (kIsWeb) {
      // delay 1s to set extra info
      await Future.delayed(const Duration(seconds: 1));
    }
    await ZegoExpressEngine.instance.setStreamExtraInfo(extraInfo);
  }

  Future<void> stopPublishingStream({ZegoPublishChannel? channel}) async {
    currentUser?.streamID = null;
    currentUser?.isCamerOnNotifier.value = false;
    currentUser?.isMicOnNotifier.value = false;
    await ZegoExpressEngine.instance.stopPublishingStream();
  }

  Future<void> mutePlayStreamAudio(String streamID, bool mute) async {
    ZegoExpressEngine.instance.mutePlayStreamAudio(streamID, mute);
  }

  Future<void> mutePlayStreamVideo(String streamID, bool mute) async {
    ZegoExpressEngine.instance.mutePlayStreamVideo(streamID, mute);
  }

  Future<void> onRoomStreamUpdate(
      String roomID, ZegoUpdateType updateType, List<ZegoStream> streamList, Map<String, dynamic> extendedData) async {
    for (final stream in streamList) {
      if (updateType == ZegoUpdateType.Add) {
        debugPrint('onRoomStreamUpdate: ${stream.streamID}');
        streamMap[stream.streamID] = stream.user.userID;
        var userInfo = getUser(stream.user.userID);
        if (userInfo == null) {
          userInfo = ZegoSDKUser(userID: stream.user.userID, userName: stream.user.userName);
          userInfoList.add(userInfo);
        }
        userInfo.streamID = stream.streamID;

        try {
          final Map<String, dynamic> extraInfoMap = convert.jsonDecode(stream.extraInfo);
          final isMicOn = extraInfoMap['mic'] == 'on';
          final isCameraOn = extraInfoMap['cam'] == 'on';
          userInfo.isCamerOnNotifier.value = isCameraOn;
          userInfo.isMicOnNotifier.value = isMicOn;
        } catch (e) {
          debugPrint('stream.extraInfo: ${stream.extraInfo}.');
        }

        startPlayingStream(stream.streamID);
      } else {
        streamMap[stream.streamID] = '';
        final userInfo = getUser(stream.user.userID);
        userInfo?.streamID = '';
        userInfo?.isCamerOnNotifier.value = false;
        userInfo?.isMicOnNotifier.value = false;
        stopPlayingStream(stream.streamID);
      }
    }
    streamListUpdateStreamCtrl.add(ZegoRoomStreamListUpdateEvent(roomID, updateType, streamList, extendedData));
  }

  Future<void> startPlayingAnotherHostStream(String streamID, ZegoSDKUser anotherHost) async {
    await ZegoExpressEngine.instance.createCanvasView((viewID) async {
      anotherHost.viewID = viewID;
      final canvas = ZegoCanvas(anotherHost.viewID, viewMode: ZegoViewMode.AspectFill);
      await ZegoExpressEngine.instance.startPlayingStream(streamID, canvas: canvas);
    }).then((videoViewWidget) {
      anotherHost.videoViewNotifier.value = videoViewWidget;
    });
  }

  Future<void> startPlayingMixerStream(String streamID) async {
    await ZegoExpressEngine.instance.createCanvasView((viewID) async {
      final canvas = ZegoCanvas(viewID, viewMode: ZegoViewMode.AspectFill);
      await ZegoExpressEngine.instance.startPlayingStream(streamID, canvas: canvas);
    }).then((videoViewWidget) {
      mixerStreamNotifier.value = videoViewWidget;
    });
  }

  Future<void> onCapturedSoundLevelUpdate(double soundLevel) async {}

  Future<void> onRemoteSoundLevelUpdate(Map<String, double> soundLevels) async {}

  Future<void> onPlayerRecvAudioFirstFrame(String streamID) async {
    recvAudioFirstFrameCtrl.add(ZegoRecvAudioFirstFrameEvent(streamID));
  }

  Future<void> onPlayerRecvVideoFirstFrame(String streamID) async {
    recvVideoFirstFrameCtrl.add(ZegoRecvVideoFirstFrameEvent(streamID));
  }

  Future<void> onPlayerRecvSEI(String streamID, Uint8List data) async {
    recvSEICtrl.add(ZegoRecvSEIEvent(streamID, data));
  }

  Future<void> startSoundLevelMonitor({int millisecond = 1000}) async {
    final config = ZegoSoundLevelConfig(millisecond, false);
    ZegoExpressEngine.instance.startSoundLevelMonitor(config: config);
  }

  Future<void> stopSoundLevelMonitor() async {
    ZegoExpressEngine.instance.stopSoundLevelMonitor();
  }

  void onRoomStreamExtraInfoUpdate(String roomID, List<ZegoStream> streamList) {
    for (final user in userInfoList) {
      for (final stream in streamList) {
        if (stream.streamID == user.streamID) {
          try {
            final Map<String, dynamic> extraInfoMap = convert.jsonDecode(stream.extraInfo);
            final isMicOn = extraInfoMap['mic'] == 'on';
            final isCameraOn = extraInfoMap['cam'] == 'on';
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
}
