import 'package:flutter/material.dart';

import '../../zego_call_manager.dart';
import 'zego_accept_button.dart';
import 'zego_defines.dart';
import 'zego_reject_button.dart';

class ZegoCallInvitationDialog extends StatefulWidget {
  const ZegoCallInvitationDialog({
    required this.invitationData,
    required this.onRejectCallback,
    required this.onAcceptCallback,
    super.key,
  });

  final ZegoCallData invitationData;

  final Function() onRejectCallback;
  final Function() onAcceptCallback;

  @override
  ZegoCallInvitationDialogState createState() => ZegoCallInvitationDialogState();
}

class ZegoCallInvitationDialogState extends State<ZegoCallInvitationDialog> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, containers) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        width: containers.maxWidth - 20,
        height: 100.0,
        decoration: BoxDecoration(
          color: const Color(0xff333333).withOpacity(0.8),
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: contentView(),
      );
    });
  }

  Widget contentView() {
    return Stack(
      children: [
        Positioned(
          left: 5,
          top: 20,
          width: 60,
          height: 60,
          child: headContainer(),
        ),
        Positioned(
          left: 70,
          top: 20,
          width: 100,
          height: 20,
          child: userNameText(),
        ),
        Positioned(
          left: 70,
          bottom: 20,
          width: 100,
          height: 20,
          child: callTypeText(),
        ),
        Positioned(
          right: 55,
          top: 30,
          width: 40,
          height: 40,
          child: rejectButton(),
        ),
        Positioned(
          right: 5,
          top: 30,
          width: 40,
          height: 40,
          child: acceptButton(),
        ),
      ],
    );
  }

  Widget headContainer() {
    return Container(
      width: 60,
      height: 60,
      decoration: const BoxDecoration(
        color: Colors.grey,
        borderRadius: BorderRadius.all(Radius.circular(30)),
      ),
      child: headView(),
    );
  }

  Widget headView() {
    if (widget.invitationData.inviter.headUrl == null) {
      return Center(
        child: SizedBox(
            child: Text(
          widget.invitationData.inviter.userName != null
              ? widget.invitationData.inviter.userName![0]
              : widget.invitationData.inviter.userID[0],
          textAlign: TextAlign.center,
          style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, decoration: TextDecoration.none, color: Colors.black),
        )),
      );
    } else {
      return Image.network(widget.invitationData.inviter.headUrl!);
    }
  }

  Widget userNameText() {
    return SizedBox(
        width: 100,
        height: 20,
        child: Text(
          widget.invitationData.inviter.userName != null
              ? widget.invitationData.inviter.userName!
              : widget.invitationData.inviter.userID,
          style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.normal, decoration: TextDecoration.none, color: Colors.grey),
        ));
  }

  Widget callTypeText() {
    return Text(
      widget.invitationData.callType == VIDEO_Call ? 'video call' : 'voice call',
      textAlign: TextAlign.left,
      style: const TextStyle(
        fontSize: 16,
        color: Colors.grey,
        fontWeight: FontWeight.normal,
        decoration: TextDecoration.none,
      ),
    );
  }

  Widget acceptButton() {
    return SizedBox(
      width: 40,
      height: 40,
      child: ZegoAcceptButton(
        icon: (widget.invitationData.callType == VIDEO_Call)
            ? ButtonIcon(icon: const Image(image: AssetImage('assets/icons/invite_video.png')))
            : ButtonIcon(icon: const Image(image: AssetImage('assets/icons/invite_voice.png'))),
        iconSize: const Size(40, 40),
        onPressed: widget.onAcceptCallback,
      ),
    );
  }

  Widget rejectButton() {
    return SizedBox(
      width: 40,
      height: 40,
      child: ZegoRejectButton(
        iconSize: const Size(40, 40),
        onPressed: widget.onRejectCallback,
      ),
    );
  }
}
