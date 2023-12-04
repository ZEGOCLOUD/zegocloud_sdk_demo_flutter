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
            ..isDeleteAfterOwnerLeft = isDeleteAfterOwnerLeft
            ..isUpdateOwner = isUpdateOwner,
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
    final setProperties = <Map<String, String>>[];
    final deleteProperties = <Map<String, String>>[];
    if (updateInfo.action == ZIMRoomAttributesUpdateAction.set) {
      setProperties.add(updateInfo.roomAttributes);
    } else {
      deleteProperties.add(updateInfo.roomAttributes);
    }

    updateInfo.roomAttributes.forEach((key, value) {
      if (updateInfo.action == ZIMRoomAttributesUpdateAction.set) {
        roomAttributesMap[key] = value;
      } else {
        roomAttributesMap.remove(key);
      }
    });
    roomAttributeUpdateStreamCtrl.add(ZIMServiceRoomAttributeUpdateEvent(updateInfo: updateInfo));
    roomAttributeUpdateStreamCtrl2.add(RoomAttributesUpdatedEvent(setProperties, deleteProperties));
  }

  void onRoomAttributesBatchUpdated(_, List<ZIMRoomAttributesUpdateInfo> updateInfo, String roomID) {
    final setProperties = <Map<String, String>>[];
    final deleteProperties = <Map<String, String>>[];
    for (final info in updateInfo) {
      if (info.action == ZIMRoomAttributesUpdateAction.set) {
        setProperties.add(info.roomAttributes);
        info.roomAttributes.forEach((key, value) {
          roomAttributesMap[key] = value;
        });
      } else {
        deleteProperties.add(info.roomAttributes);
        info.roomAttributes.forEach((key, value) {
          roomAttributesMap.remove(key);
        });
      }
    }
    roomAttributeUpdateStreamCtrl2.add(RoomAttributesUpdatedEvent(setProperties, deleteProperties));
    roomAttributeBatchUpdatedStreamCtrl.add(ZIMServiceRoomAttributeBatchUpdatedEvent(roomID, updateInfo));
  }
}
