import 'dart:convert' as convert;
import 'dart:math';

import '../zim_service.dart';
import 'zim_define.dart';

class RoomRequest {
  String? requestID;
  late RoomRequestAction actionType;
  late String senderID;
  late String receiverID;
  String extendedData = '';

  RoomRequest(this.actionType, this.senderID, this.receiverID);

  String toJsonString() {
    final jsonMap = <String, dynamic>{};
    jsonMap['action_type'] = actionType.index;
    jsonMap['sender_id'] = senderID;
    jsonMap['receiver_id'] = receiverID;
    requestID ??= generateProtocolID();
    jsonMap['request_id'] = requestID;
    jsonMap['extended_data'] = extendedData;
    return convert.jsonEncode(jsonMap);
  }

  String generateProtocolID() {
    final localUserID = ZIMService().currentZimUserInfo?.userID ?? '';
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final randomStr = (Random().nextInt(900000) + 100000).toString();
    return '${localUserID}_${timestamp}_$randomStr';
  }
}
