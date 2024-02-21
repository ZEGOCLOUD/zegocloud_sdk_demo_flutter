// Dart imports:
import 'dart:async';

// Flutter imports:
import 'package:flutter/cupertino.dart';

// Package imports:
import '../../../internal/sdk/express/express_service.dart';
import '../../../internal/sdk/zim/zim_service.dart';
import '../../../zego_sdk_manager.dart';

class ZegoLiveSwipingRoomLoginNotifier {
  ZegoLiveSwipingRoomLoginNotifier() {
    _checkExpressRoom();
    _checkZIMRoom();
  }

  final notifier = ValueNotifier<bool>(false);

  bool get value => notifier.value;

  String _targetRoomID = '';

  final List<bool> _result = [false, false];
  final _expressResultIndex = 0;
  final _zimResultIndex = 1;

  StreamSubscription<dynamic>? _zimSubscription;
  StreamSubscription<dynamic>? _expressSubscription;

  ZIMService get zimService => ZEGOSDKManager().zimService;

  ExpressService get expressService => ZEGOSDKManager().expressService;

  void resetCheckingData(String roomID) {
    debugPrint('login notifier, reset checking room to $roomID');

    _targetRoomID = roomID;

    _expressSubscription?.cancel();
    _zimSubscription?.cancel();

    _checkExpressRoom();
    _checkZIMRoom();
  }

  void _syncResult() {
    notifier.value = _result[_expressResultIndex] && _result[_zimResultIndex];

    debugPrint('login notifier, sync result, result:$_result, value:${notifier.value}');
  }

  void _checkExpressRoom() {
    debugPrint('login notifier, check express room, target room id:$_targetRoomID, '
        'room id:${expressService.currentRoomID}, '
        'room state:${expressService.currentRoomState}');

    _result[_expressResultIndex] = expressService.currentRoomID == _targetRoomID &&
        ZegoRoomStateChangedReason.Logined == expressService.currentRoomState;
    _syncResult();

    if (expressService.currentRoomID != _targetRoomID ||
        ZegoRoomStateChangedReason.Logined != expressService.currentRoomState) {
      debugPrint('login notifier, check express room, express room is not ready, listen...');

      _expressSubscription?.cancel();
      _expressSubscription = expressService.roomStateChangedStreamCtrl.stream.listen(_onExpressRoomStateChanged);
    }
  }

  void _onExpressRoomStateChanged(ZegoRoomStateEvent event) {
    debugPrint('login notifier, express room state changed, target room id:$_targetRoomID, '
        'room id:${event.roomID}, '
        'room state:${event.reason}');

    _result[_expressResultIndex] =
        expressService.currentRoomID == _targetRoomID && ZegoRoomStateChangedReason.Logined == event.reason;

    if (_result[_expressResultIndex]) {
      debugPrint('login notifier, express room state changed, room already login, remove listener');

      _expressSubscription?.cancel();
    }

    _syncResult();
  }

  void _checkZIMRoom() {
    debugPrint('login notifier, check ZIM room, target room id:$_targetRoomID, '
        'room id:${zimService.currentRoomID}, '
        'room state:${zimService.currentRoomState}');

    _result[_zimResultIndex] =
        _targetRoomID == zimService.currentRoomID && ZIMRoomState.connected == zimService.currentRoomState;
    _syncResult();

    if (_targetRoomID != zimService.currentRoomID || ZIMRoomState.connected != zimService.currentRoomState) {
      debugPrint('login notifier, check ZIM room, room is not connected, listen...');

      _zimSubscription?.cancel();
      _zimSubscription = zimService.roomStateChangedStreamCtrl.stream.listen(_onZIMRoomStateChanged);
    }
  }

  void _onZIMRoomStateChanged(
    ZIMServiceRoomStateChangedEvent event,
  ) {
    debugPrint('login notifier, ZIM room state changed, target room id:$_targetRoomID, '
        'room id:${zimService.currentRoomID}, '
        'room state:${zimService.currentRoomState}');

    _result[_zimResultIndex] =
        _targetRoomID == zimService.currentRoomID && ZIMRoomState.connected == zimService.currentRoomState;

    if (_result[_zimResultIndex]) {
      debugPrint('login notifier, ZIM room state changed, room already connected, remove listener');

      _zimSubscription?.cancel();
    }

    _syncResult();
  }
}
