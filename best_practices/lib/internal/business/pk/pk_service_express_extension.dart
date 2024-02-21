import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../zego_live_streaming_manager.dart';
import '../../../zego_sdk_manager.dart';
import '../coHost/cohost_service.dart';
import 'pk_service.dart';
import 'pk_service_zim_extension.dart';

extension PKServiceExpressExtension on PKService {
  // express
  void onReceiveStreamUpdate(ZegoRoomStreamListUpdateEvent event) {
    if (event.updateType == ZegoUpdateType.Add) {
      for (final stream in event.streamList) {
        if (isHostStreamID(stream.streamID)) {
          if (pkRoomAttribute.isNotEmpty) {
            final pkUsers = pkRoomAttribute['pk_users'];
            if (pkUsers != null && pkUsers.isNotEmpty) {
              onReceivePKRoomAttribute(pkRoomAttribute);
            }
          }
        }
      }
    }
  }

  void onRoomUserUpdate(ZegoRoomUserListUpdateEvent event) {
    if (event.updateType == ZegoUpdateType.Delete) {
      if (ZegoLiveStreamingManager().hostNotifier.value == null && pkStateNoti.value == RoomPKState.isStartPK) {
        pkStateNoti.value = RoomPKState.isNoPK;
        onPKEndStreamCtrl.add(null);
        cancelTime();
      }
    }
  }

  void onReceiveAudioFirstFrame(ZegoRecvAudioFirstFrameEvent event) {
    if (event.streamID.endsWith('_mix')) {
      muteMainStream();
      onPKViewAvaliableNoti.value = true;
    }
  }

  void onReceiveVideoFirstFrame(ZegoRecvVideoFirstFrameEvent event) {
    if (event.streamID.endsWith('_mix')) {
      muteMainStream();
      onPKViewAvaliableNoti.value = true;
    }
  }

  void muteMainStream() {
    ZEGOSDKManager().expressService.streamMap.forEach((key, value) {
      if (isHostStreamID(value)) {
        ZEGOSDKManager().expressService.mutePlayStreamAudio(value, true);
        ZEGOSDKManager().expressService.mutePlayStreamVideo(value, true);
      }
    });
  }

  void onReceiveSEIEvent(ZegoRecvSEIEvent event) {
    try {
      final jsonString = String.fromCharCodes(event.data);
      final Map<String, dynamic> seiMap = json.decode(jsonString);
      final String senderID = seiMap['sender_id'];
      seiTimeMap[senderID] = DateTime.now().millisecondsSinceEpoch;
      final isMicOpen = seiMap['mic'] as bool;
      final isCameraOpen = seiMap['cam'] as bool;

      final pkuser = getPKUser(pkInfo!, senderID);
      if (pkInfo != null && pkuser != null) {
        final micChanged = pkuser.sdkUser.isMicOnNotifier.value != isMicOpen;
        final camChanged = pkuser.sdkUser.isCamerOnNotifier.value != isCameraOpen;
        if (micChanged) {
          pkuser.sdkUser.isMicOnNotifier.value = isMicOpen;
        }
        if (camChanged) {
          pkuser.sdkUser.isCamerOnNotifier.value = isCameraOpen;
        }
      }
    } catch (e) {
      debugPrint('onReceiveSEIEvent.data: ${event.data}.');
    }
  }

  void onMixerSoundLevelUpdate(ZegoMixerSoundLevelUpdateEvent event) {
    //..
  }
}
