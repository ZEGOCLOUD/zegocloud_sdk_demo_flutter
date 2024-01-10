import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../../components/call/zego_accept_button.dart';
import '../../components/call/zego_cancel_button.dart';
import '../../components/call/zego_reject_button.dart';
import '../../internal/business/call/call_data.dart';
import '../../zego_call_manager.dart';
import '../../zego_sdk_manager.dart';
import 'call_controller.dart';
import 'calling_page.dart';

class CallWaitingPage extends StatefulWidget {
  const CallWaitingPage({required this.callData, super.key});

  final ZegoCallData callData;

  @override
  State<CallWaitingPage> createState() => _CallWaitingPageState();
}

class _CallWaitingPageState extends State<CallWaitingPage> {
  final callManager = ZegoCallManager();

  @override
  void initState() {
    super.initState();

    if (widget.callData.callType == VIDEO_Call) {
      ZEGOSDKManager().expressService.turnCameraOn(true);
      ZEGOSDKManager().expressService.startPreview();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: SafeArea(
        child: Scaffold(
          body: Stack(
            children: (widget.callData.callType == VIDEO_Call)
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
    if (widget.callData.inviter.userID == ZEGOSDKManager().currentUser!.userID) {
      return LayoutBuilder(builder: (context, containers) {
        return Padding(
          padding: EdgeInsets.only(left: 0, right: 0, top: containers.maxHeight - 70),
          child: Container(
            padding: EdgeInsets.zero,
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
            padding: EdgeInsets.zero,
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
        valueListenable: ZEGOSDKManager().currentUser!.videoViewNotifier,
        builder: (context, view, _) {
          if (view != null) {
            return view;
          } else {
            return Container(
              padding: EdgeInsets.zero,
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
    ZegoCallManager().endCall(widget.callData.callID);
    ZegoCallController().hidenWatingPage();
  }

  Widget acceptCallButton() {
    return SizedBox(
      width: 50,
      height: 50,
      child: ZegoAcceptButton(
        icon: ButtonIcon(
          icon: (widget.callData.callType == VIDEO_Call)
              ? const Image(image: AssetImage('assets/icons/invite_video.png'))
              : const Image(image: AssetImage('assets/icons/invite_voice.png')),
        ),
        onPressed: acceptCall,
      ),
    );
  }

  Future<void> acceptCall() async {
    ZegoCallManager().acceptCallInvitation(widget.callData.callID).then((value) {
      ZEGOSDKManager().expressService.stopPreview();
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
    ZegoCallManager().rejectCallInvitation(widget.callData.callID);
    ZegoCallController().hidenWatingPage();
  }
}
