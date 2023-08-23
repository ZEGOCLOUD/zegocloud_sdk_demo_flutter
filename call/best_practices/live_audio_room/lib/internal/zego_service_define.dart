import 'package:live_audio_room_demo/internal/zego_express_service.dart';
import 'package:zego_express_engine/zego_express_engine.dart';
import 'package:zego_zim/zego_zim.dart';

export 'zego_express_service.dart';
export 'zego_user_info.dart';

export 'package:zego_express_engine/zego_express_engine.dart';
export 'package:zego_zim/zego_zim.dart';

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
  ZIMServiceReceiveRoomCustomSignalingEvent({required this.signaling});

  @override
  String toString() {
    return 'ZIMServiceReceiveRoomCustomSignalingEvent{signaling: $signaling}';
  }
}

class ZIMServiceRoomAttributeUpdateEvent {
  final String roomID;
  final ZIMRoomAttributesUpdateInfo updateInfo;

  ZIMServiceRoomAttributeUpdateEvent(this.roomID, this.updateInfo);

  @override
  String toString() {
    return 'ZIMServiceRoomAttributeUpdateEvent{roomID: $roomID, updateInfo: $updateInfo}';
  }
}

class ZIMServiceRoomAttributeBatchUpdatedEvent {
  final String roomID;
  final List<ZIMRoomAttributesUpdateInfo> updateInfo;

  ZIMServiceRoomAttributeBatchUpdatedEvent(this.roomID, this.updateInfo);

  @override
  String toString() {
    return 'ZIMServiceRoomAttributeBatchUpdatedEvent{roomID: $roomID, updateInfo: $updateInfo}';
  }
}

class CustomProtocolIncomingRequestReceivedEvent {
  final String invitationID;
  final String userID;
  final String extendedData;

  CustomProtocolIncomingRequestReceivedEvent(this.invitationID, this.userID, this.extendedData);
}

class CustomProtocolInComingRequestCancelledEvent {
  final String invitationID;
  final String senderID;
  final String extendedData;

  CustomProtocolInComingRequestCancelledEvent(this.invitationID, this.senderID, this.extendedData);
}

class CustomProtocolOutgoingRequestRejectedEvent {
  final String invitationID;
  final String receiver;
  final String extendedData;

  CustomProtocolOutgoingRequestRejectedEvent(this.invitationID, this.receiver, this.extendedData);
}

class CustomProtocolOutgoingRequestAcceptedEvent {
  final String invitationID;
  final String userID;
  final String extendedData;

  CustomProtocolOutgoingRequestAcceptedEvent(this.invitationID, this.userID, this.extendedData);
}
