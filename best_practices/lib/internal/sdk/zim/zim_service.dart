import 'dart:async';
import 'dart:convert';

// Flutter imports:
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../utils/flutter_extension.dart';
import '../../../zego_sdk_manager.dart';
import 'Define/zim_define.dart';
import 'Define/zim_room_request.dart';

part 'zim_service_avatar.dart';
part 'zim_service_user_request.dart';
part 'zim_service_room_attributes.dart';
part 'zim_service_room_request.dart';

class ZIMService {
  ZIMService._internal();
  factory ZIMService() => instance;
  static final ZIMService instance = ZIMService._internal();

  Map<String, String> roomAttributesMap = {};
  Map<String, String> userAvatarUrlMap = {};
  MapNotifier<RoomRequest> roomRequestMapNoti = MapNotifier({});

  ZIMUserInfo? currentZimUserInfo;
  String? currentRoomID;

  void clearRoomData() {
    currentRoomID = null;
    roomAttributesMap.clear();
    roomRequestMapNoti.clear();
  }

  final connectionStateStreamCtrl = StreamController<ZIMServiceConnectionStateChangedEvent>.broadcast();
  final roomStateChangedStreamCtrl = StreamController<ZIMServiceRoomStateChangedEvent>.broadcast();
  final receiveRoomCustomSignalingStreamCtrl = StreamController<ZIMServiceReceiveRoomCustomSignalingEvent>.broadcast();
  final incomingUserRequestReceivedStreamCtrl = StreamController<IncomingUserRequestReceivedEvent>.broadcast();
  final incomingUserRequestCancelledStreamCtrl = StreamController<IncomingUserRequestCancelledEvent>.broadcast();
  final outgoingUserRequestAcceptedStreamCtrl = StreamController<OutgoingUserRequestAcceptedEvent>.broadcast();
  final outgoingUserRequestRejectedStreamCtrl = StreamController<OutgoingUserRequestRejectedEvent>.broadcast();
  final incomingUserRequestTimeoutStreamCtrl = StreamController<IncomingUserRequestTimeoutEvent>.broadcast();
  final outgoingUserRequestTimeoutStreamCtrl = StreamController<OutgoingUserRequestTimeoutEvent>.broadcast();
  final roomAttributeUpdateStreamCtrl = StreamController<ZIMServiceRoomAttributeUpdateEvent>.broadcast();
  final roomAttributeBatchUpdatedStreamCtrl = StreamController<ZIMServiceRoomAttributeBatchUpdatedEvent>.broadcast();
  final sendRoomRequestStreamCtrl = StreamController<SendRoomRequestEvent>.broadcast();
  final acceptIncomingRoomRequestStreamCtrl = StreamController<AcceptIncomingRoomRequestEvent>.broadcast();
  final rejectIncomingRoomRequestStreamCtrl = StreamController<RejectIncomingRoomRequestEvent>.broadcast();
  final cancelRoomRequestStreamCtrl = StreamController<CancelRoomRequestEvent>.broadcast();

  final onInComingRoomRequestStreamCtrl = StreamController<OnInComingRoomRequestReceivedEvent>.broadcast();
  final onOutgoingRoomRequestAcceptedStreamCtrl = StreamController<OnOutgoingRoomRequestAcceptedEvent>.broadcast();
  final onOutgoingRoomRequestRejectedStreamCtrl = StreamController<OnOutgoingRoomRequestRejectedEvent>.broadcast();
  final onInComingRoomRequestCancelledStreamCtrl = StreamController<OnInComingRoomRequestCancelledEvent>.broadcast();
  final onRoomCommandReceivedEventStreamCtrl = StreamController<OnRoomCommandReceivedEvent>.broadcast();

  void initEventHandle() {
    ZIMEventHandler.onConnectionStateChanged = onConnectionStateChanged;
    ZIMEventHandler.onRoomStateChanged = onRoomStateChanged;
    ZIMEventHandler.onRoomMemberLeft = onRoomMemberLeft;
    ZIMEventHandler.onReceiveRoomMessage = onReceiveRoomMessage;
    ZIMEventHandler.onCallInvitationReceived = onUserRequestReceived;
    ZIMEventHandler.onCallInvitationCancelled = onUserRequestCancelled;
    ZIMEventHandler.onCallInvitationAccepted = onUserRequestAccepted;
    ZIMEventHandler.onCallInvitationRejected = onUserRequestRejected;
    ZIMEventHandler.onCallInvitationTimeout = onUserRequestTimeout;
    ZIMEventHandler.onCallInviteesAnsweredTimeout = onUserRequestAnsweredTimeout;
    ZIMEventHandler.onRoomAttributesUpdated = onRoomAttributesUpdated;
    ZIMEventHandler.onRoomAttributesBatchUpdated = onRoomAttributesBatchUpdated;
  }

  void uninitEventHandle() {
    ZIMEventHandler.onRoomStateChanged = null;
    ZIMEventHandler.onConnectionStateChanged = null;
    ZIMEventHandler.onReceiveRoomMessage = null;
    ZIMEventHandler.onCallInvitationReceived = null;
    ZIMEventHandler.onCallInvitationCancelled = null;
    ZIMEventHandler.onCallInvitationAccepted = null;
    ZIMEventHandler.onCallInvitationRejected = null;
    ZIMEventHandler.onCallInvitationTimeout = null;
    ZIMEventHandler.onCallInviteesAnsweredTimeout = null;
    ZIMEventHandler.onRoomAttributesUpdated = null;
    ZIMEventHandler.onRoomAttributesBatchUpdated = null;
  }

  Future<void> init({required int appID, String? appSign}) async {
    initEventHandle();
    ZIM.create(
      ZIMAppConfig()
        ..appID = appID
        ..appSign = appSign ?? '',
    );
  }

  Future<void> uninit() async {
    uninitEventHandle();
    ZIM.getInstance()?.destroy();
  }

  Future<void> uploadLog() {
    return ZIM.getInstance()!.uploadLog();
  }

  Future<void> connectUser(String userID, String userName, {String? token}) async {
    currentZimUserInfo = ZIMUserInfo()
      ..userID = userID
      ..userName = userName;
    await ZIM.getInstance()!.login(currentZimUserInfo!, token);
  }

  Future<void> disconnectUser() async {
    ZIM.getInstance()!.logout();
    clearRoomData();
    currentZimUserInfo = null;
  }

  Future<ZegoRoomLoginResult> loginRoom(
    String roomID, {
    String? roomName,
    Map<String, String> roomAttributes = const {},
    int roomDestroyDelayTime = 0,
  }) async {
    currentRoomID = roomID;

    final result = ZegoRoomLoginResult(0, {});

    await ZIM
        .getInstance()!
        .enterRoom(
            ZIMRoomInfo()
              ..roomID = roomID
              ..roomName = roomName ?? '',
            ZIMRoomAdvancedConfig()
              ..roomAttributes = roomAttributes
              ..roomDestroyDelayTime = roomDestroyDelayTime)
        .then((value) {
      result.errorCode = 0;
    }).catchError((error) {
      result.extendedData['error'] = error;
      if (error is PlatformException) {
        result.errorCode = int.tryParse(error.code) ?? -1;
        result.extendedData['errorMessage'] = error.message;
      } else {
        result.errorCode = -2;
        result.extendedData['errorMessage'] = '$error';
      }
    });
    return result;
  }

  Future<ZIMRoomLeftResult> logoutRoom() async {
    if (currentRoomID != null) {
      final ret = await ZIM.getInstance()!.leaveRoom(currentRoomID!);
      clearRoomData();
      return ret;
    } else {
      debugPrint('currentRoomID is null');
      return ZIMRoomLeftResult(roomID: '');
    }
  }

  void onConnectionStateChanged(_, ZIMConnectionState state, ZIMConnectionEvent event, Map extendedData) {
    connectionStateStreamCtrl.add(ZIMServiceConnectionStateChangedEvent(state, event, extendedData));
  }

  void onRoomStateChanged(_, ZIMRoomState state, ZIMRoomEvent event, Map extendedData, String roomID) {
    roomStateChangedStreamCtrl.add(ZIMServiceRoomStateChangedEvent(roomID, state, event, extendedData));
  }

  void cancelInvitation({required String invitationID, required List<String> invitees}) {}
}
