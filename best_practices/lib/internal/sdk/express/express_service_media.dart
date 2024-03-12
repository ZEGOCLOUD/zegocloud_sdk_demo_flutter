part of 'express_service.dart';

extension ExpressServiceMedia on ExpressService {
  void onMediaPlayerFirstFrameEvent(ZegoMediaPlayer mediaPlayer, ZegoMediaPlayerFirstFrameEvent event) {
    onMediaPlayerFirstFrameEventCtrl.add(event);
  }

  void onMediaPlayerStateUpdate(ZegoMediaPlayer mediaPlayer, ZegoMediaPlayerState state, int errorCode) {
    onMediaPlayerStateUpdateCtrl.add(ZegoPlayerStateChangeEvent(state: state, errorCode: errorCode));
  }
}
