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

enum ZegoLiveRole {
  audience,
  host,
  coHost,
}

enum RoomPKState { isNoPK, isRequestPK, isStartPK }

class SEIType {
  static const int deviceState = 0; // device_state
}

class IncomingPKRequestEvent {
  final String requestID;
  IncomingPKRequestEvent({required this.requestID});

  @override
  String toString() {
    return 'IncomingPKRequestEvent{requestID: $requestID}';
  }
}

class OutgoingPKRequestAcceptEvent {
  final String requestID;
  OutgoingPKRequestAcceptEvent({required this.requestID});

  @override
  String toString() {
    return 'OutgoingPKRequestAcceptEvent{requestID: $requestID}';
  }
}

class OutgoingPKRequestRejectedEvent {
  final String requestID;
  OutgoingPKRequestRejectedEvent({required this.requestID});

  @override
  String toString() {
    return 'OutgoingPKRequestRejectedEvent{requestID: $requestID}';
  }
}

class IncomingPKRequestCancelledEvent {
  final String requestID;
  IncomingPKRequestCancelledEvent({required this.requestID});

  @override
  String toString() {
    return 'OutgoingPKRequestRejectedEvent{requestID: $requestID}';
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

