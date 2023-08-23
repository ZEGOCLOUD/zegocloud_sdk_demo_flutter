import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:live_audio_room_demo/define.dart';
import 'package:live_audio_room_demo/internal/zego_express_service.dart';
import 'package:live_audio_room_demo/internal/zego_custom_protocol_record.dart';
import 'package:live_audio_room_demo/internal/zego_live_audio_room_protocol.dart';
import 'package:live_audio_room_demo/utils/flutter_extension.dart';

import '../live_audio_room_manager.dart';
import '../zego_sdk_manager.dart';

class CustomProtocolImplement {
  Map<String, CustomProtocolRecord> recordsMap = {};
  ListNotifier<CustomProtocolRecord> recordsListNoti = ListNotifier([]);

  List<StreamSubscription<dynamic>?> subscriptions = [];

  StreamController<CustomProtocolIncomingRequestReceivedEvent> onIncomingRequestReceivedCtrl =
      StreamController<CustomProtocolIncomingRequestReceivedEvent>.broadcast();
  StreamController<CustomProtocolInComingRequestCancelledEvent> onIncomingRequestCancelledCtrl =
      StreamController<CustomProtocolInComingRequestCancelledEvent>.broadcast();
  StreamController<CustomProtocolOutgoingRequestRejectedEvent> onIncomingRequestRejectedCtrl =
      StreamController<CustomProtocolOutgoingRequestRejectedEvent>.broadcast();
  StreamController<CustomProtocolOutgoingRequestAcceptedEvent> onIncomingRequestAcceptedCtrl =
      StreamController<CustomProtocolOutgoingRequestAcceptedEvent>.broadcast();

  ValueNotifier<bool> isApplyStateNoti = ValueNotifier(false);
  String currentProtocolID = '';

  void addZIMListener() {
    subscriptions.add(ZEGOSDKManager.instance.zimService.receiveRoomCustomSignalingStreamCtrl.stream
        .listen(onRoomCustomSignalingReceived));
  }

  Future<ZIMMessageSentResult> sendTakeSeatRequest() async {
    Map<String, dynamic> senderMap = {};
    senderMap['type'] = ZegoLiveAudioRoomProtocol.applyToBecomeSpeaker;
    senderMap['senderID'] = ZEGOSDKManager.instance.localUser?.userID;
    senderMap['receiverID'] = ZegoLiveAudioRoomManager.shared.hostUserNoti.value?.userID;

    ZegoLiveAudioRoomProtocol roomProtocol = ZegoLiveAudioRoomProtocol.parse(jsonEncode(senderMap));

    CustomProtocolRecord record = CustomProtocolRecord();
    record.receivers = [roomProtocol.receiverID ?? ''];
    record.extendedData = roomProtocol.toJsonString();
    record.sender = roomProtocol.senderID ?? '';

    ZIMMessageSentResult result =
        await ZEGOSDKManager.instance.zimService.sendCustomProtocolRequest(roomProtocol.toJsonString());
    currentProtocolID = roomProtocol.protocolID ?? '';
    record.state = ZegoCustomProtocolState.sendNew;
    record.receiverStateMap[roomProtocol.receiverID ?? ''] = ZegoReceiverState.recv;
    recordsMap[currentProtocolID] = record;
    recordsListNoti.add(record);
    isApplyStateNoti.value = true;
    return result;
  }

  Future<ZIMMessageSentResult?> acceptIncoming(CustomProtocolRecord record) async {
    ZegoUserInfo? info = ZEGOSDKManager.instance.getUser(record.sender ?? '');
    if (info == null) {
      return null;
    }
    ZegoLiveAudioRoomProtocol roomProtocol = ZegoLiveAudioRoomProtocol.parse(record.extendedData ?? "");
    roomProtocol.accept();

    ZIMMessageSentResult result =
        await ZEGOSDKManager.instance.zimService.sendCustomProtocolRequest(roomProtocol.toJsonString());
    CustomProtocolRecord? lastRecord = recordsMap[roomProtocol.protocolID ?? ''];
    if (lastRecord != null) {
      lastRecord.state = ZegoCustomProtocolState.recvAccept;
      lastRecord.receiverStateMap[ZEGOSDKManager.instance.localUser?.userID ?? ''] = ZegoReceiverState.accept;
    }
    recordsMap.remove(roomProtocol.protocolID);
    recordsListNoti.remove(record);
    return result;
  }

  Future<ZIMMessageSentResult?> rejectIncoming(CustomProtocolRecord record) async {
    ZegoUserInfo? info = ZEGOSDKManager.instance.getUser(record.sender ?? '');
    if (info == null) {
      return null;
    }
    ZegoLiveAudioRoomProtocol roomProtocol = ZegoLiveAudioRoomProtocol.parse(record.extendedData ?? "");
    roomProtocol.reject();

    ZIMMessageSentResult result =
        await ZEGOSDKManager.instance.zimService.sendCustomProtocolRequest(roomProtocol.toJsonString());
    CustomProtocolRecord? lastRecord = recordsMap[roomProtocol.protocolID ?? ''];
    if (lastRecord != null) {
      lastRecord.state = ZegoCustomProtocolState.recvRejected;
      lastRecord.receiverStateMap[ZEGOSDKManager.instance.localUser?.userID ?? ''] = ZegoReceiverState.reject;
    }
    recordsMap.remove(roomProtocol.protocolID);
    recordsListNoti.remove(record);
    return result;
  }

  Future<ZIMMessageSentResult?> cancelTakeSeatRequest() async {
    CustomProtocolRecord record = recordsMap[currentProtocolID] ?? CustomProtocolRecord();

    ZegoLiveAudioRoomProtocol roomProtocol = ZegoLiveAudioRoomProtocol.parse(record.extendedData ?? "");
    roomProtocol.cancel();

    ZIMMessageSentResult result =
        await ZEGOSDKManager.instance.zimService.sendCustomProtocolRequest(roomProtocol.toJsonString());
    recordsMap.remove(roomProtocol.protocolID);
    recordsListNoti.remove(record);
    isApplyStateNoti.value = false;
    currentProtocolID = '';
    return result;
  }

  CustomProtocolRecord? getRecordByPtorocolID(String protocolID) {
    CustomProtocolRecord? record = recordsMap[protocolID];
    if (record == null) {
      recordsMap.forEach((key, value) {
        if (key.contains(protocolID)) {
          record = value;
        }
      });
    }
    return record;
  }

  void onRoomCustomSignalingReceived(ZIMServiceReceiveRoomCustomSignalingEvent event) {
    // String messageStr = jsonDecode(event.signaling);
    ZegoLiveAudioRoomProtocol protocol = ZegoLiveAudioRoomProtocol.parse(event.signaling);
    String? senderID = protocol.senderID;
    String protocolID = protocol.protocolID ?? '';
    if (protocol.isRequest()) {
      onIncomingRequestReceived(protocolID, senderID ?? '', event.signaling);
    } else if (protocol.isCancel()) {
      onInComingRequestCancelled(protocolID, senderID ?? '', event.signaling);
    } else if (protocol.isReject()) {
      isApplyStateNoti.value = false;
      if (ZEGOSDKManager.instance.localUser?.userID == protocol.senderID) {
        onOutgoingRequestRejected(protocolID, senderID ?? '', event.signaling);
      }
    } else if (protocol.isAccept()) {
      isApplyStateNoti.value = false;
      if (ZEGOSDKManager.instance.localUser?.userID == protocol.senderID) {
        onOutgoingRequestAccepted(protocolID, senderID ?? '', event.signaling);
      }
    }
  }

  void onIncomingRequestReceived(String protocolID, String senderID, String extendedData) {
    CustomProtocolRecord record = CustomProtocolRecord();
    record.sender = senderID;
    record.extendedData = extendedData;
    record.receivers.add(ZEGOSDKManager.instance.localUser!.userID);
    record.receiverStateMap[ZEGOSDKManager.instance.localUser!.userID] = ZegoReceiverState.recv;
    record.state = ZegoCustomProtocolState.recvNew;
    recordsMap[protocolID] = record;
    recordsListNoti.add(record);

    onIncomingRequestReceivedCtrl.add(CustomProtocolIncomingRequestReceivedEvent(protocolID, senderID, extendedData));
  }

  void onInComingRequestCancelled(String protocolID, String senderID, String extendedData) {
    CustomProtocolRecord? record = recordsMap[protocolID];
    record?.state = ZegoCustomProtocolState.recvIsCancelled;

    onIncomingRequestCancelledCtrl.add(CustomProtocolInComingRequestCancelledEvent(protocolID, senderID, extendedData));

    recordsMap.remove(protocolID);
    recordsListNoti.remove(record);
  }

  void onOutgoingRequestRejected(String protocolID, String receiver, String extendedData) {
    currentProtocolID = '';
    CustomProtocolRecord? record = recordsMap[protocolID];
    record?.state = ZegoCustomProtocolState.recvRejected;
    record?.receiverStateMap[receiver] = ZegoReceiverState.reject;

    onIncomingRequestRejectedCtrl.add(CustomProtocolOutgoingRequestRejectedEvent(protocolID, receiver, extendedData));

    recordsMap.remove(protocolID);
    recordsListNoti.remove(record);
    isApplyStateNoti.value = false;
  }

  void onOutgoingRequestAccepted(String protocolID, String receiver, String extendedData) {
    currentProtocolID = '';
    CustomProtocolRecord? record = recordsMap[protocolID];
    record?.state = ZegoCustomProtocolState.recvAccept;
    record?.receiverStateMap[receiver] = ZegoReceiverState.accept;

    onIncomingRequestAcceptedCtrl.add(CustomProtocolOutgoingRequestAcceptedEvent(protocolID, receiver, extendedData));

    recordsMap.remove(protocolID);
    recordsListNoti.remove(record);
    isApplyStateNoti.value = false;
  }
}
