import 'dart:async';

import '../../../live_audio_room_manager.dart';

class RoomSeatService {
  final seatCount = 8;
  int hostSeatIndex = 0;
  late List<ZegoLiveAudioRoomSeat> seatList = List.generate(seatCount, (index) => ZegoLiveAudioRoomSeat(index));
  bool isBatchOperation = false;

  List<StreamSubscription<dynamic>> subscriptions = [];

  void initWithConfig(ZegoLiveAudioRoomRole role) {
    final expressService = ZEGOSDKManager().expressService;
    final zimService = ZEGOSDKManager().zimService;
    subscriptions.addAll([
      expressService.roomUserListUpdateStreamCtrl.stream.listen(onRoomUserListUpdate),
      zimService.roomAttributeUpdateStreamCtrl.stream.listen(onRoomAttributeUpdate),
      zimService.roomAttributeBatchUpdatedStreamCtrl.stream.listen(onRoomAttributeBatchUpdate)
    ]);
  }

  Future<ZIMRoomAttributesOperatedCallResult?> takeSeat(int seatIndex, {bool? isForce}) async {
    final currentUserID = ZEGOSDKManager().currentUser!.userID;
    final attributes = {seatIndex.toString(): currentUserID};
    final result = await ZEGOSDKManager().zimService.setRoomAttributes(
          attributes,
          isForce: isForce ?? false,
          isUpdateOwner: true,
          isDeleteAfterOwnerLeft: true,
        );
    if (result != null) {
      if (!result.errorKeys.contains(seatIndex.toString())) {
        for (final element in seatList) {
          if (element.seatIndex == seatIndex) {
            ZEGOSDKManager()
                .zimService
                .roomRequestMapNoti
                .removeWhere((String k, RoomRequest v) => v.senderID == currentUserID);
            element.currentUser.value = ZEGOSDKManager().currentUser;
            break;
          }
        }
      }
    }
    return result;
  }

  Future<ZIMRoomAttributesBatchOperatedResult?> switchSeat(int fromSeatIndex, int toSeatIndex) async {
    if (!isBatchOperation) {
      ZEGOSDKManager().zimService.beginRoomAttributesBatchOperation(
            isForce: false,
            isUpdateOwner: true,
            isDeleteAfterOwnerLeft: true,
          );
      isBatchOperation = true;
      takeSeat(toSeatIndex);
      leaveSeat(fromSeatIndex);
      final result = await ZEGOSDKManager().zimService.endRoomPropertiesBatchOperation();
      isBatchOperation = false;
      return result;
    }
    return null;
  }

  Future<ZIMRoomAttributesOperatedCallResult?> leaveSeat(int seatIndex) async {
    final result = await ZEGOSDKManager().zimService.deleteRoomAttributes([seatIndex.toString()]);
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
        ZEGOSDKManager().zimService.roomAttributesMap.forEach((key, value) {
          if (element.userID == value) {
            for (final seat in seatList) {
              if (seat.seatIndex.toString() == key) {
                seat.currentUser.value = ZEGOSDKManager().getUser(value);
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
            if (value == ZEGOSDKManager().currentUser!.userID) {
              element.currentUser.value = ZEGOSDKManager().currentUser;
            } else {
              // Others made a request to sit, but he took the initiative to sit down on his own.
              ZIMService().roomRequestMapNoti.removeWhere((String k, RoomRequest v) => v.senderID == value);
              // update seat user.
              element.currentUser.value = ZEGOSDKManager().getUser(value);
              updateCurrentUserRole();
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
      if (seat.currentUser.value != null && seat.currentUser.value?.userID == ZEGOSDKManager().currentUser!.userID) {
        isFindSelf = true;
        break;
      }
    }
    final liveAudioRoomManager = ZegoLiveAudioRoomManager();
    if (isFindSelf) {
      if (liveAudioRoomManager.roleNoti.value != ZegoLiveAudioRoomRole.host) {
        liveAudioRoomManager.roleNoti.value = ZegoLiveAudioRoomRole.speaker;
      }
    } else {
      liveAudioRoomManager.roleNoti.value = ZegoLiveAudioRoomRole.audience;
      ZEGOSDKManager().expressService.stopPublishingStream();
    }
  }
}
