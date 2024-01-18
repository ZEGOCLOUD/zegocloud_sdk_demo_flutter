import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../../components/call/zego_call_invitation_dialog.dart';
import '../../main.dart';
import '../../zego_call_manager.dart';
import '../../zego_sdk_manager.dart';
import 'calling_page.dart';
import 'waiting_page.dart';

class ZegoCallController {
  ZegoCallController._internal();
  factory ZegoCallController() => instance;
  static final ZegoCallController instance = ZegoCallController._internal();

  List<StreamSubscription> subscriptions = [];

  bool dialogIsShowing = false;
  bool waitingPageIsShowing = false;
  bool callingPageIsShowing = false;

  BuildContext get context => navigatorKey.currentState!.overlay!.context;

  void initService() {
    final callManager = ZegoCallManager();
    subscriptions.addAll([
      callManager.incomingCallInvitationReceivedStreamCtrl.stream.listen(onIncomingCallInvitationReceived),
      callManager.incomingCallInvitationTimeoutStreamCtrl.stream.listen(onIncomingCallInvitationTimeout),
      callManager.onCallStartStreamCtrl.stream.listen(onCallStart),
      callManager.onCallEndStreamCtrl.stream.listen(onCallEnd),
    ]);
  }

  void onIncomingCallInvitationReceived(IncomingCallInvitationReceivedEvent event) {
    final extendedData = jsonDecode(event.info.extendedData);
    if (extendedData is Map && extendedData.containsKey('type')) {
      final callType = extendedData['type'];
      if (ZegoCallManager().isCallBusiness(callType)) {
        final inRoom = ZEGOSDKManager().expressService.currentRoomID.isNotEmpty;
        if (inRoom || (ZegoCallManager().currentCallData?.callID != event.callID)) {
          final rejectExtendedData = {'type': callType, 'reason': 'busy', 'callID': event.callID};
          ZegoCallManager().rejectCallInvitationCauseBusy(event.callID, jsonEncode(rejectExtendedData), callType);
          return;
        }
        dialogIsShowing = true;
        showTopModalSheet(
          context,
          GestureDetector(
            onTap: onIncomingCallDialogClicked,
            child: ZegoCallInvitationDialog(
              invitationData: ZegoCallManager().currentCallData!,
              onAcceptCallback: acceptCall,
              onRejectCallback: rejectCall,
            ),
          ),
          barrierDismissible: false,
        );
      }
    }
  }

  void onIncomingCallInvitationTimeout(IncomingUserRequestTimeoutEvent event) {
    hideIncomingCallDialog();
    hidenWatingPage();
  }

  void onCallStart(dynamic event) {
    hidenWatingPage();
    pushToCallingPage();
  }

  void onCallEnd(dynamic event) {
    hideIncomingCallDialog();
    hidenWatingPage();
    hidenCallingPage();
  }

  Future<void> acceptCall() async {
    hideIncomingCallDialog();
    ZegoCallManager().acceptCallInvitation(ZegoCallManager().currentCallData!.callID);
  }

  Future<void> rejectCall() async {
    hideIncomingCallDialog();
    ZegoCallManager().rejectCallInvitation(ZegoCallManager().currentCallData!.callID);
  }

  Future<T?> showTopModalSheet<T>(BuildContext context, Widget widget, {bool barrierDismissible = true}) {
    return showGeneralDialog<T?>(
      context: context,
      barrierDismissible: barrierDismissible,
      transitionDuration: const Duration(milliseconds: 250),
      barrierLabel: MaterialLocalizations.of(context).dialogLabel,
      barrierColor: Colors.black.withOpacity(0.5),
      pageBuilder: (context, _, __) => SafeArea(
          child: Column(
        children: [
          const SizedBox(height: 16),
          widget,
        ],
      )),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)
              .drive(Tween<Offset>(begin: const Offset(0, -1.0), end: Offset.zero)),
          child: child,
        );
      },
    );
  }

  void onIncomingCallDialogClicked() {
    hideIncomingCallDialog();
    pushToCallWaitingPage();
  }

  void hideIncomingCallDialog() {
    if (dialogIsShowing) {
      dialogIsShowing = false;
      final context = navigatorKey.currentState!.overlay!.context;
      Navigator.of(context).pop();
    }
  }

  void pushToCallWaitingPage() {
    waitingPageIsShowing = true;
    final context = navigatorKey.currentState!.overlay!.context;
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => CallWaitingPage(callData: ZegoCallManager().currentCallData!),
      ),
    );
  }

  void hidenWatingPage() {
    if (waitingPageIsShowing) {
      waitingPageIsShowing = false;
      final context = navigatorKey.currentState!.overlay!.context;
      Navigator.of(context).pop();
    }
  }

  void pushToCallingPage() {
    if (ZegoCallManager().currentCallData != null) {
      callingPageIsShowing = true;
      Navigator.push(
        context,
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (context) => CallingPage(callData: ZegoCallManager().currentCallData!),
        ),
      );
    }
  }

  void hidenCallingPage() {
    if (callingPageIsShowing) {
      callingPageIsShowing = false;
      final context = navigatorKey.currentState!.overlay!.context;
      Navigator.of(context).pop();
    }
  }
}
