import 'dart:typed_data';

import 'package:zego_express_engine/zego_express_engine.dart';
import 'package:zego_zim/zego_zim.dart';

export 'package:zego_express_engine/zego_express_engine.dart';
export 'package:zego_zim/zego_zim.dart';

export 'sdk/basic/zego_sdk_user.dart';
export 'sdk/express/express_service.dart';

class ZegoRoomUserListUpdateEvent {
  final String roomID;
  final ZegoUpdateType updateType;
  final List<ZegoUser> userList;

  ZegoRoomUserListUpdateEvent(
    this.roomID,
    this.updateType,
    this.userList,
  );

  @override
  String toString() {
    return 'ZegoRoomUserListUpdateEvent{roomID: $roomID, updateType: ${updateType.name}, userList: ${userList.map((e) => '${e.userID}(${e.userName}),')}}';
  }
}

class ZegoRoomStreamListUpdateEvent {
  final String roomID;
  final ZegoUpdateType updateType;
  final List<ZegoStream> streamList;
  final Map<String, dynamic> extendedData;

  ZegoRoomStreamListUpdateEvent(this.roomID, this.updateType, this.streamList, this.extendedData);

  @override
  String toString() {
    return 'ZegoRoomStreamListUpdateEvent{roomID: $roomID, updateType: ${updateType.name}, streamList: ${streamList.map((e) => '${e.streamID}(${e.extraInfo}),')}';
  }
}

class ZegoRoomStreamExtraInfoEvent {
  final String roomID;
  final List<ZegoStream> streamList;

  ZegoRoomStreamExtraInfoEvent(this.roomID, this.streamList);

  @override
  String toString() {
    return 'ZegoRoomStreamExtraInfoEvent{roomID: $roomID, streamList: ${streamList.map((e) => '${e.streamID}(${e.extraInfo}),')}}';
  }
}

class ZegoRoomStateEvent {
  final String roomID;
  final ZegoRoomStateChangedReason reason;
  final int errorCode;
  final Map<String, dynamic> extendedData;

  ZegoRoomStateEvent(this.roomID, this.reason, this.errorCode, this.extendedData);

  @override
  String toString() {
    return 'ZegoRoomStateEvent{roomID: $roomID, reason: ${reason.name}, errorCode: $errorCode, extendedData: $extendedData}';
  }
}

class ZegoRoomExtraInfoEvent {
  final List<ZegoRoomExtraInfo> extraInfoList;

  ZegoRoomExtraInfoEvent(this.extraInfoList);

  @override
  String toString() {
    return 'ZegoRoomExtraInfoEvent{key: $extraInfoList}';
  }
}

class ZegoRecvAudioFirstFrameEvent {
  final String streamID;

  ZegoRecvAudioFirstFrameEvent(this.streamID);

  @override
  String toString() {
    return 'ZegoRecvAudioFirstFrameEvent{streamID: $streamID}';
  }
}

class ZegoRecvVideoFirstFrameEvent {
  final String streamID;

  ZegoRecvVideoFirstFrameEvent(this.streamID);

  @override
  String toString() {
    return 'ZegoRecvVideoFirstFrameEvent{streamID: $streamID}';
  }
}

class ZegoRecvSEIEvent {
  final String streamID;
  final Uint8List data;

  ZegoRecvSEIEvent(this.streamID, this.data);

  @override
  String toString() {
    return 'ZegoRecvSEIEvent{streamID: $streamID, data: $data}';
  }
}

class ZegoMixerSoundLevelUpdateEvent {
  final Map<int, double> soundLevels;

  ZegoMixerSoundLevelUpdateEvent(this.soundLevels);

  @override
  String toString() {
    return 'ZegoMixerSoundLevelUpdateEvent{soundLevels: $soundLevels}';
  }
}

class ZegoPlayerStateChangeEvent {
  final ZegoMediaPlayerState state;
  final int errorCode;

  ZegoPlayerStateChangeEvent({required this.state, required this.errorCode});
   @override
  String toString() {
    return 'ZegoPlayerStateChangeEvent{state: $state, errorCode:$errorCode}';
  }
}

class ZIMServiceConnectionStateChangedEvent {
  final ZIMConnectionState state;
  final ZIMConnectionEvent event;
  final Map extendedData;

  ZIMServiceConnectionStateChangedEvent(this.state, this.event, this.extendedData);
  @override
  String toString() {
    return 'ZIMServiceConnectionStateChangedEvent{state: ${state.name}, event: ${event.name}, extendedData: $extendedData}';
  }
}

class ZIMServiceRoomStateChangedEvent {
  final String roomID;
  final ZIMRoomState state;
  final ZIMRoomEvent event;
  final Map extendedData;

  ZIMServiceRoomStateChangedEvent(this.roomID, this.state, this.event, this.extendedData);

  @override
  String toString() {
    return 'ZIMServiceRoomStateChangedEvent{roomID: $roomID, state: ${state.name}, event: ${event.name}, extendedData: $extendedData}';
  }
}

class ZIMServiceReceiveRoomCustomSignalingEvent {
  final String signaling;
  final String senderUserID;
  ZIMServiceReceiveRoomCustomSignalingEvent({required this.signaling, required this.senderUserID});

  @override
  String toString() {
    return 'ZIMServiceReceiveRoomCustomSignalingEvent{signaling: $signaling, senderUserID: $senderUserID}';
  }
}

class IncomingUserRequestReceivedEvent {
  final String requestID;
  final ZIMCallInvitationReceivedInfo info;
  IncomingUserRequestReceivedEvent({required this.requestID, required this.info});

  @override
  String toString() {
    return 'IncomingUserRequestReceivedEvent{requestID: $requestID, info: $info}';
  }
}

class IncomingUserRequestCancelledEvent {
  final String requestID;
  final ZIMCallInvitationCancelledInfo info;
  IncomingUserRequestCancelledEvent({required this.requestID, required this.info});

  @override
  String toString() {
    return 'IncomingUserRequestCancelledEvent{requestID: $requestID, info: $info}';
  }
}

class OutgoingUserRequestAcceptedEvent {
  final String requestID;
  final ZIMCallInvitationAcceptedInfo info;
  OutgoingUserRequestAcceptedEvent({required this.requestID, required this.info});

  @override
  String toString() {
    return 'OutgoingUserRequestAcceptedEvent{requestID: $requestID, info: $info}';
  }
}

class OutgoingUserRequestRejectedEvent {
  final String requestID;
  final ZIMCallInvitationRejectedInfo info;
  OutgoingUserRequestRejectedEvent({required this.requestID, required this.info});

  @override
  String toString() {
    return 'OutgoingUserRequestRejectedEvent{requestID: $requestID, info: $info}';
  }
}

class IncomingUserRequestTimeoutEvent {
  final String requestID;
  final ZIMCallInvitationTimeoutInfo info;
  IncomingUserRequestTimeoutEvent({required this.info, required this.requestID});

  @override
  String toString() {
    return 'IncomingUserRequestTimeoutEvent{requestID: $requestID, info.mode: ${info.mode.name}}';
  }
}

class OutgoingUserRequestTimeoutEvent {
  final String requestID;
  final List<String> invitees;
  OutgoingUserRequestTimeoutEvent({required this.requestID, required this.invitees});

  @override
  String toString() {
    return 'OutgoingUserRequestTimeoutEvent{invitationID: $requestID, invitees:$invitees}';
  }
}

class UserRequestStateChangeEvent {
  final String requestID;
  final ZIMCallUserStateChangeInfo info;
  UserRequestStateChangeEvent({required this.requestID, required this.info});

  @override
  String toString() {
    return 'UserRequestStateChangeEvent{invitationID: $requestID, info:$info}';
  }
}

class UserRequestEndEvent {
  final String requestID;
  final ZIMCallInvitationEndedInfo info;
  UserRequestEndEvent({required this.requestID, required this.info});

  @override
  String toString() {
    return 'UserRequestEndEvent{invitationID: $requestID, info:$info}';
  }
}

class UserRequestTimeOutEvent {
  final String requestID;
  final List<String> invitees;
  UserRequestTimeOutEvent({required this.requestID, required this.invitees});

  @override
  String toString() {
    return 'UserRequestTimeOutEvent{invitationID: $requestID, invitees:$invitees}';
  }
}

class ZIMServiceRoomAttributeUpdateEvent {
  final ZIMRoomAttributesUpdateInfo updateInfo;
  ZIMServiceRoomAttributeUpdateEvent({required this.updateInfo});

  @override
  String toString() {
    return 'ZIMServiceRoomAttributeUpdateEvent{updateInfo: $updateInfo}';
  }
}

class ZIMServiceRoomAttributeBatchUpdatedEvent {
  final String roomID;
  final List<ZIMRoomAttributesUpdateInfo> updateInfos;

  ZIMServiceRoomAttributeBatchUpdatedEvent(this.roomID, this.updateInfos);

  @override
  String toString() {
    return 'ZIMServiceRoomAttributeBatchUpdatedEvent{roomID: $roomID, updateInfos: $updateInfos}';
  }
}

class ZegoUserRequest {
  final String? requestID;

  String? roomID;
  String? inviterID;
  String? inviterName;
  List<String> invitee = [];

  ZegoUserRequest(this.requestID);

  @override
  String toString() {
    return 'ZegoUserRequest{requestID: $requestID, roomID: $roomID, inviterID: $inviterID, inviterName: $inviterName, invitee: $invitee}';
  }
}

class SendRoomRequestEvent {
  final String requestID;
  String? extendedData;
  SendRoomRequestEvent({required this.requestID, this.extendedData});

  @override
  String toString() {
    return 'SendRoomRequestEvent{requestID: $requestID, extendedData: $extendedData}';
  }
}

class AcceptIncomingRoomRequestEvent {
  final String requestID;
  String? extendedData;
  AcceptIncomingRoomRequestEvent({required this.requestID, this.extendedData});

  @override
  String toString() {
    return 'AcceptIncomingRoomRequestEvent{requestID: $requestID, extendedData: $extendedData}';
  }
}

class RejectIncomingRoomRequestEvent {
  final String requestID;
  String? extendedData;
  RejectIncomingRoomRequestEvent({required this.requestID, this.extendedData});

  @override
  String toString() {
    return 'RejectIncomingRoomRequestEvent{requestID: $requestID, extendedData:$extendedData}';
  }
}

class CancelRoomRequestEvent {
  final String requestID;
  String? extendedData;
  CancelRoomRequestEvent({required this.requestID, this.extendedData});

  @override
  String toString() {
    return 'CancelRoomRequestEvent{requestID: $requestID, extendedData: $extendedData}';
  }
}

class OnInComingRoomRequestReceivedEvent {
  final String requestID;
  String? extendedData;
  OnInComingRoomRequestReceivedEvent({required this.requestID, this.extendedData});

  @override
  String toString() {
    return 'OnInComingRoomRequestReceivedEvent{requestID: $requestID, extendedData:$extendedData}';
  }
}

class OnOutgoingRoomRequestAcceptedEvent {
  final String requestID;
  String? extendedData;
  OnOutgoingRoomRequestAcceptedEvent({required this.requestID, this.extendedData});

  @override
  String toString() {
    return 'OnOutgoingRoomRequestAcceptedEvent{requestID: $requestID, extendedData:$extendedData}';
  }
}

class OnOutgoingRoomRequestRejectedEvent {
  final String requestID;
  String? extendedData;
  OnOutgoingRoomRequestRejectedEvent({required this.requestID, this.extendedData});

  @override
  String toString() {
    return 'OnOutgoingRoomRequestRejectedEvent{requestID: $requestID, extendedData:$extendedData}';
  }
}

class OnInComingRoomRequestCancelledEvent {
  final String requestID;
  String? extendedData;
  OnInComingRoomRequestCancelledEvent({required this.requestID, this.extendedData});

  @override
  String toString() {
    return 'OnInComingRoomRequestCancelledEvent{requestID: $requestID, extendedData:$extendedData}';
  }
}

class OnRoomCommandReceivedEvent {
  final String senderID;
  final String command;

  OnRoomCommandReceivedEvent(this.senderID, this.command);

  @override
  String toString() {
    return 'OnRoomCommandReceivedEvent{senderID: $senderID command:$command}';
  }
}
