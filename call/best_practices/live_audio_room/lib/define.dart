import 'package:flutter/cupertino.dart';

class CustomSignalingType {
  static const int audienceApplyToBecomeCoHost = 10000;
  static const int audienceCancelCoHostApply = 10001;
  static const int hostRefuseAudienceCoHostApply = 10002;
  static const int hostAcceptAudienceCoHostApply = 10003;
}

enum ZegoLiveRole {
  audience,
  host,
  coHost,
}

enum ZegoCustomProtocolState {
  //send new protocol request
  sendNew,

  //send protocol request and cancelled by self
  sendCancel,

  //send protocol request and is accepted by other
  sendIsAccepted,

  //send protocol request and is rejected by other
  sendIsRejected,

  // send protocol request but no response from other
  sendTimeOut,

  //receive new protocol request
  recvNew,

  //receive a protocol request and is cancelled by sender
  recvIsCancelled,

  //receive a protocol request and is accept by self
  recvAccept,

  //receive a protocol request and is rejected by self
  recvRejected,

  //receive protocol request but no reply
  recvTimeOut,
}

enum ZegoReceiverState {
  recv,
  accept,
  reject,
  timeOut,
  offline,
  unknow,
}

class ButtonIcon {
  Widget? icon;
  Color? backgroundColor;

  ButtonIcon({this.icon, this.backgroundColor});
}
