import 'package:x_overlay/x_overlay.dart';

import '../../../internal/business/business_define.dart';

final audioRoomOverlayController = XOverlayController();

class AudioRoomOverlayData extends XOverlayData {
  final String roomID;
  final ZegoLiveAudioRoomRole role;

  AudioRoomOverlayData({
    required this.roomID,
    required this.role,
  });
}
