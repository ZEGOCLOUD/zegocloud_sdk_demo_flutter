import 'zego_live_streaming_manager.dart';

extension ZegoLiveStreamingManagerExtension on ZegoLiveStreamingManager {
  // express listener
  void onStreamListUpdate(ZegoRoomStreamListUpdateEvent event) {
    for (final stream in event.streamList) {
      if (event.updateType == ZegoUpdateType.Add) {
        if (isHostStreamID(stream.streamID)) {
          isLivingNotifier.value = true;
        }
      } else {
        if (isHostStreamID(stream.streamID)) {
          isLivingNotifier.value = false;
          endCoHost();
        }
      }
    }
    cohostService!.onReceiveStreamUpdate(event);
    pkService!.onReceiveStreamUpdate(event);
  }

  void onRoomUserUpdate(ZegoRoomUserListUpdateEvent event) {
    cohostService!.onRoomUserListUpdate(event);
    pkService!.onRoomUserUpdate(event);
  }

  void onPlayerRecvAudioFirstFrame(ZegoRecvAudioFirstFrameEvent event) {
    pkService!.onReceiveAudioFirstFrame(event);
  }

  void onPlayerRecvVideoFirstFrame(ZegoRecvVideoFirstFrameEvent event) {
    pkService!.onReceiveVideoFirstFrame(event);
  }

  void onPlayerSyncRecvSEI(ZegoRecvSEIEvent event) {
    pkService!.onReceiveSEIEvent(event);
  }
}
