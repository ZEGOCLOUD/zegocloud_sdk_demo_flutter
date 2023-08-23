import 'package:flutter/material.dart';
import 'package:live_audio_room_demo/internal/zego_express_service.dart';

class ZegoLiveAudioRoomSeat {
  int seatIndex = 0;
  int rowIndex = 0;
  int columnIndex = 0;
  ValueNotifier<ZegoUserInfo?> lastUser = ValueNotifier(null);
  ValueNotifier<ZegoUserInfo?> currentUser = ValueNotifier(null);

  ZegoLiveAudioRoomSeat(this.seatIndex, this.rowIndex, this.columnIndex);
}
