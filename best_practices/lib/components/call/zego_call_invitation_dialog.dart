import 'package:call_with_invitation/components/zego_accept_button.dart';
import 'package:call_with_invitation/components/zego_defines.dart';
import 'package:call_with_invitation/components/zego_reject_button.dart';
import 'package:call_with_invitation/interal/zim/call_data_manager.dart';
import 'package:call_with_invitation/interal/zim/zim_service_defines.dart';
import 'package:flutter/material.dart';

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
        width: containers.maxWidth,
        height: 100.0,
        decoration: BoxDecoration(
          color: const Color(0xff333333).withOpacity(0.8),
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Column(
              children: [
                const SizedBox(
                  height: 20,
                ),
                userNameText(),
                const SizedBox(height: 20),
                callTypeText(),
              ],
            ),
            const SizedBox(
              width: 40,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                rejectButton(),
                const SizedBox(width: 40),
                acceptButton(),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget userNameText() {
    return Text(
      widget.invitationData.inviter.userName,
      textAlign: TextAlign.left,
      style: const TextStyle(
        fontSize: 16,
        color: Colors.white,
        fontWeight: FontWeight.normal,
        decoration: TextDecoration.none,
      ),
    );
  }

  Widget callTypeText() {
    return Text(
      widget.invitationData.callType == ZegoCallType.video ? 'video call' : 'voice call',
      textAlign: TextAlign.left,
      style: const TextStyle(
        fontSize: 16,
        color: Colors.white,
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
