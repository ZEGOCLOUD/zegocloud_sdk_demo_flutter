import 'dart:async';
import 'dart:convert';

// Flutter imports:
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../../zego_sdk_manager.dart';

part 'zim_service_avatar.dart';
part 'zim_service_room_attributes.dart';
part 'zim_service_room_request.dart';
part 'zim_service_user_request.dart';

class ZIMService {
  ZIMService._internal();

  factory ZIMService() => instance;
  static final ZIMService instance = ZIMService._internal();

  Map<String, String> roomAttributesMap = {};
  Map<String, String> userAvatarUrlMap = {};
  Map<String, String> userNameMap = {};
  MapNotifier<RoomRequest> roomRequestMapNoti = MapNotifier({});

  ZIMUserInfo? currentZimUserInfo;
  String? currentRoomID;
  ZIMRoomState currentRoomState = ZIMRoomState.disconnected;

  void clearRoomData() {
    debugPrint('zim service, clearRoomData, currentRoomID:$currentRoomID');
    currentRoomID = null;
    currentRoomState = ZIMRoomState.disconnected;
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
  final userRequestEndStreamCtrl = StreamController<UserRequestEndEvent>.broadcast();
  final userRequestStateChangeStreamCtrl = StreamController<UserRequestStateChangeEvent>.broadcast();

  final roomAttributeUpdateStreamCtrl = StreamController<ZIMServiceRoomAttributeUpdateEvent>.broadcast();
  final roomAttributeUpdateStreamCtrl2 = StreamController<RoomAttributesUpdatedEvent>.broadcast();
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
    ZIMEventHandler.onCallInvitationEnded = onCallInvitationEnded;
    ZIMEventHandler.onCallUserStateChanged = onCallUserStateChanged;
    ZIMEventHandler.onRoomAttributesUpdated = onRoomAttributesUpdated;
    ZIMEventHandler.onRoomAttributesBatchUpdated = onRoomAttributesBatchUpdated;
  }

  void uninitEventHandle() {
    ZIMEventHandler.onConnectionStateChanged = null;
    ZIMEventHandler.onRoomStateChanged = null;
    ZIMEventHandler.onRoomMemberLeft = null;
    ZIMEventHandler.onReceiveRoomMessage = null;
    ZIMEventHandler.onCallInvitationReceived = null;
    ZIMEventHandler.onCallInvitationCancelled = null;
    ZIMEventHandler.onCallInvitationAccepted = null;
    ZIMEventHandler.onCallInvitationRejected = null;
    ZIMEventHandler.onCallInvitationTimeout = null;
    ZIMEventHandler.onCallInvitationEnded = null;
    ZIMEventHandler.onCallUserStateChanged = null;
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

  Future<void> connectUser(String userID, String userName, {String? token, bool isOfflineLogin = false}) async {
    currentZimUserInfo = ZIMUserInfo()
      ..userID = userID
      ..userName = userName;
    userNameMap[userID] = userName;
    await ZIM.getInstance()!.login(
          userID,
          ZIMLoginConfig()
            ..token = token ?? ''
            ..userName = userName
            ..isOfflineLogin = isOfflineLogin,
        );
  }

  Future<void> disconnectUser() async {
    debugPrint('zim service, disconnectUser, currentRoomID:$currentRoomID');
    ZIM.getInstance()!.logout();
    clearRoomData();
    currentZimUserInfo = null;
  }

  Future<ZegoRoomLoginResult> _loginRoom({
    required String roomID,
  }) async {
    debugPrint('zim service, ready loginRoom(join), '
        'current room id:$currentRoomID, '
        'target room id:$roomID, ');

    final result = ZegoRoomLoginResult(0, {});

    await ZIM.getInstance()!.joinRoom(roomID).then((zimResult) {
      debugPrint('zim service, loginRoom(join), room id:$currentRoomID');
      result.errorCode = 0;
    }).catchError((error) {
      debugPrint('zim service, loginRoom(join), room id:$currentRoomID, error:$error');

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

  Future<ZegoRoomLoginResult> loginRoom(
    String roomID, {
    String? roomName,
    Map<String, String> roomAttributes = const {},
    int roomDestroyDelayTime = 0,
  }) async {
    debugPrint('zim service, ready loginRoom, '
        'current room id:$currentRoomID, '
        'target room id:$roomID, ');

    currentRoomID = roomID;

    var result = ZegoRoomLoginResult(0, {});

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
      debugPrint('zim service, loginRoom, room id:$currentRoomID');
      result.errorCode = 0;
    }).catchError((error) async {
      if (error is PlatformException && int.parse(error.code) == ZIMErrorCode.roomModuleTheRoomAlreadyExists) {
        /// room is exist, just call join room
        result = await _loginRoom(roomID: roomID);
      } else {
        debugPrint('zim service, loginRoom, room id:$currentRoomID, error:$error');

        result.extendedData['error'] = error;
        if (error is PlatformException) {
          result.errorCode = int.tryParse(error.code) ?? -1;
          result.extendedData['errorMessage'] = error.message;
        } else {
          result.errorCode = -2;
          result.extendedData['errorMessage'] = '$error';
        }
      }
    });

    return result;
  }

  Future<ZIMRoomLeftResult> logoutRoom() async {
    debugPrint('zim service, ready logoutRoom, room id:$currentRoomID');

    if (currentRoomID != null) {
      final targetRoomID = currentRoomID!;
      clearRoomData();

      final ret = await ZIM.getInstance()!.leaveRoom(targetRoomID).then((value) {
        debugPrint('zim service, logoutRoom, room id:$targetRoomID');
        return value;
      }).catchError((error) {
        debugPrint('zim service, logoutRoom, room id:$targetRoomID, error:$error');
      });
      debugPrint('zim service, logoutRoom, currentRoomID:$targetRoomID');
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
    currentRoomState = state;

    debugPrint('zim service, onRoomStateChanged, room id:$roomID, state:$state');
    roomStateChangedStreamCtrl.add(ZIMServiceRoomStateChangedEvent(roomID, state, event, extendedData));
  }

  void cancelInvitation({required String invitationID, required List<String> invitees}) {}
}
