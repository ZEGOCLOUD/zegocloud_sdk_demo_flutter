part of 'zim_service.dart';

typedef ZIMUserRequestSendConfig = ZIMCallInviteConfig;
typedef ZIMUserRequestAcceptConfig = ZIMCallAcceptConfig;
typedef ZIMUserRequestRejectConfig = ZIMCallRejectConfig;
typedef ZIMUserRequestCancelConfig = ZIMCallCancelConfig;

extension ZIMServiceInvitation on ZIMService {
  Future<ZIMCallInvitationSentResult> sendUserRequest(List<String> userList, {ZIMUserRequestSendConfig? config}) async {
    return ZIM.getInstance()!.callInvite(userList, config ?? ZIMUserRequestSendConfig());
  }

  Future<ZIMCallCancelSentResult> cancelUserRequest(List<String> userList, String requestID,
      {ZIMUserRequestCancelConfig? config}) async {
    return ZIM.getInstance()!.callCancel(userList, requestID, config ?? ZIMCallCancelConfig());
  }

  Future<ZIMCallAcceptanceSentResult> acceptUserRequest(String requestID, {ZIMUserRequestAcceptConfig? config}) async {
    return ZIM.getInstance()!.callAccept(requestID, config ?? ZIMUserRequestAcceptConfig());
  }

  Future<ZIMCallRejectionSentResult> rejectUserRequest(String requestID, {ZIMUserRequestRejectConfig? config}) async {
    return ZIM.getInstance()!.callReject(requestID, config ?? ZIMUserRequestRejectConfig());
  }

  void onUserRequestReceived(ZIM zim, ZIMCallInvitationReceivedInfo info, String invitationID) {
    incomingUserRequestReceivedStreamCtrl.add(IncomingUserRequestReceivedEvent(requestID: invitationID, info: info));
  }

  void onUserRequestCancelled(ZIM zim, ZIMCallInvitationCancelledInfo info, String invitationID) {
    incomingUserRequestCancelledStreamCtrl.add(IncomingUserRequestCancelledEvent(requestID: invitationID, info: info));
  }

  void onUserRequestTimeout(ZIM zim, ZIMCallInvitationTimeoutInfo info, String invitationID) {
    incomingUserRequestTimeoutStreamCtrl.add(IncomingUserRequestTimeoutEvent(info: info, requestID: invitationID));
  }

  void onUserRequestAccepted(ZIM zim, ZIMCallInvitationAcceptedInfo info, String invitationID) {
    outgoingUserRequestAcceptedStreamCtrl.add(OutgoingUserRequestAcceptedEvent(requestID: invitationID, info: info));
  }

  void onUserRequestRejected(ZIM zim, ZIMCallInvitationRejectedInfo info, String invitationID) {
    outgoingUserRequestRejectedStreamCtrl.add(OutgoingUserRequestRejectedEvent(requestID: invitationID, info: info));
  }

  void onUserRequestAnsweredTimeout(ZIM zim, List<String> invitees, String invitationID) {
    outgoingUserRequestTimeoutStreamCtrl
        .add(OutgoingUserRequestTimeoutEvent(requestID: invitationID, invitees: invitees));
  }
}
