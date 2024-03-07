import 'dart:async';

import 'package:flutter/material.dart';

import '../../components/components.dart';
import '../../zego_call_manager.dart';
import 'call_controller.dart';

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
                    backgroundImage(),
                    videoView(),
                    headView(),
                    buttonView(),
                  ]
                : [backgroundImage(), headView(), buttonView()],
          ),
        ),
      ),
    );
  }

  Widget headView() {
    CallUserInfo? user;
    if (widget.callData.inviter.userID == ZEGOSDKManager().currentUser?.userID) {
      user = widget.callData.inviter;
    } else {
      user = widget.callData.callUserList
          .where((element) => element.userID != widget.callData.inviter.userID)
          .toList()
          .first;
    }
    if (user.headUrl != null) {
      return Center(
        child: SizedBox(
          width: 60,
          height: 60,
          child: Image.network(user.headUrl!),
        ),
      );
    } else {
      return Center(
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.grey,
            borderRadius: const BorderRadius.all(Radius.circular(30.0)),
            border: Border.all(width: 0),
          ),
          child: Center(
            child: SizedBox(
                height: 20,
                child: Text(
                  (user.userName != null) ? user.userName![0] : user.userID[0],
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                )),
          ),
        ),
      );
    }
  }

  Widget backgroundImage() {
    return Image.asset(
      'assets/icons/bg.png',
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.fill,
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
                endCallButton(),
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

  Widget endCallButton() {
    return SizedBox(
      width: 50,
      height: 50,
      child: ZegoCancelButton(
        onPressed: endCall,
      ),
    );
  }

  Future<void> endCall() async {
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
