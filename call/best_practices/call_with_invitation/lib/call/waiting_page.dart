import 'dart:async';
import 'package:call_with_invitation/call/calling_page.dart';
import 'package:call_with_invitation/components/zego_accept_button.dart';
import 'package:call_with_invitation/components/zego_cancel_button.dart';
import 'package:call_with_invitation/components/zego_defines.dart';
import 'package:call_with_invitation/components/zego_reject_button.dart';
import 'package:call_with_invitation/interal/zim/call_data_manager.dart';
import 'package:call_with_invitation/zego_sdk_manager.dart';
import 'package:flutter/material.dart';
import 'package:call_with_invitation/interal/zim/zim_service_defines.dart';
import 'package:call_with_invitation/zego_user_Info.dart';

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
      ZEGOSDKManager.instance.zimService.outgoingCallInvitationRejectedStreamCtrl.stream.listen(
        onOutgoingCallInvitationRejected,
      ),
      ZEGOSDKManager.instance.zimService.outgoingCallInvitationAcceptedStreamCtrl.stream.listen(
        onOutgoingCallInvitationAccepted,
      ),
      ZEGOSDKManager.instance.zimService.outgoingCallInvitationTimeoutStreamCtrl.stream.listen(
        onOutgoingCallInvitationTimeout,
      ),
      ZEGOSDKManager.instance.zimService.incomingCallInvitationCanceledStreamCtrl.stream.listen(
        onIncomingCallInvitationCanceled,
      ),

      ZEGOSDKManager.instance.zimService.incomingCallInvitationTimeoutStreamCtrl.stream.listen(
        onIncomingCallInvitationTimeout,
      ),
    ]);

    if (widget.callData.callType == ZegoCallType.video) {
      ZEGOSDKManager.instance.expressService.startPreview();
    }
  }

  void onOutgoingCallInvitationRejected(OutgoingCallInvitationRejectedEvent event) {
    Navigator.pop(context);
  }




  void onOutgoingCallInvitationTimeout(OutgoingCallInvitationTimeoutEvent event) {
    Navigator.pop(context);
  }

  Future<void> onOutgoingCallInvitationAccepted(OutgoingCallInvitationAcceptedEvent event) async {
    pushToCallingPage();
  }

  void onIncomingCallInvitationCanceled(IncomingCallInvitationCanceledEvent event) {
    Navigator.pop(context);
  }
    void onIncomingCallInvitationTimeout(IncomingCallInvitationTimeoutEvent event) {
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
    if (widget.callData.inviter.userID == ZEGOSDKManager.instance.localUser.userID) {
      return LayoutBuilder(builder: (context, containers) {
        return Padding(
          padding: EdgeInsets.only(left: 0, right: 0, top: containers.maxHeight - 70),
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
          padding: EdgeInsets.only(left: 0, right: 0, top: containers.maxHeight - 70),
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
    final ZegoResponseInvitationResult result =
        await ZEGOSDKManager.instance.zimService.acceptInvitation(invitationID: widget.callData.callID);
    if (result.error == null || result.error?.code == '0') {
      pushToCallingPage();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('accept call invitation failed: $result')),
      );
    }
  }

  Widget declineCallButton() {
    return SizedBox(
      width: 50,
      height: 50,
      child: ZegoRejectButton(onPressed: declineCall),
    );
  }

  Future<void> declineCall() async {
    await ZEGOSDKManager.instance.zimService.rejectInvitation(invitationID: widget.callData.callID);
    Navigator.pop(context);
  }

  void pushToCallingPage() {
    ZEGOSDKManager.instance.expressService.stopPreview();
    if (ZegoCallStateManager.instance.callData != null) {
      ZegoUserInfo otherUser;
      if (ZegoCallStateManager.instance.callData!.inviter.userID != ZEGOSDKManager.instance.localUser.userID) {
        otherUser = ZegoCallStateManager.instance.callData!.inviter;
      } else {
        otherUser = ZegoCallStateManager.instance.callData!.invitee;
      }
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              CallingPage(callData: ZegoCallStateManager.instance.callData!, otherUserInfo: otherUser),
        ),
      );
    }
  }
}
