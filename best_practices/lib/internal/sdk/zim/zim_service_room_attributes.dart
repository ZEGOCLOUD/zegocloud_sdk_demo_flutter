part of 'zim_service.dart';

extension ZIMServiceRoom on ZIMService {
  Future<ZIMRoomAttributesOperatedCallResult?> setRoomAttributes(Map<String, String> attributes,
      {bool isForce = false, bool isUpdateOwner = false, bool isDeleteAfterOwnerLeft = false}) async {
    if (ZIM.getInstance() != null) {
      final result = await ZIM.getInstance()!.setRoomAttributes(
            attributes,
            currentRoomID ?? '',
            ZIMRoomAttributesSetConfig()
              ..isForce = isForce
              ..isUpdateOwner = isUpdateOwner
              ..isDeleteAfterOwnerLeft = isDeleteAfterOwnerLeft,
          );
      if (result.errorKeys.isEmpty) {
        roomAttributesMap.addAll(attributes);
      }
      return result;
    } else {
      return null;
    }
  }

  void beginRoomAttributesBatchOperation(
      {bool isForce = false, bool isUpdateOwner = false, bool isDeleteAfterOwnerLeft = false}) {
    ZIM.getInstance()?.beginRoomAttributesBatchOperation(
          currentRoomID ?? '',
          ZIMRoomAttributesBatchOperationConfig()
            ..isForce = isForce
            ..isDeleteAfterOwnerLeft = isUpdateOwner
            ..isUpdateOwner = isDeleteAfterOwnerLeft,
        );
  }

  Future<ZIMRoomAttributesBatchOperatedResult?> endRoomPropertiesBatchOperation() async {
    return ZIM.getInstance()?.endRoomAttributesBatchOperation(currentRoomID ?? '');
  }

  Future<ZIMRoomAttributesOperatedCallResult?> deleteRoomAttributes(List<String> keys) async {
    if (ZIM.getInstance() != null) {
      final result = await ZIM.getInstance()!.deleteRoomAttributes(
            keys,
            currentRoomID ?? '',
            ZIMRoomAttributesDeleteConfig()..isForce = true,
          );
      final tempKeys = List<String>.from(keys);
      if (result.errorKeys.isNotEmpty) {
        tempKeys.removeWhere((element) {
          return result.errorKeys.contains(element);
        });
      }
      tempKeys.forEach(roomAttributesMap.remove);
      return result;
    } else {
      return null;
    }
  }

  void onRoomAttributesUpdated(ZIM zim, ZIMRoomAttributesUpdateInfo updateInfo, String roomID) {
    updateInfo.roomAttributes.forEach((key, value) {
      if (updateInfo.action == ZIMRoomAttributesUpdateAction.set) {
        roomAttributesMap[key] = value;
      } else {
        roomAttributesMap.remove(key);
      }
    });
    roomAttributeUpdateStreamCtrl.add(ZIMServiceRoomAttributeUpdateEvent(updateInfo: updateInfo));
  }

  void onRoomAttributesBatchUpdated(_, List<ZIMRoomAttributesUpdateInfo> updateInfo, String roomID) {
    for (final info in updateInfo) {
      info.roomAttributes.forEach((key, value) {
        if (info.action == ZIMRoomAttributesUpdateAction.set) {
          roomAttributesMap[key] = value;
        } else {
          roomAttributesMap.remove(key);
        }
      });
    }

    roomAttributeBatchUpdatedStreamCtrl.add(ZIMServiceRoomAttributeBatchUpdatedEvent(roomID, updateInfo));
  }
}
