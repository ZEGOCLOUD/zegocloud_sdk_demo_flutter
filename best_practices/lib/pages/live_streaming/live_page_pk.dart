import 'package:flutter/material.dart';
import '../../internal/sdk/zim/Define/zim_room_request.dart';
import '../../zego_live_streaming_manager.dart';
import '../../zego_sdk_manager.dart';
import 'live_page.dart';

extension ZegoLiveStreamingPKBattleManagerEventConv on ZegoLivePageState {
  void onIncomingPKRequestReceived(IncomingPKRequestEvent event) {
    showPKDialog(event.requestID);
  }

  void onOutgoingPKRequestAccepted(OutgoingPKRequestAcceptEvent event) {}

  void onOutgoingPKRequestRejected(OutgoingPKRequestRejectedEvent event) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('pk request is rejected')));
  }

  void onIncomingPKRequestCancelled(IncomingPKRequestCancelledEvent event) {
    if (showingPKDialog) {
      Navigator.pop(context);
    }
  }

  void onIncomingPKRequestTimeout(IncomingPKRequestTimeoutEvent event) {
    if (showingPKDialog) {
      Navigator.pop(context);
    }
  }

  void onOutgoingPKRequestTimeout(OutgoingPKRequestTimeoutEvent event) {}

  void onPKStart(dynamic event) {
    //stop cohost
    if (!ZegoLiveStreamingManager().isLocalUserHost()) {
      liveStreamingManager.endCoHost();
    }
    if (ZegoLiveStreamingManager().isLocalUserHost()) {
      for (final RoomRequest element in ZEGOSDKManager.instance.zimService.roomRequestMapNoti.value.values.toList()) {
        refuseApplyCohost(element);
      }
    }
  }

  void onPKEnd(dynamic event) {}
}
