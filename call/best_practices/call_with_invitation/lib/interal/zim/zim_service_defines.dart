import 'package:flutter/services.dart';
import 'package:zego_zim/zego_zim.dart';
export 'package:zego_zim/zego_zim.dart';

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

class ZegoSendInvitationResult {
  const ZegoSendInvitationResult({
    this.error,
    required this.invitationID,
    required this.errorInvitees,
  });

  final PlatformException? error;
  final String invitationID;
  final Map<String, ZegoCallUserState> errorInvitees;

  @override
  String toString() => '{error: $error, '
      'invitationID: $invitationID, '
      'errorInvitees: $errorInvitees}';
}

class ZegoCancelInvitationResult {
  const ZegoCancelInvitationResult({
    this.error,
    required this.errorInvitees,
  });

  final PlatformException? error;
  final List<String> errorInvitees;

  @override
  String toString() => '{error: $error, '
      'errorInvitees: $errorInvitees}';
}

class ZegoResponseInvitationResult {
  const ZegoResponseInvitationResult({
    this.error,
  });

  final PlatformException? error;

  @override
  String toString() => '{error: $error}';
}

class ZegoLoginRoomResult {
  const ZegoLoginRoomResult({
    this.error,
  });

  final PlatformException? error;

  @override
  String toString() => '{error: $error}';
}

class ZegoLeaveRoomResult {
  const ZegoLeaveRoomResult({
    this.error,
  });

  final PlatformException? error;

  @override
  String toString() => '{error: $error}';
}

class IncomingCallInvitationReveivedEvent {
  final String inviter;
  final String extendedData;
  final String callID;

  IncomingCallInvitationReveivedEvent(this.callID, this.inviter, this.extendedData);
}

class OutgoingCallInvitationAcceptedEvent {
  final String invitee;
  final String extendedData;
  final String callID;

  OutgoingCallInvitationAcceptedEvent(this.callID, this.invitee, this.extendedData);
}

class IncomingCallInvitationCanceledEvent {
  final String inviter;
  final String extendedData;
  final String callID;

  IncomingCallInvitationCanceledEvent(this.callID, this.inviter, this.extendedData);
}

class OutgoingCallInvitationRejectedEvent {
  final String invitee;
  final String extendedData;
  final String callID;

  OutgoingCallInvitationRejectedEvent(this.callID, this.invitee, this.extendedData);
}

class IncomingCallInvitationTimeoutEvent {
  final String callID;

  IncomingCallInvitationTimeoutEvent(this.callID);
}

class OutgoingCallInvitationTimeoutEvent {
  final String callID;
  final List<String> invitees;

  OutgoingCallInvitationTimeoutEvent(this.callID, this.invitees);
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
