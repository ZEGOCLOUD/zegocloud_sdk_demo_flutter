import 'call_user_info.dart';

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

const VOICE_Call = 10001;
const VIDEO_Call = 10000;

class ZegoCallData {
  late CallUserInfo inviter;
  late int callType;
  late String callID;
  List<CallUserInfo> callUserList = [];
  bool get isGroupCall => callUserList.length > 2;
}
