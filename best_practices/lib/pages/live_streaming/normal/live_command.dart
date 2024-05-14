import 'package:flutter/cupertino.dart';

class ZegoLivePageCommand {
  String roomID = '';
  String key = '';

  @override
  String toString() {
    return 'ZegoLivePageCommand{key:$key, room:$roomID}';
  }

  ZegoLivePageCommand({required this.roomID}) {
    key = DateTime.now().millisecondsSinceEpoch.toString();
  }

  void join() {
    joinRoomCommand.value = DateTime.now().millisecondsSinceEpoch;
  }

  void leave() {
    leaveRoomCommand.value = DateTime.now().millisecondsSinceEpoch;
  }

  void registerEvent() {
    registerEventCommand.value = DateTime.now().millisecondsSinceEpoch;
  }

  void unregisterEvent() {
    unregisterEventCommand.value = DateTime.now().millisecondsSinceEpoch;
  }

  final joinRoomCommand = CacheValueNotifier<int>(0);
  final leaveRoomCommand = CacheValueNotifier<int>(0);
  final registerEventCommand = CacheValueNotifier<int>(0);
  final unregisterEventCommand = CacheValueNotifier<int>(0);
}

class CacheValueNotifier<T> extends ValueNotifier<T> {
  CacheValueNotifier(super.value);

  T? cacheValue;

  @override
  void addListener(VoidCallback listener) {
    super.addListener(listener);

    if (null != cacheValue) {
      super.value = cacheValue as T;
    }
  }

  @override
  set value(T newValue) {
    if (!hasListeners) {
      cacheValue = newValue;

      return;
    }

    super.value = newValue;
  }
}
