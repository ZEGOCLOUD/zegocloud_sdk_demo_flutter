import 'package:flutter/material.dart';

import '../../internal/business/call/call_data.dart';
import 'zego_accept_button.dart';
import 'zego_defines.dart';
import 'zego_reject_button.dart';

class ZegoCallInvitationDialog extends StatefulWidget {
  const ZegoCallInvitationDialog({
    required this.invitationData,
    this.onRejectCallback,
    this.onAcceptCallback,
    super.key,
  });

  final ZegoCallData invitationData;

  final Function? onRejectCallback;
  final Function? onAcceptCallback;

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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: Container(
                alignment: Alignment.centerLeft,
                child: Column(
                  children: [
                    const SizedBox(
                      height: 20,
                    ),
                    userNameText(),
                    const SizedBox(height: 5),
                    callTypeText(),
                  ],
                ),
              ),
            ),
            const Expanded(
              flex: 2,
              child: SizedBox(
                width: 100,
              ),
            ),
            Expanded(
              flex: 2,
              child: SizedBox(
                child: Row(
                  children: [rejectButton(), const SizedBox(width: 20), acceptButton()],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget userNameText() {
    return Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(
        color: Colors.grey,
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
      child: Center(
        child: SizedBox(
            height: 20,
            child: Text(
              widget.invitationData.inviter.userName[0],
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, decoration: TextDecoration.none, color: Colors.black),
            )),
      ),
    );
  }

  Widget callTypeText() {
    return Text(
      widget.invitationData.callType == ZegoCallType.video ? 'video call' : 'voice call',
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
        icon: (widget.invitationData.callType == ZegoCallType.video)
            ? ButtonIcon(icon: const Image(image: AssetImage('assets/icons/invite_video.png')))
            : ButtonIcon(icon: const Image(image: AssetImage('assets/icons/invite_voice.png'))),
        iconSize: const Size(40, 40),
        onPressed: () {
          widget.onAcceptCallback!();
        },
      ),
    );
  }

  Widget rejectButton() {
    return SizedBox(
      width: 40,
      height: 40,
      child: ZegoRejectButton(
        iconSize: const Size(40, 40),
        onPressed: () {
          widget.onRejectCallback!();
        },
      ),
    );
  }
}
