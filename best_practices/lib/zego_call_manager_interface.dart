import 'internal/business/call/call_data.dart';
import 'zego_sdk_manager.dart';

abstract class ZegoCallManagerInterface {
  Future<ZIMCallingInvitationSentResult> inviteUserToJoinCall(List<String> targetUserIDs);
  Future<ZIMCallInvitationSentResult> sendVideoCallInvitation(String targetUserID);
  Future<ZIMCallInvitationSentResult> sendVoiceCallInvitation(String targetUserID);
  Future<ZIMCallInvitationSentResult> sendGroupVideoCallInvitation(targetUserIDs);
  Future<ZIMCallInvitationSentResult> sendGroupVoiceCallInvitation(List<String> targetUserIDs);
  Future<ZIMCallQuitSentResult> quitCall();
  Future<ZIMCallEndSentResult> endCall(String requestID);
  Future<ZIMCallRejectionSentResult> rejectCallInvitation(String requestID);
  Future<ZIMCallRejectionSentResult> rejectCallInvitationCauseBusy(
      String requestID, String extendedData, ZegoCallType type);
  Future<ZIMCallAcceptanceSentResult> acceptCallInvitation(String requestID);

  Future<ZIMUserAvatarUrlUpdatedResult> updateUserAvatarUrl(String url);
  Future<ZIMUsersInfoQueriedResult> queryUsersInfo(List<String> userIDList);
  String? getUserAvatar(String userID);
  String getMainStreamID();
}
