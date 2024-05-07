part of 'express_service.dart';

extension ExpressServiceStream on ExpressService {
  ZegoViewMode get streamPlayViewMode => ZegoViewMode.AspectFill;

  Future<void> stopPlayingStream(String streamID) async {
    final userID = streamMap[streamID];
    var userInfo = getUser(userID ?? '');
    userInfo ??= getRemoteUser(userID ?? '');
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
    currentUser!.videoViewNotifier.value = null;
    currentUser!.viewID = -1;
    await ZegoExpressEngine.instance.stopPreview();
  }

  Future<void> updateStreamExtraInfo() async {
    if (kIsWeb && (publisherState.value != ZegoPublisherState.Publishing)) return;
    final extraInfo = jsonEncode({
      'mic': currentUser!.isMicOnNotifier.value ? 'on' : 'off',
      'cam': currentUser!.isCameraOnNotifier.value ? 'on' : 'off',
    });
    await ZegoExpressEngine.instance.setStreamExtraInfo(extraInfo);
  }

  Future<void> startPublishingStream(String streamID, {ZegoPublishChannel channel = ZegoPublishChannel.Main}) async {
    currentUser!.streamID = streamID;

    debugPrint('startPublishingStream:$streamID');
    await updateStreamExtraInfo();
    await ZegoExpressEngine.instance.startPublishingStream(streamID, channel: channel);
  }

  Future<void> stopPublishingStream({ZegoPublishChannel? channel}) async {
    currentUser!.streamID = null;
    currentUser!.isCameraOnNotifier.value = false;
    currentUser!.isMicOnNotifier.value = false;
    await ZegoExpressEngine.instance.stopPublishingStream();
  }

  Future<void> mutePlayStreamAudio(String streamID, bool mute) async {
    ZegoExpressEngine.instance.mutePlayStreamAudio(streamID, mute);
  }

  Future<void> mutePlayStreamVideo(String streamID, bool mute) async {
    ZegoExpressEngine.instance.mutePlayStreamVideo(streamID, mute);
  }

  Future<void> onRoomStreamUpdate(
    String roomID,
    ZegoUpdateType updateType,
    List<ZegoStream> streamList,
    Map<String, dynamic> extendedData,
  ) async {
    debugPrint('onRoomStreamUpdate,'
        'roomID:$roomID, '
        'updateType:$updateType, '
        'streamList:${streamList.map((e) => 'user id:${e.user.userID}, stream id:${e.streamID}, ')}, '
        'extendedData:$extendedData, ');

    for (final stream in streamList) {
      if (updateType == ZegoUpdateType.Add) {
        streamMap[stream.streamID] = stream.user.userID;
        var userInfo = getUser(stream.user.userID);
        if (userInfo == null) {
          /// re-use from remote user object
          userInfo = getRemoteUser(stream.user.userID);

          userInfo ??= ZegoSDKUser(userID: stream.user.userID, userName: stream.user.userName);

          userInfoList.add(userInfo);
        }
        if (userInfo.userName.isEmpty) {
          userInfo.userName = stream.user.userName;
        }
        userInfo.streamID = stream.streamID;

        try {
          final Map<String, dynamic> extraInfoMap = convert.jsonDecode(stream.extraInfo);
          final isMicOn = extraInfoMap['mic'] == 'on';
          final isCameraOn = extraInfoMap['cam'] == 'on';
          userInfo.isCameraOnNotifier.value = isCameraOn;
          userInfo.isMicOnNotifier.value = isMicOn;
        } catch (e) {
          debugPrint('stream.extraInfo: ${stream.extraInfo}.');
        }

        startPlayingStream(stream.streamID);
      } else {
        streamMap[stream.streamID] = '';
        final userInfo = getUser(stream.user.userID);
        userInfo?.streamID = '';
        userInfo?.isCameraOnNotifier.value = false;
        userInfo?.isMicOnNotifier.value = false;
        stopPlayingStream(stream.streamID);
      }
    }
    streamListUpdateStreamCtrl.add(ZegoRoomStreamListUpdateEvent(roomID, updateType, streamList, extendedData));
  }

  Future<void> startPlayingAnotherHostStream(
    String streamID,
    ZegoSDKUser anotherHost,
  ) async {
    anotherHost.isCameraOnNotifier.value = true;
    anotherHost.isMicOnNotifier.value = true;

    if (null == getRemoteUser(anotherHost.userID)) {
      remoteStreamUserInfoListNotifier.value.add(anotherHost);
    }
    remoteStreamUserInfoListNotifier.value = List.from(remoteStreamUserInfoListNotifier.value);

    if (anotherHost.viewID != -1) {
      final canvas = ZegoCanvas(anotherHost.viewID, viewMode: streamPlayViewMode);
      await ZegoExpressEngine.instance.startPlayingStream(streamID, canvas: canvas);
    } else {
      await ZegoExpressEngine.instance.createCanvasView((viewID) async {
        anotherHost.viewID = viewID;
        final canvas = ZegoCanvas(anotherHost.viewID, viewMode: streamPlayViewMode);
        await ZegoExpressEngine.instance.startPlayingStream(streamID, canvas: canvas);
      }).then((videoViewWidget) {
        anotherHost.videoViewNotifier.value = videoViewWidget;
      });
    }
  }

  Future<void> startPlayingMixerStream(String streamID) async {
    await ZegoExpressEngine.instance.createCanvasView((viewID) async {
      final canvas = ZegoCanvas(viewID, viewMode: streamPlayViewMode);
      await ZegoExpressEngine.instance.startPlayingStream(
        streamID,
        canvas: canvas,
      );
    }).then((videoViewWidget) {
      mixerStreamNotifier.value = videoViewWidget;
    });
  }

  Future<void> stopPlayingMixerStream(String streamID) async {
    await ZegoExpressEngine.instance.stopPlayingStream(streamID).then((value) {
      mixerStreamNotifier.value = null;
    });
  }

  Future<void> startSoundLevelMonitor({int millisecond = 1000}) async {
    final config = ZegoSoundLevelConfig(millisecond, false);
    ZegoExpressEngine.instance.startSoundLevelMonitor(config: config);
  }

  Future<void> stopSoundLevelMonitor() async {
    ZegoExpressEngine.instance.stopSoundLevelMonitor();
  }

  void onCapturedSoundLevelUpdate(double soundLevel) {}

  void onRemoteSoundLevelUpdate(Map<String, double> soundLevels) {}

  void onPlayerRecvAudioFirstFrame(String streamID) {
    recvAudioFirstFrameCtrl.add(ZegoRecvAudioFirstFrameEvent(streamID));
  }

  void onPlayerRecvVideoFirstFrame(String streamID) {
    recvVideoFirstFrameCtrl.add(ZegoRecvVideoFirstFrameEvent(streamID));
  }

  void onPlayerRecvSEI(String streamID, Uint8List data) {
    recvSEICtrl.add(ZegoRecvSEIEvent(streamID, data));
  }

  void onRoomStreamExtraInfoUpdate(String roomID, List<ZegoStream> streamList) {
    for (final user in userInfoList) {
      for (final stream in streamList) {
        if (stream.streamID == user.streamID) {
          try {
            final Map<String, dynamic> extraInfoMap = convert.jsonDecode(stream.extraInfo);
            final isMicOn = extraInfoMap['mic'] == 'on';
            final isCameraOn = extraInfoMap['cam'] == 'on';
            user.isCameraOnNotifier.value = isCameraOn;
            user.isMicOnNotifier.value = isMicOn;
          } catch (e) {
            debugPrint('stream.extraInfo: ${stream.extraInfo}.');
          }
        }
      }
    }
    roomStreamExtraInfoStreamCtrl.add(ZegoRoomStreamExtraInfoEvent(roomID, streamList));
  }

  void onPublisherStateUpdate(
      String streamID, ZegoPublisherState state, int errorCode, Map<String, dynamic> extendedData) {
    publisherState.value = state;
    if (kIsWeb && state == ZegoPublisherState.Publishing) {
      updateStreamExtraInfo();
    }
  }
}
