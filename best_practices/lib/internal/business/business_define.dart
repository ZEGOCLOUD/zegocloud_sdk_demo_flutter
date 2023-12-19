import '../../zego_sdk_manager.dart';

class RoomRequestType {
  static const int audienceApplyToBecomeCoHost = 10000;
  static const int audienceCancelCoHostApply = 10001;
  static const int hostRefuseAudienceCoHostApply = 10002;
  static const int hostAcceptAudienceCoHostApply = 10003;
}

class PKProtocolType {
  // start pk
  static const int startPK = 91000;
  // end pk
  static const int endPK = 91001;
  // resume pk
  static const int resume = 91002;
}

class RoomCommandType {
  static const int muteSpeaker = 20000;
  static const int unMuteSpeaker = 20001;
  static const int kickOutRoom = 20002;
}

enum ZegoLiveStreamingRole {
  audience,
  host,
  coHost,
}

enum ZegoLiveAudioRoomRole {
  audience,
  host,
  speaker,
}

enum RoomPKState { isNoPK, isRequestPK, isStartPK }

class SEIType {
  static const int deviceState = 0; // device_state
}

class PKBattleReceivedEvent {
  final String requestID;
  final ZIMCallInvitationReceivedInfo info;
  PKBattleReceivedEvent({required this.requestID, required this.info});

  @override
  String toString() {
    return 'PKBattleReceivedEvent{requestID: $requestID, info: $info}';
  }
}

class PKBattleAcceptedEvent {
  final String userID;
  final String extendedData;
  PKBattleAcceptedEvent({required this.userID, required this.extendedData});

  @override
  String toString() {
    return 'PKBattleAcceptedEvent{userID: $userID, extendedData: $extendedData}';
  }
}

class PKBattleUserJoinEvent {
  final String userID;
  final String extendedData;
  PKBattleUserJoinEvent({required this.userID, required this.extendedData});

  @override
  String toString() {
    return 'PKBattleUserJoinEvent{userID: $userID, extendedData: $extendedData}';
  }
}

class PKBattleTimeoutEvent {
  final String userID;
  final String extendedData;
  PKBattleTimeoutEvent({required this.userID, required this.extendedData});

  @override
  String toString() {
    return 'PKBattleTimeoutEvent{userID: $userID, extendedData: $extendedData}';
  }
}

class PKBattleUserQuitEvent {
  final String userID;
  final String extendedData;
  PKBattleUserQuitEvent({required this.userID, required this.extendedData});

  @override
  String toString() {
    return 'PKBattleUserQuitEvent{userID: $userID, extendedData: $extendedData}';
  }
}

class PKBattleUserUpdateEvent {
  final List<String> userList;
  PKBattleUserUpdateEvent({required this.userList});

  @override
  String toString() {
    return 'PKBattleUserUpdateEvent{userList: $userList}';
  }
}

class PKBattleUserConnectingEvent {
  final String userID;
  final int duration;
  PKBattleUserConnectingEvent({required this.userID, required this.duration});

  @override
  String toString() {
    return 'PKBattleUserConnectingEvent{userID: $userID, duration:$duration}';
  }
}

class PKBattleRejectedEvent {
  final String userID;
  final String extendedData;
  PKBattleRejectedEvent({required this.userID, required this.extendedData});

  @override
  String toString() {
    return 'PKBattleRejectedEvent{userID: $userID, extendedData:$extendedData}';
  }
}

class PKBattleCancelledEvent {
  final String requestID;
  PKBattleCancelledEvent({required this.requestID});

  @override
  String toString() {
    return 'PKBattleCancelledEvent{requestID: $requestID}';
  }
}

class IncomingPKRequestTimeoutEvent {
  final String requestID;
  IncomingPKRequestTimeoutEvent({required this.requestID});

  @override
  String toString() {
    return 'IncomingPKRequestTimeoutEvent{requestID: $requestID}';
  }
}

class OutgoingPKRequestTimeoutEvent {
  final String requestID;
  OutgoingPKRequestTimeoutEvent({required this.requestID});

  @override
  String toString() {
    return 'OutgoingPKRequestTimeoutEvent{requestID: $requestID}';
  }
}
