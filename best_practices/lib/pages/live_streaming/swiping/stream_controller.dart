import 'package:flutter/cupertino.dart';

import '../../../zego_live_streaming_manager.dart';

class ZegoSwipingStreamController {
  bool _isInit = false;

  ZegoLiveStreamingManager? liveStreamingManager;

  void init({
    int cacheCount = 3,
    required ZegoLiveStreamingManager liveStreamingManager,
  }) {
    if (_isInit) {
      return;
    }

    debugPrint('stream controller, init');

    this.liveStreamingManager = liveStreamingManager;
    _isInit = true;
  }

  void uninit() {
    if (!_isInit) {
      return;
    }

    debugPrint('stream controller, uninit');

    _isInit = false;
    liveStreamingManager = null;
  }

  void playRemoteRoomStream(String roomID, String hostID) {
    final streamID = hostStreamIDFormat(roomID, hostID);
    final streamUser = ZEGOSDKManager().expressService.getRemoteUser(hostID) ?? ZegoSDKUser(userID: hostID, userName: '');

    debugPrint('stream controller, playRoomStream, room id:$roomID, stream id:$streamID, user:$streamUser');

    ZEGOSDKManager().expressService.startPlayingAnotherHostStream(streamID ?? '', streamUser);
  }
}
