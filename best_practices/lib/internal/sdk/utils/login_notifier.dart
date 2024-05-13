// Dart imports:
import 'dart:async';

// Flutter imports:
import 'package:flutter/cupertino.dart';

// Package imports:
import '../../../zego_sdk_manager.dart';

/// check room login
///
/// notifier's value will be true when room login
class ZegoRoomLoginNotifier {
  ZegoRoomLoginNotifier({
    String roomID = '',
    bool withExpress = true,
    bool withZIM = true,
  }) {
    _targetRoomID = roomID;

    _withExpress = withExpress;
    _withZIM = withZIM;

    if (_targetRoomID.isNotEmpty) {
      _checkExpressRoom();
      _checkZIMRoom();
    }
  }

  @override
  String toString() {
    return 'ZegoRoomLoginNotifier{'
        'room id:$_targetRoomID, '
        'result:${_result}, '
        'value:${notifier.value}, '
        '}';
  }

  final notifier = ValueNotifier<bool>(false);

  bool get value => notifier.value;
  String get targetRoomID => _targetRoomID;

  bool _withExpress = true;
  bool _withZIM = true;
  String _targetRoomID = '';

  final List<bool> _result = [false, false];
  final _expressResultIndex = 0;
  final _zimResultIndex = 1;

  StreamSubscription<dynamic>? _zimSubscription;
  StreamSubscription<dynamic>? _expressSubscription;

  ZIMService get zimService => ZEGOSDKManager().zimService;

  ExpressService get expressService => ZEGOSDKManager().expressService;

  void resetCheckingData(String roomID) {
    _targetRoomID = roomID;

    _expressSubscription?.cancel();
    _zimSubscription?.cancel();

    _checkExpressRoom();
    _checkZIMRoom();
  }

  void _syncResult() {
    notifier.value = _result[_expressResultIndex] && _result[_zimResultIndex];
  }

  void _checkExpressRoom() {
    if (!_withExpress) {
      _result[_expressResultIndex] = true;

      return;
    }

    _result[_expressResultIndex] = expressService.currentRoomID == _targetRoomID && ZegoRoomStateChangedReason.Logined == expressService.currentRoomState;

    // debugPrint('login notifier($_targetRoomID), check express(${expressService.currentRoomID}), '
    //     'result:$_result, ');

    _syncResult();

    if (expressService.currentRoomID != _targetRoomID || ZegoRoomStateChangedReason.Logined != expressService.currentRoomState) {
      _expressSubscription?.cancel();
      _expressSubscription = expressService.roomStateChangedStreamCtrl.stream.listen(_onExpressRoomStateChanged);
    }
  }

  void _onExpressRoomStateChanged(ZegoRoomStateEvent event) {
    _result[_expressResultIndex] = expressService.currentRoomID == _targetRoomID && ZegoRoomStateChangedReason.Logined == event.reason;

    // debugPrint('login notifier($_targetRoomID), express(${expressService.currentRoomID}), '
    //     'result:$_result, '
    //     'event:$event, ');

    if (_result[_expressResultIndex]) {
      _expressSubscription?.cancel();
    }

    _syncResult();
  }

  void _checkZIMRoom() {
    if (!_withZIM) {
      _result[_zimResultIndex] = true;

      return;
    }

    _result[_zimResultIndex] = _targetRoomID == zimService.currentRoomID && ZIMRoomState.connected == zimService.currentRoomState;

    // debugPrint('login notifier($_targetRoomID), check zim(${zimService.currentRoomID}), '
    //     'result:$_result, ');

    _syncResult();

    if (_targetRoomID != zimService.currentRoomID || ZIMRoomState.connected != zimService.currentRoomState) {
      _zimSubscription?.cancel();
      _zimSubscription = zimService.roomStateChangedStreamCtrl.stream.listen(_onZIMRoomStateChanged);
    }
  }

  void _onZIMRoomStateChanged(
    ZIMServiceRoomStateChangedEvent event,
  ) {
    _result[_zimResultIndex] = _targetRoomID == zimService.currentRoomID && ZIMRoomState.connected == zimService.currentRoomState;

    // debugPrint('login notifier($_targetRoomID), zim(${zimService.currentRoomID}), '
    //     'result:$_result, '
    //     'event:$event, ');

    if (_result[_zimResultIndex]) {
      _zimSubscription?.cancel();
    }

    _syncResult();
  }
}
