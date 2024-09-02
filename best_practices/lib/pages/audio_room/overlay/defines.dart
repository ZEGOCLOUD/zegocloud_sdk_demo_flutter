import 'package:zego_overlay/zego_overlay.dart';

import '../../../internal/business/business_define.dart';

final audioRoomOverlayController = ZegoOverlayController();

class AudioRoomOverlayData extends ZegoOverlayData {
  final String roomID;
  final ZegoLiveAudioRoomRole role;

  AudioRoomOverlayData({
    required this.roomID,
    required this.role,
  });
}
