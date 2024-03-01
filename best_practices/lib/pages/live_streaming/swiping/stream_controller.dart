import 'package:flutter/cupertino.dart';

import '../../../zego_live_streaming_manager.dart';
import '../../../zego_sdk_manager.dart';

class ZegoSwipingStreamController {
  bool _isInit = false;
  List<String> _playingRemoteStreamings = [];

  void init({int cacheCount = 3}) {
    if (_isInit) {
      return;
    }

    debugPrint('stream controller, init');

    _isInit = true;
  }

  void uninit() {
    if (!_isInit) {
      return;
    }

    debugPrint('stream controller, uninit');

    _isInit = false;
  }

  void clear() {
    for (var streamID in _playingRemoteStreamings) {
      ZEGOSDKManager().expressService.stopPlayingStream(streamID);
    }
    _playingRemoteStreamings.clear();
  }

  void playRemoteRoomStream(String roomID, String hostID) {
    final streamID = ZegoLiveStreamingManager().hostStreamIDFormat(roomID, hostID);
    final streamUser =
        ZEGOSDKManager().expressService.getRemoteUser(hostID) ?? ZegoSDKUser(userID: hostID, userName: '');

    debugPrint('stream controller, playRoomStream, room id:$roomID, stream id:$streamID, user:$streamUser');

    if (!_playingRemoteStreamings.contains(streamID)) {
      _playingRemoteStreamings.add(streamID);
    }

    if (_playingRemoteStreamings.length > 3) {
      debugPrint('stream controller, stopPlayingStream,stream id:$streamID');
      ZEGOSDKManager().expressService.stopPlayingStream(_playingRemoteStreamings.removeAt(0));
    }

    ZEGOSDKManager().expressService.startPlayingAnotherHostStream(streamID, streamUser);
  }
}
