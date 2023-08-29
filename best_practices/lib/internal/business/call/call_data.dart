import '../../../zego_sdk_manager.dart';

enum ZegoCallUserState {
  inviting,
  accepted,
  rejected,
  cancelled,
  offline,
  received,
}

enum ZegoCallType {
  voice,
  video,
}

class ZegoCallData {
  ZegoCallData({
    required this.inviter,
    required this.invitee,
    required this.callType,
    required this.callID,
    this.state = ZegoCallUserState.inviting,
  });

  final ZegoSDKUser inviter;
  final ZegoSDKUser invitee;
  final ZegoCallType callType;
  final String callID;
  ZegoCallUserState state;
}