import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../zego_live_streaming_manager.dart';
import '../../zego_sdk_manager.dart';
import 'live_page.dart';

extension ZegoLiveStreamingPKBattleManagerEventConv on ZegoLivePageState {
  void listenPKEvents() {
    subscriptions.addAll([
      ZegoLiveStreamingManager().onPKBattleReceived.stream.listen(onPKRequestReceived),
      ZegoLiveStreamingManager().onPKBattleCancelStreamCtrl.stream.listen(onPKRequestCancelled),
      ZegoLiveStreamingManager().onPKBattleRejectedStreamCtrl.stream.listen(onPKRequestRejected),
      ZegoLiveStreamingManager().incomingPKRequestTimeoutStreamCtrl.stream.listen(onIncomingPKRequestTimeout),
      ZegoLiveStreamingManager().outgoingPKRequestAnsweredTimeoutStreamCtrl.stream.listen(onOutgoingPKRequestTimeout),
      ZegoLiveStreamingManager().onPKStartStreamCtrl.stream.listen(onPKStart),
      ZegoLiveStreamingManager().onPKEndStreamCtrl.stream.listen(onPKEnd),
      ZegoLiveStreamingManager().onPKUserConnectingCtrl.stream.listen(onPKUserConnecting),
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
        ZegoLiveStreamingManager().removeUserFromPKBattle(event.userID);
      } else {
        ZegoLiveStreamingManager().quitPKBattle();
      }
    }
  }

  void onPKStart(dynamic event) {
    //stop cohost
    if (!ZegoLiveStreamingManager().iamHost()) {
      ZegoLiveStreamingManager().endCoHost();
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
                ZegoLiveStreamingManager().rejectPKStartRequest(requestID);
                Navigator.pop(context);
              },
            ),
            CupertinoDialogAction(
              child: const Text('Agree'),
              onPressed: () {
                ZegoLiveStreamingManager().acceptPKStartRequest(requestID);
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    ).whenComplete(() => showingPKDialog = false);
  }
}
