import 'dart:async';

import '../../../live_audio_room_manager.dart';
import '../../../zego_sdk_manager.dart';
import 'live_audio_room_seat.dart';

class RoomSeatService {
  final seatCount = 8;
  int hostSeatIndex = 0;
  late List<ZegoLiveAudioRoomSeat> seatList = List.generate(seatCount, (index) => ZegoLiveAudioRoomSeat(index));
  bool isBatchOperation = false;

  List<StreamSubscription<dynamic>> subscriptions = [];

  void initWithConfig(ZegoLiveRole role) {
    final expressService = ZEGOSDKManager.instance.expressService;
    final zimService = ZEGOSDKManager.instance.zimService;
    subscriptions.addAll([
      expressService.roomUserListUpdateStreamCtrl.stream.listen(onRoomUserListUpdate),
      zimService.roomAttributeUpdateStreamCtrl.stream.listen(onRoomAttributeUpdate),
      zimService.roomAttributeBatchUpdatedStreamCtrl.stream.listen(onRoomAttributeBatchUpdate)
    ]);
  }

  Future<ZIMRoomAttributesOperatedCallResult?> takeSeat(int seatIndex) async {
    final attributes = {seatIndex.toString(): ZEGOSDKManager.instance.currentUser?.userID ?? ''};
    final result = await ZEGOSDKManager.instance.zimService.setRoomAttributes(
      attributes,
      isForce: false,
      isUpdateOwner: true,
      isDeleteAfterOwnerLeft: true,
    );
    if (result != null) {
      if (!result.errorKeys.contains(seatIndex.toString())) {
        for (final element in seatList) {
          if (element.seatIndex == seatIndex) {
            element.currentUser.value = ZEGOSDKManager.instance.currentUser;
            break;
          }
        }
      }
    }
    return result;
  }

  Future<ZIMRoomAttributesBatchOperatedResult?> switchSeat(int fromSeatIndex, int toSeatIndex) async {
    if (!isBatchOperation) {
      ZEGOSDKManager.instance.zimService.beginRoomAttributesBatchOperation(
        isForce: false,
        isUpdateOwner: true,
        isDeleteAfterOwnerLeft: true,
      );
      isBatchOperation = true;
      takeSeat(toSeatIndex);
      leaveSeat(fromSeatIndex);
      final result = await ZEGOSDKManager.instance.zimService.endRoomPropertiesBatchOperation();
      isBatchOperation = false;
      return result;
    }
    return null;
  }

  Future<ZIMRoomAttributesOperatedCallResult?> leaveSeat(int seatIndex) async {
    final result = await ZEGOSDKManager.instance.zimService.deleteRoomAttributes([seatIndex.toString()]);
    if (result != null) {
      if (result.errorKeys.contains(seatIndex.toString())) {
        for (final element in seatList) {
          if (element.seatIndex == seatIndex) {
            element.currentUser.value = null;
          }
        }
      }
    }
    return result;
  }

  Future<ZIMRoomAttributesOperatedCallResult?> removeSpeakerFromSeat(String userID) async {
    for (final seat in seatList) {
      if (seat.currentUser.value?.userID == userID) {
        final result = await leaveSeat(seat.seatIndex);
        return result;
      }
    }
    return null;
  }

  void unInit() {
    for (final subscription in subscriptions) {
      subscription.cancel();
    }
    subscriptions.clear();
  }

  void clear() {
    seatList.clear();
    isBatchOperation = false;
    unInit();
  }

  void onRoomUserListUpdate(ZegoRoomUserListUpdateEvent event) {
    if (event.updateType == ZegoUpdateType.Add) {
      final userIDList = <String>[];
      for (final element in event.userList) {
        userIDList.add(element.userID);
        ZEGOSDKManager.instance.zimService.roomAttributesMap.forEach((key, value) {
          if (element.userID == value) {
            for (final seat in seatList) {
              if (seat.seatIndex.toString() == key) {
                seat.currentUser.value = ZEGOSDKManager.instance.getUser(value);
                break;
              }
            }
          }
        });
      }
    } else {
      // empty seat
    }
  }

  void onRoomAttributeBatchUpdate(ZIMServiceRoomAttributeBatchUpdatedEvent event) {
    event.updateInfos.forEach(_onRoomAttributeUpdate);
  }

  void onRoomAttributeUpdate(ZIMServiceRoomAttributeUpdateEvent event) {
    _onRoomAttributeUpdate(event.updateInfo);
  }

  void _onRoomAttributeUpdate(ZIMRoomAttributesUpdateInfo updateInfo) {
    if (updateInfo.action == ZIMRoomAttributesUpdateAction.set) {
      updateInfo.roomAttributes.forEach((key, value) {
        for (final element in seatList) {
          if (element.seatIndex.toString() == key) {
            if (value == ZEGOSDKManager.instance.currentUser?.userID) {
              element.currentUser.value = ZEGOSDKManager.instance.currentUser;
            } else {
              element.currentUser.value = ZEGOSDKManager.instance.getUser(value);
            }
          }
        }
      });
    } else {
      updateInfo.roomAttributes.forEach((key, value) {
        for (final element in seatList) {
          if (element.seatIndex.toString() == key) {
            element.currentUser.value = null;
            updateCurrentUserRole();
          }
        }
      });
    }
  }

  void updateCurrentUserRole() {
    var isFindSelf = false;
    for (final seat in seatList) {
      if (seat.currentUser.value != null && seat.currentUser.value?.userID == ZEGOSDKManager().currentUser?.userID) {
        isFindSelf = true;
        break;
      }
    }
    final liveAudioRoomManager = ZegoLiveAudioRoomManager();
    if (isFindSelf) {
      if (liveAudioRoomManager.roleNoti.value != ZegoLiveRole.host) {
        liveAudioRoomManager.roleNoti.value = ZegoLiveRole.coHost;
      }
    } else {
      liveAudioRoomManager.roleNoti.value = ZegoLiveRole.audience;
      ZEGOSDKManager().expressService.stopPublishingStream();
    }
  }
}
