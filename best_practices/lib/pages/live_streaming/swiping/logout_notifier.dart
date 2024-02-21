// Dart imports:
import 'dart:async';

// Flutter imports:
import 'package:flutter/cupertino.dart';

// Package imports:
import '../../../zego_sdk_manager.dart';

class ZegoLiveSwipingRoomLogoutNotifier {
  ZegoLiveSwipingRoomLogoutNotifier() {
    _checkExpressRoom();
    _checkZIMRoom();
  }

  final notifier = ValueNotifier<bool>(false);

  String? get checkingRoomID => _checkingRoomID;

  bool get value => notifier.value;

  String? _checkingRoomID;

  final List<bool> _result = [false, false];
  final _expressResultIndex = 0;
  final _zimResultIndex = 1;

  StreamSubscription<dynamic>? _zimSubscription;
  StreamSubscription<dynamic>? _expressSubscription;

  ZIMService get zimService => ZEGOSDKManager().zimService;

  ExpressService get expressService => ZEGOSDKManager().expressService;

  void resetCheckingData() {
    debugPrint('logout notifier, reset checking room');

    _checkingRoomID = null;

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
    debugPrint('logout notifier, check express room, '
        'room id:${expressService.currentRoomID}, '
        'state:${expressService.currentRoomState}, ');

    _result[_expressResultIndex] = expressService.currentRoomID.isEmpty;
    _syncResult();

    if (expressService.currentRoomID.isNotEmpty) {
      debugPrint(
          'logout notifier, check express room, express room ${expressService.currentRoomID} is exist, listen...');

      _checkingRoomID = expressService.currentRoomID;

      _expressSubscription?.cancel();
      _expressSubscription = expressService.roomStateChangedStreamCtrl.stream.listen(_onExpressRoomStateChanged);
    }
  }

  void _onExpressRoomStateChanged(ZegoRoomStateEvent event) {
    debugPrint('logout notifier, express room state changed, target room id:$_checkingRoomID, '
        'room id:${event.roomID}, '
        'room state:${event.reason}');

    _result[_expressResultIndex] = ZegoRoomStateChangedReason.Logout == event.reason;

    if (_result[_expressResultIndex]) {
      debugPrint('logout notifier, express room state changed, room already logout, remove listener');

      _expressSubscription?.cancel();
    }

    _syncResult();
  }

  void _checkZIMRoom() {
    debugPrint('logout notifier, check zim room, target room id:$_checkingRoomID, '
        'room id:${zimService.currentRoomID}, '
        'room state:${zimService.currentRoomState}');

    _result[_zimResultIndex] = ZIMRoomState.disconnected == zimService.currentRoomState;
    _syncResult();

    if (ZIMRoomState.disconnected != zimService.currentRoomState) {
      debugPrint('logout notifier, check zim room, room is not disconnected, listen...');

      _zimSubscription?.cancel();
      _zimSubscription = zimService.roomStateChangedStreamCtrl.stream.listen(onZIMRoomStateChanged);
    }
  }

  void onZIMRoomStateChanged(
    ZIMServiceRoomStateChangedEvent event,
  ) {
    debugPrint('logout notifier, zim room state changed, target room id:$_checkingRoomID, '
        'room id:${event.roomID}, '
        'room state:${event.state}');

    _result[_zimResultIndex] = ZIMRoomState.disconnected == event.state;

    if (_result[_zimResultIndex]) {
      debugPrint('logout notifier, zim room state changed, room already disconnected, remove listener');

      _zimSubscription?.cancel();
    }

    _syncResult();
  }
}
