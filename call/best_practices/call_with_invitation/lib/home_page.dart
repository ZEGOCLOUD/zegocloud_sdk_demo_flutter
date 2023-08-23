import 'dart:convert';
import 'package:flutter/material.dart';
import 'call/waiting_page.dart';
import 'utils/permission.dart';
import 'dart:async';
import 'call/calling_page.dart';
import 'interal/zim/zim_service_defines.dart';
import 'zego_sdk_manager.dart';
import 'zego_user_Info.dart';
import 'components/zego_call_invitation_dialog.dart';
import 'interal/zim/call_data_manager.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key, required this.localUserID, required this.localUserName}) : super(key: key);

  final String localUserID;
  final String localUserName;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<StreamSubscription<dynamic>?> subscriptions = [];
  final myController = TextEditingController();

  bool dialogIsShowing = false;

  @override
  void initState() {
    super.initState();
    requestPermission();
    subscriptions.addAll([
      ZEGOSDKManager.instance.zimService.incomingCallInvitationReceivedStreamCtrl.stream.listen(
        onIncomingCallInvitationReceived,
      ),
      ZEGOSDKManager.instance.zimService.incomingCallInvitationCanceledStreamCtrl.stream.listen(
        onIncomingCallInvitationCanceled,
      ),
      ZEGOSDKManager.instance.zimService.incomingCallInvitationTimeoutStreamCtrl.stream.listen(
        onIncomingCallInvitationTimeout,
      )
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Zego Call Invitation Demo'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Your userID: ${widget.localUserID}'),
              const SizedBox(height: 20),
              Text('Your userName: ${widget.localUserName}'),
              const SizedBox(height: 20),
              const Divider(),
              const Text('make a direct call:'),
              Row(
                children: [
                  Expanded(
                      child: TextField(
                    controller: myController,
                    decoration: const InputDecoration(labelText: 'input invitee userID'),
                  )),
                  ElevatedButton(
                    onPressed: () => startCall(ZegoCallType.voice),
                    child: const ImageIcon(AssetImage('assets/icons/voice_call_normal.png')),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () => startCall(ZegoCallType.video),
                    child: const ImageIcon(AssetImage('assets/icons/video_call_normal.png')),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<void> startCall(ZegoCallType callType) async {
    final extendedData = jsonEncode({
      'type': callType.index,
      'inviterName': widget.localUserName,
    });

    final ZegoSendInvitationResult result = await ZEGOSDKManager.instance.zimService.sendInvitation(
      invitees: [myController.text],
      callType: callType,
      extendedData: extendedData,
    );

    if (result.error == null || result.error?.code == '0') {
      if (result.errorInvitees.containsKey(myController.text)) {
        ZegoCallStateManager.instance.clearCallData();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('user is not online: $result')),
        );
      } else {
        pushToCallWaitingPage();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('send call invitation failed: $result')),
      );
    }
  }

  void onIncomingCallInvitationReceived(IncomingCallInvitationReveivedEvent event) {
    dialogIsShowing = true;
    showTopModalSheet(
      context,
      GestureDetector(
        onTap: onIncomingCallDialogClicked,
        child: ZegoCallInvitationDialog(
          invitationData: ZegoCallStateManager.instance.callData!,
          onAcceptCallback: acceptCall,
          onRejectCallback: rejectCall,
        ),
      ),
      barrierDismissible: false,
    );
  }

  Future<void> acceptCall() async {
    hideIncomingCallDialog();
    ZegoResponseInvitationResult result = await ZEGOSDKManager.instance.zimService.acceptInvitation(
      invitationID: ZegoCallStateManager.instance.callData!.callID,
    );
    if (result.error == null || result.error?.code == '0') {
      pushToCallingPage();
    }
  }

  Future<void> rejectCall() async {
    hideIncomingCallDialog();
    ZEGOSDKManager.instance.zimService.rejectInvitation(
      invitationID: ZegoCallStateManager.instance.callData!.callID,
    );
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
      Navigator.of(context).pop();
    }
  }

  void onIncomingCallInvitationCanceled(IncomingCallInvitationCanceledEvent event) {
    hideIncomingCallDialog();
  }

  void onIncomingCallInvitationTimeout(IncomingCallInvitationTimeoutEvent event) {
    hideIncomingCallDialog();
  }

  void pushToCallWaitingPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => CallWaitingPage(callData: ZegoCallStateManager.instance.callData!),
      ),
    );
  }

  void pushToCallingPage() {
    if (ZegoCallStateManager.instance.callData != null) {
      ZegoUserInfo otherUser;
      if (ZegoCallStateManager.instance.callData!.inviter.userID != ZEGOSDKManager.instance.localUser.userID) {
        otherUser = ZegoCallStateManager.instance.callData!.inviter;
      } else {
        otherUser = ZegoCallStateManager.instance.callData!.invitee;
      }
      Navigator.push(
        context,
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (context) =>
              CallingPage(callData: ZegoCallStateManager.instance.callData!, otherUserInfo: otherUser),
        ),
      );
    }
  }
}
