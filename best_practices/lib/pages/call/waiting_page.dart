import 'dart:async';

import 'package:flutter/material.dart';

import '../../components/call/zego_accept_button.dart';
import '../../components/call/zego_cancel_button.dart';
import '../../components/call/zego_defines.dart';
import '../../components/call/zego_reject_button.dart';
import '../../internal/business/call/call_data.dart';
import '../../zego_sdk_manager.dart';

class CallWaitingPage extends StatefulWidget {
  const CallWaitingPage({required this.callData, super.key});

  final ZegoCallData callData;

  @override
  State<CallWaitingPage> createState() => _CallWaitingPageState();
}

class _CallWaitingPageState extends State<CallWaitingPage> {
  List<StreamSubscription<dynamic>?> subscriptions = [];

  @override
  void initState() {
    super.initState();

    subscriptions.addAll([
      ZEGOSDKManager
          .instance.zimService.outgoingUserRequestRejectedStreamCtrl.stream
          .listen(onOutgoingCallInvitationRejected),
      ZEGOSDKManager
          .instance.zimService.outgoingUserRequestAcceptedStreamCtrl.stream
          .listen(
        onOutgoingCallInvitationAccepted,
      ),
      ZEGOSDKManager
          .instance.zimService.outgoingUserRequestTimeoutStreamCtrl.stream
          .listen(
        onOutgoingCallInvitationTimeout,
      ),
      ZEGOSDKManager
          .instance.zimService.incomingUserRequestCancelledStreamCtrl.stream
          .listen(
        onIncomingCallInvitationCanceled,
      ),
      ZEGOSDKManager
          .instance.zimService.incomingUserRequestTimeoutStreamCtrl.stream
          .listen(
        onIncomingCallInvitationTimeout,
      ),
    ]);

    if (widget.callData.callType == ZegoCallType.video) {
      ZEGOSDKManager.instance.expressService.startPreview();
    }
  }

  void onOutgoingCallInvitationRejected(
      OutgoingUserRequestRejectedEvent event) {
    Navigator.pop(context);
  }

  void onOutgoingCallInvitationTimeout(OutgoingUserRequestTimeoutEvent event) {
    Navigator.pop(context);
  }

  Future<void> onOutgoingCallInvitationAccepted(
      OutgoingUserRequestAcceptedEvent event) async {
    pushToCallingPage();
  }

  void onIncomingCallInvitationCanceled(
      IncomingUserRequestCancelledEvent event) {
    Navigator.pop(context);
  }

  void onIncomingCallInvitationTimeout(IncomingUserRequestTimeoutEvent event) {
    Navigator.pop(context);
  }

  @override
  void dispose() {
    super.dispose();
    for (final subscription in subscriptions) {
      subscription?.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: SafeArea(
        child: Scaffold(
          body: Stack(
            children: (widget.callData.callType == ZegoCallType.video)
                ? [
                    videoView(),
                    buttonView(),
                  ]
                : [buttonView()],
          ),
        ),
      ),
    );
  }

  Widget buttonView() {
    if (widget.callData.inviter.userID ==
        ZEGOSDKManager.instance.currentUser?.userID) {
      return LayoutBuilder(builder: (context, containers) {
        return Padding(
          padding: EdgeInsets.only(
              left: 0, right: 0, top: containers.maxHeight - 70),
          child: Container(
            padding: const EdgeInsets.only(left: 0, right: 0, bottom: 0),
            height: 70,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                cancelCallButton(),
              ],
            ),
          ),
        );
      });
    } else {
      return LayoutBuilder(builder: (context, containers) {
        return Padding(
          padding: EdgeInsets.only(
              left: 0, right: 0, top: containers.maxHeight - 70),
          child: Container(
            padding: const EdgeInsets.only(left: 0, right: 0, bottom: 0),
            height: 70,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                declineCallButton(),
                acceptCallButton(),
              ],
            ),
          ),
        );
      });
    }
  }

  Widget videoView() {
    return ValueListenableBuilder<Widget?>(
        valueListenable: ZEGOSDKManager.instance.getVideoViewNotifier(null),
        builder: (context, view, _) {
          if (view != null) {
            return view;
          } else {
            return Container(
              padding: const EdgeInsets.all(0),
              color: Colors.black,
            );
          }
        });
  }

  Widget cancelCallButton() {
    return SizedBox(
      width: 50,
      height: 50,
      child: ZegoCancelButton(
        onPressed: cancelCall,
      ),
    );
  }

  Future<void> cancelCall() async {
    ZEGOSDKManager.instance.zimService.cancelInvitation(
      invitationID: widget.callData.callID,
      invitees: [widget.callData.invitee.userID],
    );
    Navigator.pop(context);
  }

  Widget acceptCallButton() {
    return SizedBox(
      width: 50,
      height: 50,
      child: ZegoAcceptButton(
        icon: ButtonIcon(
          icon: (widget.callData.callType == ZegoCallType.video)
              ? const Image(image: AssetImage('assets/icons/invite_video.png'))
              : const Image(image: AssetImage('assets/icons/invite_voice.png')),
        ),
        onPressed: acceptCall,
      ),
    );
  }

  Future<void> acceptCall() async {
    ZEGOSDKManager.instance.zimService
        .acceptUserRequest(widget.callData.callID)
        .then((value) {
      pushToCallingPage();
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('accept call invitation failed: $error')),
      );
    });
  }

  Widget declineCallButton() {
    return SizedBox(
      width: 50,
      height: 50,
      child: ZegoRejectButton(onPressed: declineCall),
    );
  }

  Future<void> declineCall() async {
    ZEGOSDKManager.instance.zimService
        .rejectUserRequest(widget.callData.callID)
        .then((value) {
      Navigator.pop(context);
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('reject call invitation failed: $error')),
      );
    });
  }

  void pushToCallingPage() {
    ZEGOSDKManager.instance.expressService.stopPreview();
    if (ZegoCallStateManager.instance.callData != null) {
      ZegoUserInfo otherUser;
      if (ZegoCallStateManager.instance.callData!.inviter.userID !=
          ZEGOSDKManager.instance.localUser.userID) {
        otherUser = ZegoCallStateManager.instance.callData!.inviter;
      } else {
        otherUser = ZegoCallStateManager.instance.callData!.invitee;
      }
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => CallingPage(
              callData: ZegoCallStateManager.instance.callData!,
              otherUserInfo: otherUser),
        ),
      );
    }
  }
}
