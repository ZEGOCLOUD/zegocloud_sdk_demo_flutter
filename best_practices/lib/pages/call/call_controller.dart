import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';

import '../../internal/business/call/call_data.dart';
import '../../main.dart';
import 'calling_page.dart';
import 'waiting_page.dart';
import '../../zego_call_manager.dart';
import '../../zego_sdk_manager.dart';
import '../../components/call/zego_call_invitation_dialog.dart';

class ZegoCallController {
  ZegoCallController._internal();
  factory ZegoCallController() => instance;
  static final ZegoCallController instance = ZegoCallController._internal();

  List<StreamSubscription> subscriptions = [];

  bool dialogIsShowing = false;

  BuildContext get context => navigatorKey.currentState!.overlay!.context;

  void initService() {
    final zimService = ZEGOSDKManager().zimService;
    subscriptions.addAll([
      ZegoCallManager().incomingCallInvitationReceivedStreamCtrl.stream.listen(onIncomingCallInvitationReceived),
      zimService.incomingUserRequestCancelledStreamCtrl.stream.listen(onIncomingCallInvitationCanceled),
      zimService.incomingUserRequestTimeoutStreamCtrl.stream.listen(onIncomingCallInvitationTimeout),
    ]); 
  }

  void onIncomingCallInvitationReceived(IncomingCallInvitationReceivedEvent event) {
    final extendedData = jsonDecode(event.info.extendedData);
    if (extendedData is Map && extendedData.containsKey('type')) {
      final callType = extendedData['type'];
      if (ZegoCallManager().isCallBusiness(callType)) {
        final type = callType == 0 ? ZegoCallType.voice : ZegoCallType.video;
        final inRoom = ZEGOSDKManager().expressService.currentRoomID.isNotEmpty;
        if (inRoom || (ZegoCallManager().callData?.callID != event.callID)) {
          final rejectExtendedData = {'type': type.index, 'reason': 'busy', 'callID': event.callID};
          ZegoCallManager().busyRejectCallRequest(event.callID, jsonEncode(rejectExtendedData), type);
          return;
        }
        dialogIsShowing = true;
        showTopModalSheet(
          context,
          GestureDetector(
            onTap: onIncomingCallDialogClicked,
            child: ZegoCallInvitationDialog(
              invitationData: ZegoCallManager().callData!,
              onAcceptCallback: acceptCall,
              onRejectCallback: rejectCall,
            ),
          ),
          barrierDismissible: false,
        );
      }
    }
  }

  void onIncomingCallInvitationCanceled(IncomingUserRequestCancelledEvent event) {
    hideIncomingCallDialog();
  }

  void onIncomingCallInvitationTimeout(IncomingUserRequestTimeoutEvent event) {
    hideIncomingCallDialog();
  }

  Future<void> acceptCall() async {
    hideIncomingCallDialog();
    ZegoCallManager().acceptCallRequest(ZegoCallManager().callData!.callID).then((value) {
      pushToCallingPage();
    });
  }

  Future<void> rejectCall() async {
    hideIncomingCallDialog();
    ZegoCallManager().rejectCallRequest(ZegoCallManager().callData!.callID);
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
    final context = navigatorKey.currentState!.overlay!.context;
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => CallWaitingPage(callData: ZegoCallManager().callData!),
      ),
    );
  }

  void pushToCallingPage() {
    if (ZegoCallManager().callData != null) {
      ZegoSDKUser otherUser;
      if (ZegoCallManager().callData!.inviter.userID != ZEGOSDKManager.instance.currentUser?.userID) {
        otherUser = ZegoCallManager().callData!.inviter;
      } else {
        otherUser = ZegoCallManager().callData!.invitee;
      }
      Navigator.push(
        context,
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (context) => CallingPage(callData: ZegoCallManager().callData!, otherUserInfo: otherUser),
        ),
      );
    }
  }
}
