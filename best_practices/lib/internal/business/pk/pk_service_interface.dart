import '../../../zego_sdk_manager.dart';
import 'pk_define.dart';

abstract class PKServiceInterface {
  void addListener();
  void uninit();
  void removeUserFromPKBattle(String userID);
  void stopPKBattle();
  Future<PKInviteSentResult> invitePKbattle(List<String> targetUserIDList, bool autoAccept);
  Future<void> acceptPKBattle(String requestID);
  Future<ZIMCallQuitSentResult> quitPKBattle(String requestID);
  Future<ZIMCallEndSentResult> endPKBattle(String requestID);
  Future<void> cancelPKBattle(String requestID, String userID);
  Future<void> rejectPKBattle(String requestID);
  Future<ZegoMixerStartResult> mutePKUser(List<int> muteIndexList, bool mute);
  bool isPKUserMuted(String userID);
  bool isPKUser(String userID);
}
