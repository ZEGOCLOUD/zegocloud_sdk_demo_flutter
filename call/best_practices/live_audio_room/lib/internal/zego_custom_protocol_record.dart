import 'package:live_audio_room_demo/define.dart';

class CustomProtocolRecord {
  List<String> receivers = [];
  String? sender;

  String? extendedData;
  Map<String, ZegoReceiverState> receiverStateMap = {};
  ZegoCustomProtocolState? lastState;
  ZegoCustomProtocolState? state;

  void setState(ZegoCustomProtocolState newState) {
    lastState = state;
    state = newState;
  }

  bool isFinished() {
    return state != ZegoCustomProtocolState.sendNew && state != ZegoCustomProtocolState.recvNew;
  }
}
