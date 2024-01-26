import '../../../zego_sdk_manager.dart';

extension ExpressServiceMedia on ExpressService {
  // void onMediaPlayerFirstFrameEvent(ZegoMediaPlayer mediaPlayer, ZegoMediaPlayerFirstFrameEvent event) {

  // }

  void onMediaPlayerStateUpdate(ZegoMediaPlayer mediaPlayer, ZegoMediaPlayerState state, int errorCode) {
    onMediaPlayerStateUpdateCtrl.add(ZegoPlayerStateChangeEvent(state: state, errorCode: errorCode));
  }
}
