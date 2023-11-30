import 'package:flutter/material.dart';
import '../../internal/sdk/zim/Define/zim_room_request.dart';
import '../../zego_live_streaming_manager.dart';
import '../../zego_sdk_manager.dart';
import 'live_page.dart';

extension ZegoLiveStreamingPKBattleManagerEventConv on ZegoLivePageState {
  void onPKRequestReceived(PKBattleReceivedEvent event) {
    showPKDialog(event.requestID);
  }

  void onPKRequestRejected(PKBattleRejectedEvent event) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('pk request is rejected')));
  }

  void onPKRequestCancelled(PKBattleCancelledEvent event) {
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

  void onPKUserConnecting(PKBattleUserConnectingEvent event) {
    if (event.duration > 60000) {
      if (event.userID != ZEGOSDKManager().currentUser?.userID) {
        liveStreamingManager.removeUserFromPKBattle(event.userID);
      } else {
        liveStreamingManager.quitPKBattle();
      }
    }
  }

  void onPKStart(dynamic event) {
    //stop cohost
    if (!ZegoLiveStreamingManager().isLocalUserHost()) {
      liveStreamingManager.endCoHost();
    }
    if (ZegoLiveStreamingManager().isLocalUserHost()) {
      ZEGOSDKManager().zimService.roomRequestMapNoti.value.values.toList().forEach((element) {
        refuseApplyCohost(element);
      });
    }
  }

  void onPKEnd(dynamic event) {
    if (showingPKDialog) {
      Navigator.pop(context);
    }
  }
}
