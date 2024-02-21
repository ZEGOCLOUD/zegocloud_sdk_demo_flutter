import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../zego_live_streaming_manager.dart';
import '../../zego_sdk_manager.dart';
import 'live_page.dart';

extension ZegoLiveStreamingPKBattleManagerEventConv on ZegoLivePageState {
  void listenPKEvents() {
    subscriptions.addAll([
      liveStreamingManager.onPKBattleReceived.stream.listen(onPKRequestReceived),
      liveStreamingManager.onPKBattleCancelStreamCtrl.stream.listen(onPKRequestCancelled),
      liveStreamingManager.onPKBattleRejectedStreamCtrl.stream.listen(onPKRequestRejected),
      liveStreamingManager.incomingPKRequestTimeoutStreamCtrl.stream.listen(onIncomingPKRequestTimeout),
      liveStreamingManager.outgoingPKRequestAnsweredTimeoutStreamCtrl.stream.listen(onOutgoingPKRequestTimeout),
      liveStreamingManager.onPKStartStreamCtrl.stream.listen(onPKStart),
      liveStreamingManager.onPKEndStreamCtrl.stream.listen(onPKEnd),
      liveStreamingManager.onPKUserConnectingCtrl.stream.listen(onPKUserConnecting),
    ]);
  }

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
      if (event.userID != ZEGOSDKManager().currentUser!.userID) {
        liveStreamingManager.removeUserFromPKBattle(event.userID);
      } else {
        liveStreamingManager.quitPKBattle();
      }
    }
  }

  void onPKStart(dynamic event) {
    //stop cohost
    if (!ZegoLiveStreamingManager().iamHost()) {
      liveStreamingManager.endCoHost();
    }
    if (ZegoLiveStreamingManager().iamHost()) {
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

  void showPKDialog(String requestID) {
    if (showingPKDialog) {
      return;
    }
    showingPKDialog = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return CupertinoAlertDialog(
          title: const Text('receive pk invitation'),
          actions: [
            CupertinoDialogAction(
              child: const Text('Disagree'),
              onPressed: () {
                liveStreamingManager.rejectPKStartRequest(requestID);
                Navigator.pop(context);
              },
            ),
            CupertinoDialogAction(
              child: const Text('Agree'),
              onPressed: () {
                liveStreamingManager.acceptPKStartRequest(requestID);
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    ).whenComplete(() => showingPKDialog = false);
  }
}
