import 'dart:convert' as convert;
import 'dart:math';

import 'package:live_audio_room_demo/zego_sdk_manager.dart';

class ZegoLiveAudioRoomProtocol {
  static const int applyToBecomeSpeaker = 20000;
  static const int cancelSpeakerApply = 20001;
  static const int hostRefuseSpeakerApply = 20002;
  static const int hostAcceptSpeakerApply = 20003;

  static const int hostInviteToBecomeSpeaker = 20100;
  static const int hostCancelSpeakerInvitation = 20101;
  static const int refuseSpeakerInvitation = 20102;
  static const int acceptSpeakerInvitation = 20103;

  int type = 0;
  String? senderID;
  String? receiverID;
  String? protocolID;

  static ZegoLiveAudioRoomProtocol parse(String string) {
    ZegoLiveAudioRoomProtocol roomProtocol = ZegoLiveAudioRoomProtocol();

    Map<String, dynamic> jsonMap = convert.jsonDecode(string);
    roomProtocol.type = jsonMap['type'];
    roomProtocol.senderID = jsonMap['senderID'];
    roomProtocol.receiverID = jsonMap['receiverID'];
    roomProtocol.protocolID = jsonMap['protocolID'];
    return roomProtocol;
  }

  String toJsonString() {
    Map<String, dynamic> jsonMap = {};
    jsonMap['type'] = type;
    jsonMap['senderID'] = senderID;
    jsonMap['receiverID'] = receiverID;
    protocolID ??= generateProtocolID();
    jsonMap['protocolID'] = protocolID!;

    return convert.jsonEncode(jsonMap);
  }

  bool isRequest() {
    return type == ZegoLiveAudioRoomProtocol.applyToBecomeSpeaker ||
        type == ZegoLiveAudioRoomProtocol.hostInviteToBecomeSpeaker;
  }

  void accept() {
    if (type == ZegoLiveAudioRoomProtocol.applyToBecomeSpeaker) {
      type = ZegoLiveAudioRoomProtocol.hostAcceptSpeakerApply;
    } else if (type == ZegoLiveAudioRoomProtocol.hostInviteToBecomeSpeaker) {
      type = ZegoLiveAudioRoomProtocol.acceptSpeakerInvitation;
    }
  }

  bool isAccept() {
    return type == ZegoLiveAudioRoomProtocol.acceptSpeakerInvitation ||
        type == ZegoLiveAudioRoomProtocol.hostAcceptSpeakerApply;
  }

  void reject() {
    if (type == ZegoLiveAudioRoomProtocol.applyToBecomeSpeaker) {
      type = ZegoLiveAudioRoomProtocol.hostRefuseSpeakerApply;
    } else if (type == ZegoLiveAudioRoomProtocol.hostInviteToBecomeSpeaker) {
      type = ZegoLiveAudioRoomProtocol.refuseSpeakerInvitation;
    }
  }

  bool isReject() {
    return type == ZegoLiveAudioRoomProtocol.refuseSpeakerInvitation ||
        type == ZegoLiveAudioRoomProtocol.hostRefuseSpeakerApply;
  }

  void cancel() {
    if (type == ZegoLiveAudioRoomProtocol.applyToBecomeSpeaker) {
      type = ZegoLiveAudioRoomProtocol.cancelSpeakerApply;
    } else if (type == ZegoLiveAudioRoomProtocol.hostInviteToBecomeSpeaker) {
      type = ZegoLiveAudioRoomProtocol.hostCancelSpeakerInvitation;
    }
  }

  bool isCancel() {
    return type == ZegoLiveAudioRoomProtocol.cancelSpeakerApply ||
        type == ZegoLiveAudioRoomProtocol.hostCancelSpeakerInvitation;
  }

  String generateProtocolID() {
    String localUserID = ZEGOSDKManager.instance.localUser?.userID ?? '';
    String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    String randomStr = (Random().nextInt(900000) + 100000).toString();
    return '${localUserID}_${timestamp}_$randomStr';
  }
}
