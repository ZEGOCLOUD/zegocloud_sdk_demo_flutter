
class IncomingCallInvitationReceivedEvent {
  final String callID;
  final ZegoCallInvitationReceivedInfo info;
  IncomingCallInvitationReceivedEvent({required this.callID, required this.info});

  @override
  String toString() {
    return 'IncomingCallInvitationReceivedEvent{callID: $callID, info: $info}';
  }
}

class ZegoCallInvitationReceivedInfo {

  /// Description: Inviter ID.
  String inviter = '';

  String caller = '';

  /// Description: Extended field, through which the inviter can carry information to the invitee.
  String extendedData = '';

  ZegoCallInvitationReceivedInfo();
}