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

  final incomingCallInvitationReceivedStreamCtrl = StreamController<IncomingCallInvitationReceivedEvent>.broadcast();

  void addListener() {
    final zimService = ZEGOSDKManager().zimService;
    subscriptions.addAll([
      zimService.incomingUserRequestReceivedStreamCtrl.stream.listen(onInComingUserRequestReceived),
      zimService.incomingUserRequestCancelledStreamCtrl.stream.listen(onInComingUserRequestCancelled),
      zimService.incomingUserRequestTimeoutStreamCtrl.stream.listen(onInComingUserRequestTimeout),
      zimService.outgoingUserRequestAcceptedStreamCtrl.stream.listen(onOutgoingUserRequestAccepted),
      zimService.outgoingUserRequestRejectedStreamCtrl.stream.listen(onOutgoingUserRequestRejected),
    ]);
  }

  void createCallData(
      String callID, ZegoSDKUser inviter, ZegoSDKUser invitee, ZegoCallUserState state, ZegoCallType callType) {
    callData = ZegoCallData(inviter: inviter, invitee: invitee, state: state, callType: callType, callID: callID);
  }

  void updateCall(String callID, ZegoCallUserState state) {
    if (callID.isNotEmpty && callID == callData?.callID) {
      callData?.state = state;
    } else {
      assert(false, 'callID is not match, curent:${callData!.callID}, new:$callID');
    }
  }

  void clearCallData() => callData = null;

  //MARK - invitation
  Future<ZIMCallInvitationSentResult> sendVideoCall(String targetUserID) async {
    final result = await sendCall(targetUserID, ZegoCallType.video);
    return result;
  }

  Future<ZIMCallInvitationSentResult> sendVoiceCall(String targetUserID) async {
    final result = await sendCall(targetUserID, ZegoCallType.voice);
    return result;
  }

  Future<ZIMCallInvitationSentResult> sendCall(String targetUserID, ZegoCallType callType) async {
    final extendedData = jsonEncode({
      'type': callType.index,
      'inviterName': ZEGOSDKManager().currentUser?.userName ?? '',
    });

    final result = await ZEGOSDKManager.instance.zimService
        .sendUserRequest([targetUserID], config: ZIMCallInviteConfig()..extendedData = extendedData);
    var inviteFail = false;
    for (final element in result.info.errorInvitees) {
      if (element.userID == targetUserID) {
        inviteFail = true;
        break;
      }
    }
    if (!inviteFail) {
      final invitee = ZegoSDKUser(userID: targetUserID, userName: targetUserID);
      createCallData(result.callID, ZEGOSDKManager().currentUser!, invitee, ZegoCallUserState.inviting, callType);
    }
    return result;
  }

  Future<ZIMCallCancelSentResult> cancelCallRequest(String requestID, String userID) async {
    final extendedData = jsonEncode({
      'type': callData?.callType.index ?? ZegoCallType.video.index,
    });
    final config = ZIMCallCancelConfig()..extendedData = extendedData;
    final result = await ZEGOSDKManager().zimService.cancelUserRequest([userID], requestID, config: config);
    return result;
  }

  Future<ZIMCallAcceptanceSentResult> acceptCallRequest(String requestID) async {
    updateCall(requestID, ZegoCallUserState.accepted);
    final extendedData = jsonEncode({
      'type': callData?.callType.index ?? ZegoCallType.video.index,
    });
    final config = ZIMCallAcceptConfig()..extendedData = extendedData;
    final result = ZEGOSDKManager().zimService.acceptUserRequest(requestID, config: config);
    return result;
  }

  Future<ZIMCallRejectionSentResult> rejectCallRequest(String requestID) async {
    final extendedData = jsonEncode({
      'type': callData?.callType.index ?? ZegoCallType.video.index,
      'inviterName': ZEGOSDKManager().currentUser?.userName ?? '',
    });
    if (requestID == callData?.callID) {
      clearCallData();
    }
    final config = ZIMCallRejectConfig()..extendedData = extendedData;
    final result = await ZEGOSDKManager().zimService.rejectUserRequest(requestID, config: config);
    return result;
  }

  Future<ZIMCallRejectionSentResult> busyRejectCallRequest(
      String requestID, String extendedData, ZegoCallType type) async {
    final config = ZIMCallRejectConfig()..extendedData = extendedData;
    final result = ZEGOSDKManager().zimService.rejectUserRequest(requestID, config: config);
    return result;
  }

  Future<void> leaveRoom() async {
    ZEGOSDKManager.instance.logoutRoom();
  }

  String getMainStreamID() {
    return '${ZEGOSDKManager.instance.expressService.currentRoomID}_${ZEGOSDKManager.instance.currentUser?.userID ?? ''}_main';
  }

  bool isCallBusiness(dynamic type) {
    if (type is int) {
      if (type == ZegoCallType.voice.index || type == ZegoCallType.video.index) {
        return true;
      } else {
        return false;
      }
    } else {
      return false;
    }
  }

  //zim listener
  void onInComingUserRequestReceived(IncomingUserRequestReceivedEvent event) {
    final extendedData = jsonDecode(event.info.extendedData);
    if (extendedData is! Map) {
      return;
    }
    final type = extendedData['type'];
    if (!isCallBusiness(type)) {
      return;
    }
    final inRoom = ZEGOSDKManager().expressService.currentRoomID.isNotEmpty;
    final info = ZegoCallInvitationReceivedInfo()
      ..inviter = event.info.inviter
      ..caller = event.info.caller
      ..extendedData = event.info.extendedData;
    if (inRoom || (callData != null && callData?.callID != event.requestID)) {
      incomingCallInvitationReceivedStreamCtrl
          .add(IncomingCallInvitationReceivedEvent(callID: event.requestID, info: info));
      return;
    }
    final userName = extendedData['user_name'].toString();
    final inviterUser = ZegoSDKUser(userID: event.info.inviter, userName: userName);
    final callType = type == 1 ? ZegoCallType.video : ZegoCallType.voice;
    createCallData(event.requestID, inviterUser, ZEGOSDKManager().currentUser!, ZegoCallUserState.received, callType);

    incomingCallInvitationReceivedStreamCtrl
        .add(IncomingCallInvitationReceivedEvent(callID: event.requestID, info: info));
  }

  void onInComingUserRequestCancelled(IncomingUserRequestCancelledEvent event) {
    if (event.requestID == callData?.callID) {
      clearCallData();
    }
  }

  void onInComingUserRequestTimeout(IncomingUserRequestTimeoutEvent event) {
    if (event.requestID == callData?.callID) {
      clearCallData();
    }
  }

  void onOutgoingUserRequestTimeout(OutgoingUserRequestTimeoutEvent event) {
    if (event.requestID == callData?.callID) {
      clearCallData();
    }
  }

  void onOutgoingUserRequestAccepted(OutgoingUserRequestAcceptedEvent event) {
    if (event.requestID == callData?.callID) {
      updateCall(event.requestID, ZegoCallUserState.accepted);
    }
  }

  void onOutgoingUserRequestRejected(OutgoingUserRequestRejectedEvent event) {
    if (event.requestID == callData?.callID) {
      updateCall(event.requestID, ZegoCallUserState.rejected);
      clearCallData();
    }
  }
}


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
