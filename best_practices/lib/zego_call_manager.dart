import 'dart:async';
import 'dart:convert';

import 'internal/business/call/call_data.dart';
import 'zego_sdk_manager.dart';

class ZegoCallManager {
  ZegoCallManager._internal();
  factory ZegoCallManager() => instance;
  static final ZegoCallManager instance = ZegoCallManager._internal();

  List<StreamSubscription> subscriptions = [];

  ZegoCallData? callData;

  bool get busy => callData != null;

  void init() {
    final zimService = ZEGOSDKManager().zimService;
    subscriptions.addAll([
      zimService.incomingUserRequestReceivedStreamCtrl.stream
          .listen(onInComingUserRequestReceived),
      zimService.incomingUserRequestCancelledStreamCtrl.stream
          .listen(onInComingUserRequestCancelled),
      zimService.incomingUserRequestTimeoutStreamCtrl.stream
          .listen(onInComingUserRequestTimeout),
      zimService.outgoingUserRequestAcceptedStreamCtrl.stream
          .listen(onOutgoingUserRequestAccepted),
      zimService.outgoingUserRequestRejectedStreamCtrl.stream
          .listen(onOutgoingUserRequestRejected),
    ]);
  }

  void createCallData(String callID, ZegoSDKUser inviter, ZegoSDKUser invitee,
      ZegoCallUserState state, ZegoCallType callType) {
    callData = ZegoCallData(
        inviter: inviter,
        invitee: invitee,
        state: state,
        callType: callType,
        callID: callID);
  }

  void updateCall(String callID, ZegoCallUserState state) {
    if (callID.isNotEmpty && callID == callData?.callID) {
      callData?.state = state;
    } else {
      assert(false,
          'callID is not match, curent:${callData!.callID}, new:$callID');
    }
  }

  void clearCallData() => callData = null;

  //MARK - invitation
  Future<ZIMCallInvitationSentResult> sendVideoCall(String targetUserID) async {
    final extendedData = jsonEncode({
      'type': ZegoCallType.video,
      'inviterName': ZEGOSDKManager().currentUser?.userName ?? '',
    });

    final result = await ZEGOSDKManager().zimService.sendUserRequest(
        [targetUserID],
        config: ZIMCallInviteConfig()..extendedData = extendedData);
    bool inviteFail = false;
    for (final element in result.info.errorInvitees) {
      if (element.userID == targetUserID) {
        inviteFail = true;
        break;
      }
    }
    if (!inviteFail) {
      createCallData(result.callID, inviter, invitee, state, callType)
    }
    return result;

    final ZegoSendInvitationResult result =
        await ZEGOSDKManager.instance.zimService.sendInvitation(
      invitees: [myController.text],
      callType: callType,
      extendedData: extendedData,
    );

    if (result.error == null || result.error?.code == '0') {
      if (result.errorInvitees.containsKey(myController.text)) {
        ZegoCallStateManager.instance.clearCallData();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('user is not online: $result')),
        );
      } else {
        pushToCallWaitingPage();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('send call invitation failed: $result')),
      );
    }
  }

  Future<void> sendVoiceCall(String targetUserID) async {}

  Future<void> cancelCallRequest(String requestID, String userID) async {}

  Future<void> rejectCallRequest(String requestID) async {}

  Future<void> busyRejectCallRequest(
      String requestID, String extendedData, ZegoCallType type) async {}

  Future<void> leaveRoom() async {
    ZEGOSDKManager.instance.logoutRoom();
  }

  String getMainStreamID() {
    return '${ZEGOSDKManager.instance.expressService.currentRoomID}_${ZEGOSDKManager.instance.currentUser?.userID ?? ''}_main';
  }

  //zim listener
  void onInComingUserRequestReceived(IncomingUserRequestReceivedEvent event) {}

  void onInComingUserRequestCancelled(
      IncomingUserRequestCancelledEvent event) {}

  void onInComingUserRequestTimeout(IncomingUserRequestTimeoutEvent event) {}

  void onOutgoingUserRequestTimeout(OutgoingUserRequestTimeoutEvent event) {}

  void onOutgoingUserRequestAccepted(OutgoingUserRequestAcceptedEvent event) {}

  void onOutgoingUserRequestRejected(OutgoingUserRequestRejectedEvent event) {}
}
