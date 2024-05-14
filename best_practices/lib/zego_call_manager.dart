import 'dart:async';

import 'zego_call_manager_extension.dart';
import 'zego_call_manager_interface.dart';
import 'zego_sdk_manager.dart';

export 'zego_call_manager_extension.dart';
export 'zego_call_manager_interface.dart';
export 'zego_sdk_manager.dart';

class ZegoCallManager implements ZegoCallManagerInterface {
  ZegoCallManager._internal();
  factory ZegoCallManager() => instance;
  static final ZegoCallManager instance = ZegoCallManager._internal();

  List<StreamSubscription> subscriptions = [];

  ZegoCallData? currentCallData;

  bool isCallStart = false;

  bool get busy => currentCallData != null;

  ZegoSDKUser? get localUser => ZEGOSDKManager().currentUser;

  final incomingCallInvitationReceivedStreamCtrl = StreamController<IncomingCallInvitationReceivedEvent>.broadcast();
  final incomingCallInvitationTimeoutStreamCtrl = StreamController<IncomingUserRequestTimeoutEvent>.broadcast();
  final outgoingCallInvitationTimeoutStreamCtrl = StreamController<OutgoingCallTimeoutEvent>.broadcast();
  final outgoingCallInvitationRejectedStreamCtrl = StreamController<OutgoingCallInvitationRejectedEvent>.broadcast();
  final onOutgoingCallInvitationAccepted = StreamController<OnOutgoingCallAcceptedEvent>.broadcast();
  final onCallUserQuitStreamCtrl = StreamController<CallUserQuitEvent>.broadcast();
  final onCallUserInfoUpdateStreamCtrl = StreamController<OnCallUserInfoUpdateEvent>.broadcast();
  final onCallUserUpdateStreamCtrl = StreamController<OnCallUserUpdateEvent>.broadcast();

  final onCallStartStreamCtrl = StreamController.broadcast();
  final onCallEndStreamCtrl = StreamController.broadcast();

  void addListener() {
    final zimService = ZEGOSDKManager().zimService;
    final expressService = ZEGOSDKManager().expressService;
    subscriptions.addAll([
      expressService.roomUserListUpdateStreamCtrl.stream.listen(onRoomUserListUpdate),
      zimService.incomingUserRequestReceivedStreamCtrl.stream.listen(onInComingUserRequestReceived),
      zimService.userRequestStateChangeStreamCtrl.stream.listen(onUserRequestStateChanged),
      zimService.userRequestEndStreamCtrl.stream.listen(onUserRequestEnded),
      zimService.incomingUserRequestTimeoutStreamCtrl.stream.listen(onInComingUserRequestTimeout)
    ]);
  }

  void clearCallData() {
    isCallStart = false;
    currentCallData = null;
  }

  CallExtendedData getCallExtendata(ZegoCallType type) {
    final callType = type == ZegoCallType.video ? VIDEO_Call : VOICE_Call;
    final extendedData = CallExtendedData()..type = callType;
    return extendedData;
  }

  Future<ZIMCallAcceptanceSentResult> acceptUserRequest(String requestID, String extendedData) async {
    final config = ZIMCallAcceptConfig()..extendedData = extendedData;
    final result = await ZEGOSDKManager().zimService.acceptUserRequest(requestID, config: config);
    return result;
  }

  Future<ZIMCallEndSentResult> endUserRequest(String requestID, String extendedData) async {
    final config = ZIMCallEndConfig()..extendedData = extendedData;
    final result = await ZEGOSDKManager().zimService.endUserRequest(requestID, config);
    return result;
  }

  Future<ZIMCallRejectionSentResult> refuseUserRequest(String requestID, String extendedData) async {
    final config = ZIMCallRejectConfig()..extendedData = extendedData;
    final result = await ZEGOSDKManager().zimService.rejectUserRequest(requestID, config: config);
    return result;
  }

  Future<ZIMCallQuitSentResult> quitUserRequest(String requestID, String extendedData) async {
    final config = ZIMCallQuitConfig()..extendedData = extendedData;
    final result = await ZEGOSDKManager().zimService.quitUserRequest(requestID, config);
    return result;
  }

  Future<ZIMCallingInvitationSentResult> addUserToRequest(List<String> userList, String requestID) async {
    await ZEGOSDKManager().zimService.queryUsersInfo(userList);
    final config = ZIMCallingInviteConfig();
    final result = await ZEGOSDKManager().zimService.addUserToRequest(userList, requestID, config);
    return result;
  }

  Future<ZIMCallInvitationSentResult> sendUserRequest(
      List<String> userList, String extendedData, ZegoCallType type) async {
    await ZEGOSDKManager().zimService.queryUsersInfo(userList);
    currentCallData = ZegoCallData();
    final config = ZIMCallInviteConfig()
      ..mode = ZIMCallInvitationMode.advanced
      ..extendedData = extendedData
      ..timeout = 60;
    final result = await ZEGOSDKManager().zimService.sendUserRequest(userList, config: config);
    final errorUser = result.info.errorUserList.map((e) => e.userID).toList();
    final sucessUsers = userList.where((element) => !errorUser.contains(element));
    if (sucessUsers.isNotEmpty) {
      currentCallData!
        ..callID = result.callID
        ..inviter = CallUserInfo(userID: localUser?.userID ?? '')
        ..callType = type == ZegoCallType.video ? VIDEO_Call : VOICE_Call
        ..callUserList = [];
    } else {
      clearCallData();
    }
    return result;
  }

  //MARK - invitation
  @override
  Future<ZIMCallAcceptanceSentResult> acceptCallInvitation(String requestID) async {
    final extendedData =
        getCallExtendata(currentCallData?.callType == VIDEO_Call ? ZegoCallType.video : ZegoCallType.voice);
    final result = await acceptUserRequest(requestID, extendedData.toJsonString());
    return result;
  }

  @override
  Future<ZIMCallEndSentResult> endCall(String requestID) async {
    final extendedData =
        getCallExtendata(currentCallData?.callType == VIDEO_Call ? ZegoCallType.video : ZegoCallType.voice);
    final result = await endUserRequest(requestID, extendedData.toJsonString());
    leaveRoom();
    clearCallData();
    return result;
  }

  @override
  String? getUserAvatar(String userID) {
    return ZEGOSDKManager().zimService.getUserAvatar(userID);
  }

  @override
  Future<ZIMCallingInvitationSentResult> inviteUserToJoinCall(List<String> targetUserIDs) async {
    final result = await addUserToRequest(targetUserIDs, currentCallData?.callID ?? '');
    return result;
  }

  @override
  Future<ZIMUsersInfoQueriedResult> queryUsersInfo(List<String> userIDList) {
    return ZEGOSDKManager().zimService.queryUsersInfo(userIDList);
  }

  @override
  Future<void> quitCall() async {
    if (currentCallData != null) {
      final extendedData =
          getCallExtendata(currentCallData?.callType == VIDEO_Call ? ZegoCallType.video : ZegoCallType.voice);
      await quitUserRequest(currentCallData!.callID, extendedData.toJsonString());
      stopCall();
    }
  }

  @override
  Future<void> rejectCallInvitation(String requestID) async {
    if (currentCallData != null && requestID == currentCallData!.callID) {
      final extendedData =
          getCallExtendata(currentCallData?.callType == VIDEO_Call ? ZegoCallType.video : ZegoCallType.voice);
      await refuseUserRequest(requestID, extendedData.toJsonString());
      clearCallData();
    }
  }

  @override
  Future<void> rejectCallInvitationCauseBusy(String requestID, String extendedData, ZegoCallType type) async {
    await refuseUserRequest(requestID, extendedData);
  }

  @override
  Future<ZIMCallInvitationSentResult> sendGroupVideoCallInvitation(targetUserIDs) async {
    const callType = ZegoCallType.video;
    final extendedData = getCallExtendata(callType);
    final result = await sendUserRequest(targetUserIDs, extendedData.toJsonString(), callType);
    return result;
  }

  @override
  Future<ZIMCallInvitationSentResult> sendGroupVoiceCallInvitation(List<String> targetUserIDs) async {
    const callType = ZegoCallType.voice;
    final extendedData = getCallExtendata(callType);
    final result = await sendUserRequest(targetUserIDs, extendedData.toJsonString(), callType);
    return result;
  }

  @override
  Future<ZIMCallInvitationSentResult> sendVideoCallInvitation(String targetUserID) async {
    const callType = ZegoCallType.video;
    final extendedData = getCallExtendata(callType);
    final result = await sendUserRequest([targetUserID], extendedData.toJsonString(), callType);
    return result;
  }

  @override
  Future<ZIMCallInvitationSentResult> sendVoiceCallInvitation(String targetUserID) async {
    const callType = ZegoCallType.voice;
    final extendedData = getCallExtendata(callType);
    final result = await sendUserRequest([targetUserID], extendedData.toJsonString(), callType);
    return result;
  }

  @override
  Future<ZIMUserAvatarUrlUpdatedResult> updateUserAvatarUrl(String url) async {
    return ZEGOSDKManager().zimService.updateUserAvatarUrl(url);
  }

  Future<void> leaveRoom() async {
    ZEGOSDKManager().logoutRoom();
  }

  @override
  String getMainStreamID() {
    return '${ZEGOSDKManager().expressService.currentRoomID}_${ZEGOSDKManager().currentUser!.userID}_main';
  }

  bool isCallBusiness(dynamic type) {
    if (type is int) {
      if (type == VOICE_Call || type == VIDEO_Call) {
        return true;
      } else {
        return false;
      }
    } else {
      return false;
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

class OutgoingCallInvitationRejectedEvent {
  final String userID;
  final String extendedData;
  OutgoingCallInvitationRejectedEvent({required this.userID, required this.extendedData});

  @override
  String toString() {
    return 'OutgoingCallInvitationRejectedEvent{userID: $userID, extendedData: $extendedData}';
  }
}

class CallUserQuitEvent {
  final String userID;
  final String extendedData;
  CallUserQuitEvent({required this.userID, required this.extendedData});

  @override
  String toString() {
    return 'CallUserQuitEvent{userID: $userID, extendedData: $extendedData}';
  }
}

class OutgoingCallTimeoutEvent {
  final String userID;
  final String extendedData;
  OutgoingCallTimeoutEvent({required this.userID, required this.extendedData});

  @override
  String toString() {
    return 'OutgoingCallTimeoutEvent{userID: $userID, extendedData: $extendedData}';
  }
}

class OnOutgoingCallAcceptedEvent {
  final String userID;
  final String extendedData;
  OnOutgoingCallAcceptedEvent({required this.userID, required this.extendedData});

  @override
  String toString() {
    return 'OnOutgoingCallAcceptedEvent{userID: $userID, extendedData: $extendedData}';
  }
}

class OnCallUserInfoUpdateEvent {
  final List<String> userList;
  OnCallUserInfoUpdateEvent({required this.userList});

  @override
  String toString() {
    return 'OnCallUserInfoUpdateEvent{userList: $userList}';
  }
}

class OnCallUserUpdateEvent {
  final String userID;
  final String extendedData;
  OnCallUserUpdateEvent({required this.userID, required this.extendedData});

  @override
  String toString() {
    return 'OnCallUserUpdateEvent{userID: $userID, extendedData: $extendedData}';
  }
}

class ZegoCallInvitationReceivedInfo {
  /// Description: Inviter ID.
  String inviter = '';

  List<String> inviteeList = [];

  /// Description: Extended field, through which the inviter can carry information to the invitee.
  String extendedData = '';

  ZegoCallInvitationReceivedInfo();
}
