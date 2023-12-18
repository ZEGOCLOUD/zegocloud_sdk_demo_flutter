import 'package:flutter/material.dart';

import '../../sdk/express/express_service.dart';

class ZegoLiveAudioRoomSeat {
  int seatIndex = 0;
  ValueNotifier<ZegoSDKUser?> lastUser = ValueNotifier(null);
  ValueNotifier<ZegoSDKUser?> currentUser = ValueNotifier(null);

  ZegoLiveAudioRoomSeat(this.seatIndex);
}
