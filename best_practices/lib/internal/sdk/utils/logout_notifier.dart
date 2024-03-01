// Dart imports:
import 'dart:async';

// Flutter imports:
import 'package:flutter/cupertino.dart';

// Package imports:
import '../../../zego_sdk_manager.dart';

/// check room logout
///
/// notifier's value will be true when room logout
class ZegoRoomLogoutNotifier {
  ZegoRoomLogoutNotifier({
    bool withExpress = true,
    bool withZIM = true,
    String roomID = '',
  }) {
    _targetRoomID = roomID.isEmpty ? expressService.currentRoomID : roomID;
    _withExpress = withExpress;
    _withZIM = withZIM;

    _checkExpressRoom();
    _checkZIMRoom();
  }

  final notifier = ValueNotifier<bool>(false);

  bool get value => notifier.value;

  String _targetRoomID = '';
  bool _withExpress = true;
  bool _withZIM = true;

  final List<bool> _result = [false, false];
  final _expressResultIndex = 0;
  final _zimResultIndex = 1;

  StreamSubscription<dynamic>? _zimSubscription;
  StreamSubscription<dynamic>? _expressSubscription;

  String get checkingRoomID => _targetRoomID;

  ZIMService get zimService => ZEGOSDKManager().zimService;

  ExpressService get expressService => ZEGOSDKManager().expressService;

  void resetCheckingData(String roomID) {
    debugPrint('logout notifier, reset checking room');

    _targetRoomID = roomID;

    _expressSubscription?.cancel();
    _zimSubscription?.cancel();

    _checkExpressRoom();
    _checkZIMRoom();
  }

  void _syncResult() {
    notifier.value = _result[_expressResultIndex] && _result[_zimResultIndex];

    debugPrint('logout notifier, sync result, result:$_result, value:${notifier.value}');
  }

  void _checkExpressRoom() {
    if (!_withExpress) {
      debugPrint('logout notifier, not need to check express room');

      _result[_expressResultIndex] = true;

      return;
    }

    debugPrint('logout notifier, check express room, '
        'room id:${expressService.currentRoomID}, '
        'state:${expressService.currentRoomState}, ');

    _result[_expressResultIndex] = expressService.currentRoomID != _targetRoomID;
    _syncResult();

    if (expressService.currentRoomID == _targetRoomID &&
        expressService.currentRoomState != ZegoRoomStateChangedReason.Logout) {
      debugPrint(
          'logout notifier, check express room, express room ${expressService.currentRoomID} is exist, listen...');

      _expressSubscription?.cancel();
      _expressSubscription = expressService.roomStateChangedStreamCtrl.stream.listen(_onExpressRoomStateChanged);
    }
  }

  void _onExpressRoomStateChanged(ZegoRoomStateEvent event) {
    debugPrint('logout notifier, express room state changed, target room id:$_targetRoomID, '
        'room id:${event.roomID}, '
        'room state:${event.reason}');

    _result[_expressResultIndex] = ZegoRoomStateChangedReason.Logout == event.reason && event.roomID == _targetRoomID;

    if (_result[_expressResultIndex]) {
      debugPrint('logout notifier, express room state changed, room already logout, remove listener');

      _expressSubscription?.cancel();
    }

    _syncResult();
  }

  void _checkZIMRoom() {
    if (!_withZIM) {
      debugPrint('logout notifier, not need to check ZIM room');

      _result[_zimResultIndex] = true;

      return;
    }

    debugPrint('logout notifier, check ZIM room, target room id:$_targetRoomID, '
        'room id:${zimService.currentRoomID}, '
        'room state:${zimService.currentRoomState}');

    _result[_zimResultIndex] = ZIMRoomState.disconnected == zimService.currentRoomState;
    _syncResult();

    if (zimService.currentRoomID == _targetRoomID && ZIMRoomState.disconnected != zimService.currentRoomState) {
      debugPrint('logout notifier, check ZIM room, room is not disconnected, listen...');

      _zimSubscription?.cancel();
      _zimSubscription = zimService.roomStateChangedStreamCtrl.stream.listen(onZIMRoomStateChanged);
    }
  }

  void onZIMRoomStateChanged(
    ZIMServiceRoomStateChangedEvent event,
  ) {
    debugPrint('logout notifier, ZIM room state changed, target room id:$_targetRoomID, '
        'room id:${event.roomID}, '
        'room state:${event.state}');

    _result[_zimResultIndex] = ZIMRoomState.disconnected == event.state && event.roomID == _targetRoomID;

    if (_result[_zimResultIndex]) {
      debugPrint('logout notifier, ZIM room state changed, room already disconnected, remove listener');

      _zimSubscription?.cancel();
    }

    _syncResult();
  }
}
