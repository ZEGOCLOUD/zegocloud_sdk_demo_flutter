import '../../../zego_sdk_manager.dart';

class PKInviteSentResult {
  String requestID = '';
  List<ZIMErrorUserInfo> errorUserList = [];
  PKInviteSentResult({required this.requestID, required this.errorUserList});
}
